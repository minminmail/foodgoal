import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_translations.dart';
import '../l10n/locale_provider.dart';
import '../models/pantry_item.dart';
import '../services/pantry_service.dart';
import '../theme/app_theme.dart';

/// Typed pantry list, grouped by section.
class PantryScreen extends StatelessWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final pantry = context.read<PantryService>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(t(context, 'pantry_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.brand),
            onPressed: () => _showAddSheet(context, pantry),
          ),
        ],
      ),
      body: StreamBuilder<List<PantryItem>>(
        stream: pantry.watch(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) return _empty(context, pantry);

          final bySection =
              groupBy<PantryItem, PantrySection>(items, (i) => i.section);
          final sectionsInOrder = PantrySection.values
              .where((s) => bySection.containsKey(s))
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              GestureDetector(
                onTap: () => _showAddSheet(context, pantry),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border.all(
                      color: AppColors.line,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(t(context, 'pantry_add_item'),
                        style: const TextStyle(color: AppColors.muted)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              for (final s in sectionsInOrder) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 8, bottom: 6),
                  child: Text(
                    t(context, s.labelKey).toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                ...bySection[s]!.map((it) => _PantryRow(
                      item: it,
                      onDelete: () => pantry.remove(it.id),
                      onEdit: () => _showEditSheet(context, pantry, it),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _empty(BuildContext context, PantryService pantry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t(context, 'pantry_empty'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => _showAddSheet(context, pantry),
              child: Text(t(context, 'pantry_add_btn')),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context, PantryService pantry) {
    _showItemSheet(context: context, pantry: pantry);
  }

  void _showEditSheet(
      BuildContext context, PantryService pantry, PantryItem item) {
    _showItemSheet(context: context, pantry: pantry, existing: item);
  }

  void _showItemSheet({
    required BuildContext context,
    required PantryService pantry,
    PantryItem? existing,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PantryEditor(pantry: pantry, existing: existing),
    );
  }
}

class _PantryRow extends StatelessWidget {
  const _PantryRow({
    required this.item,
    required this.onDelete,
    required this.onEdit,
  });

  final PantryItem item;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.warningSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.warning),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(item.name,
                    style: const TextStyle(fontSize: 14)),
              ),
              Text(item.quantity,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PantryEditor extends StatefulWidget {
  const _PantryEditor({required this.pantry, this.existing});
  final PantryService pantry;
  final PantryItem? existing;

  @override
  State<_PantryEditor> createState() => _PantryEditorState();
}

class _PantryEditorState extends State<_PantryEditor> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _qty =
      TextEditingController(text: widget.existing?.quantity ?? '');
  late PantrySection _section =
      widget.existing?.section ?? PantrySection.fresh;

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    if (widget.existing == null) {
      await widget.pantry.add(
        name: name,
        quantity: _qty.text.trim(),
        section: _section,
      );
    } else {
      await widget.pantry.update(widget.existing!.copyWith(
        name: name,
        quantity: _qty.text.trim(),
        section: _section,
      ));
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 18 + inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existing == null
                ? t(context, 'pantry_add_title')
                : t(context, 'pantry_edit_title'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(
              labelText: t(context, 'pantry_name_hint'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qty,
            decoration: InputDecoration(
              labelText: t(context, 'pantry_qty_hint'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          SegmentedButton<PantrySection>(
            showSelectedIcon: false,
            segments: PantrySection.values
                .map((s) => ButtonSegment(
                    value: s, label: Text(t(context, s.labelKey))))
                .toList(),
            selected: {_section},
            onSelectionChanged: (s) =>
                setState(() => _section = s.first),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: Text(widget.existing == null
                  ? t(context, 'btn_add')
                  : t(context, 'btn_save')),
            ),
          ),
        ],
      ),
    );
  }
}
