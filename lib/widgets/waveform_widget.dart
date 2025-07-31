import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';

class WaveformWidget extends StatefulWidget {
  final String? audioPath;
  final Color waveColor;
  final double height;

  const WaveformWidget({
    super.key,
    this.audioPath,
    this.waveColor = Colors.blue,
    this.height = 100,
  });

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget> {
  List<double> waveformData = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.audioPath != null) {
      _generateMockWaveform();
    }
  }

  @override
  void didUpdateWidget(WaveformWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.audioPath != oldWidget.audioPath) {
      if (widget.audioPath != null) {
        _generateMockWaveform();
      } else {
        setState(() {
          waveformData.clear();
        });
      }
    }
  }

  // Generate a mock waveform since we can't easily parse M4A files without additional dependencies
  Future<void> _generateMockWaveform() async {
    if (widget.audioPath == null) return;

    setState(() => isLoading = true);

    try {
      final file = File(widget.audioPath!);
      if (await file.exists()) {
        // Generate a realistic-looking waveform based on file size and random data
        final fileSize = await file.length();
        final random = Random(fileSize); // Use file size as seed for consistent results

        List<double> mockData = [];
        for (int i = 0; i < 200; i++) {
          // Create a more natural waveform pattern
          double baseWave = sin(i * 0.1) * 0.5 + 0.5;
          double noise = (random.nextDouble() - 0.5) * 0.3;
          double amplitude = (baseWave + noise).clamp(0.0, 1.0);
          mockData.add(amplitude);
        }

        setState(() {
          waveformData = mockData;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error generating waveform: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : waveformData.isEmpty
          ? const Center(
        child: Text(
          'No audio data',
          style: TextStyle(color: Colors.grey),
        ),
      )
          : CustomPaint(
        painter: WaveformPainter(
          waveformData: waveformData,
          color: widget.waveColor,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final Color color;

  WaveformPainter({
    required this.waveformData,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    final barWidth = width / waveformData.length;

    for (int i = 0; i < waveformData.length; i++) {
      final barHeight = waveformData[i] * centerY;
      final x = i * barWidth;

      final rect = Rect.fromLTWH(
        x,
        centerY - barHeight,
        barWidth * 0.8,
        barHeight * 2,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}