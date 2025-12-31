import 'package:elabora_app/pages/notification_page.dart';
import 'package:flutter/material.dart';
import '../data/api_client.dart';
import '../data/auth_api.dart';
import '../data/exams_api.dart';
import '../data/devices_api.dart';
import '../utils/date_id.dart';
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

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: FutureBuilder(
        future: _futureMe,
        builder: (context, snapshot) {
          String nama = 'Memuat...';
          String roleLabel = '';
          Map<String, dynamic>? profil;

          if (snapshot.connectionState == ConnectionState.waiting) {
            // ...
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      children: [
                        TextSpan(text: 'e', style: TextStyle(color: cs.secondary)),
                        TextSpan(text: 'Labora', style: TextStyle(color: cs.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header profil + bell
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: cs.primary.withValues(alpha: .08),
                            child: Icon(Icons.person_outline_rounded, size: 36, color: cs.primary),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nama,
                                style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(roleLabel, style: t.bodyMedium),
                            ],
                          ),
                        ],
                      ),

                      // ✅ Bell + badge unread
                      IconButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationsPage()),
                          );
                          // setelah balik dari halaman notifikasi, refresh badge
                          if (mounted) setState(() {});
                        },
                        icon: _BellWithBadge(color: cs.primary),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  Text('Layanan', style: t.titleLarge),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _serviceTile(context, 'assets/icons/icon-pendaftaran.png', 'Pendaftaran', '/pendaftaran'),
                      _serviceTile(context, 'assets/icons/icon-hasil.png', 'Hasil\nPemeriksaan', '/cek_hasil'),
                      _serviceTile(context, 'assets/icons/icon-riwayat.png', 'Riwayat\nPemeriksaan', '/riwayat'),
                    ],
                  ),

                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Aktivitas Terakhir', style: t.titleLarge),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/cek_hasil'),
                        child: Text('Lihat semua', style: t.bodyMedium?.copyWith(color: cs.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (profil == null || profil!['id'] == null)
                    const _ActivityItem(
                      icon: Icons.info_outline_rounded,
                      title: 'Aktivitas belum tersedia',
                      date: '-',
                    )
                  else
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _examsApi.listByPatient(profil!['id'] as int),
                      builder: (context, examsSnap) {
                        if (examsSnap.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
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

                        final latest = hasilTersedia.take(4).toList();
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
                            return _ActivityItem(
                              icon: Icons.biotech_rounded,
                              title: 'Hasil pemeriksaan tersedia ($kategori)',
                              date: _formatTanggal(tglRaw),
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

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurface.withValues(alpha: .6),
        onTap: (value) {
          Navigator.pushReplacementNamed(context, ['/home', '/antrian', '/akun'][value]);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'Antrian'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Akun'),
        ],
      ),
    );
  }

  Widget _serviceTile(BuildContext context, String iconPath, String label, String routeName) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, routeName),
        child: SizedBox(
          height: 116,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: cs.secondary.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(iconPath, width: 28, height: 28, fit: BoxFit.contain),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: t.bodyMedium?.copyWith(color: cs.onSurface),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ widget bell + badge
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
  const _ActivityItem({required this.icon, required this.title, required this.date});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: cs.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(date, style: t.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
