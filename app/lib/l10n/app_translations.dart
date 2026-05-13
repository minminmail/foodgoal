// Manual translations map for EN / ES / ZH.
// Usage: `t(context, 'key')` or `tr(context, 'key', {'n': '5'})`.
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'locale_provider.dart';

/// Shorthand — looks up the current language from [LocaleProvider].
String t(BuildContext context, String key) {
  final lang = context.read<LocaleProvider>().language;
  return _strings[key]?[lang] ?? _strings[key]?['en'] ?? key;
}

/// With named parameter substitution: `{n}` → value.
String tr(BuildContext context, String key, Map<String, String> params) {
  var s = t(context, key);
  params.forEach((k, v) => s = s.replaceAll('{$k}', v));
  return s;
}

const _strings = <String, Map<String, String>>{
  // ── Tab labels ──────────────────────────────────────────────
  'tab_today': {'en': 'Today', 'es': 'Hoy', 'zh': '今天'},
  'tab_pantry': {'en': 'Pantry', 'es': 'Despensa', 'zh': '食材'},
  'tab_meal_track': {'en': 'Meal Track', 'es': 'Registro', 'zh': '餐食记录'},
  'tab_weight': {'en': 'Weight', 'es': 'Peso', 'zh': '体重'},
  'tab_profile': {'en': 'Profile', 'es': 'Perfil', 'zh': '个人资料'},

  // ── Today / Tonight screen ──────────────────────────────────
  'today_hi': {'en': 'Hi, {name}', 'es': 'Hola, {name}', 'zh': '你好, {name}'},
  'today_today': {'en': 'Today', 'es': 'Hoy', 'zh': '今天'},
  'today_swap': {'en': 'Swap', 'es': 'Cambiar', 'zh': '换一个'},
  'today_add_pantry_hint': {
    'en': 'Add items to your pantry for suggestions',
    'es': 'Agrega ingredientes a tu despensa para sugerencias',
    'zh': '添加食材到你的储物柜以获取建议',
  },
  'today_empty_pantry': {
    'en':
        'Add a few items to your pantry and we\'ll suggest meals you can cook today.',
    'es':
        'Agrega algunos ingredientes a tu despensa y te sugeriremos comidas que puedes cocinar hoy.',
    'zh': '添加一些食材到你的储物柜，我们会为你推荐今天可以做的菜。',
  },
  'today_empty_no_suggestions': {
    'en': 'No suggestions yet — try adding more pantry items.',
    'es': 'Aún no hay sugerencias — intenta agregar más ingredientes.',
    'zh': '还没有建议——试试添加更多食材。',
  },
  'today_uses': {'en': 'Uses: {items}', 'es': 'Usa: {items}', 'zh': '使用: {items}'},
  'today_kcal_day': {
    'en': '{n} kcal/day',
    'es': '{n} kcal/día',
    'zh': '{n} 千卡/天',
  },

  // ── Meal slots ──────────────────────────────────────────────
  'slot_breakfast': {'en': 'Breakfast', 'es': 'Desayuno', 'zh': '早餐'},
  'slot_lunch': {'en': 'Lunch', 'es': 'Almuerzo', 'zh': '午餐'},
  'slot_dinner': {'en': 'Dinner', 'es': 'Cena', 'zh': '晚餐'},
  'slot_snack': {'en': 'Snack', 'es': 'Merienda', 'zh': '零食'},

  // ── Pantry screen ──────────────────────────────────────────
  'pantry_title': {'en': 'Pantry', 'es': 'Despensa', 'zh': '食材'},
  'pantry_add_item': {
    'en': '+ Add an item to your pantry',
    'es': '+ Agregar un ingrediente a tu despensa',
    'zh': '+ 添加食材到储物柜',
  },
  'pantry_empty': {
    'en':
        'Your pantry is empty.\nAdd a few items so we can suggest dinners.',
    'es':
        'Tu despensa está vacía.\nAgrega algunos ingredientes para sugerirte cenas.',
    'zh': '你的储物柜是空的。\n添加一些食材，我们就能为你推荐晚餐。',
  },
  'pantry_add_btn': {'en': 'Add an item', 'es': 'Agregar', 'zh': '添加食材'},
  'pantry_add_title': {
    'en': 'Add to pantry',
    'es': 'Agregar a despensa',
    'zh': '添加到储物柜',
  },
  'pantry_edit_title': {
    'en': 'Edit pantry item',
    'es': 'Editar ingrediente',
    'zh': '编辑食材',
  },
  'pantry_name_hint': {
    'en': 'Name (e.g. Carrots)',
    'es': 'Nombre (ej. Zanahorias)',
    'zh': '名称（例如 胡萝卜）',
  },
  'pantry_qty_hint': {
    'en': 'Quantity (optional, e.g. 4 or 1 kg)',
    'es': 'Cantidad (opcional, ej. 4 o 1 kg)',
    'zh': '数量（可选，例如 4 或 1 kg）',
  },
  'btn_add': {'en': 'Add', 'es': 'Agregar', 'zh': '添加'},
  'btn_save': {'en': 'Save', 'es': 'Guardar', 'zh': '保存'},

  // ── Pantry sections ─────────────────────────────────────────
  'section_fresh': {'en': 'Fresh', 'es': 'Fresco', 'zh': '新鲜'},
  'section_cupboard': {'en': 'Cupboard', 'es': 'Alacena', 'zh': '橱柜'},
  'section_frozen': {'en': 'Frozen', 'es': 'Congelado', 'zh': '冷冻'},

  // ── Log / Meal Track screen ─────────────────────────────────
  'log_title': {'en': 'Meal Track', 'es': 'Registro', 'zh': '餐食记录'},
  'log_slot_title': {
    'en': 'Log {slot}',
    'es': 'Registrar {slot}',
    'zh': '记录{slot}',
  },
  'log_what_eat': {
    'en': 'What did you eat?',
    'es': '¿Qué comiste?',
    'zh': '你吃了什么？',
  },
  'log_grams': {
    'en': 'Grams (optional)',
    'es': 'Gramos (opcional)',
    'zh': '克数（可选）',
  },
  'log_it': {'en': 'Log it', 'es': 'Registrar', 'zh': '记录'},
  'log_not_logged': {
    'en': 'Not logged yet',
    'es': 'No registrado aún',
    'zh': '尚未记录',
  },
  'log_add_what': {
    'en': '+ Add what you ate',
    'es': '+ Agregar lo que comiste',
    'zh': '+ 添加你吃的',
  },
  'log_total_today': {
    'en': 'total today',
    'es': 'total hoy',
    'zh': '今日总计',
  },
  'log_meals_logged': {
    'en': '{n} {unit} logged',
    'es': '{n} {unit} registradas',
    'zh': '已记录 {n} 餐',
  },
  'log_meal_singular': {'en': 'meal', 'es': 'comida', 'zh': '餐'},
  'log_meal_plural': {'en': 'meals', 'es': 'comidas', 'zh': '餐'},
  'log_variety': {
    'en': 'Variety this week: {n} {unit}',
    'es': 'Variedad esta semana: {n} {unit}',
    'zh': '本周种类: {n} {unit}',
  },

  // ── Weight screen ───────────────────────────────────────────
  'weight_title': {'en': 'Weight', 'es': 'Peso', 'zh': '体重'},
  'weight_period_morning': {'en': 'Morning', 'es': 'Mañana', 'zh': '早晨'},
  'weight_period_midday': {'en': 'Midday', 'es': 'Mediodía', 'zh': '中午'},
  'weight_period_night': {'en': 'Night', 'es': 'Noche', 'zh': '夜晚'},
  'weight_dialog_title': {
    'en': '{period} Weight',
    'es': 'Peso de {period}',
    'zh': '{period}体重',
  },
  'weight_hint': {
    'en': 'Enter weight in kg',
    'es': 'Ingresa peso en kg',
    'zh': '输入体重（公斤）',
  },
  'btn_cancel': {'en': 'Cancel', 'es': 'Cancelar', 'zh': '取消'},
  'weight_history': {'en': 'HISTORY', 'es': 'HISTORIAL', 'zh': '历史记录'},
  'weight_no_entries': {
    'en': 'No weight entries yet',
    'es': 'Aún no hay registros de peso',
    'zh': '还没有体重记录',
  },
  'weight_no_data': {
    'en': 'No weight data yet',
    'es': 'Aún no hay datos de peso',
    'zh': '还没有体重数据',
  },
  'weight_sync_tooltip': {
    'en': 'Sync from Health Connect',
    'es': 'Sincronizar desde Health Connect',
    'zh': '从 Health Connect 同步',
  },
  'weight_sync_denied': {
    'en': 'Health Connect permission denied',
    'es': 'Permiso de Health Connect denegado',
    'zh': 'Health Connect 权限被拒绝',
  },
  'weight_sync_imported': {
    'en': 'Imported {n} weight entries',
    'es': 'Se importaron {n} registros de peso',
    'zh': '已导入 {n} 条体重记录',
  },
  'weight_sync_none': {
    'en': 'No new weight entries to import',
    'es': 'No hay nuevos registros de peso para importar',
    'zh': '没有新的体重记录可导入',
  },
  'weight_sync_failed': {
    'en': 'Sync failed: {error}',
    'es': 'Sincronización fallida: {error}',
    'zh': '同步失败: {error}',
  },

  // ── Recipe detail screen ────────────────────────────────────
  'recipe_title': {'en': 'Recipe', 'es': 'Receta', 'zh': '食谱'},
  'recipe_ingredients': {'en': 'Ingredients', 'es': 'Ingredientes', 'zh': '食材'},
  'recipe_steps': {'en': 'Steps', 'es': 'Pasos', 'zh': '步骤'},
  'recipe_needs': {'en': 'needs', 'es': 'falta', 'zh': '需要'},
  'recipe_cook_btn': {
    'en': "I'll cook this",
    'es': 'Voy a cocinar esto',
    'zh': '我要做这道菜',
  },
  'recipe_add_missing': {
    'en': 'Add {n} missing item(s) to shopping list',
    'es': 'Agregar {n} ingrediente(s) faltante(s) a la lista de compras',
    'zh': '将 {n} 项缺少的食材添加到购物清单',
  },
  'recipe_logged': {
    'en': 'Logged {title}. Enjoy.',
    'es': 'Registrado {title}. ¡Buen provecho!',
    'zh': '已记录 {title}。请享用。',
  },
  'recipe_added_shopping': {
    'en': 'Added to shopping list.',
    'es': 'Agregado a la lista de compras.',
    'zh': '已添加到购物清单。',
  },

  // ── Shopping screen ─────────────────────────────────────────
  'shopping_title': {'en': 'Shopping', 'es': 'Compras', 'zh': '购物'},
  'shopping_clear_tooltip': {
    'en': 'Clear ticked items',
    'es': 'Limpiar seleccionados',
    'zh': '清除已勾选项',
  },
  'shopping_summary': {
    'en': '{n} {unit} · for the meals you picked',
    'es': '{n} {unit} · para las comidas que elegiste',
    'zh': '{n} {unit} · 为你选择的餐食',
  },
  'shopping_item_singular': {'en': 'item', 'es': 'artículo', 'zh': '项'},
  'shopping_item_plural': {'en': 'items', 'es': 'artículos', 'zh': '项'},
  'shopping_empty': {
    'en':
        'Nothing on the list yet.\nPick a meal on Tonight and the missing ingredients will show up here.',
    'es':
        'La lista está vacía.\nElige una comida en Hoy y los ingredientes faltantes aparecerán aquí.',
    'zh': '清单还是空的。\n在"今天"选择一道菜，缺少的食材会显示在这里。',
  },

  // ── Profile screen ──────────────────────────────────────────
  'profile_title': {'en': 'Profile', 'es': 'Perfil', 'zh': '个人资料'},
  'profile_personal': {'en': 'Personal', 'es': 'Personal', 'zh': '个人信息'},
  'profile_name': {'en': 'Name', 'es': 'Nombre', 'zh': '姓名'},
  'profile_gender': {'en': 'Gender', 'es': 'Género', 'zh': '性别'},
  'profile_age': {'en': 'Age', 'es': 'Edad', 'zh': '年龄'},
  'profile_height': {'en': 'Height (cm)', 'es': 'Altura (cm)', 'zh': '身高 (cm)'},
  'profile_country': {'en': 'Country', 'es': 'País', 'zh': '国家'},
  'profile_weight_goal': {
    'en': 'Weight Goal',
    'es': 'Meta de peso',
    'zh': '体重目标',
  },
  'profile_current_weight': {
    'en': 'Current weight (kg)',
    'es': 'Peso actual (kg)',
    'zh': '当前体重 (kg)',
  },
  'profile_target_weight': {
    'en': 'Target weight (kg)',
    'es': 'Peso meta (kg)',
    'zh': '目标体重 (kg)',
  },
  'profile_planned_time': {
    'en': 'Planned time (months)',
    'es': 'Tiempo planeado (meses)',
    'zh': '计划时间（月）',
  },
  'profile_months': {
    'en': '{n} month{s}',
    'es': '{n} mes{s}',
    'zh': '{n} 个月',
  },
  'profile_months_plural_suffix': {'en': 's', 'es': 'es', 'zh': ''},
  'profile_diet': {'en': 'Diet', 'es': 'Dieta', 'zh': '饮食'},
  'profile_vegetarian': {'en': 'Vegetarian', 'es': 'Vegetariano', 'zh': '素食'},
  'profile_language': {'en': 'Language', 'es': 'Idioma', 'zh': '语言'},
  'profile_saved': {
    'en': 'Profile saved',
    'es': 'Perfil guardado',
    'zh': '个人资料已保存',
  },
  'profile_daily_plan': {
    'en': 'Your Daily Plan',
    'es': 'Tu plan diario',
    'zh': '你的每日计划',
  },
  'profile_daily_calories': {
    'en': 'Daily Calories',
    'es': 'Calorías diarias',
    'zh': '每日热量',
  },
  'profile_per_meal': {
    'en': 'Per Meal',
    'es': 'Por comida',
    'zh': '每餐',
  },
  'profile_based_on': {
    'en': 'Based on 3 meals per day',
    'es': 'Basado en 3 comidas al día',
    'zh': '基于每天3餐',
  },
  'validation_required': {'en': 'Required', 'es': 'Requerido', 'zh': '必填'},
  'validation_number': {
    'en': 'Enter a valid number',
    'es': 'Ingresa un número válido',
    'zh': '请输入有效数字',
  },

  // ── Gender labels ───────────────────────────────────────────
  'gender_male': {'en': 'Male', 'es': 'Masculino', 'zh': '男'},
  'gender_female': {'en': 'Female', 'es': 'Femenino', 'zh': '女'},
  'gender_other': {'en': 'Other', 'es': 'Otro', 'zh': '其他'},
};
