import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class AudioUtils {
  static Future<String> getAudioDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${directory.path}/audio_recordings');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir.path;
  }

  static Future<List<String>> getAllRecordings() async {
    final audioDir = await getAudioDirectory();
    final directory = Directory(audioDir);

    if (!await directory.exists()) return [];

    final files = await directory.list().toList();
    return files
        .where((file) => file is File && file.path.endsWith('.wav'))
        .map((file) => file.path)
        .toList();
  }

  static Future<void> deleteRecording(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static bool isValidAudioFile(String filePath) {
    return filePath.toLowerCase().endsWith('.wav') ||
        filePath.toLowerCase().endsWith('.mp3') ||
        filePath.toLowerCase().endsWith('.m4a');
  }

  // Convert other audio formats to WAV if needed
  static Future<String?> convertToWav(String inputPath) async {
    // This would require additional audio processing libraries
    // For now, we assume input is already in WAV format
    if (inputPath.toLowerCase().endsWith('.wav')) {
      return inputPath;
    }

    // In a real implementation, you would use libraries like FFmpeg
    // to convert between audio formats
    return null;
  }

  // Extract amplitude data for waveform visualization
  static List<double> extractWaveformData(Uint8List audioBytes, int targetPoints) {
    List<double> samples = [];

    // Skip WAV header (44 bytes) and extract 16-bit samples
    for (int i = 44; i < audioBytes.length - 1; i += 2) {
      int sample = (audioBytes[i + 1] << 8) | audioBytes[i];
      if (sample > 32767) sample -= 65536;
      samples.add(sample.abs() / 32768.0); // Normalize to 0.0-1.0
    }

    if (samples.isEmpty) return [];

    // Downsample to target number of points
    final chunkSize = samples.length / targetPoints;
    List<double> result = [];

    for (int i = 0; i < targetPoints; i++) {
      final start = (i * chunkSize).floor();
      final end = ((i + 1) * chunkSize).floor().clamp(0, samples.length);

      if (start < end) {
        double max = 0;
        for (int j = start; j < end; j++) {
          max = samples[j] > max ? samples[j] : max;
        }
        result.add(max);
      } else {
        result.add(0);
      }
    }

    return result;
  }

  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final milliseconds = (duration.inMilliseconds.remainder(1000) / 10).floor().toString().padLeft(2, '0');
    return '$minutes:$seconds.$milliseconds';
  }

  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}