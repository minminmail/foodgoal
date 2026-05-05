import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/weight_entry.dart';
import '../services/weight_service.dart';
import '../theme/app_theme.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  final _today = DateTime.now();
  String _selectedRange = '1M';

  static const _ranges = {
    '1W': Duration(days: 7),
    '1M': Duration(days: 30),
    '3M': Duration(days: 90),
    '6M': Duration(days: 180),
    '1Y': Duration(days: 365),
  };

  @override
  Widget build(BuildContext context) {
    final svc = context.read<WeightService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Text('Weight',
              style: Theme.of(context).textTheme.titleLarge),
        ),

        // Today's period cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: StreamBuilder<List<WeightEntry>>(
            stream: svc.watchDay(_today),
            builder: (context, snap) {
              final entries = snap.data ?? [];
              return Row(
                children: WeightPeriod.values.map((period) {
                  final entry = entries
                      .where((e) => e.period == period)
                      .toList();
                  final recorded = entry.isNotEmpty ? entry.first : null;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: period != WeightPeriod.night ? 8 : 0,
                      ),
                      child: _PeriodCard(
                        period: period,
                        entry: recorded,
                        onTap: () => _showInputDialog(context, svc, period),
                        onRemove: recorded != null
                            ? () async {
                                await svc.remove(recorded.id);
                              }
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // Range filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: _ranges.keys.map((label) {
              final selected = _selectedRange == label;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedRange = label),
                  selectedColor: AppColors.brand,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: AppColors.card,
                  side: BorderSide(
                    color: selected ? AppColors.brand : AppColors.line,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  showCheckmark: false,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Chart
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 20, 16),
            child: _WeightChart(
              range: _ranges[_selectedRange]!,
              service: svc,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showInputDialog(
    BuildContext context,
    WeightService svc,
    WeightPeriod period,
  ) async {
    final controller = TextEditingController();
    final weight = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${period.label} Weight'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter weight in kg',
            suffixText: 'kg',
          ),
          onSubmitted: (v) {
            final val = double.tryParse(v);
            if (val != null && val > 0) Navigator.pop(ctx, val);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) Navigator.pop(ctx, val);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (weight != null) {
      await svc.add(period: period, weight: weight);
    }
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.period,
    required this.entry,
    required this.onTap,
    this.onRemove,
  });

  final WeightPeriod period;
  final WeightEntry? entry;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onRemove,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Text(period.label,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              entry != null
                  ? Text(
                      '${entry!.weight.toStringAsFixed(1)} kg',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.brand,
                          ),
                    )
                  : const Icon(Icons.add_circle_outline,
                      color: AppColors.muted, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.range, required this.service});

  final Duration range;
  final WeightService service;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final from = now.subtract(range);

    return FutureBuilder<List<WeightEntry>>(
      future: service.fetchRange(from, now),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final entries = snap.data ?? [];
        if (entries.isEmpty) {
          return Center(
            child: Text('No weight data yet',
                style: Theme.of(context).textTheme.bodySmall),
          );
        }

        // Compute daily averages
        final dailyAvg = <DateTime, List<double>>{};
        for (final e in entries) {
          final day = DateTime(e.recordedAt.year, e.recordedAt.month,
              e.recordedAt.day);
          dailyAvg.putIfAbsent(day, () => []).add(e.weight);
        }

        final sortedDays = dailyAvg.keys.toList()..sort();
        final spots = <FlSpot>[];
        for (int i = 0; i < sortedDays.length; i++) {
          final day = sortedDays[i];
          final avg = dailyAvg[day]!.reduce((a, b) => a + b) /
              dailyAvg[day]!.length;
          spots.add(FlSpot(i.toDouble(), avg));
        }

        // Y axis range
        final weights = spots.map((s) => s.y);
        final minY = weights.reduce((a, b) => a < b ? a : b) - 1;
        final maxY = weights.reduce((a, b) => a > b ? a : b) + 1;

        return LineChart(
          LineChartData(
            minY: minY,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: AppColors.line,
                strokeWidth: 0.5,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.min || value == meta.max) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.muted),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: (sortedDays.length / 5).ceilToDouble().clamp(1, double.infinity),
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= sortedDays.length) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      DateFormat('d/M').format(sortedDays[idx]),
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.muted),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.3,
                color: AppColors.brand,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: spots.length < 30,
                  getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                    radius: 3,
                    color: AppColors.brand,
                    strokeWidth: 0,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.brand.withValues(alpha: 0.08),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots.map((s) {
                  final idx = s.x.toInt();
                  final date = idx >= 0 && idx < sortedDays.length
                      ? DateFormat('MMM d').format(sortedDays[idx])
                      : '';
                  return LineTooltipItem(
                    '$date\n${s.y.toStringAsFixed(1)} kg',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
