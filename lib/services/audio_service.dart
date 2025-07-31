import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/audio_metadata.dart';
import '../models/audio_processing_options.dart';

class AudioService {
  FlutterSoundRecorder? _recorder;
  final ap.AudioPlayer _player = ap.AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;
  String? _processedAudioPath;

  int _sampleRate = 44100;
  bool _isStereo = false;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get currentRecordingPath => _currentRecordingPath;
  String? get processedAudioPath => _processedAudioPath;
  int get sampleRate => _sampleRate;
  bool get isStereo => _isStereo;

  // Initialize the audio service
  Future<void> initialize() async {
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
  }

  void setSampleRate(int rate) => _sampleRate = rate;
  void setStereoMode(bool stereo) => _isStereo = stereo;

  Future<bool> hasPermission() async {
    try {
      final status = await Permission.microphone.status;
      if (status != PermissionStatus.granted) {
        final result = await Permission.microphone.request();
        return result == PermissionStatus.granted;
      }
      return true;
    } catch (e) {
      print('Error checking permission: $e');
      return false;
    }
  }

  Future<bool> startRecording() async {
    try {
      if (await hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.aac';
        _currentRecordingPath = '${directory.path}/$fileName';

        if (_recorder == null) {
          await initialize();
        }

        await _recorder!.startRecorder(
          toFile: _currentRecordingPath,
          codec: Codec.aacADTS,
          sampleRate: _sampleRate,
          numChannels: _isStereo ? 2 : 1,
        );

        _isRecording = true;
        return true;
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
    return false;
  }

  Future<String?> stopRecording() async {
    try {
      if (_recorder != null && _isRecording) {
        await _recorder!.stopRecorder();
        _isRecording = false;
        return _currentRecordingPath;
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
    return null;
  }

  Future<void> playAudio(String path) async {
    try {
      await _player.play(ap.DeviceFileSource(path));
      _isPlaying = true;

      _player.onPlayerStateChanged.listen((state) {
        _isPlaying = state == ap.PlayerState.playing;
      });
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<void> stopPlaying() async {
    try {
      await _player.stop();
      _isPlaying = false;
    } catch (e) {
      print('Error stopping playback: $e');
    }
  }

  Future<void> pausePlaying() async {
    try {
      await _player.pause();
      _isPlaying = false;
    } catch (e) {
      print('Error pausing playback: $e');
    }
  }

  Future<String?> processAudio(String inputPath, AudioProcessingOptions options) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'processed_${DateTime.now().millisecondsSinceEpoch}.aac';
      final outputPath = '${directory.path}/$fileName';

      // Simple copy for now - in a real app you'd implement actual audio processing
      final inputFile = File(inputPath);
      final outputFile = File(outputPath);

      if (await inputFile.exists()) {
        await inputFile.copy(outputPath);
        _processedAudioPath = outputPath;

        // Add a small delay to simulate processing
        await Future.delayed(const Duration(milliseconds: 500));

        return outputPath;
      }

      return null;
    } catch (e) {
      print('Error processing audio: $e');
      return null;
    }
  }

  Future<AudioMetadata> getAudioMetadata(String filePath) async {
    try {
      final file = File(filePath);
      final stats = await file.stat();

      return AudioMetadata(
        fileName: file.path.split('/').last,
        filePath: filePath,
        duration: const Duration(seconds: 0), // Would need audio analysis for accurate duration
        format: 'AAC',
        sampleRate: _sampleRate,
        recordedAt: stats.modified,
        isStereo: _isStereo,
        bitDepth: 16,
        fileSize: stats.size / (1024 * 1024),
      );
    } catch (e) {
      print('Error getting metadata: $e');
      return AudioMetadata(
        fileName: 'unknown.aac',
        filePath: filePath,
        duration: Duration.zero,
        format: 'AAC',
        sampleRate: _sampleRate,
        recordedAt: DateTime.now(),
        isStereo: _isStereo,
        bitDepth: 16,
        fileSize: 0.0,
      );
    }
  }

  Future<void> shareAudio(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await Share.shareXFiles([XFile(filePath)], text: 'Recorded Audio');
      } else {
        print('File does not exist: $filePath');
      }
    } catch (e) {
      print('Error sharing audio: $e');
    }
  }

  void dispose() {
    try {
      _recorder?.closeRecorder();
      _player.dispose();
    } catch (e) {
      print('Error disposing audio service: $e');
    }
  }
}