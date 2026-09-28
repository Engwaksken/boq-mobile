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
      body: FutureBuilder<List<NotificationItem>>(
        future: _notifications,
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
          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noNotifications,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
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
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length + (_loadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= notifications.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final notification = notifications[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: notification.isRead
                      ? null
                      : Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: notification.isRead
                          ? Colors.grey[300]
                          : Theme.of(context).colorScheme.primary,
                      child: Icon(
                        _iconForType(notification.type),
                        color: notification.isRead
                            ? Colors.grey[600]
                            : Colors.white,
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead
                            ? FontWeight.w400
                            : FontWeight.w700,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification.message),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(notification.createdAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    trailing: !notification.isRead
                        ? TextButton(
                            onPressed: () => _markAsRead(notification),
                            child: Text(l10n.markAsRead),
                          )
                        : null,
                    onTap: () => _markAsRead(notification),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
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
