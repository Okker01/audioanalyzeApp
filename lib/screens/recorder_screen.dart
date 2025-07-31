import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/audio_service.dart';
import '../models/audio_metadata.dart';
import '../models/audio_processing_options.dart';
import '../widgets/waveform_widget.dart';
import '../widgets/audio_visualizer.dart';
import '../utils/audio_utils.dart';

class RecorderScreen extends StatefulWidget {
  const RecorderScreen({super.key});

  @override
  State<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends State<RecorderScreen> {
  final AudioService _audioService = AudioService();
  AudioMetadata? _currentMetadata;
  AudioMetadata? _processedMetadata;
  bool _hasPermission = false;
  bool _isInitialized = false;
  String _recordingStatus = 'Initializing...';

  bool _normalizeAudio = true;
  double _lowPassFilter = 0;
  double _highPassFilter = 0;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      await _audioService.initialize();
      await _requestPermissions();
      setState(() {
        _isInitialized = true;
        _recordingStatus = _hasPermission ? 'Ready to record' : 'Permission required';
      });
    } catch (e) {
      print('Error initializing app: $e');
      setState(() {
        _recordingStatus = 'Initialization failed';
      });
    }
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.microphone.request();
    setState(() {
      _hasPermission = status == PermissionStatus.granted;
    });
  }

  Future<void> _startRecording() async {
    if (!_hasPermission) {
      await _requestPermissions();
      if (!_hasPermission) return;
    }

    final success = await _audioService.startRecording();
    if (success) {
      setState(() {
        _recordingStatus = 'Recording...';
      });
    } else {
      _showErrorDialog('Failed to start recording');
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioService.stopRecording();
    if (path != null) {
      final metadata = await _audioService.getAudioMetadata(path);
      setState(() {
        _currentMetadata = metadata;
        _recordingStatus = 'Recording saved';
      });
    }
  }

  Future<void> _processAudio() async {
    if (_currentMetadata == null) return;

    final options = AudioProcessingOptions(
      normalize: _normalizeAudio,
      lowPassFilter: _lowPassFilter,
      highPassFilter: _highPassFilter,
    );

    _showProcessingDialog();

    final processedPath = await _audioService.processAudio(
      _currentMetadata!.filePath,
      options,
    );

    Navigator.of(context).pop(); // Close processing dialog

    if (processedPath != null) {
      final metadata = await _audioService.getAudioMetadata(processedPath);
      setState(() {
        _processedMetadata = metadata;
      });
      _showSuccessDialog('Audio processed successfully');
    } else {
      _showErrorDialog('Failed to process audio');
    }
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing audio...'),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              _recordingStatus,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            AudioVisualizer(
              isRecording: _audioService.isRecording,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: (!_isInitialized || _audioService.isRecording) ? null : _startRecording,
                  icon: const Icon(Icons.mic),
                  label: const Text('Record'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _audioService.isRecording ? _stopRecording : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recording Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Sample Rate: '),
                DropdownButton<int>(
                  value: _audioService.sampleRate,
                  items: [22050, 44100, 48000].map((rate) {
                    return DropdownMenuItem(
                      value: rate,
                      child: Text('${rate} Hz'),
                    );
                  }).toList(),
                  onChanged: _audioService.isRecording ? null : (value) {
                    if (value != null) {
                      _audioService.setSampleRate(value);
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Stereo Mode: '),
                Switch(
                  value: _audioService.isStereo,
                  onChanged: _audioService.isRecording ? null : (value) {
                    _audioService.setStereoMode(value);
                    setState(() {});
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audio Processing',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Normalize Audio'),
              subtitle: const Text('Adjust volume to optimal level'),
              value: _normalizeAudio,
              onChanged: (value) {
                setState(() {
                  _normalizeAudio = value;
                });
              },
            ),
            const Divider(),
            Text(
              'Low-pass Filter: ${_lowPassFilter.toStringAsFixed(1)} kHz',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const Text(
              'Removes high-frequency noise',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Slider(
              value: _lowPassFilter,
              min: 0,
              max: 20,
              divisions: 20,
              onChanged: (value) {
                setState(() {
                  _lowPassFilter = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              'High-pass Filter: ${_highPassFilter.toStringAsFixed(0)} Hz',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const Text(
              'Removes low-frequency hums and background noise',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Slider(
              value: _highPassFilter,
              min: 0,
              max: 1000,
              divisions: 100,
              onChanged: (value) {
                setState(() {
                  _highPassFilter = value;
                });
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _currentMetadata != null ? _processAudio : null,
                icon: const Icon(Icons.tune),
                label: const Text('Process Audio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveformCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Waveform Analysis',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_currentMetadata != null) ...[
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Original Recording'),
                ],
              ),
              const SizedBox(height: 8),
              WaveformWidget(
                audioPath: _currentMetadata!.filePath,
                waveColor: Colors.blue,
                height: 80,
              ),
            ],
            if (_processedMetadata != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Processed Audio'),
                ],
              ),
              const SizedBox(height: 8),
              WaveformWidget(
                audioPath: _processedMetadata!.filePath,
                waveColor: Colors.green,
                height: 80,
              ),
            ],
            if (_currentMetadata == null && _processedMetadata == null)
              Container(
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Record audio to see waveform',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Playback & Comparison',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentMetadata != null
                        ? () => _audioService.playAudio(_currentMetadata!.filePath)
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play Original'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _processedMetadata != null
                        ? () => _audioService.playAudio(_processedMetadata!.filePath)
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play Processed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _audioService.isPlaying ? _audioService.stopPlaying : null,
                icon: const Icon(Icons.stop),
                label: const Text('Stop Playback'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard() {
    final metadata = _processedMetadata ?? _currentMetadata;
    if (metadata == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audio Metadata',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildMetadataRow('File Name', metadata.fileName),
            _buildMetadataRow('Duration', AudioUtils.formatDuration(metadata.duration)),
            _buildMetadataRow('Format', metadata.format),
            _buildMetadataRow('Sample Rate', '${metadata.sampleRate} Hz'),
            _buildMetadataRow('Channels', metadata.isStereo ? 'Stereo' : 'Mono'),
            _buildMetadataRow('Bit Depth', '${metadata.bitDepth} bit'),
            _buildMetadataRow('File Size', '${metadata.fileSize.toStringAsFixed(2)} MB'),
            _buildMetadataRow('Recorded At', AudioUtils.formatDateTime(metadata.recordedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildShareCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Save & Share',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentMetadata != null
                        ? () => _audioService.shareAudio(_currentMetadata!.filePath)
                        : null,
                    icon: const Icon(Icons.share),
                    label: const Text('Share Original'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _processedMetadata != null
                        ? () => _audioService.shareAudio(_processedMetadata!.filePath)
                        : null,
                    icon: const Icon(Icons.share),
                    label: const Text('Share Processed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Files are saved to app documents directory and can be shared via email, cloud storage, or other apps.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Recorder & Preprocessor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About'),
                  content: const Text(
                    'Professional audio recorder with real-time preprocessing capabilities.\n\n'
                        'Features:\n'
                        '• High-quality AAC recording\n'
                        '• Real-time waveform visualization\n'
                        '• Audio noise reduction simulation\n'
                        '• A/B comparison\n'
                        '• Easy sharing',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: !_isInitialized
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing audio system...'),
          ],
        ),
      )
          : !_hasPermission
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mic_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Microphone permission required',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'We need access to your microphone to record audio',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _requestPermissions,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildRecordingControls(),
            const SizedBox(height: 16),
            _buildSettingsCard(),
            const SizedBox(height: 16),
            _buildWaveformCard(),
            const SizedBox(height: 16),
            _buildProcessingCard(),
            const SizedBox(height: 16),
            _buildPlaybackCard(),
            const SizedBox(height: 16),
            _buildMetadataCard(),
            const SizedBox(height: 16),
            _buildShareCard(),
          ],
        ),
      ),
      floatingActionButton: (_hasPermission && _isInitialized)
          ? FloatingActionButton(
        onPressed: _audioService.isRecording ? _stopRecording : _startRecording,
        backgroundColor: _audioService.isRecording ? Colors.red : Colors.blue,
        child: Icon(_audioService.isRecording ? Icons.stop : Icons.mic),
      )
          : null,
    );
  }
}