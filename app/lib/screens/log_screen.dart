import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/meal_log_entry.dart';
import '../services/meal_log_service.dart';
import '../theme/app_theme.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  DateTime _day = DateTime.now();

  void _shiftDay(int days) {
    setState(() => _day = _day.add(Duration(days: days)));
  }

  @override
  Widget build(BuildContext context) {
    final mealLog = context.read<MealLogService>();
    final isToday = _isSameDay(_day, DateTime.now());
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(isToday ? 'Meal Track' : DateFormat('EEEE').format(_day)),
      ),
      body: StreamBuilder<List<MealLogEntry>>(
        stream: mealLog.watchDay(_day),
        builder: (context, snap) {
          final entries = snap.data ?? const <MealLogEntry>[];
          final bySlot = <MealSlot, MealLogEntry?>{
            for (final s in MealSlot.values) s: null,
          };
          for (final e in entries) {
            final cur = bySlot[e.slot];
            if (cur == null || e.eatenAt.isAfter(cur.eatenAt)) {
              bySlot[e.slot] = e;
            }
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _DayPill(day: _day, onPrev: () => _shiftDay(-1), onNext: () => _shiftDay(1)),
              const SizedBox(height: 12),
              for (final slot in MealSlot.values)
                _MealSlotCard(
                  slot: slot,
                  entry: bySlot[slot],
                  onTap: () => _addOrEdit(context, mealLog, slot, bySlot[slot]),
                ),
              const SizedBox(height: 16),
              _CalorieSummary(entries: entries),
              const SizedBox(height: 10),
              _VarietyHint(distinct: _distinctMealsThisWeek(entries)),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addOrEdit(
    BuildContext context,
    MealLogService mealLog,
    MealSlot slot,
    MealLogEntry? existing,
  ) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final gramsController = TextEditingController(
      text: existing?.grams != null ? existing!.grams!.toStringAsFixed(0) : '',
    );
    double? previewCalories = existing?.calories;

    final result = await showModalBottomSheet<_MealInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final inset = MediaQuery.of(ctx).viewInsets.bottom;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 18 + inset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Log ${slot.label.toLowerCase()}',
                      style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'What did you eat?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: gramsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Grams (optional)',
                      border: OutlineInputBorder(),
                      suffixText: 'g',
                    ),
                    onChanged: (v) {
                      final g = double.tryParse(v);
                      setSheetState(() {
                        previewCalories = g != null ? g * 1.5 : null;
                      });
                    },
                  ),
                  if (previewCalories != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '~${previewCalories!.toStringAsFixed(0)} kcal',
                      style: const TextStyle(
                        color: AppColors.brand,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;
                        final g = double.tryParse(gramsController.text);
                        Navigator.of(ctx).pop(_MealInput(
                          name: name,
                          grams: g,
                          calories: g != null ? g * 1.5 : null,
                        ));
                      },
                      child: const Text('Log it'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (result == null) return;

    final now = DateTime.now();
    final eatenAt = _isSameDay(_day, now)
        ? now
        : DateTime(_day.year, _day.month, _day.day, 12);

    await mealLog.log(
      slot: slot,
      name: result.name,
      eatenAt: eatenAt,
      grams: result.grams,
      calories: result.calories,
    );
  }

  int _distinctMealsThisWeek(List<MealLogEntry> entries) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return entries
        .where((e) => e.eatenAt.isAfter(cutoff))
        .map((e) => e.name.toLowerCase())
        .toSet()
        .length;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _MealInput {
  final String name;
  final double? grams;
  final double? calories;

  _MealInput({required this.name, this.grams, this.calories});
}

class _DayPill extends StatelessWidget {
  const _DayPill(
      {required this.day, required this.onPrev, required this.onNext});
  final DateTime day;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 18),
              onPressed: onPrev,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            Text(
              DateFormat('EEEE, d MMM').format(day),
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 18),
              onPressed: onNext,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealSlotCard extends StatelessWidget {
  const _MealSlotCard({
    required this.slot,
    required this.entry,
    required this.onTap,
  });

  final MealSlot slot;
  final MealLogEntry? entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isEmpty = entry == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(slot.label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 4),
              if (isEmpty) ...[
                const Text('Not logged yet',
                    style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                const Text('+ Add what you ate',
                    style: TextStyle(
                        color: AppColors.brand,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ] else
                Text(
                  _buildEntryText(entry!),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildEntryText(MealLogEntry e) {
    final parts = <String>[e.name];
    if (e.grams != null) parts.add('${e.grams!.toStringAsFixed(0)}g');
    if (e.calories != null) parts.add('${e.calories!.toStringAsFixed(0)} kcal');
    return parts.join(' · ');
  }
}

class _CalorieSummary extends StatelessWidget {
  const _CalorieSummary({required this.entries});
  final List<MealLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<double>(0, (sum, e) => sum + (e.calories ?? 0));
    final logged = entries.where((e) => e.calories != null).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: AppColors.brand, size: 20),
          const SizedBox(width: 8),
          Text(
            '${total.toStringAsFixed(0)} kcal',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'total today',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.muted,
            ),
          ),
          const Spacer(),
          Text(
            '$logged ${logged == 1 ? 'meal' : 'meals'} logged',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _VarietyHint extends StatelessWidget {
  const _VarietyHint({required this.distinct});
  final int distinct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          'Variety this week: $distinct ${distinct == 1 ? 'meal' : 'meals'}',
          style: const TextStyle(
            color: AppColors.brand,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
