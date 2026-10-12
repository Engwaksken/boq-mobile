part of '../main.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.l10n, required this.api});

  final AppLocalizations l10n;
  final ApiClient api;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Fetched once and on Retry / pull-to-refresh, not on every rebuild.
  late Future<DashboardSummary> _summary = widget.api.dashboard();

  AppLocalizations get l10n => widget.l10n;
  ApiClient get api => widget.api;

  Future<void> _reload() async {
    final future = api.dashboard();
    setState(() => _summary = future);
    try {
      await future;
    } on Object {
      // Shown by the FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardSummary>(
      future: _summary,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _DashboardSkeleton();
        }

        if (snapshot.hasError) {
          return ErrorState(error: snapshot.error, onRetry: _reload);
        }

        final summary = snapshot.data;

        if (summary == null) {
          return const SizedBox.shrink();
        }

        return RefreshIndicator(
          onRefresh: _reload,
          child: _buildContent(context, summary),
        );
      },
    );
  }

  void _openProjects(
    BuildContext context,
    String title, {
    String? status,
    String? boqStatus,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: ProjectsPage(
            l10n: l10n,
            api: api,
            status: status,
            boqStatus: boqStatus,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DashboardSummary summary) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.page,
      children: [
        ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: l10n.goodMorning,
                subtitle: l10n.overview,
                leading: const BrandMark(size: 44),
                trailing: IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NotificationsPage(api: api),
                    ),
                  ),
                  tooltip: l10n.notifications,
                  icon: const Icon(Icons.notifications_none_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openProjects(context, l10n.projects),
                child: HighlightCard(
                  label: l10n.estimatedValue,
                  value: formatAmount(summary.totalEstimatedValue),
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: StatCard(
                        label: l10n.totalProjects,
                        value: '${summary.totalProjects}',
                        icon: Icons.account_tree_outlined,
                        tone: StatusTone.info,
                        onTap: () => _openProjects(context, l10n.totalProjects),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 2),
                    Expanded(
                      child: StatCard(
                        label: l10n.activeProjects,
                        value: '${summary.activeProjects}',
                        icon: Icons.play_circle_outline,
                        tone: StatusTone.success,
                        onTap: () => _openProjects(
                          context,
                          l10n.activeProjects,
                          status: 'active',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 2),
                    Expanded(
                      child: StatCard(
                        label: l10n.boqsInReview,
                        value: '${summary.boqsAwaitingReview}',
                        icon: Icons.fact_check_outlined,
                        tone: StatusTone.warning,
                        onTap: () => _openProjects(
                          context,
                          l10n.boqsInReview,
                          boqStatus: 'under_review',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SectionHeader(
                title: l10n.recentProjects,
                actionLabel: l10n.viewAll,
                onAction: () => _openProjects(context, l10n.projects),
              ),
              if (summary.recentProjects.isEmpty)
                Card(
                  child: EmptyState(
                    compact: true,
                    icon: Icons.folder_open_outlined,
                    title: l10n.dashNoRecentProjects,
                    message: l10n.noProjects,
                  ),
                ),
              ...summary.recentProjects.map(
                (project) => _ProjectTile(
                  name: project.name,
                  code: project.code,
                  status: project.status == 'active'
                      ? l10n.projectStatusActive
                      : project.status == 'planning'
                      ? l10n.projectStatusPlanning
                      : l10n.draft,
                  color: project.status == 'active'
                      ? AppColors.success
                      : AppColors.warning,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ProjectDetailPage(api: api, projectId: project.id),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: AppSpacing.page,
      children: const [
        SkeletonBox(width: 180, height: 26),
        SizedBox(height: AppSpacing.sm),
        SkeletonBox(width: 120, height: 14),
        SizedBox(height: AppSpacing.xl),
        SkeletonBox(height: 128, radius: AppRadii.lg),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 112, radius: AppRadii.md)),
            SizedBox(width: AppSpacing.sm + 2),
            Expanded(child: SkeletonBox(height: 112, radius: AppRadii.md)),
            SizedBox(width: AppSpacing.sm + 2),
            Expanded(child: SkeletonBox(height: 112, radius: AppRadii.md)),
          ],
        ),
        SizedBox(height: AppSpacing.xxl),
        SkeletonBox(width: 140, height: 18),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(height: 68, radius: AppRadii.md),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(height: 68, radius: AppRadii.md),
      ],
    );
  }
}
