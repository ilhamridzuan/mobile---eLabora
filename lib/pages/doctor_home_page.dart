import 'package:flutter/material.dart';
import 'package:elabora_app/utils/constants.dart';
import 'package:elabora_app/pages/notification_page.dart';

import '../data/api_client.dart';
import '../data/auth_api.dart';
import '../data/queue_api.dart';
import '../data/notification_store.dart';

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

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) {
      return 'Selamat pagi';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat siang';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat sore';
    } else {
      return 'Selamat malam';
    }
  }

  String _formatRole(String role) {
    final r = role.replaceAll('_', ' ').toLowerCase();
    if (r.isEmpty) return '-';
    return r[0].toUpperCase() + r.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
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
            final role = (akun?['role'] ?? 'DOKTER').toString();
            final roleLabel = _formatRole(role);

            final statsWrap = (root['statsWrap'] as Map<String, dynamic>? ?? {});
            final stats = (statsWrap['stats'] as Map<String, dynamic>? ?? {});
            final total = _toInt(stats['total']);
            final menunggu = _toInt(stats['menunggu']);

            final todayWrap = (root['todayWrap'] as Map<String, dynamic>? ?? {});
            final todayItems = (todayWrap['data'] is List)
                ? (todayWrap['data'] as List).whereType<Map<String, dynamic>>().toList()
                : <Map<String, dynamic>>[];

            final currentNo = _currentNoFromToday(todayItems);

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                setState(() => _future = _load());
                await _future;
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Row (Branding & Bell Notification)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: text.titleLarge?.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            children: const [
                              TextSpan(text: 'e', style: TextStyle(color: AppColors.secondary)),
                              TextSpan(text: 'Labora', style: TextStyle(color: AppColors.primary)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NotificationsPage()),
                            );
                            if (mounted) setState(() {});
                          },
                          icon: const _BellWithBadge(color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Greeting Header (Sleek, simple M3 layout without avatar card, text-only)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${_getTimeGreeting()},',
                              style: text.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            if (roleLabel.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.verified_user_outlined,
                                      color: AppColors.primary,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      roleLabel,
                                      style: text.bodySmall?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nama,
                          style: text.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Menu Layanan Row
                    Row(
                      children: const [
                        Expanded(
                          child: _ServiceTile(
                            icon: Icons.biotech_rounded,
                            label: 'Hasil\nPemeriksaan',
                            routeName: '/semua_pemeriksaan',
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _ServiceTile(
                            icon: Icons.people_outline_rounded,
                            label: 'Pasien',
                            routeName: '/data_pasien',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Data Lab hari ini header
                    Text(
                      'Data Laboratorium Hari Ini',
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Hero Card: Nomor Antrian Saat Ini
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textPrimary.withValues(alpha: 0.015),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.campaign_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Nomor Antrian Saat Ini',
                                style: text.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            currentNo,
                            style: text.displayLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              fontSize: 56,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentNo == '-' ? 'Belum ada antrian yang dipanggil' : 'Silakan panggil nomor berikutnya',
                            style: text.bodySmall?.copyWith(
                              color: currentNo == '-' ? AppColors.textSecondary : Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Row of Two Statistics Cards
                    Row(
                      children: [
                        // Card Kapasitas Antrian
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.05),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.textPrimary.withValues(alpha: 0.015),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.people_alt_outlined,
                                    color: Colors.blue,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Kapasitas Antrian',
                                  style: text.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  total.toString(),
                                  style: text.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    fontSize: 22,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Card Sisa Antrian
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.05),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.textPrimary.withValues(alpha: 0.015),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.hourglass_empty_rounded,
                                    color: Colors.orange,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Sisa Antrian',
                                  style: text.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  menunggu.toString(),
                                  style: text.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    fontSize: 22,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),

      // bottom nav: M3 NavigationBar
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0, // Beranda
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        onDestinationSelected: (value) {
          if (value == 0) return;
          Navigator.pushReplacementNamed(
            context,
            ['/doctor_home', '/pencarian', '/akun_dokter'][value],
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.search_rounded, color: AppColors.primary),
            label: 'Pencarian',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
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
    final text = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.05),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.015),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, routeName),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BellWithBadge extends StatelessWidget {
  final Color color;
  const _BellWithBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: NotificationStore.unreadCount(),
      builder: (context, snap) {
        final unread = snap.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.notifications_none_rounded, color: color),
            if (unread > 0)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    unread > 99 ? '99+' : unread.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
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
