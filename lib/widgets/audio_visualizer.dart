import 'package:flutter/material.dart';
import 'dart:math' as math;

class AudioVisualizer extends StatefulWidget {
  final bool isRecording;
  final List<double> audioLevels;
  final Color color;

  const AudioVisualizer({
    super.key,
    required this.isRecording,
    this.audioLevels = const [],
    this.color = Colors.blue,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);

    if (widget.isRecording) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      child: widget.isRecording
          ? AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: VisualizerPainter(
              animation: _animation.value,
              color: widget.color,
            ),
            size: Size.infinite,
          );
        },
      )
          : widget.audioLevels.isNotEmpty
          ? CustomPaint(
        painter: StaticWaveformPainter(
          levels: widget.audioLevels,
          color: widget.color,
        ),
        size: Size.infinite,
      )
          : Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Audio Visualizer',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

class VisualizerPainter extends CustomPainter {
  final double animation;
  final Color color;

  VisualizerPainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final barCount = 20;
    final barWidth = size.width / barCount;
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final height = (math.sin(animation * 2 * math.pi + i * 0.5) + 1) *
          centerY *
          (0.3 + 0.7 * math.Random(i).nextDouble());

      final rect = Rect.fromLTWH(
        i * barWidth + barWidth * 0.1,
        centerY - height / 2,
        barWidth * 0.8,
        height,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class StaticWaveformPainter extends CustomPainter {
  final List<double> levels;
  final Color color;

  StaticWaveformPainter({required this.levels, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final barWidth = size.width / levels.length;
    final centerY = size.height / 2;

    for (int i = 0; i < levels.length; i++) {
      final height = levels[i] * size.height;

      final rect = Rect.fromLTWH(
        i * barWidth,
        centerY - height / 2,
        barWidth * 0.8,
        height,
      );

      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}