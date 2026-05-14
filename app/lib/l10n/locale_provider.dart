import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Holds the user's chosen language code ('en', 'es', 'zh') and notifies
/// listeners so `MaterialApp` can rebuild with the new locale.
class LocaleProvider extends ChangeNotifier {
  LocaleProvider(String language) : _language = language {
    _applyLocale();
  }

  String _language;
  String get language => _language;

  Locale get locale {
    switch (_language) {
      case 'es':
        return const Locale('es');
      case 'zh':
        return const Locale('zh');
      default:
        return const Locale('en');
    }
  }

  void setLanguage(String code) {
    if (code == _language) return;
    _language = code;
    _applyLocale();
    notifyListeners();
  }

  /// Maps app language code to a full intl locale for date formatting.
  String get intlLocale {
    switch (_language) {
      case 'zh':
        return 'zh_CN';
      default:
        return _language;
    }
  }

  void _applyLocale() {
    Intl.defaultLocale = intlLocale;
  }

  /// Maps language code → display name shown in the dropdown.
  static const languageNames = {
    'en': 'English',
    'es': 'Español',
    'zh': '中文',
  };
}
