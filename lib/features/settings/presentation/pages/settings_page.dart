import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../schedule/presentation/bloc/schedule_bloc.dart';
import '../../../schedule/presentation/bloc/schedule_event.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _confirmResetTournament(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.resetTournament),
        content: const Text(AppStrings.confirmResetTournament),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<ScheduleBloc>().add(const ResetTournamentEvent());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Turnir o‘yinlari va natijalari tozalandi')),
              );
            },
            child: const Text(AppStrings.reset, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settingsTitle),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            children: [
              // 1. Appearance Section (Dark / Light / System)
              _buildSectionHeader(AppStrings.appearance),
              Material(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(14.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            state.themeMode == ThemeMode.dark
                                ? Icons.dark_mode
                                : (state.themeMode == ThemeMode.light
                                    ? Icons.light_mode
                                    : Icons.brightness_auto),
                            color: AppColors.primary,
                            size: 20.r,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Mavzu (Theme)',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.dark,
                              icon: Icon(Icons.dark_mode_outlined),
                              label: Text('Tun'),
                            ),
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.light,
                              icon: Icon(Icons.light_mode_outlined),
                              label: Text('Kun'),
                            ),
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.system,
                              icon: Icon(Icons.brightness_auto_outlined),
                              label: Text('Tizim'),
                            ),
                          ],
                          selected: {state.themeMode},
                          onSelectionChanged: (newSelection) {
                            context.read<SettingsCubit>().setThemeMode(newSelection.first);
                          },
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // 2. Tournament Lifecycle Controls
              _buildSectionHeader(AppStrings.tournamentSettings),
              Material(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.sports_soccer, color: AppColors.primary),
                      title: const Text(
                        AppConstants.defaultTournamentName,
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        state.isTournamentActive
                            ? 'Holat: Faol turnir davom etmoqda'
                            : 'Holat: Turnir yakunlangan',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: state.isTournamentActive ? AppColors.primary : Colors.grey,
                        ),
                      ),
                      trailing: Switch(
                        value: state.isTournamentActive,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          context.read<SettingsCubit>().toggleTournamentActive(val);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                val ? 'Turnir faol holatga o‘tkazildi' : 'Turnir yakunlandi deb belgilandi',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.archive_outlined, color: AppColors.accentGold),
                      title: const Text(
                        'Eski turnirlarni arxivlash',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Turnir natijalarini arxivga o‘tkazish',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Joriy turnir ma’lumotlari arxivlandi'),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.restart_alt, color: AppColors.error),
                      title: const Text(
                        AppStrings.resetTournament,
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.error),
                      ),
                      subtitle: const Text(
                        'Barcha o‘yinlar va natijalarni tozalash',
                        style: TextStyle(fontSize: 12),
                      ),
                      onTap: () => _confirmResetTournament(context),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // 3. Developer & Performance Section (Mock Delay & Simulate Errors)
              _buildSectionHeader(AppStrings.developerOptions),
              Material(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(14.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Simulate Errors Toggle
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          AppStrings.simulateErrors,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Faqat sinov uchun (yoqilsa, ataylab tarmoq xatosi beradi)',
                          style: TextStyle(fontSize: 12),
                        ),
                        secondary: const Icon(
                          Icons.bug_report_outlined,
                          color: AppColors.accentGold,
                        ),
                        activeThumbColor: AppColors.primary,
                        value: state.simulateErrors,
                        onChanged: (val) {
                          context.read<SettingsCubit>().toggleSimulateErrors(val);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              duration: const Duration(seconds: 2),
                              content: Text(
                                val
                                    ? 'Xatoliklar simulyatsiyasi yoqildi (xato chiqsa, shu yerdan o‘chiring)'
                                    : 'Xatoliklar simulyatsiyasi o‘chirildi (normal rejim)',
                              ),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 20),

                      // Mock Delay Header & Value Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.speed, color: AppColors.info, size: 20),
                                SizedBox(width: 8.w),
                                Flexible(
                                  child: Text(
                                    AppStrings.mockDelay,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              '${state.mockDelayMs} ms',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),

                      // Slider for Delay (0 to 1000 ms)
                      Slider(
                        value: state.mockDelayMs.toDouble().clamp(0.0, 1000.0),
                        min: 0,
                        max: 1000,
                        divisions: 20,
                        activeColor: AppColors.primary,
                        inactiveColor: Colors.grey.withValues(alpha: 0.25),
                        label: '${state.mockDelayMs} ms',
                        onChanged: (val) {
                          context.read<SettingsCubit>().setMockDelay(val.round());
                        },
                      ),

                      // Preset Chips for quick selection
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 6.h,
                        children: [0, 100, 300, 500, 800].map((ms) {
                          final isSelected = state.mockDelayMs == ms;
                          return ChoiceChip(
                            label: Text(ms == 0 ? 'Tezkor (0ms)' : '$ms ms'),
                            selected: isSelected,
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                            labelStyle: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.primary : null,
                            ),
                            onSelected: (_) {
                              context.read<SettingsCubit>().setMockDelay(ms);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // 4. App Info Section
              _buildSectionHeader(AppStrings.aboutApp),
              Material(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.sports_soccer, color: AppColors.primary),
                          ),
                          SizedBox(width: 12.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppConfig.appName,
                                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'Versiya ${AppConfig.appVersion} • Drift SQLite • PDF & Rasm eksport',
                                style: TextStyle(fontSize: 11.sp, color: theme.textTheme.bodyMedium?.color),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Futbol turnirini boshqarish, o‘yinlarni avtomatik taqsimlash, adolatli vaqt algoritmi, turnir jadvalini avtomatik hisoblash va eksport tizimi.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: theme.textTheme.bodyMedium?.color,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
