import 'package:elabora_app/pages/notification_page.dart';
import 'package:flutter/material.dart';
import '../data/api_client.dart';
import '../data/auth_api.dart';
import '../data/exams_api.dart';
import '../data/devices_api.dart';
import '../utils/date_id.dart';
import '../utils/constants.dart';
import '../data/notification_store.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ApiClient _client;
  late final AuthApi _authApi;
  late final ExamsApi _examsApi;
  late final DevicesApi _devicesApi;

  late Future<Map<String, dynamic>> _futureMe;

  bool _deviceTokenRegistered = false;

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _authApi = AuthApi(_client);
    _examsApi = ExamsApi(_client);
    _devicesApi = DevicesApi(_client);

    _futureMe = _authApi.me();
    _registerDeviceIfLoggedIn();
  }

  Future<void> _registerDeviceIfLoggedIn() async {
    if (_deviceTokenRegistered) return;

    try {
      final token = await _client.tokenStorage.getToken();
      if (token == null || token.isEmpty) return;

      await _devicesApi.registerMyDeviceToken();
      _deviceTokenRegistered = true;
    } catch (_) {}
  }

  String _formatRole(String role) {
    final r = role.replaceAll('_', ' ').toLowerCase();
    if (r.isEmpty) return '-';
    return r[0].toUpperCase() + r.substring(1);
  }

  String _formatTanggal(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateId.formatFullWithTime(dt);
    } catch (_) {
      return iso.isEmpty ? '-' : iso;
    }
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

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureMe,
        builder: (context, snapshot) {
          String nama = 'Memuat...';
          String roleLabel = '';
          Map<String, dynamic>? profil;

          if (snapshot.connectionState == ConnectionState.waiting) {
            // keep default
          } else if (snapshot.hasError) {
            nama = 'Gagal memuat profil';
            roleLabel = snapshot.error.toString();
          } else if (snapshot.hasData) {
            final data = snapshot.data!;
            final akun = (data['akun'] as Map?)?.cast<String, dynamic>();
            profil = (data['profil'] as Map?)?.cast<String, dynamic>();

            nama = (profil?['nama'] ?? akun?['username'] ?? '-').toString();
            final role = (akun?['role'] ?? '-').toString();
            roleLabel = _formatRole(role);
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Row (Branding & Bell Notification only)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: t.titleLarge?.copyWith(
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
                        icon: _BellWithBadge(color: AppColors.primary),
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
                            style: t.bodyLarge?.copyWith(
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
                                    style: t.bodySmall?.copyWith(
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
                        style: t.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Semoga sehat selalu, silakan cek jadwal pemeriksaan Anda hari ini.',
                        style: t.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Card 1: Pendaftaran Baru
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textPrimary.withValues(alpha: 0.02),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pendaftaran Baru',
                                style: t.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Daftar tes laboratorium secara online dan pilih jadwal pemeriksaan Anda.',
                                style: t.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/pendaftaran');
                                },
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text(
                                  'Daftar Sekarang',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.secondary.withValues(alpha: 0.08),
                                AppColors.secondary.withValues(alpha: 0.18),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_note_rounded,
                            color: AppColors.secondary,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card 2: Punya Jadwal? (Antrian Card - Ticket Style Pass)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primary,
                          Color(0xFF745CFF),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          bottom: -20,
                          child: Icon(
                            Icons.biotech_outlined,
                            size: 110,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Punya Jadwal Hari Ini?',
                                    style: t.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Pantau status antrian pemeriksaan Anda secara real-time dari mana saja.',
                                    style: t.bodyMedium?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/antrian');
                                    },
                                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                                    label: const Text(
                                      'Cek Antrian',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.primary,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Ticket stub divider
                            Container(
                              height: 90,
                              width: 1.5,
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                  8,
                                  (_) => Container(
                                    width: 1.5,
                                    height: 5,
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ),
                                ),
                              ),
                            ),
                            // Stub Content
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.confirmation_number_outlined,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ANTRIAN',
                                  style: t.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Aktivitas Terakhir Section (at the bottom)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Aktivitas Terakhir',
                        style: t.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 18,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/cek_hasil'),
                        child: Text(
                          'Lihat semua',
                          style: t.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (profil == null || profil['id'] == null)
                    const _ActivityItem(
                      icon: Icons.info_outline_rounded,
                      title: 'Aktivitas belum tersedia',
                      date: '-',
                    )
                  else
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _examsApi.listByPatient(profil['id'] as int),
                      builder: (context, examsSnap) {
                        if (examsSnap.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (examsSnap.hasError) {
                          return _ActivityItem(
                            icon: Icons.error_outline_rounded,
                            title: 'Gagal memuat aktivitas',
                            date: examsSnap.error.toString(),
                          );
                        }

                        final rows = examsSnap.data ?? [];
                        final hasilTersedia = rows.where((e) {
                          final status = (e['status_hasil'] ?? '').toString().toUpperCase();
                          return status == 'HASIL_TERSEDIA';
                        }).toList();

                        hasilTersedia.sort((a, b) {
                          final da = DateTime.tryParse((a['tgl_pemeriksaan'] ?? '').toString());
                          final db = DateTime.tryParse((b['tgl_pemeriksaan'] ?? '').toString());
                          if (da == null && db == null) return 0;
                          if (da == null) return 1;
                          if (db == null) return -1;
                          return db.compareTo(da);
                        });

                        final latest = hasilTersedia.take(2).toList();
                        if (latest.isEmpty) {
                          return const _ActivityItem(
                            icon: Icons.inbox_rounded,
                            title: 'Belum ada hasil pemeriksaan tersedia',
                            date: '-',
                          );
                        }

                        return Column(
                          children: latest.map((e) {
                            final kategori = (e['kategori_nama'] ?? '-').toString();
                            final tglRaw = (e['tgl_pemeriksaan'] ?? '').toString();
                            final pemeriksaanId = e['pemeriksaan_id'];
                            
                            return _ActivityItem(
                              icon: Icons.biotech_rounded,
                              title: 'Hasil pemeriksaan tersedia ($kategori)',
                              date: _formatTanggal(tglRaw),
                              onTap: pemeriksaanId != null
                                  ? () {
                                      Navigator.pushNamed(
                                        context,
                                        '/exam_detail',
                                        arguments: {'id': pemeriksaanId},
                                      );
                                    }
                                  : null,
                            );
                          }).toList(),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        onDestinationSelected: (value) {
          if (value == 0) return;
          if (value == 1) {
            Navigator.pushReplacementNamed(context, '/cek_hasil');
          } else if (value == 2) {
            Navigator.pushReplacementNamed(context, '/riwayat');
          } else if (value == 3) {
            Navigator.pushReplacementNamed(context, '/akun');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.biotech_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.biotech_rounded, color: AppColors.primary),
            label: 'Hasil',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.history_rounded, color: AppColors.primary),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
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

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String date;
  final VoidCallback? onTap;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.date,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              date,
                              style: t.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
