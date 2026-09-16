class Suggestion {
  final String id;
  final String text;
  final String? category;

  const Suggestion({
    required this.id,
    required this.text,
    this.category,
  });

  factory Suggestion.fromMap(Map<String, dynamic> map) {
    return Suggestion(
      id: map['id'] as String,
      text: map['text'] as String,
      category: map['category'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'category': category,
    };
  }
}
