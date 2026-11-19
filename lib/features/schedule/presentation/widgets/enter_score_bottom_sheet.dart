import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/team_avatar.dart';
import '../../../teams/domain/entities/team_entity.dart';
import '../../domain/entities/match_entity.dart';

class EnterScoreBottomSheet extends StatefulWidget {
  final MatchEntity match;
  final TeamEntity homeTeam;
  final TeamEntity awayTeam;
  final Future<void> Function({
    required int? homeScore,
    required int? awayScore,
    required MatchStatus status,
  }) onSave;

  const EnterScoreBottomSheet({
    super.key,
    required this.match,
    required this.homeTeam,
    required this.awayTeam,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required MatchEntity match,
    required TeamEntity homeTeam,
    required TeamEntity awayTeam,
    required Future<void> Function({
      required int? homeScore,
      required int? awayScore,
      required MatchStatus status,
    }) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnterScoreBottomSheet(
        match: match,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EnterScoreBottomSheet> createState() => _EnterScoreBottomSheetState();
}

class _EnterScoreBottomSheetState extends State<EnterScoreBottomSheet> {
  late int _homeScore;
  late int _awayScore;
  late MatchStatus _status;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _homeScore = widget.match.homeScore ?? 0;
    _awayScore = widget.match.awayScore ?? 0;
    _status = widget.match.status == MatchStatus.upcoming
        ? MatchStatus.finished
        : widget.match.status;
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);
    await widget.onSave(
      homeScore: _status == MatchStatus.upcoming ? null : _homeScore,
      awayScore: _status == MatchStatus.upcoming ? null : _awayScore,
      status: _status,
    );
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleResetScore() async {
    setState(() => _isLoading = true);
    await widget.onSave(
      homeScore: null,
      awayScore: null,
      status: MatchStatus.upcoming,
    );
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, MediaQuery.of(context).viewInsets.bottom + 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.match.round}-tur • ${widget.match.timeSlot}',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Teams and Score Steppers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Home Team
              Expanded(
                child: Column(
                  children: [
                    TeamAvatar(
                      name: widget.homeTeam.name,
                      colorValue: widget.homeTeam.colorValue,
                      logoPath: widget.homeTeam.logoPath,
                      size: 54,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      widget.homeTeam.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 12.h),
                    _buildScoreStepper(
                      score: _homeScore,
                      onDecrement: () {
                        if (_homeScore > 0) setState(() => _homeScore--);
                      },
                      onIncrement: () => setState(() => _homeScore++),
                    ),
                  ],
                ),
              ),

              // Divider / Colon
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Column(
                  children: [
                    Text(
                      ':',
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // Away Team
              Expanded(
                child: Column(
                  children: [
                    TeamAvatar(
                      name: widget.awayTeam.name,
                      colorValue: widget.awayTeam.colorValue,
                      logoPath: widget.awayTeam.logoPath,
                      size: 54,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      widget.awayTeam.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 12.h),
                    _buildScoreStepper(
                      score: _awayScore,
                      onDecrement: () {
                        if (_awayScore > 0) setState(() => _awayScore--);
                      },
                      onIncrement: () => setState(() => _awayScore++),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Match Status Selection
          Text(
            AppStrings.matchStatus,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              _buildStatusChip(MatchStatus.upcoming, AppStrings.statusUpcoming),
              SizedBox(width: 8.w),
              _buildStatusChip(MatchStatus.live, AppStrings.statusLive),
              SizedBox(width: 8.w),
              _buildStatusChip(MatchStatus.finished, AppStrings.statusFinished),
            ],
          ),
          SizedBox(height: 24.h),

          // Action Buttons
          Row(
            children: [
              if (widget.match.status == MatchStatus.finished || widget.match.homeScore != null) ...[
                Expanded(
                  flex: 1,
                  child: AppButton(
                    text: AppStrings.resetScore,
                    isOutlined: true,
                    backgroundColor: AppColors.error,
                    textColor: AppColors.error,
                    isLoading: _isLoading,
                    onPressed: _handleResetScore,
                  ),
                ),
                SizedBox(width: 10.w),
              ],
              Expanded(
                flex: 2,
                child: AppButton(
                  text: AppStrings.saveResult,
                  isLoading: _isLoading,
                  onPressed: _handleSave,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreStepper({
    required int score,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton.filledTonal(
            onPressed: _isLoading ? null : onDecrement,
            icon: const Icon(Icons.remove),
            iconSize: 16.r,
            style: IconButton.styleFrom(
              padding: EdgeInsets.all(6.r),
              minimumSize: Size(32.r, 32.r),
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 6.w),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              '$score',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ),
          IconButton.filledTonal(
            onPressed: _isLoading ? null : onIncrement,
            icon: const Icon(Icons.add),
            iconSize: 16.r,
            style: IconButton.styleFrom(
              padding: EdgeInsets.all(6.r),
              minimumSize: Size(32.r, 32.r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(MatchStatus status, String label) {
    final isSelected = _status == status;
    Color chipColor;
    switch (status) {
      case MatchStatus.upcoming:
        chipColor = AppColors.info;
        break;
      case MatchStatus.live:
        chipColor = AppColors.liveRed;
        break;
      case MatchStatus.finished:
        chipColor = AppColors.primary;
        break;
    }

    return Expanded(
      child: GestureDetector(
        onTap: _isLoading ? null : () => setState(() => _status = status),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected
                ? chipColor.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isSelected ? chipColor : Colors.grey.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? chipColor : Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ),
    );
  }
}
