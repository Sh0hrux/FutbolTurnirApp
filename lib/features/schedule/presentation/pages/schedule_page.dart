import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/team_avatar.dart';
import '../../../teams/domain/entities/team_entity.dart';
import '../../domain/entities/match_entity.dart';
import '../bloc/schedule_bloc.dart';
import '../bloc/schedule_event.dart';
import '../bloc/schedule_state.dart';
import '../widgets/edit_time_slot_dialog.dart';
import '../widgets/enter_score_bottom_sheet.dart';
import '../widgets/match_card.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late final PageController _pageController;
  final ScrollController _chipsScrollController = ScrollController();
  late final ValueNotifier<int> _activeRoundNotifier;
  bool _isProgrammaticAnimation = false;

  @override
  void initState() {
    super.initState();
    final currentState = context.read<ScheduleBloc>().state;
    int initialPage = 0;
    int initialRound = 1;
    if (currentState is ScheduleSuccess) {
      final idx = currentState.availableRounds.indexOf(currentState.selectedRound);
      if (idx != -1) {
        initialPage = idx;
        initialRound = currentState.selectedRound;
      } else if (currentState.availableRounds.isNotEmpty) {
        initialRound = currentState.availableRounds.first;
      }
    }
    _activeRoundNotifier = ValueNotifier<int>(initialRound);
    _pageController = PageController(initialPage: initialPage);
    _pageController.addListener(_onPageScroll);
    context.read<ScheduleBloc>().add(const LoadScheduleEvent());
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    _chipsScrollController.dispose();
    _activeRoundNotifier.dispose();
    super.dispose();
  }

  void _onPageScroll() {
    if (!_pageController.hasClients || !_chipsScrollController.hasClients) return;
    if (_isProgrammaticAnimation) return;
    if (!_pageController.position.haveDimensions) return;

    final page = _pageController.page;
    if (page == null) return;

    final currentState = context.read<ScheduleBloc>().state;
    if (currentState is! ScheduleSuccess || currentState.availableRounds.isEmpty) return;

    final itemWidth = 78.w;
    final itemGap = 8.w;
    final itemExtent = itemWidth + itemGap;
    final screenWidth = MediaQuery.of(context).size.width;

    // Follow page movement continuously in 1:1 sync with the finger gesture
    final targetOffset = 16.w + (page * itemExtent) + (itemWidth / 2) - (screenWidth / 2);
    final maxScroll = _chipsScrollController.position.maxScrollExtent;
    final clampedOffset = targetOffset.clamp(0.0, maxScroll);

    if (_chipsScrollController.position.haveDimensions) {
      _chipsScrollController.jumpTo(clampedOffset);
    }

    // Update the active round pill when crossing midpoint (0.5)
    final nearestIndex = page.round().clamp(0, currentState.availableRounds.length - 1);
    final nearestRound = currentState.availableRounds[nearestIndex];
    if (_activeRoundNotifier.value != nearestRound) {
      _activeRoundNotifier.value = nearestRound;
    }
  }

  void _onSelectChip(int round, int index, List<int> availableRounds) {
    if (_activeRoundNotifier.value == round &&
        _pageController.hasClients &&
        _pageController.position.haveDimensions &&
        _pageController.page?.round() == index) {
      return;
    }

    _activeRoundNotifier.value = round;
    _isProgrammaticAnimation = true;

    final itemWidth = 78.w;
    final itemGap = 8.w;
    final itemExtent = itemWidth + itemGap;
    final screenWidth = MediaQuery.of(context).size.width;
    final targetOffset = 16.w + (index * itemExtent) + (itemWidth / 2) - (screenWidth / 2);
    final maxScroll = _chipsScrollController.hasClients && _chipsScrollController.position.haveDimensions
        ? _chipsScrollController.position.maxScrollExtent
        : 0.0;
    final clampedOffset = targetOffset.clamp(0.0, maxScroll);

    if (_chipsScrollController.hasClients && _chipsScrollController.position.haveDimensions) {
      _chipsScrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }

    if (_pageController.hasClients) {
      _pageController
          .animateToPage(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      )
          .then((_) {
        _isProgrammaticAnimation = false;
      });
    } else {
      _isProgrammaticAnimation = false;
    }

    context.read<ScheduleBloc>().add(SelectRoundEvent(round));
  }

  void _scrollToSelectedRound(int selectedRound, List<int> availableRounds) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chipsScrollController.hasClients || !_chipsScrollController.position.haveDimensions) return;
      final index = availableRounds.indexOf(selectedRound);
      if (index == -1) return;

      final itemWidth = 78.w;
      final itemExtent = itemWidth + 8.w;
      final screenWidth = MediaQuery.of(context).size.width;
      final targetOffset = 16.w + (index * itemExtent) + (itemWidth / 2) - (screenWidth / 2);
      final maxScroll = _chipsScrollController.position.maxScrollExtent;
      final clampedOffset = targetOffset.clamp(0.0, maxScroll);

      if ((_chipsScrollController.offset - clampedOffset).abs() > 2.0) {
        _chipsScrollController.animateTo(
          clampedOffset,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _onEnterScore(MatchEntity match, TeamEntity home, TeamEntity away) {
    final bloc = context.read<ScheduleBloc>();
    EnterScoreBottomSheet.show(
      context,
      match: match,
      homeTeam: home,
      awayTeam: away,
      onSave: ({required homeScore, required awayScore, required status}) async {
        bloc.add(
          UpdateMatchScoreEvent(
            matchId: match.id,
            homeScore: homeScore,
            awayScore: awayScore,
            status: status,
          ),
        );
      },
    );
  }

  void _onEditTime(MatchEntity match) {
    final bloc = context.read<ScheduleBloc>();
    EditTimeSlotDialog.show(
      context,
      currentTimeSlot: match.timeSlot,
      currentSlotIndex: match.slotIndex,
      onSave: (newSlot, newIndex) async {
        bloc.add(
          UpdateMatchSlotEvent(
            matchId: match.id,
            newTimeSlot: newSlot,
            newSlotIndex: newIndex,
          ),
        );
      },
    );
  }

  void _onDeleteMatch(MatchEntity match) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteMatch),
        content: const Text(AppStrings.confirmDeleteMatch),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<ScheduleBloc>().add(DeleteMatchEvent(match.id));
            },
            child: const Text(AppStrings.delete, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRound(int round, List<MatchEntity> roundMatches) {
    final hasFinished = roundMatches.any((m) => m.status == MatchStatus.finished);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
        title: Row(
          children: [
            const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
            SizedBox(width: 8.w),
            Expanded(child: Text('$round-turni o‘chirish')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Haqiqatan ham $round-turni va uning barcha o‘yinlarini o‘chirmoqchimisiz?'),
            if (hasFinished) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.deleteRoundWarning,
                        style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<ScheduleBloc>().add(DeleteRoundEvent(round));
            },
            child: const Text(AppStrings.delete, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmResetTournament() {
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
        title: const Text(AppStrings.scheduleTitle),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.tune),
            onSelected: (val) {
              final bloc = context.read<ScheduleBloc>();
              if (val == 'next_round') {
                bloc.add(const GenerateNextRoundEvent());
              } else if (val == 'full_schedule') {
                bloc.add(const GenerateFullScheduleEvent(totalRounds: 22));
              } else if (val == 'randomize') {
                if (bloc.state is ScheduleSuccess) {
                  final curRound = (bloc.state as ScheduleSuccess).selectedRound;
                  bloc.add(RandomizeRoundEvent(curRound));
                }
              } else if (val == 'delete_round') {
                if (bloc.state is ScheduleSuccess) {
                  final s = bloc.state as ScheduleSuccess;
                  final currentRound = _activeRoundNotifier.value;
                  final roundMatches = s.allMatches.where((m) => m.round == currentRound).toList();
                  _confirmDeleteRound(currentRound, roundMatches);
                }
              } else if (val == 'reset') {
                _confirmResetTournament();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'next_round',
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Text(AppStrings.generateNextRound),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'full_schedule',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.accentGold, size: 20),
                    SizedBox(width: 10),
                    Text('22 tur taqvimini yaratish'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'randomize',
                child: Row(
                  children: [
                    Icon(Icons.shuffle, color: AppColors.info, size: 20),
                    SizedBox(width: 10),
                    Text(AppStrings.randomizeUpcoming),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_round',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, color: AppColors.error, size: 20),
                    SizedBox(width: 10),
                    Text(AppStrings.deleteCurrentRound, style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restart_alt, color: AppColors.error, size: 20),
                    SizedBox(width: 10),
                    Text(AppStrings.resetTournament, style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocConsumer<ScheduleBloc, ScheduleState>(
        buildWhen: (previous, current) {
          if (previous is ScheduleSuccess && current is ScheduleSuccess) {
            return previous.allMatches != current.allMatches ||
                previous.availableRounds != current.availableRounds ||
                previous.teamsMap != current.teamsMap ||
                previous.isActionLoading != current.isActionLoading;
          }
          return true;
        },
        listener: (context, state) {
          if (state is ScheduleSuccess) {
            if (state.actionMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.actionMessage!)),
              );
            }
            if (!state.availableRounds.contains(_activeRoundNotifier.value)) {
              if (state.availableRounds.isNotEmpty) {
                _activeRoundNotifier.value = state.availableRounds.first;
              }
            }
            final targetIndex = state.availableRounds.indexOf(_activeRoundNotifier.value);
            if (targetIndex != -1 && _pageController.hasClients) {
              if (_pageController.position.haveDimensions && _pageController.page?.round() != targetIndex) {
                _pageController.jumpToPage(targetIndex);
              }
              _scrollToSelectedRound(_activeRoundNotifier.value, state.availableRounds);
            }
          }
        },
        builder: (context, state) {
          if (state is ScheduleLoading) {
            return _buildSkeletonLoading();
          }

          if (state is ScheduleFailure) {
            return ErrorView(
              message: state.message,
              onRetry: () => context.read<ScheduleBloc>().add(const LoadScheduleEvent()),
            );
          }

          if (state is ScheduleSuccess) {
            if (state.allMatches.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<ScheduleBloc>().add(const LoadScheduleEvent());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: 0.7.sh,
                    child: EmptyView(
                      title: 'O‘yinlar taqvimi mavjud emas',
                      subtitle: 'Turnir o‘yinlarini avtomatik taqsimlash uchun tugmani bosing',
                      icon: Icons.calendar_month,
                      actionTitle: AppStrings.generateSchedule,
                      onAction: () => context.read<ScheduleBloc>().add(const GenerateFullScheduleEvent(totalRounds: 22)),
                    ),
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Fixed top chips bar that auto-scrolls to the active round
                Padding(
                  padding: EdgeInsets.only(top: 8.h, bottom: 6.h),
                  child: _buildRoundChips(state),
                ),

                // Smooth animated PageView for matches per round with native swipe animation
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: state.availableRounds.length,
                    onPageChanged: (pageIndex) {
                      if (pageIndex < 0 || pageIndex >= state.availableRounds.length) return;
                      final newRound = state.availableRounds[pageIndex];
                      if (_activeRoundNotifier.value != newRound) {
                        _activeRoundNotifier.value = newRound;
                      }
                      if (!_isProgrammaticAnimation) {
                        _scrollToSelectedRound(newRound, state.availableRounds);
                      }
                      context.read<ScheduleBloc>().add(SelectRoundEvent(newRound));
                    },
                    itemBuilder: (context, index) {
                      final round = state.availableRounds[index];
                      final roundMatches = state.allMatches.where((m) => m.round == round).toList();
                      final rest = state.allRests.where((r) => r.round == round).firstOrNull;
                      final restingTeam = rest != null ? state.teamsMap[rest.teamId] : null;

                      final pageContent = _RoundMatchesPage(
                        key: ValueKey('round_$round'),
                        round: round,
                        matches: roundMatches,
                        restingTeam: restingTeam,
                        teamsMap: state.teamsMap,
                        isDark: isDark,
                        isActionLoading: state.isActionLoading,
                        onEnterScore: _onEnterScore,
                        onEditTime: _onEditTime,
                        onDeleteMatch: _onDeleteMatch,
                        onDeleteRound: _confirmDeleteRound,
                        onGenerateNextRound: () => context.read<ScheduleBloc>().add(const GenerateNextRoundEvent()),
                        onRefresh: () async {
                          context.read<ScheduleBloc>().add(LoadScheduleEvent(selectedRound: round));
                        },
                      );

                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double pageOffset = 0.0;
                          if (_pageController.hasClients &&
                              _pageController.position.haveDimensions &&
                              _pageController.page != null) {
                            pageOffset = _pageController.page! - index;
                          } else {
                            pageOffset = (_pageController.initialPage - index).toDouble();
                          }

                          final absOffset = pageOffset.abs().clamp(0.0, 1.0);
                          final scale = 1.0 - (absOffset * 0.04);
                          final opacity = (1.0 - (absOffset * 0.35)).clamp(0.0, 1.0);
                          final translationX = pageOffset * 16.w;

                          return Transform.translate(
                            offset: Offset(translationX, 0),
                            child: Transform.scale(
                              scale: scale,
                              child: Opacity(
                                opacity: opacity,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: pageContent,
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildRoundChips(ScheduleSuccess state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemWidth = 78.w;

    return ValueListenableBuilder<int>(
      valueListenable: _activeRoundNotifier,
      builder: (context, activeRound, _) {
        return SizedBox(
          height: 38.h,
          child: ListView.separated(
            controller: _chipsScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: state.availableRounds.length,
            separatorBuilder: (context, index) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final r = state.availableRounds[index];
              final isSelected = r == activeRound;

              return SizedBox(
                width: itemWidth,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(19.r),
                    onTap: () => _onSelectChip(r, index, state.availableRounds),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? const Color(0xFF1E232A) : const Color(0xFFEDF2F7)),
                        borderRadius: BorderRadius.circular(19.r),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.black.withValues(alpha: 0.08)),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? Colors.black
                              : (isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black87),
                          fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                        ),
                        child: Text('$r-tur'),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  static Widget buildRestingTeamBanner(TeamEntity restingTeam, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.accentGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.accentGold.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: const BoxDecoration(
              color: AppColors.accentGold,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.coffee, size: 16.r, color: Colors.black),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.restingTeam,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  restingTeam.name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          TeamAvatar(
            name: restingTeam.name,
            colorValue: restingTeam.colorValue,
            logoPath: restingTeam.logoPath,
            size: 32,
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
        itemCount: 5,
        itemBuilder: (context, index) => Container(
          margin: EdgeInsets.only(bottom: 12.h),
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

class _RoundMatchesPage extends StatefulWidget {
  final int round;
  final List<MatchEntity> matches;
  final TeamEntity? restingTeam;
  final Map<String, TeamEntity> teamsMap;
  final bool isDark;
  final bool isActionLoading;
  final Function(MatchEntity, TeamEntity, TeamEntity) onEnterScore;
  final Function(MatchEntity) onEditTime;
  final Function(MatchEntity) onDeleteMatch;
  final Function(int, List<MatchEntity>) onDeleteRound;
  final VoidCallback onGenerateNextRound;
  final Future<void> Function() onRefresh;

  const _RoundMatchesPage({
    super.key,
    required this.round,
    required this.matches,
    required this.restingTeam,
    required this.teamsMap,
    required this.isDark,
    required this.isActionLoading,
    required this.onEnterScore,
    required this.onEditTime,
    required this.onDeleteMatch,
    required this.onDeleteRound,
    required this.onGenerateNextRound,
    required this.onRefresh,
  });

  @override
  State<_RoundMatchesPage> createState() => _RoundMatchesPageState();
}

class _RoundMatchesPageState extends State<_RoundMatchesPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        children: [
          // Resting team banner
          if (widget.restingTeam != null) ...[
            _SchedulePageState.buildRestingTeamBanner(widget.restingTeam!, widget.isDark),
            SizedBox(height: 12.h),
          ],

          // Matches count info + Delete Round Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${widget.round}-tur o‘yinlari (${widget.matches.length} ta o‘yin)',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.isActionLoading)
                SizedBox(
                  width: 16.r,
                  height: 16.r,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
                  tooltip: '${widget.round}-turni o‘chirish',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => widget.onDeleteRound(widget.round, widget.matches),
                ),
            ],
          ),
          SizedBox(height: 10.h),

          // Match Cards
          ...widget.matches.map((match) {
            final homeTeam = widget.teamsMap[match.homeTeamId] ??
                TeamEntity(
                  id: match.homeTeamId,
                  name: 'Team',
                  colorValue: 0xFF666666,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
            final awayTeam = widget.teamsMap[match.awayTeamId] ??
                TeamEntity(
                  id: match.awayTeamId,
                  name: 'Team',
                  colorValue: 0xFF666666,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

            return MatchCard(
              key: ValueKey(match.id),
              match: match,
              homeTeam: homeTeam,
              awayTeam: awayTeam,
              onEnterScore: () => widget.onEnterScore(match, homeTeam, awayTeam),
              onEditTime: () => widget.onEditTime(match),
              onDeleteMatch: () => widget.onDeleteMatch(match),
            );
          }),

          SizedBox(height: 20.h),
          // Bottom quick action: Generate next round
          AppButton(
            text: AppStrings.generateNextRound,
            icon: Icons.add,
            isLoading: widget.isActionLoading,
            isOutlined: true,
            onPressed: widget.onGenerateNextRound,
          ),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }
}

