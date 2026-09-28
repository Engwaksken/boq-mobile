part of '../main.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.l10n, required this.api});

  final AppLocalizations l10n;
  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardSummary>(
      future: api.dashboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                friendlyError(snapshot.error),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final summary = snapshot.data;

        if (summary == null) {
          return const SizedBox.shrink();
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.goodMorning,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.overview,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NotificationsPage(api: api),
                    ),
                  ),
                  tooltip: l10n.notifications,
                  icon: const Icon(Icons.notifications_none_outlined),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _ValueCard(
              title: l10n.estimatedValue,
              value: 'UGX ${summary.totalEstimatedValue.toStringAsFixed(0)}',
              icon: Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.88,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Metric(
                  label: l10n.totalProjects,
                  value: '${summary.totalProjects}',
                  color: const Color(0xFF1D4ED8),
                ),
                _Metric(
                  label: l10n.activeProjects,
                  value: '${summary.activeProjects}',
                  color: const Color(0xFF047857),
                ),
                _Metric(
                  label: l10n.boqsInReview,
                  value: '${summary.boqsAwaitingReview}',
                  color: const Color(0xFFB45309),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.recentProjects,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        body: ProjectsPage(l10n: l10n, api: api),
                      ),
                    ),
                  ),
                  child: Text(l10n.viewAll),
                ),
              ],
            ),
            if (summary.recentProjects.isEmpty)
              const Center(child: Text('No recent projects yet')),
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
                    ? const Color(0xFF047857)
                    : const Color(0xFFB45309),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ProjectDetailPage(api: api, projectId: project.id),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
