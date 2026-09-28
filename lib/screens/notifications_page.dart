part of '../main.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, required this.api});
  final ApiClient api;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<NotificationItem>> _notifications;
  int _page = 1;
  bool _loadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications({bool loadMore = false}) async {
    if (_loadingMore) return;
    final targetPage = loadMore ? _page + 1 : 1;
    if (loadMore) {
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _notifications = widget.api.getNotifications(page: targetPage);
      });
    }
    try {
      final notifications = await widget.api.getNotifications(page: targetPage);
      if (mounted) {
        setState(() {
          if (loadMore) {
            // We need to get the current list and append
            // For simplicity, we'll just reload the whole list
            _notifications = widget.api.getNotifications(page: 1);
            _page = 1;
          } else {
            _notifications = Future.value(notifications);
            _page = targetPage;
          }
          _hasMore = notifications.length >= 20;
          _loadingMore = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loadingMore = false;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.message)));
        });
      }
    }
  }

  Future<void> _markAsRead(NotificationItem notification) async {
    if (notification.isRead) return;
    try {
      await widget.api.markNotificationAsRead(notification.id);
      if (mounted) {
        setState(() {
          _loadNotifications();
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notifications)),
      body: RefreshIndicator(
        onRefresh: () => _loadNotifications(),
        child: FutureBuilder<List<NotificationItem>>(
          future: _notifications,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SkeletonList();
            }
            if (snapshot.hasError) {
              return _fillScrollable(
                ErrorState(
                  error: snapshot.error,
                  onRetry: () => _loadNotifications(),
                  compact: true,
                ),
              );
            }
            final notifications = snapshot.data ?? [];
            if (notifications.isEmpty) {
              return _fillScrollable(
                EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: l10n.noNotifications,
                  compact: true,
                ),
              );
            }
            return NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 200 &&
                    !_loadingMore &&
                    _hasMore) {
                  _loadNotifications(loadMore: true);
                }
                return false;
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppSpacing.page,
                itemCount: notifications.length + (_loadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= notifications.length) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final notification = notifications[index];
                  return ContentWidth(
                    child: _buildNotificationRow(context, l10n, notification),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  /// Centres a compact state inside a scrollable so pull-to-refresh works.
  Widget _fillScrollable(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.page,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight * 0.7),
            child: Center(child: child),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationRow(
    BuildContext context,
    AppLocalizations l10n,
    NotificationItem notification,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final unread = !notification.isRead;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.itemGap),
      child: Card(
        color: unread ? scheme.primaryContainer.withValues(alpha: 0.35) : null,
        child: InkWell(
          onTap: () => _markAsRead(notification),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md + 2,
              AppSpacing.sm,
              AppSpacing.md + 2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconTile(
                  icon: _iconForType(notification.type),
                  tone: _toneForType(notification.type),
                ),
                const SizedBox(width: AppSpacing.md + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: unread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (unread) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Semantics(
                              label: 'Unread',
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        notification.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              _formatDate(notification.createdAt),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          if (unread)
                            TextButton.icon(
                              onPressed: () => _markAsRead(notification),
                              icon: const Icon(
                                Icons.done_all_rounded,
                                size: 18,
                              ),
                              label: Text(l10n.markAsRead),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  StatusTone _toneForType(String type) {
    switch (type) {
      case 'success':
        return StatusTone.success;
      case 'warning':
        return StatusTone.warning;
      case 'error':
        return StatusTone.danger;
      default:
        return StatusTone.info;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle_outline_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'error':
        return Icons.error_outline_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}
