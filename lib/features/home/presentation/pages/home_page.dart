import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/team_avatar.dart';
import '../../../schedule/domain/entities/match_entity.dart';
import '../../../schedule/presentation/bloc/schedule_bloc.dart';
import '../../../schedule/presentation/bloc/schedule_event.dart';
import '../../../schedule/presentation/bloc/schedule_state.dart';
import '../../../schedule/presentation/widgets/enter_score_bottom_sheet.dart';
import '../../../standings/domain/entities/standing_row_entity.dart';
import '../../../standings/presentation/bloc/standings_bloc.dart';
import '../../../standings/presentation/bloc/standings_event.dart';
import '../../../standings/presentation/bloc/standings_state.dart';
import '../../../teams/domain/entities/team_entity.dart';
import '../../../teams/presentation/cubit/teams_cubit.dart';
import '../../domain/entities/home_summary_entity.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(const LoadHomeDataEvent());
  }

  Future<void> _refreshAll() async {
    final homeBloc = context.read<HomeBloc>();
    final scheduleBloc = context.read<ScheduleBloc>();
    final standingsBloc = context.read<StandingsBloc>();
    final teamsCubit = context.read<TeamsCubit>();

    try {
      homeBloc.add(const LoadHomeDataEvent());
      scheduleBloc.add(const LoadScheduleEvent());
      standingsBloc.add(const LoadStandingsEvent());
      final teamsFuture = teamsCubit.loadTeams();

      await Future.wait([
        teamsFuture,
        homeBloc.stream.firstWhere((s) => s is HomeSuccess || s is HomeFailure),
        scheduleBloc.stream.firstWhere((s) => s is ScheduleSuccess || s is ScheduleFailure),
        standingsBloc.stream.firstWhere((s) => s is StandingsSuccess || s is StandingsFailure),
      ]).timeout(const Duration(seconds: 4));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Yangilashda xatolik yuz berdi: $e"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _onEnterScoreForMatch(MatchEntity match, TeamEntity home, TeamEntity away) {
    EnterScoreBottomSheet.show(
      context,
      match: match,
      homeTeam: home,
      awayTeam: away,
      onSave: ({required homeScore, required awayScore, required status}) async {
        context.read<ScheduleBloc>().add(
              UpdateMatchScoreEvent(
                matchId: match.id,
                homeScore: homeScore,
                awayScore: awayScore,
                status: status,
              ),
            );
        // Refresh home data
        _refreshAll();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sports_soccer, color: AppColors.primary, size: 20),
            ),
            SizedBox(width: 8.w),
            const Text(AppStrings.appTitle),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppStrings.refresh,
            onPressed: () {
              _refreshKey.currentState?.show() ?? _refreshAll();
            },
          ),
        ],
      ),
      body: BlocConsumer<HomeBloc, HomeState>(
        listener: (context, state) {
          if (state is HomeSuccess && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is HomeLoading) {
            return _buildSkeletonLoading();
          }

          if (state is HomeFailure) {
            return ErrorView(
              message: state.message,
              onRetry: _refreshAll,
            );
          }

          if (state is HomeSuccess) {
            final summary = state.summary;

            return RefreshIndicator(
              key: _refreshKey,
              onRefresh: _refreshAll,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                children: [
                  // 1. Tournament Hero Card
                  _buildHeroBanner(summary, isDark),
                  SizedBox(height: 16.h),

                  // 2. Stat Counter Cards Grid
                  _buildStatsGrid(summary, isDark),
                  SizedBox(height: 18.h),

                  // 3. Next Match Highlight Card
                  _buildNextMatchSection(summary, isDark),
                  SizedBox(height: 18.h),

                  // 4. TOP 3 Standings Preview
                  _buildTop3Section(summary, isDark),
                  SizedBox(height: 18.h),

                  // 5. Recent Results
                  _buildRecentResultsSection(summary, isDark),
                  SizedBox(height: 30.h),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeroBanner(HomeSummaryEntity summary, bool isDark) {
    final progress = summary.totalMatchesCount > 0
        ? (summary.finishedMatchesCount / summary.totalMatchesCount)
        : 0.0;

    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.22),
            isDark ? AppColors.darkCard : AppColors.lightCard,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.tournamentName,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    AppStrings.tournamentManager,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'FAOL',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Turnir jarayoni',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
              Text(
                '${summary.finishedMatchesCount} / ${summary.totalMatchesCount} o‘yin',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 7.h,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(HomeSummaryEntity summary, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            title: AppStrings.totalTeams,
            value: '${summary.totalTeamsCount}',
            icon: Icons.shield_outlined,
            color: AppColors.primary,
            isDark: isDark,
            onTap: () => context.go('/teams'),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _buildStatItem(
            title: AppStrings.totalMatches,
            value: '${summary.totalMatchesCount}',
            icon: Icons.calendar_month_outlined,
            color: AppColors.accentGold,
            isDark: isDark,
            onTap: () => context.go('/schedule'),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _buildStatItem(
            title: AppStrings.finishedMatches,
            value: '${summary.finishedMatchesCount}',
            icon: Icons.check_circle_outline,
            color: AppColors.info,
            isDark: isDark,
            onTap: () => context.go('/standings'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22.r),
            SizedBox(height: 6.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextMatchSection(HomeSummaryEntity summary, bool isDark) {
    final nextMatch = summary.nextMatch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on, color: AppColors.accentGold, size: 18),
                SizedBox(width: 6.w),
                Text(
                  AppStrings.nextMatch.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            if (nextMatch != null)
              Text(
                '${nextMatch.round}-tur',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        if (nextMatch == null)
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.info),
                SizedBox(width: 10.w),
                const Expanded(child: Text(AppStrings.noUpcomingMatches)),
                AppButton(
                  text: 'Taqvim yaratish',
                  onPressed: () => context.go('/schedule'),
                ),
              ],
            ),
          )
        else
          _buildNextMatchCard(nextMatch, summary.teamsMap, isDark),
      ],
    );
  }

  Widget _buildNextMatchCard(MatchEntity match, Map<String, TeamEntity> teamsMap, bool isDark) {
    final home = teamsMap[match.homeTeamId] ?? TeamEntity(id: match.homeTeamId, name: 'Team 1', colorValue: 0xFF999999, createdAt: DateTime.now(), updatedAt: DateTime.now());
    final away = teamsMap[match.awayTeamId] ?? TeamEntity(id: match.awayTeamId, name: 'Team 2', colorValue: 0xFF666666, createdAt: DateTime.now(), updatedAt: DateTime.now());

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          // Time Slot Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              match.timeSlot,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // Teams
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Column(
                  children: [
                    TeamAvatar(name: home.name, colorValue: home.colorValue, logoPath: home.logoPath, size: 48),
                    SizedBox(height: 6.h),
                    Text(
                      home.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Text(
                  'VS',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900, color: Colors.grey),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    TeamAvatar(name: away.name, colorValue: away.colorValue, logoPath: away.logoPath, size: 48),
                    SizedBox(height: 6.h),
                    Text(
                      away.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Action
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: AppStrings.enterScore,
              icon: Icons.sports_score,
              onPressed: () => _onEnterScoreForMatch(match, home, away),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTop3Section(HomeSummaryEntity summary, bool isDark) {
    final List<StandingRowEntity> top3 = summary.top3Standings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.leaderboard, color: AppColors.primary, size: 18),
                SizedBox(width: 6.w),
                Text(
                  AppStrings.topTeams.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => context.go('/standings'),
              child: Text(
                'To‘liq jadval →',
                style: TextStyle(fontSize: 12.sp, color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: top3.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(16.r),
                  child: const Center(child: Text('Hali o‘yinlar o‘tkazilmagan')),
                )
              : Column(
                  children: top3.map((row) {
                    final isFirst = row.pos == 1;
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        border: row.pos < top3.length
                            ? Border(
                                bottom: BorderSide(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  width: 0.7,
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24.r,
                            height: 24.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isFirst
                                  ? AppColors.accentGold.withValues(alpha: 0.2)
                                  : Colors.grey.withValues(alpha: 0.15),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${row.pos}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w900,
                                color: isFirst ? AppColors.accentGold : null,
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          TeamAvatar(
                            name: row.teamName,
                            colorValue: row.colorValue,
                            logoPath: row.logoPath,
                            size: 30,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              row.teamName,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: isFirst ? FontWeight.w800 : FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'GD: ${row.goalDifference > 0 ? "+" : ""}${row.goalDifference}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            '${row.points} ochko',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildRecentResultsSection(HomeSummaryEntity summary, bool isDark) {
    final List<MatchEntity> recent = summary.recentFinishedMatches;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: AppColors.info, size: 18),
                SizedBox(width: 6.w),
                Text(
                  AppStrings.recentResults.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => context.go('/schedule'),
              child: Text(
                'Barcha o‘yinlar →',
                style: TextStyle(fontSize: 12.sp, color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        if (recent.isEmpty)
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: const Center(
              child: Text(AppStrings.noRecentResults),
            ),
          )
        else
          Column(
            children: recent.map((m) {
              final home = summary.teamsMap[m.homeTeamId] ?? TeamEntity(id: m.homeTeamId, name: 'Team', colorValue: 0xFF666666, createdAt: DateTime.now(), updatedAt: DateTime.now());
              final away = summary.teamsMap[m.awayTeamId] ?? TeamEntity(id: m.awayTeamId, name: 'Team', colorValue: 0xFF666666, createdAt: DateTime.now(), updatedAt: DateTime.now());

              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Row(
                  children: [
                    Text(
                      '${m.round}-tur',
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              home.name,
                              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          TeamAvatar(name: home.name, colorValue: home.colorValue, size: 24),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 10.w),
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        '${m.homeScore ?? 0} : ${m.awayScore ?? 0}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          TeamAvatar(name: away.name, colorValue: away.colorValue, size: 24),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              away.name,
                              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSkeletonLoading() {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: EdgeInsets.all(16.r),
        itemCount: 4,
        itemBuilder: (context, index) => Container(
          margin: EdgeInsets.only(bottom: 16.h),
          height: 120.h,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      ),
    );
  }
}
