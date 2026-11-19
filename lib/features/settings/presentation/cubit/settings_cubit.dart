import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/app_config.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SharedPreferences prefs;

  static const String _keyThemeMode = 'app_theme_mode';
  static const String _keyMockDelay = 'app_mock_delay';
  static const String _keySimulateErrors = 'app_simulate_errors';
  static const String _keyTournamentActive = 'app_tournament_active';

  SettingsCubit({required this.prefs}) : super(const SettingsState()) {
    _loadSettings();
  }

  void _loadSettings() {
    // 1. Theme Mode
    final savedTheme = prefs.getString(_keyThemeMode);
    ThemeMode themeMode = ThemeMode.dark;
    if (savedTheme == 'light') {
      themeMode = ThemeMode.light;
    } else if (savedTheme == 'dark') {
      themeMode = ThemeMode.dark;
    } else if (savedTheme == 'system') {
      themeMode = ThemeMode.system;
    }

    // 2. Mock Delay (clamp between 0 and 1500)
    final savedDelay = prefs.getInt(_keyMockDelay) ?? 100;
    final validDelay = savedDelay.clamp(0, 1500);
    AppConfig.artificialDelayMs = validDelay;

    // 3. Simulate Errors
    final savedSimulateErrors = prefs.getBool(_keySimulateErrors) ?? false;
    AppConfig.simulateErrors = savedSimulateErrors;

    // 4. Tournament Active
    final savedTournamentActive = prefs.getBool(_keyTournamentActive) ?? true;

    emit(state.copyWith(
      themeMode: themeMode,
      mockDelayMs: validDelay,
      simulateErrors: savedSimulateErrors,
      isTournamentActive: savedTournamentActive,
    ));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    String value = 'dark';
    if (mode == ThemeMode.light) {
      value = 'light';
    } else if (mode == ThemeMode.system) {
      value = 'system';
    }
    await prefs.setString(_keyThemeMode, value);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> toggleTheme(bool isDark) async {
    await setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> toggleSimulateErrors(bool enable) async {
    AppConfig.simulateErrors = enable;
    await prefs.setBool(_keySimulateErrors, enable);
    emit(state.copyWith(simulateErrors: enable));
  }

  Future<void> setMockDelay(int delayMs) async {
    final validDelay = delayMs.clamp(0, 1500);
    AppConfig.artificialDelayMs = validDelay;
    await prefs.setInt(_keyMockDelay, validDelay);
    emit(state.copyWith(mockDelayMs: validDelay));
  }

  Future<void> toggleTournamentActive(bool active) async {
    await prefs.setBool(_keyTournamentActive, active);
    emit(state.copyWith(isTournamentActive: active));
  }
}
