class AudioMetadata {
  final String fileName;
  final String filePath;
  final Duration duration;
  final String format;
  final int sampleRate;
  final DateTime recordedAt;
  final bool isStereo;
  final int bitDepth;
  final double fileSize; // in MB

  AudioMetadata({
    required this.fileName,
    required this.filePath,
    required this.duration,
    required this.format,
    required this.sampleRate,
    required this.recordedAt,
    required this.isStereo,
    required this.bitDepth,
    required this.fileSize,
  });

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'filePath': filePath,
      'duration': duration.inMilliseconds,
      'format': format,
      'sampleRate': sampleRate,
      'recordedAt': recordedAt.toIso8601String(),
      'isStereo': isStereo,
      'bitDepth': bitDepth,
      'fileSize': fileSize,
    };
  }

  factory AudioMetadata.fromJson(Map<String, dynamic> json) {
    return AudioMetadata(
      fileName: json['fileName'],
      filePath: json['filePath'],
      duration: Duration(milliseconds: json['duration']),
      format: json['format'],
      sampleRate: json['sampleRate'],
      recordedAt: DateTime.parse(json['recordedAt']),
      isStereo: json['isStereo'],
      bitDepth: json['bitDepth'],
      fileSize: json['fileSize'],
    );
  }
}