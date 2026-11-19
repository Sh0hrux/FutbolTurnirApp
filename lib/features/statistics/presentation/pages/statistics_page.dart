import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/team_avatar.dart';
import '../../domain/entities/tournament_statistics_entity.dart';
import '../bloc/statistics_bloc.dart';
import '../bloc/statistics_event.dart';
import '../bloc/statistics_state.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  @override
  void initState() {
    super.initState();
    context.read<StatisticsBloc>().add(const LoadStatisticsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.statisticsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppStrings.refresh,
            onPressed: () => context.read<StatisticsBloc>().add(const LoadStatisticsEvent()),
          ),
        ],
      ),
      body: BlocBuilder<StatisticsBloc, StatisticsState>(
        builder: (context, state) {
          if (state is StatisticsLoading) {
            return _buildSkeletonLoading();
          }

          if (state is StatisticsFailure) {
            return ErrorView(
              message: state.message,
              onRetry: () => context.read<StatisticsBloc>().add(const LoadStatisticsEvent()),
            );
          }

          if (state is StatisticsSuccess) {
            final stats = state.statistics;

            if (stats.totalMatchesPlayed == 0) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<StatisticsBloc>().add(const LoadStatisticsEvent());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: 0.7.sh,
                    child: const EmptyView(
                      title: 'Hali statistika mavjud emas',
                      subtitle: 'O‘yinlar o‘tkazilib hisob kiritilgach, ushbu sahifada to‘liq statistika va diagrammalar hosil bo‘ladi',
                      icon: Icons.query_stats,
                    ),
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<StatisticsBloc>().add(const LoadStatisticsEvent());
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                children: [
                  // 1. General Tournament Totals
                  _buildTotalsCard(stats, isDark),
                  SizedBox(height: 18.h),

                  // 2. Key Highlights (2 columns grid)
                  _buildSectionTitle('Asosiy ko‘rsatkichlar'),
                  SizedBox(height: 8.h),
                  _buildHighlightsGrid(stats, isDark),
                  SizedBox(height: 20.h),

                  // 3. Goals Scored Bar Chart
                  _buildSectionTitle('Jamoalar bo‘yicha urilgan gollar'),
                  SizedBox(height: 10.h),
                  _buildGoalsChart(stats.teamStats, isDark),
                  SizedBox(height: 20.h),

                  // 4. Detailed Team Performance Breakdown
                  _buildSectionTitle('Har bir jamoaning to‘liq statistikasi'),
                  SizedBox(height: 10.h),
                  ...stats.teamStats.map((teamStat) => _buildTeamDetailCard(teamStat, isDark)),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildTotalsCard(TournamentStatisticsEntity stats, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTotalMetric(
            label: AppStrings.finishedMatches,
            value: '${stats.totalMatchesPlayed}',
            icon: Icons.sports_soccer,
            color: AppColors.primary,
          ),
          Container(width: 1, height: 38.h, color: Colors.grey.withValues(alpha: 0.3)),
          _buildTotalMetric(
            label: AppStrings.totalGoals,
            value: '${stats.totalGoals}',
            icon: Icons.sports_score,
            color: AppColors.accentGold,
          ),
          Container(width: 1, height: 38.h, color: Colors.grey.withValues(alpha: 0.3)),
          _buildTotalMetric(
            label: AppStrings.goalsPerMatch,
            value: stats.averageGoalsPerMatch.toStringAsFixed(1),
            icon: Icons.analytics_outlined,
            color: AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20.r),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900, color: color),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
      ],
    );
  }

  Widget _buildHighlightsGrid(TournamentStatisticsEntity stats, bool isDark) {
    final items = [
      if (stats.topPointsTeam != null)
        _HighlightData(
          title: AppStrings.mostPoints,
          metric: stats.topPointsTeam!,
          icon: Icons.emoji_events,
          color: AppColors.accentGold,
        ),
      if (stats.topScoringTeam != null)
        _HighlightData(
          title: AppStrings.mostGoalsScored,
          metric: stats.topScoringTeam!,
          icon: Icons.local_fire_department,
          color: Colors.deepOrange,
        ),
      if (stats.bestDefenseTeam != null)
        _HighlightData(
          title: AppStrings.leastGoalsConceded,
          metric: stats.bestDefenseTeam!,
          icon: Icons.security,
          color: AppColors.primary,
        ),
      if (stats.bestGoalDiffTeam != null)
        _HighlightData(
          title: AppStrings.bestGoalDiff,
          metric: stats.bestGoalDiffTeam!,
          icon: Icons.trending_up,
          color: AppColors.info,
        ),
      if (stats.mostWinsTeam != null)
        _HighlightData(
          title: AppStrings.mostWins,
          metric: stats.mostWinsTeam!,
          icon: Icons.thumb_up_alt_outlined,
          color: Colors.green,
        ),
      if (stats.mostLossesTeam != null)
        _HighlightData(
          title: AppStrings.mostLosses,
          metric: stats.mostLossesTeam!,
          icon: Icons.sentiment_dissatisfied,
          color: AppColors.error,
        ),
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10.h,
        crossAxisSpacing: 10.w,
        childAspectRatio: 1.55,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(item.icon, color: item.color, size: 20.r),
                  TeamAvatar(
                    name: item.metric.team.name,
                    colorValue: item.metric.team.colorValue,
                    size: 24,
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                item.metric.team.name,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                item.metric.label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: item.color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGoalsChart(List<DetailedTeamStat> teamStats, bool isDark) {
    final activeTeams = teamStats.where((t) => t.played > 0).take(6).toList();
    if (activeTeams.isEmpty) return const SizedBox.shrink();

    final maxGoals = activeTeams.map((t) => t.goalsFor).fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = (maxGoals + 2).toDouble();

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      height: 200.h,
      child: BarChart(
        BarChartData(
          maxY: maxY < 6 ? 6 : maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final team = activeTeams[groupIndex].team;
                return BarTooltipItem(
                  '${team.name}\n${rod.toY.round()} ta gol',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < activeTeams.length) {
                    final name = activeTeams[idx].team.name;
                    return Padding(
                      padding: EdgeInsets.only(top: 6.h),
                      child: Text(
                        name.length > 5 ? name.substring(0, 5) : name,
                        style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24.w,
                interval: 2,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withValues(alpha: 0.15),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(activeTeams.length, (index) {
            final t = activeTeams[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: t.goalsFor.toDouble(),
                  color: Color(t.team.colorValue),
                  width: 18.w,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(6.r)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTeamDetailCard(DetailedTeamStat stat, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          TeamAvatar(
            name: stat.team.name,
            colorValue: stat.team.colorValue,
            size: 34,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.team.name,
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 2.h),
                Text(
                  'O‘yinlar: ${stat.played} | G‘: ${stat.won}  D: ${stat.drawn}  M: ${stat.lost}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${stat.goalsFor} : ${stat.goalsAgainst}',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
              ),
              Text(
                '${stat.points} ochko',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: EdgeInsets.all(16.r),
        itemCount: 4,
        itemBuilder: (context, index) => Container(
          margin: EdgeInsets.only(bottom: 12.h),
          height: 100.h,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
      ),
    );
  }
}

class _HighlightData {
  final String title;
  final TeamStatMetric metric;
  final IconData icon;
  final Color color;

  const _HighlightData({
    required this.title,
    required this.metric,
    required this.icon,
    required this.color,
  });
}
