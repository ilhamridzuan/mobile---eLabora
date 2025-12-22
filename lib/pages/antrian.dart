import 'package:elabora_app/utils/constants.dart';
import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/auth_api.dart';
import '../data/queue_api.dart';
import '../utils/date_id.dart';

class AntrianPage extends StatefulWidget {
  const AntrianPage({super.key});

  @override
  State<AntrianPage> createState() => _AntrianPageState();
}

class _AntrianPageState extends State<AntrianPage> {
  late final ApiClient _client;
  late final QueueApi _queueApi;
  late final AuthApi _authApi;

  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _queueApi = QueueApi(_client);
    _authApi = AuthApi(_client);
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final me = await _authApi.me();
    final profil = me['profil'] as Map<String, dynamic>?;
    final pasienId = (profil?['id'] as int?);

    final today = await _queueApi.today();
    final statsWrap = await _queueApi.stats();

    return {
      'me': me,
      'pasienId': pasienId,
      'today': today,
      'statsWrap': statsWrap,
    };
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  String _pad3(dynamic v) => _toInt(v).toString().padLeft(3, '0');

  String _fmtDateTime(dynamic isoOrStr) {
    final raw = (isoOrStr ?? '').toString();
    if (raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateId.formatFullWithTime(dt);
    } catch (_) {
      return raw;
    }
  }

  // ✅ ambil no_antrian “saat ini” berdasarkan status
  // prioritas: DILAYANI -> MENUNGGU terkecil -> null
  String? _currentNoFromItems(List<Map<String, dynamic>> items) {
    Map<String, dynamic>? current;

    // 1) cari item DILAYANI
    for (final e in items) {
      final st = (e['status'] ?? '').toString().toUpperCase();
      if (st == 'DILAYANI') {
        current = e;
        break;
      }
    }
    if (current != null) return _pad3(current['no_antrian']);

    // 2) fallback: kalau belum ada DILAYANI, ambil MENUNGGU yang no_antrian paling kecil
    final waiting = items
        .where((e) => (e['status'] ?? '').toString().toUpperCase() == 'MENUNGGU')
        .toList();

    if (waiting.isEmpty) return null;

    waiting.sort((a, b) => _toInt(a['no_antrian']).compareTo(_toInt(b['no_antrian'])));
    return _pad3(waiting.first['no_antrian']);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final text = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Antrian'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: color.surface,
        foregroundColor: color.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorState(
              message: snap.error.toString(),
              onRetry: () => setState(() => _future = _load()),
            );
          }

          final root = snap.data ?? {};
          final pasienId = root['pasienId'] as int?;

          final today = (root['today'] as Map<String, dynamic>? ?? {});
          final todayTanggal = (today['tanggal'] ?? '').toString();
          final items = (today['data'] is List)
              ? (today['data'] as List).whereType<Map<String, dynamic>>().toList()
              : <Map<String, dynamic>>[];

          final statsWrap = (root['statsWrap'] as Map<String, dynamic>? ?? {});
          final statsTanggal = (statsWrap['tanggal'] ?? '').toString();
          final stats = (statsWrap['stats'] as Map<String, dynamic>? ?? {});

          final total = _toInt(stats['total']);
          final menunggu = _toInt(stats['menunggu']);

          // ✅ Nomor antrian saat ini dari item status DILAYANI
          final currentNo = _currentNoFromItems(items) ?? '-';

          // ambil antrian user berdasarkan pasien_id
          Map<String, dynamic>? my;
          if (pasienId != null) {
            try {
              my = items.firstWhere((e) => e['pasien_id'] == pasienId);
            } catch (_) {
              my = null;
            }
          }

          final myNo = my == null ? null : _pad3(my['no_antrian']);
          final myStatus = my == null ? null : (my['status'] ?? '').toString();
          final myJadwal = my == null ? null : _fmtDateTime(my['jadwal_pemeriksaan_at']);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _load());
              await _future;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nomor antrian saya',
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: color.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textSecondary.withValues(alpha: 0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.access_time_rounded,
                            color: color.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                my == null
                                    ? 'Belum ada antrian hari ini'
                                    : 'Nomor Antrian : $myNo',
                                style: text.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: color.onSurface,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                my == null ? '-' : (myJadwal ?? '-'),
                                style: text.bodyMedium?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                my == null ? '-' : 'Status : $myStatus',
                                style: text.bodyMedium?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                              if (todayTanggal.isNotEmpty || statsTanggal.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Tanggal: ${todayTanggal.isNotEmpty ? todayTanggal : statsTanggal}',
                                    style: text.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: my == null
                              ? null
                              : () => Navigator.pushNamed(
                                    context,
                                    '/detail_antrian',
                                    arguments: my,
                                  ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 18,
                            color: my == null
                                ? color.onSurfaceVariant.withValues(alpha: 0.4)
                                : color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'Antrian Hari Ini',
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _StatCard(
                    title: 'Total antrian hari ini',
                    value: total.toString(),
                    icon: Icons.groups_rounded,
                  ),

                  // ✅ sekarang tampil no_antrian, bukan count
                  _StatCard(
                    title: 'Nomor antrian saat ini',
                    value: currentNo,
                    icon: Icons.confirmation_number_rounded,
                  ),

                  _StatCard(
                    title: 'Sisa antrian hari ini',
                    value: menunggu.toString(),
                    icon: Icons.hourglass_bottom_rounded,
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        backgroundColor: Theme.of(context).colorScheme.surface,
        showUnselectedLabels: true,
        onTap: (value) {
          Navigator.pushReplacementNamed(
            context,
            ['/home', '/antrian', '/akun'][value],
          );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'Antrian'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Akun'),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final text = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 22),
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: text.bodyMedium?.copyWith(color: color.onSurfaceVariant)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color.primary, size: 40),
              const SizedBox(width: 10),
              Text(
                value,
                style: text.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}
