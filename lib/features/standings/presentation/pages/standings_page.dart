import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:screenshot/screenshot.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/tournament_export_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/team_avatar.dart';
import '../../domain/entities/standing_row_entity.dart';
import '../bloc/standings_bloc.dart';
import '../bloc/standings_event.dart';
import '../bloc/standings_state.dart';

class StandingsPage extends StatefulWidget {
  const StandingsPage({super.key});

  @override
  State<StandingsPage> createState() => _StandingsPageState();
}

class _StandingsPageState extends State<StandingsPage> {
  final ScreenshotController _screenshotController = ScreenshotController();

  static const Color headerYellow = Color(0xFFE4F060);

  @override
  void initState() {
    super.initState();
    context.read<StandingsBloc>().add(const LoadStandingsEvent());
  }

  void _onExportPdf(List<StandingRowEntity> standings) {
    TournamentExportService.exportStandingsToPdf(
      tournamentName: AppConstants.defaultTournamentName,
      standings: standings,
    );
  }

  void _onExportImage() {
    TournamentExportService.exportAndShareImage(
      screenshotController: _screenshotController,
      tournamentName: AppConstants.defaultTournamentName,
    );
  }

  void _onShareText(List<StandingRowEntity> standings) {
    TournamentExportService.shareStandingsText(
      tournamentName: AppConstants.defaultTournamentName,
      standings: standings,
    );
  }

  void _showRulesBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: headerYellow.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.info_outline, color: headerYellow, size: 22),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Qoidalar va qisqartmalar',
                        style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Text(
                  'Ochko hisoblash tizimi:',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: headerYellow),
                ),
                SizedBox(height: 6.h),
                _buildRuleRow('G‘alaba', '3 ochko', AppColors.primary),
                _buildRuleRow('Durang', '1 ochko', headerYellow),
                _buildRuleRow('Mag‘lubiyat', '0 ochko', theme.colorScheme.error),
                SizedBox(height: 14.h),
                Text(
                  'Tenglik bo‘lganda joylashuv tartibi:',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: headerYellow),
                ),
                SizedBox(height: 6.h),
                _buildOrderRow('1.', 'Eng ko‘p to‘plangan ochkolar (Pts)'),
                _buildOrderRow('2.', 'Gollar farqi (+/-)'),
                _buildOrderRow('3.', 'Eng ko‘p urilgan gollar (Goals)'),
                _buildOrderRow('4.', 'O‘zaro o‘yinlar natijasi (Head-to-Head)'),
                SizedBox(height: 14.h),
                Text(
                  'Jadval ustunlari qisqartmalari:',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: headerYellow),
                ),
                SizedBox(height: 6.h),
                Wrap(
                  spacing: 12.w,
                  runSpacing: 6.h,
                  children: [
                    _buildAbbreviationChip('Pl', 'O‘rin (Place)'),
                    _buildAbbreviationChip('Team', 'Jamoa nomi (Team)'),
                    _buildAbbreviationChip('G', 'O‘yinlar soni (Games played)'),
                    _buildAbbreviationChip('Goals', 'Urilgan : O‘tkazilgan gollar (Scored:Conceded)'),
                    _buildAbbreviationChip('+/-', 'To‘plar farqi (Goal difference)'),
                    _buildAbbreviationChip('Pts', 'To‘plangan ochkolar (Points)'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRuleRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13.sp)),
          Text(value, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildOrderRow(String num, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          Text(num, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: headerYellow)),
          SizedBox(width: 8.w),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13.sp))),
        ],
      ),
    );
  }

  Widget _buildAbbreviationChip(String short, String full) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        '$short — $full',
        style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.standingsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Qoidalar va qisqartmalar',
            onPressed: () => _showRulesBottomSheet(context),
          ),
          BlocBuilder<StandingsBloc, StandingsState>(
            builder: (context, state) {
              if (state is! StandingsSuccess || state.standings.isEmpty) {
                return const SizedBox.shrink();
              }

              return PopupMenuButton<String>(
                icon: const Icon(Icons.share_outlined),
                tooltip: AppStrings.export,
                onSelected: (val) {
                  if (val == 'pdf') _onExportPdf(state.standings);
                  if (val == 'image') _onExportImage();
                  if (val == 'text') _onShareText(state.standings);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: AppColors.primary, size: 20),
                        SizedBox(width: 10),
                        Text(AppStrings.exportPdf),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'image',
                    child: Row(
                      children: [
                        Icon(Icons.image_outlined, color: AppColors.accentGold, size: 20),
                        SizedBox(width: 10),
                        Text(AppStrings.exportImage),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'text',
                    child: Row(
                      children: [
                        Icon(Icons.share, color: AppColors.info, size: 20),
                        SizedBox(width: 10),
                        Text(AppStrings.shareTable),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppStrings.refresh,
            onPressed: () => context.read<StandingsBloc>().add(const LoadStandingsEvent()),
          ),
        ],
      ),
      body: BlocConsumer<StandingsBloc, StandingsState>(
        listener: (context, state) {
          if (state is StandingsSuccess && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is StandingsLoading) {
            return _buildSkeletonLoading();
          }

          if (state is StandingsFailure) {
            return ErrorView(
              message: state.message,
              onRetry: () => context.read<StandingsBloc>().add(const LoadStandingsEvent()),
            );
          }

          if (state is StandingsSuccess) {
            if (state.standings.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<StandingsBloc>().add(const LoadStandingsEvent());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: 0.7.sh,
                    child: const EmptyView(
                      title: 'Turnir jadvali bo‘sh',
                      subtitle: 'Jamoalar qo‘shilishi bilan jadval avtomatik shakllanadi',
                      icon: Icons.leaderboard,
                    ),
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<StandingsBloc>().add(const LoadStandingsEvent());
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                children: [
                  // Standings Table Card wrapped in Screenshot
                  Screenshot(
                    controller: _screenshotController,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF191C1F) : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14.r),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Pinned Sticky Header Row: Pl | Team | G | Goals | +/- | Pts
                            _buildStickyHeader(isDark),
                            // Compact Team Rows
                            ...state.standings.asMap().entries.map(
                                  (e) => _buildTeamRow(e.value, e.key, isDark),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 10.h),
                  // Compact 1-line footer
                  Center(
                    child: Text(
                      'G‘alaba 3 · Durang 1 · Mag‘lubiyat 0',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStickyHeader(bool isDark) {
    return Container(
      height: 40.h,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF22262A)
            : AppColors.lightBackground.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Row(
        children: [
          // Pl
          SizedBox(
            width: 32.w,
            child: Text(
              'Pl',
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w700,
                color: headerYellow,
              ),
            ),
          ),
          // Team
          Expanded(
            child: Text(
              'Team',
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w700,
                color: headerYellow,
              ),
            ),
          ),
          // G (Games played)
          _headerCell('G', 34.w),
          // Goals (GF:GA)
          _headerCell('Goals', 58.w),
          // +/- (GD)
          _headerCell('+/-', 44.w),
          // Pts (Points)
          _headerCell('Pts', 38.w),
        ],
      ),
    );
  }

  Widget _headerCell(String title, double width) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w700,
            color: headerYellow,
          ),
        ),
      ),
    );
  }

  Widget _buildTeamRow(StandingRowEntity row, int index, bool isDark) {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: index.isEven
            ? (isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.015))
            : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.transparent),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.darkBorder.withValues(alpha: 0.4)
                : AppColors.lightBorder.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Row(
        children: [
          // Pl (1., 2., ...)
          SizedBox(
            width: 32.w,
            child: Text(
              '${row.pos}.',
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          // Team (Avatar + Name)
          Expanded(
            child: Row(
              children: [
                TeamAvatar(
                  name: row.teamName,
                  colorValue: row.colorValue,
                  logoPath: row.logoPath,
                  size: 26,
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    row.teamName,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // G (Played)
          _dataCell('${row.played}', 34.w, isDark),
          // Goals (GF:GA)
          _dataCell('${row.goalsFor}:${row.goalsAgainst}', 58.w, isDark),
          // +/- (GD)
          _dataCell(
            row.goalDifference > 0 ? '+${row.goalDifference}' : '${row.goalDifference}',
            44.w,
            isDark,
          ),
          // Pts
          _dataCell('${row.points}', 38.w, isDark, isBold: true),
        ],
      ),
    );
  }

  Widget _dataCell(String text, double width, bool isDark, {bool isBold = false}) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: EdgeInsets.all(14.r),
        itemCount: 11,
        itemBuilder: (context, index) => Container(
          margin: EdgeInsets.only(bottom: 6.h),
          height: 48.h,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      ),
    );
  }
}
