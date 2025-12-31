import 'package:flutter/material.dart';
import 'package:elabora_app/utils/constants.dart';

import '../data/api_client.dart';
import '../data/auth_api.dart';
import '../data/queue_api.dart';

class DoctorHomePage extends StatefulWidget {
  const DoctorHomePage({super.key});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  late final ApiClient _client;
  late final AuthApi _authApi;
  late final QueueApi _queueApi;

  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _authApi = AuthApi(_client);
    _queueApi = QueueApi(_client);
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final me = await _authApi.me();
    final statsWrap = await _queueApi.stats(); // {tanggal, stats}
    final todayWrap = await _queueApi.today(); // {tanggal, data}

    return {
      'me': me,
      'statsWrap': statsWrap,
      'todayWrap': todayWrap,
    };
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  String _pad3(dynamic v) => _toInt(v).toString().padLeft(3, '0');

  /// Nomor antrian saat ini:
  /// - Prioritas 1: item status == DILAYANI
  /// - Fallback: MENUNGGU dengan no_antrian paling kecil
  /// - Kalau kosong: "-"
  String _currentNoFromToday(List<Map<String, dynamic>> items) {
    for (final e in items) {
      final st = (e['status'] ?? '').toString().toUpperCase();
      if (st == 'DILAYANI') {
        return _pad3(e['no_antrian']);
      }
    }

    final waiting = items
        .where((e) => (e['status'] ?? '').toString().toUpperCase() == 'MENUNGGU')
        .toList();

    if (waiting.isEmpty) return '-';

    waiting.sort((a, b) => _toInt(a['no_antrian']).compareTo(_toInt(b['no_antrian'])));
    return _pad3(waiting.first['no_antrian']);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
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

            final me = (root['me'] as Map<String, dynamic>? ?? {});
            final akun = me['akun'] as Map<String, dynamic>?;
            final profil = me['profil'] as Map<String, dynamic>?;

            final nama =
                (profil?['nama'] ?? akun?['username'] ?? '-').toString();
            final role = (akun?['role'] ?? '-').toString();

            final statsWrap = (root['statsWrap'] as Map<String, dynamic>? ?? {});
            final stats = (statsWrap['stats'] as Map<String, dynamic>? ?? {});
            final total = _toInt(stats['total']);

            final todayWrap = (root['todayWrap'] as Map<String, dynamic>? ?? {});
            final todayItems = (todayWrap['data'] is List)
                ? (todayWrap['data'] as List).whereType<Map<String, dynamic>>().toList()
                : <Map<String, dynamic>>[];

            final currentNo = _currentNoFromToday(todayItems);

            return RefreshIndicator(
              onRefresh: () async {
                setState(() => _future = _load());
                await _future;
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header (nama & role dari /auth/me)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: color.primary.withValues(alpha: 0.15),
                              child: Icon(
                                Icons.person_rounded,
                                color: color.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nama,
                                  style: text.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(role, style: text.bodyMedium),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // menu layanan 
                    SizedBox(
                      height: 110,
                      child: Row(
                        children: const [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: _ServiceTile(
                                icon: Icons.biotech_rounded,
                                label: 'Hasil\nPemeriksaan',
                                routeName: '/semua_pemeriksaan',
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: _ServiceTile(
                                icon: Icons.view_list_rounded,
                                label: 'Pasien',
                                routeName: '/data_pasien',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Data Lab hari ini
                    Text('Data Laboratorium Hari ini', style: text.titleLarge),
                    const SizedBox(height: 12),

                    // Kapasitas/Total antrian hari ini (stats.total)
                    _StatCard(
                      title: 'Kapasitas antrian hari ini',
                      value: total.toString(),
                      icon: Icons.groups_rounded,
                    ),

                    // Nomor antrian saat ini (dari item DILAYANI)
                    _StatCard(
                      title: 'Nomor antrian saat ini',
                      value: currentNo,
                      icon: Icons.confirmation_number_rounded,
                    ),

                    // jumlah pasien yang sudah mendaftar (stats.total)
                    _StatCard(
                      title: 'Jumlah pasien yang sudah mendaftar',
                      value: total.toString(),
                      icon: Icons.groups_rounded,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),

      // bottom nav: tambah menu akun
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Beranda
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        backgroundColor: Theme.of(context).colorScheme.surface,
        showUnselectedLabels: true,
        onTap: (value) {
          Navigator.pushReplacementNamed(
            context,
            ['/doctor_home', '/pencarian', '/akun_dokter'][value],
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: 'Pencarian',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}

// card menu layanan
class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String routeName;

  const _ServiceTile({
    required this.icon,
    required this.label,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => Navigator.pushNamed(context, routeName),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minHeight: 110),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.textSecondary.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color.onSurface,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
          Text(
            title,
            style: text.bodyMedium?.copyWith(color: color.onSurfaceVariant),
          ),
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
