import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/tournament_export_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/team_avatar.dart';
import '../../../teams/domain/entities/team_entity.dart';
import '../../domain/entities/match_entity.dart';

class MatchCard extends StatelessWidget {
  final MatchEntity match;
  final TeamEntity homeTeam;
  final TeamEntity awayTeam;
  final VoidCallback onEnterScore;
  final VoidCallback onEditTime;
  final VoidCallback onDeleteMatch;

  const MatchCard({
    super.key,
    required this.match,
    required this.homeTeam,
    required this.awayTeam,
    required this.onEnterScore,
    required this.onEditTime,
    required this.onDeleteMatch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFinished = match.status == MatchStatus.finished;
    final isLive = match.status == MatchStatus.live;

    final Color statusColor;
    switch (match.status) {
      case MatchStatus.finished:
        statusColor = AppColors.primary;
        break;
      case MatchStatus.live:
        statusColor = AppColors.liveRed;
        break;
      case MatchStatus.upcoming:
        statusColor = AppColors.accentBlue;
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: statusColor.withValues(alpha: isLive ? 0.9 : 0.75),
          width: isLive ? 1.8 : 1.4,
        ),
        boxShadow: isLive
            ? [
                BoxShadow(
                  color: AppColors.liveRed.withValues(alpha: 0.15),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Top bar: Time Slot + Status Badge + Actions Menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Time Slot Badge
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 15.r,
                      color: statusColor,
                    ),
                    SizedBox(width: 5.w),
                    Flexible(
                      child: Text(
                        match.timeSlot,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Badge and Menu
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusBadge(match.status),
                  SizedBox(width: 4.w),
                  SizedBox(
                    width: 28.r,
                    height: 28.r,
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        size: 18.r,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                      padding: EdgeInsets.zero,
                      onSelected: (val) {
                        if (val == 'time') onEditTime();
                        if (val == 'delete') onDeleteMatch();
                        if (val == 'share') {
                          TournamentExportService.shareMatchResult(
                          match: match,
                          homeTeam: homeTeam,
                          awayTeam: awayTeam,
                          tournamentName: AppConstants.defaultTournamentName,
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share_outlined, size: 18, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('Natijani ulashish'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'time',
                        child: Row(
                          children: [
                            Icon(Icons.edit_calendar_outlined, size: 18),
                            SizedBox(width: 8),
                            Text(AppStrings.editMatchTime),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                            SizedBox(width: 8),
                            Text(AppStrings.deleteMatch, style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          ),
          SizedBox(height: 12.h),

          // Teams and Score Line
          Row(
            children: [
              // Home Team
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    TeamAvatar(
                      name: homeTeam.name,
                      colorValue: homeTeam.colorValue,
                      logoPath: homeTeam.logoPath,
                      size: 36,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        homeTeam.name,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: isFinished && (match.homeScore ?? 0) > (match.awayScore ?? 0)
                              ? AppColors.primary
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Score Box
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isFinished || isLive
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: isFinished || isLive
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  isFinished || isLive
                      ? '${match.homeScore ?? 0}  :  ${match.awayScore ?? 0}'
                      : AppStrings.vs,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: isFinished || isLive ? AppColors.primary : Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              // Away Team
              Expanded(
                flex: 4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        awayTeam.name,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: isFinished && (match.awayScore ?? 0) > (match.homeScore ?? 0)
                              ? AppColors.primary
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    TeamAvatar(
                      name: awayTeam.name,
                      colorValue: awayTeam.colorValue,
                      logoPath: awayTeam.logoPath,
                      size: 36,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Enter Score Button
          SizedBox(
            width: double.infinity,
            height: 36.h,
            child: OutlinedButton.icon(
              onPressed: onEnterScore,
              icon: Icon(
                isFinished ? Icons.edit_note : Icons.sports_score,
                size: 16.r,
                color: isFinished ? theme.textTheme.bodyLarge?.color : AppColors.primary,
              ),
              label: Text(
                isFinished ? AppStrings.editScore : AppStrings.enterScore,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: isFinished ? theme.textTheme.bodyLarge?.color : AppColors.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isFinished
                      ? Colors.grey.withValues(alpha: 0.3)
                      : AppColors.primary.withValues(alpha: 0.6),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(MatchStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case MatchStatus.upcoming:
        bg = AppColors.accentBlue.withValues(alpha: 0.15);
        fg = AppColors.accentBlue;
        label = AppStrings.statusUpcoming;
        break;
      case MatchStatus.live:
        bg = AppColors.liveRed.withValues(alpha: 0.15);
        fg = AppColors.liveRed;
        label = '● ${AppStrings.statusLive}';
        break;
      case MatchStatus.finished:
        bg = AppColors.primary.withValues(alpha: 0.15);
        fg = AppColors.primary;
        label = '✓ ${AppStrings.statusFinished}';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
