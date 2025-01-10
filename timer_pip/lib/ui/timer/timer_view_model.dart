import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/pip_service.dart';

class TimerViewModel extends ChangeNotifier {
  final PiPService _pipService = PiPService();
  int _selectedMinutes = 0;
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
  }

  int get selectedMinutes => _selectedMinutes;
  bool get isRunning => _isRunning;
  Duration get remainingTime => _remainingTime;
  bool get isInPiPMode => _isInPiPMode;

  void setMinutes(int minutes) {
    if (_isRunning) return;
    _selectedMinutes = minutes;
    _remainingTime = Duration(minutes: minutes);
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
    _remainingTime = Duration(minutes: _selectedMinutes);
    _pipService.updateTimerStatus(false);
    notifyListeners();
  }

  Future<void> enterPiP() async {
    if (_isRunning) {
      await _pipService.enterPiP();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
