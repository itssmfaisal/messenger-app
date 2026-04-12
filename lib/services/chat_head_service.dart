import 'dart:io';

import 'package:flutter/services.dart';

class ChatHeadService {
  static const MethodChannel _channel = MethodChannel(
    'messenger_app/chat_head',
  );

  static Future<bool> isChatHeadRunning() async {
    if (!Platform.isAndroid) return false;
    final running = await _channel.invokeMethod<bool>('isChatHeadRunning');
    return running ?? false;
  }

  static Future<bool> ensureOverlayPermission() async {
    if (!Platform.isAndroid) return false;
    final hasPermission =
        await _channel.invokeMethod<bool>('hasOverlayPermission') ?? false;
    if (hasPermission) return true;

    await _channel.invokeMethod('requestOverlayPermission');
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final granted =
        await _channel.invokeMethod<bool>('hasOverlayPermission') ?? false;
    return granted;
  }

  static Future<void> startChatHead({
    String label = 'Chat',
    required String partner,
    required String token,
    required String currentUsername,
  }) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('startChatHead', {
      'label': label,
      'partner': partner,
      'token': token,
      'currentUsername': currentUsername,
    });
  }

  static Future<void> stopChatHead() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('stopChatHead');
  }
}
