import 'package:flutter/services.dart';

class PiPService {
  static const _channel = MethodChannel('com.example.timer_pip/pip');
  bool _isInPiPMode = false;
  Function(bool)? _onPiPChanged;

  bool get isInPiPMode => _isInPiPMode;

  PiPService() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPiPChanged':
        _isInPiPMode = call.arguments as bool;
        _onPiPChanged?.call(_isInPiPMode);
        break;
    }
  }

  Future<bool> enterPiP() async {
    try {
      final bool result = await _channel.invokeMethod('enterPiP');
      return result;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<void> updateTimerStatus(bool isRunning) async {
    try {
      await _channel.invokeMethod('updateTimerStatus', {'isRunning': isRunning});
    } on PlatformException catch (_) {
      // Handle error
    }
  }

  void setOnPiPChangedListener(Function(bool) listener) {
    _onPiPChanged = listener;
  }
}
