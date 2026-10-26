import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/history_repository.dart';

const _kTimeout = 'request_timeout_seconds';
const _kInsecureTls = 'allow_insecure_tls';
const _kHistoryMaxEntries = 'history_max_entries';
const _kHistoryMaxBodyKb = 'history_max_body_kb';

class AppSettings {
  final int timeoutSeconds;
  final bool allowInsecureTls;
  final int historyMaxEntries;
  final int historyMaxBodyKb;

  const AppSettings({
    this.timeoutSeconds = 30,
    this.allowInsecureTls = false,
    this.historyMaxEntries = 500,
    this.historyMaxBodyKb = 1024,
  });

  Duration get timeout => Duration(seconds: timeoutSeconds);

  AppSettings copyWith({
    int? timeoutSeconds,
    bool? allowInsecureTls,
    int? historyMaxEntries,
    int? historyMaxBodyKb,
  }) {
    return AppSettings(
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      allowInsecureTls: allowInsecureTls ?? this.allowInsecureTls,
      historyMaxEntries: historyMaxEntries ?? this.historyMaxEntries,
      historyMaxBodyKb: historyMaxBodyKb ?? this.historyMaxBodyKb,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

/// App-wide preferences, persisted in SharedPreferences. History limits are
/// pushed into [HistoryRepository]'s static configuration whenever they load
/// or change.
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _applyHistoryLimits(state);
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final loaded = AppSettings(
      timeoutSeconds: prefs.getInt(_kTimeout) ?? 30,
      allowInsecureTls: prefs.getBool(_kInsecureTls) ?? false,
      historyMaxEntries: prefs.getInt(_kHistoryMaxEntries) ?? 500,
      historyMaxBodyKb: prefs.getInt(_kHistoryMaxBodyKb) ?? 1024,
    );
    _applyHistoryLimits(loaded);
    if (mounted) state = loaded;
  }

  Future<void> update(AppSettings settings) async {
    state = settings;
    _applyHistoryLimits(settings);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTimeout, settings.timeoutSeconds);
    await prefs.setBool(_kInsecureTls, settings.allowInsecureTls);
    await prefs.setInt(_kHistoryMaxEntries, settings.historyMaxEntries);
    await prefs.setInt(_kHistoryMaxBodyKb, settings.historyMaxBodyKb);
  }

  static void _applyHistoryLimits(AppSettings s) {
    HistoryRepository.maxEntries = s.historyMaxEntries;
    HistoryRepository.maxBodyBytes = s.historyMaxBodyKb * 1024;
  }
}
