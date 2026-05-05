import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/meal_log_entry.dart';
import '../services/meal_log_service.dart';
import '../theme/app_theme.dart';

/// One-tap meal log. The brief explicitly says no portion sizes or
/// calories — just record what was eaten and when, by slot.
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
        title: Text(isToday ? 'Today' : DateFormat('EEEE').format(_day)),
      ),
      body: StreamBuilder<List<MealLogEntry>>(
        stream: mealLog.watchDay(_day),
        builder: (context, snap) {
          final entries = snap.data ?? const <MealLogEntry>[];
          final bySlot = <MealSlot, MealLogEntry?>{
            for (final s in MealSlot.values) s: null,
          };
          for (final e in entries) {
            // If multiple entries exist for a slot, the most recent wins
            // for the headline; the rest still live on disk.
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
    final controller = TextEditingController(text: existing?.name ?? '');
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final inset = MediaQuery.of(ctx).viewInsets.bottom;
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
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'What did you eat?',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (v) => Navigator.of(ctx).pop(v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(ctx).pop(controller.text.trim()),
                  child: const Text('Log it'),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (result == null || result.isEmpty) return;

    // Stamp the entry on the displayed day, but with the current time
    // if it's today (so the 7-day recency rule stays accurate).
    final now = DateTime.now();
    final eatenAt = _isSameDay(_day, now)
        ? now
        : DateTime(_day.year, _day.month, _day.day, 12);

    await mealLog.log(slot: slot, name: result, eatenAt: eatenAt);
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
                Text(entry!.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
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
