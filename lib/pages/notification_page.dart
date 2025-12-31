import 'package:flutter/material.dart';
import '../data/notification_store.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<AppNotification>> _future;

  @override
  void initState() {
    super.initState();
    _future = NotificationStore.list();
  }

  Future<void> _reload() async {
    setState(() {
      _future = NotificationStore.list();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          IconButton(
            tooltip: 'Tandai semua dibaca',
            onPressed: () async {
              await NotificationStore.markAllRead();
              await _reload();
            },
            icon: const Icon(Icons.done_all_rounded),
          ),
          IconButton(
            tooltip: 'Hapus semua',
            onPressed: () async {
              await NotificationStore.clear();
              await _reload();
            },
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<AppNotification>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.notifications_off_outlined, size: 56),
                  SizedBox(height: 12),
                  Center(child: Text('Belum ada notifikasi')),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final n = items[i];
                final bg = n.read ? cs.surface : cs.primary.withValues(alpha: .08);

                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    await NotificationStore.markRead(n.id);
                    await _reload();

                    // (Opsional) navigasi ke halaman antrian/detail jika ada pendaftaran_id
                    // final pid = n.data['pendaftaran_id'];
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notifications_rounded, color: cs.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.title,
                                style: t.bodyLarge?.copyWith(
                                  fontWeight: n.read ? FontWeight.w600 : FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(n.body, style: t.bodyMedium),
                              const SizedBox(height: 8),
                              Text(
                                _fmt(n.receivedAt),
                                style: t.bodySmall?.copyWith(
                                  color: cs.onSurface.withValues(alpha: .6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!n.read)
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final local = dt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}
