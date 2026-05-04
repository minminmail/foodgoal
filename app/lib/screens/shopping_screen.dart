import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/shopping_item.dart';
import '../services/shopping_service.dart';
import '../theme/app_theme.dart';

/// Missing ingredients from chosen meals collect here. Tap to tick off,
/// long-press / swipe to delete, action button clears all checked.
class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shop = context.read<ShoppingService>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Shopping'),
        actions: [
          IconButton(
            tooltip: 'Clear ticked items',
            icon: const Icon(Icons.cleaning_services_outlined,
                color: AppColors.brand),
            onPressed: () => shop.clearChecked(),
          ),
        ],
      ),
      body: StreamBuilder<List<ShoppingItem>>(
        stream: shop.watch(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const _Empty();
          }

          // Tickbox UX: unchecked first, oldest at top; checked drift down.
          items.sort((a, b) {
            if (a.checked != b.checked) return a.checked ? 1 : -1;
            return a.addedAt.compareTo(b.addedAt);
          });

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: items.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) {
              if (i == 0) {
                final pending = items.where((it) => !it.checked).length;
                return Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(
                    '$pending ${pending == 1 ? 'item' : 'items'} · for the meals you picked',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.muted),
                  ),
                );
              }
              final item = items[i - 1];
              return _ShopRow(
                item: item,
                onToggle: () => shop.setChecked(item, !item.checked),
                onDelete: () => shop.remove(item.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _ShopRow extends StatelessWidget {
  const _ShopRow({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  final ShoppingItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.warningSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.warning),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              _Tick(checked: item.checked),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 14,
                    color: item.checked ? AppColors.muted : AppColors.text,
                    decoration: item.checked
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
              if (item.forRecipeTitle != null)
                Text(
                  item.forRecipeTitle!,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.muted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tick extends StatelessWidget {
  const _Tick({required this.checked});
  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: checked ? AppColors.brand : Colors.transparent,
        border: Border.all(
          color: checked ? AppColors.brand : AppColors.line,
          width: 2,
        ),
        shape: BoxShape.circle,
      ),
      child: checked
          ? const Icon(Icons.check, color: Colors.white, size: 12)
          : null,
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Nothing on the list yet.\nPick a meal on Tonight and the missing ingredients will show up here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted),
        ),
      ),
    );
  }
}
