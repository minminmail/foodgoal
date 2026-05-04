import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _currentWeightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();

  String _gender = 'male';
  int _plannedMonths = 6;
  bool _isVegetarian = false;
  String? _existingId;
  bool _loading = true;
  int? _dailyCalories;
  int? _mealCalories;

  static const _genderOptions = ['male', 'female', 'other'];
  static const _monthOptions = [1, 2, 3, 6, 9, 12, 18, 24];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadProfile);
  }

  Future<void> _loadProfile() async {
    final service = context.read<ProfileService>();
    final profile = await service.get();
    if (profile != null) {
      _existingId = profile.id;
      _nameCtrl.text = profile.name;
      _gender = profile.gender;
      _currentWeightCtrl.text = profile.currentWeight.toString();
      _targetWeightCtrl.text = profile.targetWeight.toString();
      _plannedMonths = profile.plannedWeightLossMonths;
      _isVegetarian = profile.isVegetarian;
      _ageCtrl.text = profile.age.toString();
      _heightCtrl.text = profile.height.toString();
      _countryCtrl.text = profile.country;
      if (profile.dailyCalories > 0) {
        _dailyCalories = profile.dailyCalories;
        _mealCalories = profile.mealCalories;
      }
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currentWeightCtrl.dispose();
    _targetWeightCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final service = context.read<ProfileService>();

    final weight = double.parse(_currentWeightCtrl.text.trim());
    final target = double.parse(_targetWeightCtrl.text.trim());
    final age = int.parse(_ageCtrl.text.trim());
    final h = double.parse(_heightCtrl.text.trim());

    final (daily, meal) = UserProfile.calculateCalories(
      gender: _gender,
      age: age,
      height: h,
      currentWeight: weight,
      targetWeight: target,
      plannedMonths: _plannedMonths,
    );

    final profile = UserProfile(
      id: _existingId ?? service.newId(),
      name: _nameCtrl.text.trim(),
      gender: _gender,
      currentWeight: weight,
      targetWeight: target,
      plannedWeightLossMonths: _plannedMonths,
      isVegetarian: _isVegetarian,
      age: age,
      height: h,
      country: _countryCtrl.text.trim(),
      dailyCalories: daily,
      mealCalories: meal,
      updatedAt: DateTime.now(),
    );
    await service.save(profile);
    _existingId = profile.id;

    setState(() {
      _dailyCalories = daily;
      _mealCalories = meal;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(title: const Text('Profile')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _sectionCard('Personal', [
                    _textField(_nameCtrl, 'Name', TextInputType.name),
                    const SizedBox(height: 12),
                    _dropdownField<String>(
                      label: 'Gender',
                      value: _gender,
                      items: _genderOptions
                          .map((g) => DropdownMenuItem(
                                value: g,
                                child: Text(
                                  g[0].toUpperCase() + g.substring(1),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _gender = v!),
                    ),
                    const SizedBox(height: 12),
                    _numberField(_ageCtrl, 'Age', decimal: false),
                    const SizedBox(height: 12),
                    _numberField(_heightCtrl, 'Height (cm)'),
                    const SizedBox(height: 12),
                    _textField(_countryCtrl, 'Country', TextInputType.text),
                  ]),
                  const SizedBox(height: 16),
                  _sectionCard('Weight Goal', [
                    _numberField(_currentWeightCtrl, 'Current weight (kg)'),
                    const SizedBox(height: 12),
                    _numberField(_targetWeightCtrl, 'Target weight (kg)'),
                    const SizedBox(height: 12),
                    _dropdownField<int>(
                      label: 'Planned time (months)',
                      value: _monthOptions.contains(_plannedMonths)
                          ? _plannedMonths
                          : 6,
                      items: _monthOptions
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text('$m month${m == 1 ? '' : 's'}'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _plannedMonths = v!),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _sectionCard('Diet', [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Vegetarian'),
                      activeTrackColor: AppColors.brandSoft,
                      thumbColor: WidgetStatePropertyAll(AppColors.brand),
                      value: _isVegetarian,
                      onChanged: (v) => setState(() => _isVegetarian = v),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                  if (_dailyCalories != null) ...[
                    const SizedBox(height: 24),
                    _calorieResultCard(),
                  ],
                ],
              ),
            ),
      ),
    );
  }

  Widget _calorieResultCard() {
    return Card(
      color: AppColors.brandSoft,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Daily Plan',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _calorieBox(
                    'Daily Calories',
                    '$_dailyCalories kcal',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _calorieBox(
                    'Per Meal',
                    '$_mealCalories kcal',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Based on 3 meals per day',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _calorieBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String label,
    TextInputType type,
  ) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(labelText: label),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
    );
  }

  Widget _numberField(
    TextEditingController ctrl,
    String label, {
    bool decimal = true,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Required';
        final n = num.tryParse(v.trim());
        if (n == null || n <= 0) return 'Enter a valid number';
        return null;
      },
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: onChanged,
    );
  }
}
