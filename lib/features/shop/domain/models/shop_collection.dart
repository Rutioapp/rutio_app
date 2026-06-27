class ShopCollection {
  const ShopCollection({
    required this.id,
    required this.title,
    this.description = '',
    this.themeKey = '',
    this.isEnabled = true,
    this.sortOrder = 0,
  });

  final String id;
  final String title;
  final String description;
  final String themeKey;
  final bool isEnabled;
  final int sortOrder;

  ShopCollection copyWith({
    String? id,
    String? title,
    String? description,
    String? themeKey,
    bool? isEnabled,
    int? sortOrder,
  }) {
    return ShopCollection(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      themeKey: themeKey ?? this.themeKey,
      isEnabled: isEnabled ?? this.isEnabled,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory ShopCollection.fromJson(Map<String, dynamic> json) {
    return ShopCollection(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      themeKey: (json['themeKey'] ?? '').toString(),
      isEnabled: json['isEnabled'] as bool? ?? true,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'themeKey': themeKey,
      'isEnabled': isEnabled,
      'sortOrder': sortOrder,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShopCollection &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.themeKey == themeKey &&
        other.isEnabled == isEnabled &&
        other.sortOrder == sortOrder;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        themeKey,
        isEnabled,
        sortOrder,
      );
}
