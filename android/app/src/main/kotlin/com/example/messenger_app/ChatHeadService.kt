package com.example.messenger_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowInsets
import android.view.WindowManager
import android.widget.Button
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.core.app.NotificationCompat
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStream
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import kotlin.math.abs

class ChatHeadService : Service() {
    companion object {
        const val ACTION_START = "messenger_app.chathead.START"
        const val ACTION_STOP = "messenger_app.chathead.STOP"
        private const val CHANNEL_ID = "chat_head_channel"
        private const val NOTIFICATION_ID = 8127

        @Volatile
        var isRunning: Boolean = false
    }

    private var windowManager: WindowManager? = null
    private var bubbleView: View? = null
    private var panelView: View? = null
    private var deleteTargetView: View? = null
    private var deleteTargetParams: WindowManager.LayoutParams? = null
    private var bubbleParams: WindowManager.LayoutParams? = null
    private var authToken: String? = null
    private var partner: String? = null
    private var currentUsername: String? = null
    private var messagesContainer: LinearLayout? = null
    private var messagesScrollView: ScrollView? = null
    private var messageInput: EditText? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        if (ACTION_STOP == action) {
            stopSelf()
            return START_NOT_STICKY
        }

        authToken = intent?.getStringExtra("token") ?: authToken
        partner = intent?.getStringExtra("partner") ?: partner
        currentUsername = intent?.getStringExtra("currentUsername") ?: currentUsername
        if (authToken.isNullOrBlank() || partner.isNullOrBlank()) {
            stopSelf()
            return START_NOT_STICKY
        }
        val label = intent?.getStringExtra("label") ?: "Chat"
        startInForeground(label)

        if (bubbleView == null) {
            showBubble(label)
            isRunning = true
        }

        return START_NOT_STICKY
    }

    private fun startInForeground(label: String) {
        createNotificationChannel()

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val contentIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val stopIntent = Intent(this, ChatHeadService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this,
            1,
            stopIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("$label bubble is active")
            .setContentText("Tap bubble for quick chat")
            .setSmallIcon(android.R.drawable.sym_action_chat)
            .setContentIntent(contentIntent)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Stop bubble",
                stopPendingIntent
            )
            .setOngoing(true)
            .build()

        startForeground(NOTIFICATION_ID, notification)
    }

    private fun showBubble(label: String) {
        val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        windowManager = wm
        val bubbleSize = dp(56)

        val bubbleBackground = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(0xFF1277F2.toInt())
        }

        val bubbleText = TextView(this).apply {
            text = label.firstOrNull()?.uppercase() ?: "C"
            textSize = 18f
            setTypeface(typeface, Typeface.BOLD)
            setTextColor(0xFFFFFFFF.toInt())
            gravity = Gravity.CENTER
            background = bubbleBackground
            elevation = dp(6).toFloat()
            layoutParams = FrameLayout.LayoutParams(bubbleSize, bubbleSize)
        }

        val root = FrameLayout(this).apply {
            addView(bubbleText)
        }

        val params = WindowManager.LayoutParams(
            bubbleSize,
            bubbleSize,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )

        params.gravity = Gravity.TOP or Gravity.START
        params.x = 24
        params.y = 300
        clampBubblePosition(params)
        bubbleParams = params

        var startX = 0
        var startY = 0
        var touchX = 0f
        var touchY = 0f
        var dragStarted = false

        root.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    startX = params.x
                    startY = params.y
                    touchX = event.rawX
                    touchY = event.rawY
                    dragStarted = false
                    true
                }

                MotionEvent.ACTION_MOVE -> {
                    if (!dragStarted) {
                        showDeleteTarget()
                        dragStarted = true
                    }
                    params.x = startX + (event.rawX - touchX).toInt()
                    params.y = startY + (event.rawY - touchY).toInt()
                    clampBubblePosition(params)
                    wm.updateViewLayout(root, params)
                    updateDeleteTargetState(params)
                    true
                }

                MotionEvent.ACTION_UP -> {
                    val movedX = abs(event.rawX - touchX)
                    val movedY = abs(event.rawY - touchY)
                    val droppedOnDelete = isInsideDeleteTarget(params)
                    hideDeleteTarget()
                    if (movedX < 12 && movedY < 12 && event.eventTime - event.downTime > 900) {
                        stopSelf()
                        return@setOnTouchListener true
                    }
                    if (droppedOnDelete) {
                        stopSelf()
                        return@setOnTouchListener true
                    }
                    if (movedX < 12 && movedY < 12) {
                        toggleQuickPanel(label)
                    } else {
                        snapBubbleToEdge(root, params, wm)
                    }
                    true
                }

                MotionEvent.ACTION_CANCEL -> {
                    hideDeleteTarget()
                    false
                }

                else -> false
            }
        }

        bubbleView = root
        wm.addView(root, params)
    }

    private fun toggleQuickPanel(label: String) {
        if (panelView == null) {
            showQuickPanel(label)
        } else {
            hideQuickPanel()
        }
    }

    private fun showQuickPanel(label: String) {
        val wm = windowManager ?: return
        val metrics = resources.displayMetrics
        val panelWidth = metrics.widthPixels
        val panelHeight = metrics.heightPixels

        val cardBackground = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = dp(18).toFloat()
            setColor(0xFFF5F6F8.toInt())
            setStroke(dp(1), 0xFFE3E8F2.toInt())
        }

        val title = TextView(this).apply {
            text = partner ?: label
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 17f)
            setTypeface(typeface, Typeface.BOLD)
            setTextColor(0xFF16233A.toInt())
        }

        val subtitle = TextView(this).apply {
            text = "Chat bubble"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            setTextColor(0xFF72819A.toInt())
        }

        val header = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            addView(title)
            addView(subtitle)
        }

        val closeButton = TextView(this).apply {
            text = "✕"
            gravity = Gravity.CENTER
            setTextColor(0xFF5B6D89.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(0xFFE7EDF8.toInt())
            }
            layoutParams = LinearLayout.LayoutParams(dp(30), dp(30))
            setOnClickListener { hideQuickPanel() }
        }

        val messageIconBadge = ImageView(this).apply {
            setImageResource(android.R.drawable.sym_action_chat)
            setColorFilter(0xFFFFFFFF.toInt())
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(0x73000000)
            }
            setPadding(dp(8), dp(8), dp(8), dp(8))
            layoutParams = LinearLayout.LayoutParams(dp(36), dp(36))
        }

        val receiverAvatarImage = ImageView(this).apply {
            scaleType = ImageView.ScaleType.CENTER_CROP
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(0xFFE8EDF6.toInt())
            }
            layoutParams = FrameLayout.LayoutParams(dp(32), dp(32), Gravity.CENTER)
            clipToOutline = true
        }

        val receiverAvatar = FrameLayout(this).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(0x73000000)
            }
            layoutParams = LinearLayout.LayoutParams(dp(36), dp(36))
            addView(receiverAvatarImage)
        }
        loadPartnerAvatarInto(receiverAvatarImage)

        val headerActions = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            addView(messageIconBadge)
            addView(spacerWidth(8))
            addView(receiverAvatar)
            addView(spacerWidth(8))
            addView(closeButton)
        }

        val headerRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            addView(
                header,
                LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            )
            addView(headerActions)
        }

        messagesContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(6), dp(2), dp(6), dp(2))
        }

        val scrollView = ScrollView(this).apply {
            isVerticalScrollBarEnabled = false
            overScrollMode = View.OVER_SCROLL_NEVER
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(14).toFloat()
                setColor(0xFFFFFFFF.toInt())
                setStroke(dp(1), 0xFFE7ECF6.toInt())
            }
            addView(
                messagesContainer,
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.WRAP_CONTENT
                )
            )
        }

        messageInput = EditText(this).apply {
            hint = "Type a message"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            setTextColor(0xFF1D2433.toInt())
            setHintTextColor(0xFF93A0B7.toInt())
            setPadding(dp(14), dp(10), dp(14), dp(10))
            setSingleLine(true)
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(14).toFloat()
                setColor(0xFFEEF0F4.toInt())
                setStroke(dp(1), 0xFFDCE3EE.toInt())
            }
        }

        val sendButton = TextView(this).apply {
            text = "Send"
            gravity = Gravity.CENTER
            setTextColor(0xFFFFFFFF.toInt())
            setTypeface(typeface, Typeface.BOLD)
            setPadding(dp(16), dp(10), dp(16), dp(10))
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(14).toFloat()
                setColor(0xFF4ED0AF.toInt())
            }
            setOnClickListener {
                val text = messageInput?.text?.toString()?.trim().orEmpty()
                if (text.isNotEmpty()) {
                    sendMessageAsync(text)
                    messageInput?.setText("")
                }
            }
        }

        messageInput?.setOnEditorActionListener { _, _, _ ->
            val text = messageInput?.text?.toString()?.trim().orEmpty()
            if (text.isNotEmpty()) {
                sendMessageAsync(text)
                messageInput?.setText("")
                true
            } else {
                false
            }
        }

        val composer = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            addView(
                messageInput,
                LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            )
            addView(spacerWidth(8))
            addView(
                sendButton,
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            )
        }

        val openAppButton = TextView(this).apply {
            text = "Open Full App"
            gravity = Gravity.CENTER
            setTextColor(0xFF697386.toInt())
            setTypeface(typeface, Typeface.BOLD)
            setPadding(dp(16), dp(10), dp(16), dp(10))
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(14).toFloat()
                setColor(0xFFEDEFF3.toInt())
            }
            setOnClickListener { openFullApp() }
        }

        val messagesTab = TextView(this).apply {
            text = "Messages"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            setTextColor(0xFFFFFFFF.toInt())
            setTypeface(typeface, Typeface.BOLD)
            gravity = Gravity.CENTER
            setPadding(dp(14), dp(7), dp(14), dp(7))
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(18).toFloat()
                setColor(0xFF4ED0AF.toInt())
            }
        }

        val mediaTab = TextView(this).apply {
            text = "Media"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            setTextColor(0xFF8B95A7.toInt())
            setPadding(dp(10), dp(7), dp(10), dp(7))
        }

        val tabsRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.START or Gravity.CENTER_VERTICAL
            addView(messagesTab)
            addView(spacerWidth(8))
            addView(mediaTab)
        }

        val basePaddingLeft = dp(14)
        val basePaddingTop = dp(28)
        val basePaddingRight = dp(14)
        val basePaddingBottom = dp(10)

        val bodyCard = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = cardBackground
            setPadding(dp(12), dp(12), dp(12), dp(10))
            addView(tabsRow)
            addView(spacer(12))
            addView(
                scrollView,
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    0,
                    1f
                )
            )
            addView(spacer(12))
            addView(composer)
            addView(spacer(8))
            addView(
                openAppButton,
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            )
        }

        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(basePaddingLeft, basePaddingTop, basePaddingRight, basePaddingBottom)
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                setColor(Color.TRANSPARENT)
            }
            addView(headerRow)
            addView(spacer(10))
            addView(
                bodyCard,
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    0,
                    1f
                )
            )
        }

        val root = FrameLayout(this).apply {
            addView(content)
        }

        val params = WindowManager.LayoutParams(
            panelWidth,
            panelHeight,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )
        params.softInputMode =
            WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE or
                WindowManager.LayoutParams.SOFT_INPUT_STATE_HIDDEN

        params.gravity = Gravity.TOP or Gravity.START
        params.x = 0
        params.y = 0
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            root.setOnApplyWindowInsetsListener { _, insets ->
                val imeBottom = insets.getInsets(WindowInsets.Type.ime()).bottom
                val systemBottom = insets.getInsets(WindowInsets.Type.systemBars()).bottom
                val keyboardInset = (imeBottom - systemBottom).coerceAtLeast(0)
                content.setPadding(
                    basePaddingLeft,
                    basePaddingTop,
                    basePaddingRight,
                    basePaddingBottom + keyboardInset
                )
                if (keyboardInset > 0) {
                    scrollToLatestMessages()
                }
                insets
            }
        }

        messagesScrollView = scrollView
        panelView = root
        wm.addView(root, params)
        loadMessagesAsync()
    }

    private fun loadPartnerAvatarInto(imageView: ImageView) {
        val peer = partner ?: return
        val token = resolveAuthToken() ?: return

        Thread {
            try {
                val encodedPartner = URLEncoder.encode(peer, "UTF-8")
                val profileUrl = URL("https://messenger.otaworkstation.shop/api/profile/$encodedPartner")
                val profileConnection = (profileUrl.openConnection() as HttpURLConnection).apply {
                    requestMethod = "GET"
                    setRequestProperty("Authorization", "Bearer $token")
                    setRequestProperty("Content-Type", "application/json")
                    connectTimeout = 12000
                    readTimeout = 12000
                }

                val profileBody = readStream(
                    if (profileConnection.responseCode in 200..299) {
                        profileConnection.inputStream
                    } else {
                        profileConnection.errorStream
                    }
                )
                profileConnection.disconnect()

                if (profileBody.isBlank()) return@Thread
                val profileJson = JSONObject(profileBody)
                val rawPath = profileJson.optString("profilePictureUrl", "")
                if (rawPath.isBlank()) return@Thread

                val resolvedPath = resolveApiUrl(rawPath)
                val bitmapConnection = (URL(resolvedPath).openConnection() as HttpURLConnection).apply {
                    requestMethod = "GET"
                    connectTimeout = 12000
                    readTimeout = 12000
                }
                val bitmap = bitmapConnection.inputStream.use { input ->
                    BitmapFactory.decodeStream(input)
                }
                bitmapConnection.disconnect()

                if (bitmap != null) {
                    mainHandler.post {
                        imageView.setImageBitmap(bitmap)
                    }
                }
            } catch (_: Exception) {
            }
        }.start()
    }

    private fun resolveApiUrl(urlOrPath: String): String {
        return if (urlOrPath.startsWith("http://") || urlOrPath.startsWith("https://")) {
            urlOrPath
        } else if (urlOrPath.startsWith("/api/")) {
            "https://messenger.otaworkstation.shop$urlOrPath"
        } else {
            "https://messenger.otaworkstation.shop/api${if (urlOrPath.startsWith('/')) "" else "/"}$urlOrPath"
        }
    }

    private fun hideQuickPanel() {
        val wm = windowManager ?: return
        panelView?.let { wm.removeView(it) }
        panelView = null
        messagesContainer = null
        messagesScrollView = null
        messageInput = null
    }

    private fun openFullApp() {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        launchIntent?.addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
        )
        if (launchIntent != null) {
            startActivity(launchIntent)
        }
    }

    private fun loadMessagesAsync() {
        val token = resolveAuthToken() ?: return
        val peer = partner ?: return

        Thread {
            val encodedPartner = URLEncoder.encode(peer, "UTF-8")
            val url = URL("https://messenger.otaworkstation.shop/api/messages/conversation/$encodedPartner?page=0&size=20")
            val connection = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "GET"
                setRequestProperty("Authorization", "Bearer $token")
                setRequestProperty("Content-Type", "application/json")
                connectTimeout = 12000
                readTimeout = 12000
            }

            try {
                var code = connection.responseCode
                var source = if (code in 200..299) connection.inputStream else connection.errorStream
                var body = readStream(source)

                if (code == 401 || code == 403) {
                    val retryToken = getStoredToken()
                    if (!retryToken.isNullOrBlank() && retryToken != token) {
                        authToken = retryToken
                        connection.disconnect()
                        val retryConnection = (url.openConnection() as HttpURLConnection).apply {
                            requestMethod = "GET"
                            setRequestProperty("Authorization", "Bearer $retryToken")
                            setRequestProperty("Content-Type", "application/json")
                            connectTimeout = 12000
                            readTimeout = 12000
                        }
                        code = retryConnection.responseCode
                        source = if (code in 200..299) retryConnection.inputStream else retryConnection.errorStream
                        body = readStream(source)
                        retryConnection.disconnect()
                    }
                }

                if (code !in 200..299 || body.isBlank()) {
                    postSystemMessage("Failed to load messages ($code)")
                    return@Thread
                }

                val json = JSONObject(body)
                val page = json.optJSONObject("messages") ?: json
                val array = page.optJSONArray("content") ?: return@Thread
                val items = mutableListOf<Pair<String, String>>()
                for (i in array.length() - 1 downTo 0) {
                    val item = array.getJSONObject(i)
                    val sender = item.optString("sender")
                    val content = item.optString("content")
                    if (content.isNotBlank()) {
                        items.add(sender to content)
                    }
                }

                mainHandler.post { renderMessages(items) }
            } catch (_: Exception) {
                postSystemMessage("Message sync error")
            } finally {
                connection.disconnect()
            }
        }.start()
    }

    private fun sendMessageAsync(text: String) {
        val token = resolveAuthToken() ?: return
        val peer = partner ?: return

        Thread {
            // Use the same transport as the Flutter app first (STOMP over WebSocket).
            if (trySendViaStomp(token, peer, text)) {
                mainHandler.postDelayed({ loadMessagesAsync() }, 500)
                return@Thread
            }

            val url = URL("https://messenger.otaworkstation.shop/api/messages/send")
            val connection = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                doOutput = true
                setRequestProperty("Authorization", "Bearer $token")
                setRequestProperty("Content-Type", "application/json")
                setRequestProperty("Accept", "application/json")
                connectTimeout = 12000
                readTimeout = 12000
            }

            try {
                val payload = JSONObject().apply {
                    put("recipient", peer)
                    put("content", text)
                }
                connection.outputStream.use { out ->
                    out.write(payload.toString().toByteArray(Charsets.UTF_8))
                }

                var code = connection.responseCode
                if (code in 200..299) {
                    loadMessagesAsync()
                } else {
                    var details = readStream(connection.errorStream)

                    if (code == 401 || code == 403) {
                        val retryToken = getStoredToken()
                        if (!retryToken.isNullOrBlank() && retryToken != token) {
                            authToken = retryToken
                            val retryConnection = (url.openConnection() as HttpURLConnection).apply {
                                requestMethod = "POST"
                                doOutput = true
                                setRequestProperty("Authorization", "Bearer $retryToken")
                                setRequestProperty("Content-Type", "application/json")
                                setRequestProperty("Accept", "application/json")
                                connectTimeout = 12000
                                readTimeout = 12000
                            }
                            retryConnection.outputStream.use { out ->
                                out.write(payload.toString().toByteArray(Charsets.UTF_8))
                            }
                            code = retryConnection.responseCode
                            if (code in 200..299) {
                                retryConnection.disconnect()
                                loadMessagesAsync()
                                return@Thread
                            }
                            details = readStream(retryConnection.errorStream)
                            retryConnection.disconnect()
                        }
                    }

                    val trimmed = details
                        .replace("\n", " ")
                        .replace("\r", " ")
                        .trim()
                        .take(100)
                    postSystemMessage(
                        if (trimmed.isBlank()) {
                            "Send failed ($code)"
                        } else {
                            "Send failed ($code): $trimmed"
                        }
                    )
                }
            } catch (_: Exception) {
                postSystemMessage("Send failed")
            } finally {
                connection.disconnect()
            }
        }.start()
    }

    private fun trySendViaStomp(token: String, peer: String, text: String): Boolean {
        val payload = JSONObject().apply {
            put("recipient", peer)
            put("content", text)
        }.toString()

        val latch = CountDownLatch(1)
        var sent = false
        val client = OkHttpClient.Builder()
            .readTimeout(0, TimeUnit.MILLISECONDS)
            .connectTimeout(8, TimeUnit.SECONDS)
            .build()

        val request = Request.Builder()
            .url("wss://messenger.otaworkstation.shop/ws/websocket")
            .addHeader("Authorization", "Bearer $token")
            .build()

        lateinit var socket: WebSocket
        socket = client.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                val connectFrame = buildString {
                    append("CONNECT\n")
                    append("accept-version:1.2\n")
                    append("heart-beat:0,0\n")
                    append("Authorization:Bearer $token\n")
                    append("\n")
                    append('\u0000')
                }
                webSocket.send(connectFrame)
            }

            override fun onMessage(webSocket: WebSocket, textFrame: String) {
                if (textFrame.startsWith("CONNECTED")) {
                    val sendFrame = buildString {
                        append("SEND\n")
                        append("destination:/app/chat.send\n")
                        append("content-type:application/json\n")
                        append("\n")
                        append(payload)
                        append('\u0000')
                    }
                    sent = webSocket.send(sendFrame)
                    webSocket.close(1000, "done")
                    latch.countDown()
                }
                if (textFrame.startsWith("ERROR")) {
                    webSocket.close(1002, "stomp_error")
                    latch.countDown()
                }
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                latch.countDown()
            }

            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                latch.countDown()
            }
        })

        val completed = latch.await(6, TimeUnit.SECONDS)
        if (!completed) {
            socket.cancel()
        }

        client.dispatcher.executorService.shutdown()
        return completed && sent
    }

    private fun clampBubblePosition(params: WindowManager.LayoutParams) {
        val metrics = resources.displayMetrics
        val margin = dp(8)
        val minX = margin
        val maxX = (metrics.widthPixels - params.width - margin).coerceAtLeast(minX)
        val minY = dp(40)
        val maxY = (metrics.heightPixels - params.height - margin).coerceAtLeast(minY)
        params.x = params.x.coerceIn(minX, maxX)
        params.y = params.y.coerceIn(minY, maxY)
    }

    private fun snapBubbleToEdge(
        view: View,
        params: WindowManager.LayoutParams,
        wm: WindowManager
    ) {
        val metrics = resources.displayMetrics
        val margin = dp(8)
        val center = params.x + (params.width / 2)
        params.x = if (center >= metrics.widthPixels / 2) {
            (metrics.widthPixels - params.width - margin).coerceAtLeast(margin)
        } else {
            margin
        }
        clampBubblePosition(params)
        wm.updateViewLayout(view, params)
    }

    private fun clampPanelPosition(params: WindowManager.LayoutParams) {
        val metrics = resources.displayMetrics
        val margin = dp(8)
        val panelWidth = params.width
        if (panelWidth >= metrics.widthPixels - margin * 2) {
            params.width = (metrics.widthPixels - margin * 2).coerceAtLeast(dp(220))
        }
        val minX = margin
        val maxX = (metrics.widthPixels - params.width - margin).coerceAtLeast(minX)
        val minY = dp(32)
        val panelHeight = if (params.height > 0) params.height else dp(220)
        val maxY = (metrics.heightPixels - panelHeight - margin).coerceAtLeast(minY)
        params.x = params.x.coerceIn(minX, maxX)
        params.y = params.y.coerceIn(minY, maxY)
    }

    private fun showDeleteTarget() {
        val wm = windowManager ?: return
        if (deleteTargetView != null) return

        val targetSize = dp(80)
        val iconSize = dp(50)

        val icon = TextView(this).apply {
            text = "✕"
            gravity = Gravity.CENTER
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
            setTypeface(typeface, Typeface.BOLD)
            setTextColor(0xFFFFFFFF.toInt())
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(0xFFFF4D5A.toInt())
            }
            layoutParams = FrameLayout.LayoutParams(iconSize, iconSize, Gravity.CENTER)
            elevation = dp(6).toFloat()
        }

        val root = FrameLayout(this).apply {
            addView(icon)
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(0x30FF4D5A)
            }
        }

        val params = WindowManager.LayoutParams(
            targetSize,
            targetSize,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )

        params.gravity = Gravity.TOP or Gravity.START
        params.x = (resources.displayMetrics.widthPixels - targetSize) / 2
        params.y = (resources.displayMetrics.heightPixels - targetSize - dp(28)).coerceAtLeast(dp(80))

        deleteTargetView = root
        deleteTargetParams = params
        wm.addView(root, params)
    }

    private fun hideDeleteTarget() {
        val wm = windowManager ?: return
        deleteTargetView?.let { wm.removeView(it) }
        deleteTargetView = null
        deleteTargetParams = null
    }

    private fun updateDeleteTargetState(bubble: WindowManager.LayoutParams) {
        val root = deleteTargetView ?: return
        root.alpha = if (isInsideDeleteTarget(bubble)) 1f else 0.78f
    }

    private fun isInsideDeleteTarget(bubble: WindowManager.LayoutParams): Boolean {
        val target = deleteTargetParams ?: return false
        val bubbleCenterX = bubble.x + bubble.width / 2
        val bubbleCenterY = bubble.y + bubble.height / 2

        val targetCenterX = target.x + target.width / 2
        val targetCenterY = target.y + target.height / 2
        val thresholdX = (target.width / 2) + dp(8)
        val thresholdY = (target.height / 2) + dp(8)

        return abs(bubbleCenterX - targetCenterX) <= thresholdX &&
            abs(bubbleCenterY - targetCenterY) <= thresholdY
    }

    private fun renderMessages(items: List<Pair<String, String>>) {
        val container = messagesContainer ?: return
        container.removeAllViews()

        if (items.isEmpty()) {
            postSystemMessage("No messages yet")
            return
        }

        items.takeLast(12).forEach { (sender, content) ->
            val isMine = sender == currentUsername
            container.addView(buildBubble(content, isMine))
            container.addView(spacer(6))
        }

        scrollToLatestMessages()
    }

    private fun scrollToLatestMessages() {
        messagesScrollView?.post {
            messagesScrollView?.fullScroll(View.FOCUS_DOWN)
        }
    }

    private fun postSystemMessage(text: String) {
        mainHandler.post {
            val container = messagesContainer ?: return@post
            val note = TextView(this).apply {
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
                setTextColor(0xFF6F7888.toInt())
                this.text = text
                gravity = Gravity.CENTER
            }
            container.removeAllViews()
            container.addView(note)
        }
    }

    private fun buildBubble(text: String, isMine: Boolean): View {
        val bubble = TextView(this).apply {
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            setTextColor(0xFF3D4656.toInt())
            setPadding(dp(14), dp(10), dp(14), dp(10))
            this.text = text
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(14).toFloat()
                setColor(if (isMine) 0xFFE8E3FF.toInt() else 0xFFEFF1F5.toInt())
            }
        }

        return LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = if (isMine) Gravity.END else Gravity.START
            addView(
                bubble,
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            )
        }
    }

    private fun resolveAuthToken(): String? {
        if (!authToken.isNullOrBlank()) return authToken
        authToken = getStoredToken()
        return authToken
    }

    private fun getStoredToken(): String? {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        return prefs.getString("flutter.jwt_token", null)
    }

    private fun readStream(stream: InputStream?): String {
        if (stream == null) return ""
        val builder = StringBuilder()
        BufferedReader(InputStreamReader(stream)).use { reader ->
            var line: String? = reader.readLine()
            while (line != null) {
                builder.append(line)
                line = reader.readLine()
            }
        }
        return builder.toString()
    }

    private fun spacer(heightDp: Int): View {
        return View(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(heightDp)
            )
        }
    }

    private fun spacerWidth(widthDp: Int): View {
        return View(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                dp(widthDp),
                LinearLayout.LayoutParams.MATCH_PARENT
            )
        }
    }

    private fun dp(value: Int): Int {
        return (value * resources.displayMetrics.density).toInt()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Chat Bubble",
            NotificationManager.IMPORTANCE_LOW
        )
        channel.description = "Shows notification for chat bubble service"

        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.createNotificationChannel(channel)
    }

    override fun onDestroy() {
        super.onDestroy()
        hideQuickPanel()
        hideDeleteTarget()
        bubbleView?.let { view ->
            windowManager?.removeView(view)
        }
        bubbleView = null
        isRunning = false
    }
}
