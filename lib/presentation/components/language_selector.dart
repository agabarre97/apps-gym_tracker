import 'package:flutter/material.dart';

import 'package:gym_tracker/domain/ports/storage_port.dart';

/// A globe icon button that toggles between ES and EN.
///
/// Reads the current locale from [BuildContext] (always up-to-date)
/// and notifies the parent via [onLocaleChanged].
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    super.key,
    required this.onLocaleChanged,
  });

  final ValueChanged<Locale> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    final current = Localizations.localeOf(context);

    return IconButton(
      icon: const Icon(Icons.language),
      tooltip: current.languageCode == 'es' ? 'English' : 'Español',
      onPressed: () {
        final next = current.languageCode == 'es'
            ? const Locale('en')
            : const Locale('es');
        onLocaleChanged(next);
      },
    );
  }
}

/// Persists the locale choice and reads it back.
class LocaleStorage {
  const LocaleStorage(this._storage);

  final StoragePort _storage;
  static const _key = 'app_locale';

  Future<Locale> load() async {
    final code = await _storage.get(_key);
    return Locale(code ?? 'es');
  }

  Future<void> save(Locale locale) =>
      _storage.set(_key, locale.languageCode);
}
