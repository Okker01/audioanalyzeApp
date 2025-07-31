class AudioProcessingOptions {
  final bool normalize;
  final double lowPassFilter;
  final double highPassFilter;

  AudioProcessingOptions({
    this.normalize = false,
    this.lowPassFilter = 0,
    this.highPassFilter = 0,
  });

  AudioProcessingOptions copyWith({
    bool? normalize,
    double? lowPassFilter,
    double? highPassFilter,
  }) {
    return AudioProcessingOptions(
      normalize: normalize ?? this.normalize,
      lowPassFilter: lowPassFilter ?? this.lowPassFilter,
      highPassFilter: highPassFilter ?? this.highPassFilter,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'normalize': normalize,
      'lowPassFilter': lowPassFilter,
      'highPassFilter': highPassFilter,
    };
  }

  factory AudioProcessingOptions.fromJson(Map<String, dynamic> json) {
    return AudioProcessingOptions(
      normalize: json['normalize'] ?? false,
      lowPassFilter: json['lowPassFilter']?.toDouble() ?? 0.0,
      highPassFilter: json['highPassFilter']?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() {
    return 'AudioProcessingOptions(normalize: $normalize, lowPassFilter: $lowPassFilter, highPassFilter: $highPassFilter)';
  }
}