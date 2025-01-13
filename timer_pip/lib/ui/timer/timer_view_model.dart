import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/pip_service.dart';
import 'package:flutter/services.dart' show MethodChannel, MethodCall;

class TimerViewModel extends ChangeNotifier {
  final PiPService _pipService = PiPService();
  static const platform = MethodChannel('com.example.timer_pip/timer');
  double _selectedMinutes = 0;
  bool _isRunning = false;
  Duration _remainingTime = Duration.zero;
  Timer? _timer;
  bool _isInPiPMode = false;

  TimerViewModel() {
    _pipService.setOnPiPChangedListener((inPiPMode) {
      _isInPiPMode = inPiPMode;
      notifyListeners();
    });

    _pipService.setOnPlayRequestedListener(() {
      if (!_isRunning) {
        startTimer();
      }
    });

    _pipService.setOnPauseRequestedListener(() {
      if (_isRunning) {
        pauseTimer();
      }
    });

    platform.setMethodCallHandler(_handleMethodCall);
  }

  int get selectedMinutes => _selectedMinutes.round();
  bool get isRunning => _isRunning;
  Duration get remainingTime => _remainingTime;
  bool get isInPiPMode => _isInPiPMode;

  void setMinutes(double minutes) {
    if (_isRunning) return;
    _selectedMinutes = minutes;
    _remainingTime = Duration(seconds: (minutes * 60).round());
    notifyListeners();
  }

  void startTimer() {
    if (_remainingTime.inSeconds == 0) return;
    
    _isRunning = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);
        notifyListeners();
      } else {
        _timer?.cancel();
        _isRunning = false;
        notifyListeners();
      }
    });
    _pipService.updateTimerStatus(true);
    notifyListeners();
  }

  void pauseTimer() {
    _isRunning = false;
    _timer?.cancel();
    _pipService.updateTimerStatus(false);
    notifyListeners();
  }

  void resetTimer() {
    _isRunning = false;
    _timer?.cancel();
    _remainingTime = Duration(seconds: (_selectedMinutes * 60).round());
    _pipService.updateTimerStatus(false);
    notifyListeners();
  }

  Future<void> enterPiP() async {
    if (_isRunning) {
      await _pipService.enterPiP();
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'setTimer':
        final seconds = call.arguments as int;
        final minutes = seconds / 60;
        setMinutes(minutes);
        startTimer();
        break;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
