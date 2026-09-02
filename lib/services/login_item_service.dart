import 'package:flutter/services.dart';

/// Bridges to a native macOS `SMAppService.mainApp` login-item toggle
/// registered in MainFlutterWindow.swift.
class LoginItemService {
  static const _channel = MethodChannel('app.launch_at_login');

  Future<bool> isEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('isEnabled') ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> setEnabled(bool value) async {
    try {
      final method = value ? 'enable' : 'disable';
      return await _channel.invokeMethod<bool>(method) ?? false;
    } on PlatformException {
      return false;
    }
  }
}
