enum TextSizeOption {
  normal('Normal', 1.0),
  large('Grande', 1.15),
  extraLarge('Muy grande', 1.35);

  const TextSizeOption(this.label, this.scaleFactor);

  final String label;
  final double scaleFactor;

  static TextSizeOption fromKey(String key) {
    return TextSizeOption.values.firstWhere(
      (option) => option.name == key,
      orElse: () => TextSizeOption.normal,
    );
  }
}

class AppAccessibilitySettings {
  const AppAccessibilitySettings({
    this.highContrast = false,
    this.textSize = TextSizeOption.normal,
  });

  final bool highContrast;
  final TextSizeOption textSize;

  double get textScaleFactor => textSize.scaleFactor;

  AppAccessibilitySettings copyWith({
    bool? highContrast,
    TextSizeOption? textSize,
  }) {
    return AppAccessibilitySettings(
      highContrast: highContrast ?? this.highContrast,
      textSize: textSize ?? this.textSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'high_contrast': highContrast,
      'text_size': textSize.name,
    };
  }

  factory AppAccessibilitySettings.fromJson(Map<String, dynamic> json) {
    return AppAccessibilitySettings(
      highContrast: json['high_contrast'] as bool? ?? false,
      textSize: TextSizeOption.fromKey(json['text_size'] as String? ?? 'normal'),
    );
  }
}
