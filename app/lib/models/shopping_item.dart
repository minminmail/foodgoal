/// One row on the Shopping tab. Created automatically when a user picks a
/// recipe that's missing pantry ingredients; ticked off by hand.
class ShoppingItem {
  final String id;
  final String name;
  final String? forRecipeTitle; // shown as "Lentejas" / "Miso bowl" in the UI
  final bool checked;
  final DateTime addedAt;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.forRecipeTitle,
    required this.checked,
    required this.addedAt,
  });

  ShoppingItem copyWith({bool? checked}) => ShoppingItem(
        id: id,
        name: name,
        forRecipeTitle: forRecipeTitle,
        checked: checked ?? this.checked,
        addedAt: addedAt,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'forRecipeTitle': forRecipeTitle,
        'checked': checked,
        'addedAt': addedAt.toIso8601String(),
      };

  factory ShoppingItem.fromMap(String id, Map<String, dynamic> map) {
    return ShoppingItem(
      id: id,
      name: map['name'] as String? ?? '',
      forRecipeTitle: map['forRecipeTitle'] as String?,
      checked: map['checked'] as bool? ?? false,
      addedAt: DateTime.tryParse(map['addedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
