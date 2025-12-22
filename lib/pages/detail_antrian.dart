import 'package:flutter/material.dart';
import 'package:elabora_app/utils/constants.dart';

import '../data/api_client.dart';
import '../data/auth_api.dart';
import '../data/queue_api.dart';
import '../utils/date_id.dart';

class DetailAntrianPage extends StatefulWidget {
  const DetailAntrianPage({super.key});

  @override
  State<DetailAntrianPage> createState() => _DetailAntrianPageState();
}

class _DetailAntrianPageState extends State<DetailAntrianPage> {
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
    _future = Future.value({});
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

  String? _currentNoFromItems(List<Map<String, dynamic>> items) {
    Map<String, dynamic>? current;
    for (final e in items) {
      final st = (e['status'] ?? '').toString().toUpperCase();
      if (st == 'DILAYANI') {
        current = e;
        break;
      }
    }
    if (current != null) return _pad3(current['no_antrian']);

    final waiting = items
        .where((e) => (e['status'] ?? '').toString().toUpperCase() == 'MENUNGGU')
        .toList();
    if (waiting.isEmpty) return null;

    waiting.sort((a, b) => _toInt(a['no_antrian']).compareTo(_toInt(b['no_antrian'])));
    return _pad3(waiting.first['no_antrian']);
  }

  Future<Map<String, dynamic>> _loadFromApi(Map<String, dynamic>? argMy) async {
    final me = await _authApi.me();
    final profil = me['profil'] as Map<String, dynamic>?;
    final pasienId = (profil?['id'] as int?);

    final today = await _queueApi.today();
    final statsWrap = await _queueApi.stats();

    final items = (today['data'] is List)
        ? (today['data'] as List).whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];

    Map<String, dynamic>? my = argMy;
    if (my == null && pasienId != null) {
      try {
        my = items.firstWhere((e) => e['pasien_id'] == pasienId);
      } catch (_) {
        my = null;
      }
    }

    final currentNo = _currentNoFromItems(items);

    return {
      'me': me,
      'my': my,
      'today': today,
      'statsWrap': statsWrap,
      'currentNo': currentNo,
    };
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final argMy = (args is Map) ? Map<String, dynamic>.from(args as Map) : null;

    _future = _loadFromApi(argMy);

    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final text = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Nomor antrian'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: color.surface,
        foregroundColor: color.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pushReplacementNamed(context, '/antrian'),
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
              onRetry: () => setState(() {}),
            );
          }

          final root = snap.data ?? {};
          final me = (root['me'] as Map<String, dynamic>? ?? {});
          final my = root['my'] as Map<String, dynamic>?;
          final statsWrap = (root['statsWrap'] as Map<String, dynamic>? ?? {});
          final stats = (statsWrap['stats'] as Map<String, dynamic>? ?? {});
          final tanggal = (statsWrap['tanggal'] ?? '').toString();

          final sisa = _toInt(stats['menunggu']);
          final currentNo = (root['currentNo'] ?? '-').toString();

          final profil = me['profil'] as Map<String, dynamic>?;
          final akun = me['akun'] as Map<String, dynamic>?;

          final role = (akun?['role'] ?? '-').toString();
          final nama = (profil?['nama'] ?? '-').toString();

          final jadwal = my == null ? '-' : _fmtDateTime(my['jadwal_pemeriksaan_at']);
          final noAntrian = my == null ? '-' : _pad3(my['no_antrian']);
          final status = my == null ? '-' : (my['status'] ?? '-').toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: color.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Nomor antrian saat ini',
                        style: text.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentNo,
                        style: text.displayLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 64,
                        ),
                      ),
                      if (tanggal.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Tanggal: $tanggal',
                            style: text.bodySmall?.copyWith(color: Colors.white70),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: color.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textSecondary.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        role,
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nama,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        jadwal,
                        style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'Nomor Antrian',
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        noAntrian,
                        style: text.displayLarge?.copyWith(
                          color: color.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 56,
                        ),
                      ),

                      const SizedBox(height: 8),
                      Text(
                        'Status: $status',
                        style: text.bodyMedium?.copyWith(color: color.onSurfaceVariant),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.people_outline, color: color.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    sisa.toString().padLeft(2, '0'),
                                    style: text.titleMedium?.copyWith(
                                      color: color.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sisa antrian',
                                style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  'Silahkan datang ke ruangan laboratorium 15 menit sebelum giliran antrian anda.',
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        },
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
