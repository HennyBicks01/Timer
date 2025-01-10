import 'dart:math';
import 'package:flutter/material.dart';
import 'timer_view_model.dart';

class TimerView extends StatefulWidget {
  const TimerView({Key? key}) : super(key: key);

  @override
  State<TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends State<TimerView> with WidgetsBindingObserver {
  final _viewModel = TimerViewModel();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive && _viewModel.isRunning) {
      _viewModel.enterPiP();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            if (_viewModel.isInPiPMode) {
              return AspectRatio(
                aspectRatio: 3/4,
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 300 * 0.8,
                    maxHeight: 400 * 0.8,
                  ),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: 300,
                      height: 400,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularTimerPicker(
                            viewModel: _viewModel,
                            size: 200,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '${_viewModel.remainingTime.inMinutes.toString().padLeft(2, '0')}:${(_viewModel.remainingTime.inSeconds % 60).toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
            
            // Normal mode layout
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularTimerPicker(
                  viewModel: _viewModel,
                  size: 300,
                ),
                const SizedBox(height: 20),
                Text(
                  '${_viewModel.remainingTime.inMinutes.toString().padLeft(2, '0')}:${(_viewModel.remainingTime.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TimerControls(viewModel: _viewModel),
              ],
            );
          },
        ),
      ),
    );
  }
}

class CircularTimerPicker extends StatelessWidget {
  final TimerViewModel viewModel;
  final double size;

  const CircularTimerPicker({
    Key? key,
    required this.viewModel,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: GestureDetector(
        onPanUpdate: (details) {
          if (viewModel.isRunning || viewModel.isInPiPMode) return;
          final box = context.findRenderObject() as RenderBox;
          final center = box.size.center(Offset.zero);
          final position = details.localPosition - center;
          final angle = (atan2(position.dy, position.dx) * 180 / pi + 90) % 360;
          final minutes = ((angle / 360) * 60).round();
          viewModel.setMinutes(minutes);
        },
        child: CustomPaint(
          painter: TimerPainter(
            viewModel,
            viewModel.isInPiPMode,
          ),
        ),
      ),
    );
  }
}

class TimerPainter extends CustomPainter {
  final TimerViewModel viewModel;
  final bool isInPipMode;

  TimerPainter(this.viewModel, this.isInPipMode);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = isInPipMode ? 1 : 2;
    canvas.drawCircle(center, radius, borderPaint);

    // Draw selected arc
    final selectedPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    double progress;
    if (viewModel.remainingTime.inSeconds > 0) {
      progress = viewModel.remainingTime.inSeconds / (60 * 60);
    } else {
      progress = viewModel.selectedMinutes / 60;
    }
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      true,
      selectedPaint,
    );

    // Only draw time markers if not in PIP mode or if specifically requested
    if (!isInPipMode) {
      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
      );

      for (int i = 0; i < 12; i++) {
        final angle = 2 * pi * (i / 12) - pi / 2;
        final markerX = center.dx + cos(angle) * (radius - 30);
        final markerY = center.dy + sin(angle) * (radius - 30);
        
        textPainter.text = TextSpan(
          text: '${i * 5}',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        );
        
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(markerX - textPainter.width / 2, markerY - textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TimerControls extends StatelessWidget {
  final TimerViewModel viewModel;

  const TimerControls({
    Key? key,
    required this.viewModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(viewModel.isRunning ? Icons.pause : Icons.play_arrow),
          iconSize: 48,
          onPressed: () {
            if (viewModel.isRunning) {
              viewModel.pauseTimer();
            } else {
              viewModel.startTimer();
            }
          },
        ),
        const SizedBox(width: 20),
        IconButton(
          icon: const Icon(Icons.refresh),
          iconSize: 48,
          onPressed: () => viewModel.resetTimer(),
        ),
      ],
    );
  }
}
