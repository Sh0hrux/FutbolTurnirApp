import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/team_avatar.dart';
import '../../domain/entities/team_entity.dart';

class TeamCard extends StatelessWidget {
  final TeamEntity team;
  final int played;
  final int points;
  final bool hasMatches;
  final VoidCallback onEdit;
  final VoidCallback onDeleteOrArchive;
  final VoidCallback? onUnarchive;

  const TeamCard({
    super.key,
    required this.team,
    this.played = 0,
    this.points = 0,
    this.hasMatches = false,
    required this.onEdit,
    required this.onDeleteOrArchive,
    this.onUnarchive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: team.isArchived
              ? Colors.grey.withValues(alpha: 0.3)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Opacity(
            opacity: team.isArchived ? 0.6 : 1.0,
            child: TeamAvatar(
              name: team.name,
              colorValue: team.colorValue,
              logoPath: team.logoPath,
              size: 44,
            ),
          ),
          SizedBox(width: 12.w),

          // Name and stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        team.name,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: team.isArchived
                              ? theme.textTheme.bodyMedium?.color
                              : theme.textTheme.bodyLarge?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (team.isArchived) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 1),
                        ),
                        child: Text(
                          AppStrings.archive,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4.h),
                // Replaced ID with concise statistics
                Text(
                  "O‘yinlar: $played · Ochko: $points",
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

          // Actions
          if (team.isArchived) ...[
            _buildCircleButton(
              context: context,
              icon: Icons.unarchive_outlined,
              iconColor: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              tooltip: AppStrings.unarchive,
              onPressed: onUnarchive,
            ),
          ] else ...[
            // Edit tonal button
            _buildCircleButton(
              context: context,
              icon: Icons.edit_outlined,
              iconColor: theme.colorScheme.onSurfaceVariant,
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              tooltip: AppStrings.edit,
              onPressed: onEdit,
            ),
            SizedBox(width: 8.w),
            // Delete or Archive tonal button
            _buildCircleButton(
              context: context,
              icon: hasMatches ? Icons.archive_outlined : Icons.delete_outline_rounded,
              iconColor: hasMatches ? AppColors.accentGold : theme.colorScheme.error,
              backgroundColor: hasMatches
                  ? AppColors.accentGold.withValues(alpha: 0.14)
                  : theme.colorScheme.error.withValues(alpha: 0.12),
              tooltip: hasMatches ? AppStrings.archive : AppStrings.delete,
              onPressed: onDeleteOrArchive,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 40.r,
            height: 40.r,
            child: Center(
              child: Icon(
                icon,
                size: 20.sp,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

