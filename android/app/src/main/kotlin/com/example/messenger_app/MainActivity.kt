package com.example.messenger_app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val channelName = "messenger_app/chat_head"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"hasOverlayPermission" -> {
						result.success(Settings.canDrawOverlays(this))
					}

					"requestOverlayPermission" -> {
						val intent = Intent(
							Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
							Uri.parse("package:$packageName")
						)
						intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
						startActivity(intent)
						result.success(true)
					}

					"startChatHead" -> {
						val label = call.argument<String>("label") ?: "Chat"
						val partner = call.argument<String>("partner") ?: ""
						val token = call.argument<String>("token") ?: ""
						val currentUsername = call.argument<String>("currentUsername") ?: ""
						val serviceIntent = Intent(this, ChatHeadService::class.java)
						serviceIntent.putExtra("label", label)
						serviceIntent.putExtra("partner", partner)
						serviceIntent.putExtra("token", token)
						serviceIntent.putExtra("currentUsername", currentUsername)
						serviceIntent.action = ChatHeadService.ACTION_START

						if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
							startForegroundService(serviceIntent)
						} else {
							startService(serviceIntent)
						}
						result.success(true)
					}

					"stopChatHead" -> {
						val serviceIntent = Intent(this, ChatHeadService::class.java)
						serviceIntent.action = ChatHeadService.ACTION_STOP
						startService(serviceIntent)
						result.success(true)
					}

					"isChatHeadRunning" -> {
						result.success(ChatHeadService.isRunning)
					}

					else -> result.notImplemented()
				}
			}
	}
}
