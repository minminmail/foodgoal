/// One row in the pantry. v1 keeps it deliberately small: name, optional
/// quantity string, and a "section" so the UI can group Fresh / Cupboard /
/// Frozen the way the screen sketch does.
class PantryItem {
  final String id;
  final String name;
  final String quantity; // free text for v1: "4", "1 kg", "1 bunch"
  final PantrySection section;
  final DateTime addedAt;

  PantryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.section,
    required this.addedAt,
  });

  /// Lower-cased name used for matching against recipe ingredients.
  String get matchKey => name.trim().toLowerCase();

  PantryItem copyWith({
    String? name,
    String? quantity,
    PantrySection? section,
  }) {
    return PantryItem(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      section: section ?? this.section,
      addedAt: addedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'quantity': quantity,
        'section': section.name,
        'addedAt': addedAt.toIso8601String(),
      };

  factory PantryItem.fromMap(String id, Map<String, dynamic> map) {
    return PantryItem(
      id: id,
      name: map['name'] as String? ?? '',
      quantity: map['quantity'] as String? ?? '',
      section: PantrySection.values.firstWhere(
        (s) => s.name == map['section'],
        orElse: () => PantrySection.cupboard,
      ),
      addedAt: DateTime.tryParse(map['addedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

enum PantrySection {
  fresh,
  cupboard,
  frozen;

  String get label {
    switch (this) {
      case PantrySection.fresh:
        return 'Fresh';
      case PantrySection.cupboard:
        return 'Cupboard';
      case PantrySection.frozen:
        return 'Frozen';
    }
  }

  String get labelKey {
    switch (this) {
      case PantrySection.fresh:
        return 'section_fresh';
      case PantrySection.cupboard:
        return 'section_cupboard';
      case PantrySection.frozen:
        return 'section_frozen';
    }
  }
}
