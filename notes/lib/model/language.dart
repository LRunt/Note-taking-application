part of models;

/// Class [Language] represents object of language contains flag, name and language code.
class Language {
  /// The flag of the language represented as a string (emoji).
  final String flag;

  /// The name of the language.
  final String name;

  /// The ISO language code for the language.
  /// This follows the standard ISO 639-1 two-letter code that uniquely identifies the language.
  final String langCode;

  /// Constructor for creating a [Language] instance.
  ///
  /// Requires three positional arguments:
  /// - [flag] representing the flag emoji of the language.
  /// - [name] representing the name of the language.
  /// - [langCode] representing the ISO language code.
  ///
  /// Example:
  /// ```
  /// Language("🇬🇧", "English", "en")
  /// ```
  Language(this.flag, this.name, this.langCode);

  /// Static method to get a list of predefined [Language] objects.
  ///
  /// Returns:
  /// A list of [Language] instances representing the languages available.
  static List<Language> languageList() {
    return <Language>[
      Language("🇬🇧", "English", "en"),
      Language("🇨🇿", "Čeština", "cs"),
    ];
  }

  /// Finds a Language by its ISO language code.
  /// Returns the matching Language object, or null if no match is found.
  static Language? getByLangCode(String code) {
    try {
      return languageList().firstWhere((language) => language.langCode == code);
    } catch (e) {
      return null;
    }
  }

  // Operator for comparing two objects
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Language && runtimeType == other.runtimeType && langCode == other.langCode;

  // Hash function of the object
  @override
  int get hashCode => langCode.hashCode;

  // Text representation of the object
  @override
  String toString() {
    return "$flag  $name";
  }
}
