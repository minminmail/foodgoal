/// A single weight measurement for a specific period of the day.
class WeightEntry {
  final String id;
  final WeightPeriod period;
  final double weight; // in kg
  final DateTime recordedAt;

  WeightEntry({
    required this.id,
    required this.period,
    required this.weight,
    required this.recordedAt,
  });

  Map<String, dynamic> toMap() => {
        'period': period.name,
        'weight': weight,
        'recordedAt': recordedAt.toIso8601String(),
      };

  factory WeightEntry.fromMap(String id, Map<String, dynamic> map) {
    return WeightEntry(
      id: id,
      period: WeightPeriod.values.firstWhere(
        (p) => p.name == map['period'],
        orElse: () => WeightPeriod.morning,
      ),
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      recordedAt: DateTime.tryParse(map['recordedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

enum WeightPeriod {
  morning,
  midday,
  night;

  String get label {
    switch (this) {
      case WeightPeriod.morning:
        return 'Morning';
      case WeightPeriod.midday:
        return 'Midday';
      case WeightPeriod.night:
        return 'Night';
    }
  }

  String get icon {
    switch (this) {
      case WeightPeriod.morning:
        return '🌅';
      case WeightPeriod.midday:
        return '☀️';
      case WeightPeriod.night:
        return '🌙';
    }
  }
}
