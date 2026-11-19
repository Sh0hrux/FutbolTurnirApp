import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final bool simulateErrors;
  final int mockDelayMs;
  final bool isTournamentActive;

  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.simulateErrors = false,
    this.mockDelayMs = 100,
    this.isTournamentActive = true,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? simulateErrors,
    int? mockDelayMs,
    bool? isTournamentActive,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      simulateErrors: simulateErrors ?? this.simulateErrors,
      mockDelayMs: mockDelayMs ?? this.mockDelayMs,
      isTournamentActive: isTournamentActive ?? this.isTournamentActive,
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        simulateErrors,
        mockDelayMs,
        isTournamentActive,
      ];
}
