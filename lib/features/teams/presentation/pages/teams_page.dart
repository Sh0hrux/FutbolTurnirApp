import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/entities/team_entity.dart';
import '../cubit/teams_cubit.dart';
import '../cubit/teams_state.dart';
import '../widgets/add_edit_team_dialog.dart';
import '../widgets/team_card.dart';

class TeamsPage extends StatefulWidget {
  const TeamsPage({super.key});

  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<TeamsCubit>().loadTeams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddTeamDialog() {
    final cubit = context.read<TeamsCubit>();
    AddEditTeamDialog.show(
      context,
      onSave: ({required name, required colorValue, logoPath}) async {
        return cubit.addTeam(
          name: name,
          colorValue: colorValue,
          logoPath: logoPath,
        );
      },
    );
  }

  void _showEditTeamDialog(TeamEntity team) {
    final cubit = context.read<TeamsCubit>();
    AddEditTeamDialog.show(
      context,
      team: team,
      onSave: ({required name, required colorValue, logoPath}) async {
        return cubit.updateTeam(
          team.copyWith(
            name: name,
            colorValue: colorValue,
            logoPath: logoPath,
          ),
        );
      },
    );
  }

  Future<void> _handleDeleteOrArchive(TeamEntity team) async {
    final cubit = context.read<TeamsCubit>();
    final hasMatches = await cubit.checkTeamHasMatches(team.id);

    if (!mounted) return;

    if (hasMatches) {
      // Must offer Archive since matches exist
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text(AppStrings.archive),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${team.name} ${AppStrings.teamMatchesWarning}',
                style: TextStyle(fontSize: 13.sp),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text(AppStrings.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                await cubit.deleteOrArchiveTeam(team.id, forceArchive: true);
              },
              child: const Text(AppStrings.archive, style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
    } else {
      // Permanent delete confirmation
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text(AppStrings.deleteTeam),
          content: Text(
            '${team.name} ${AppStrings.confirmDeleteTeam}',
            style: TextStyle(fontSize: 13.sp),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text(AppStrings.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                await cubit.deleteOrArchiveTeam(team.id, forceArchive: false);
              },
              child: const Text(AppStrings.delete, style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navTeams),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
          tabs: const [
            Tab(text: AppStrings.activeTeams),
            Tab(text: AppStrings.archivedTeams),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTeamDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          AppStrings.addTeam,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: BlocConsumer<TeamsCubit, TeamsState>(
        listener: (context, state) {
          if (state is TeamsSuccess && state.actionMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.actionMessage!)),
            );
          }
        },
        builder: (context, state) {
          if (state is TeamsLoading) {
            return _buildSkeletonLoading();
          }

          if (state is TeamsFailure) {
            return ErrorView(
              message: state.message,
              onRetry: () => context.read<TeamsCubit>().loadTeams(),
            );
          }

          if (state is TeamsSuccess) {
            final activeTeams = state.teams.where((t) => !t.isArchived).toList();
            final archivedTeams = state.teams.where((t) => t.isArchived).toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildTeamList(
                  teams: activeTeams,
                  statsMap: state.statsMap,
                  isArchivedTab: false,
                  emptyTitle: AppStrings.noTeamsFound,
                  emptySubtitle: 'Turnirda qatnashish uchun yangi jamoa qo‘shing',
                ),
                _buildTeamList(
                  teams: archivedTeams,
                  statsMap: state.statsMap,
                  isArchivedTab: true,
                  emptyTitle: 'Arxivlangan jamoalar yo‘q',
                  emptySubtitle: 'Faol jamoalarni arxivlash orqali bu yerga o‘tkazish mumkin',
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildTeamList({
    required List<TeamEntity> teams,
    required Map<String, TeamStatsInfo> statsMap,
    required bool isArchivedTab,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (teams.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<TeamsCubit>().loadTeams(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 0.65.sh,
            child: EmptyView(
              title: emptyTitle,
              subtitle: emptySubtitle,
              icon: Icons.shield_outlined,
              actionTitle: isArchivedTab ? null : AppStrings.addTeam,
              onAction: isArchivedTab ? null : _showAddTeamDialog,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<TeamsCubit>().loadTeams(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 14.h, bottom: 84.h),
        itemCount: teams.length,
        itemBuilder: (context, index) {
          final team = teams[index];
          final stats = statsMap[team.id] ?? const TeamStatsInfo();
          return TeamCard(
            team: team,
            played: stats.played,
            points: stats.points,
            hasMatches: stats.hasMatches,
            onEdit: () => _showEditTeamDialog(team),
            onDeleteOrArchive: () => _handleDeleteOrArchive(team),
            onUnarchive: isArchivedTab
                ? () => context.read<TeamsCubit>().unarchiveTeam(team.id)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Row(
              children: [
                CircleAvatar(radius: 22.r),
                SizedBox(width: 14.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120.w, height: 16.h, color: Colors.white),
                    SizedBox(height: 6.h),
                    Container(width: 60.w, height: 12.h, color: Colors.white),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

