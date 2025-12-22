import 'package:flutter/material.dart';
import '../data/api_client.dart';
import '../data/auth_api.dart';
import '../data/token_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ApiClient _client;
  late final TokenStorage _tokenStorage;
  late final AuthApi _authApi;

  late Future<Map<String, dynamic>> _futureMe;

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _tokenStorage = TokenStorage();
    _authApi = AuthApi(_client, _tokenStorage);

    _futureMe = _authApi.me();
  }

  String _formatRole(String role) {
    // role backend: "PASIEN", "DOKTER", "PETUGAS", "PETUGAS_LAB", dll
    final r = role.replaceAll('_', ' ').toLowerCase();
    if (r.isEmpty) return '-';
    return r[0].toUpperCase() + r.substring(1);
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

          if (snapshot.connectionState == ConnectionState.waiting) {
            // biarkan default "Memuat..."
          } else if (snapshot.hasError) {
            nama = 'Gagal memuat profil';
            roleLabel = snapshot.error.toString();
          } else if (snapshot.hasData) {
            final data = snapshot.data!;
            final akun = (data['akun'] as Map?)?.cast<String, dynamic>();
            final profil = (data['profil'] as Map?)?.cast<String, dynamic>();

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
                  // Brand
                  RichText(
                    text: TextSpan(
                      style: t.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      children: [
                        TextSpan(
                          text: 'e',
                          style: TextStyle(color: cs.secondary),
                        ),
                        TextSpan(
                          text: 'Labora',
                          style: TextStyle(color: cs.primary),
                        ),
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
                            child: Icon(
                              Icons.person_outline_rounded,
                              size: 36,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nama,
                                style: t.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(roleLabel, style: t.bodyMedium),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.notifications_none_rounded,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Layanan
                  Text('Layanan', style: t.titleLarge),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _serviceTile(
                        context,
                        'assets/icons/icon-pendaftaran.png',
                        'Pendaftaran',
                        '/pendaftaran',
                      ),
                      _serviceTile(
                        context,
                        'assets/icons/icon-hasil.png',
                        'Hasil\nPemeriksaan',
                        '/cek_hasil',
                      ),
                      _serviceTile(
                        context,
                        'assets/icons/icon-riwayat.png',
                        'Riwayat\nPemeriksaan',
                        '/riwayat',
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Aktivitas Terakhir
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Aktivitas Terakhir', style: t.titleLarge),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Lihat semua',
                          style: t.bodyMedium?.copyWith(color: cs.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  const _ActivityItem(
                    icon: Icons.biotech_rounded,
                    title: 'Mendapatkan hasil pemeriksaan',
                    date: 'Kamis, 05 Juni 2025 Pukul 12.30',
                  ),
                  const _ActivityItem(
                    icon: Icons.confirmation_number_outlined,
                    title: 'Mendapatkan nomor antrian',
                    date: 'Kamis, 05 Juni 2025 Pukul 09.50',
                  ),
                  const _ActivityItem(
                    icon: Icons.assignment_add,
                    title: 'Melakukan pendaftaran',
                    date: 'Kamis, 05 Juni 2025 Pukul 09.45',
                  ),
                  const _ActivityItem(
                    icon: Icons.biotech_rounded,
                    title: 'Mendapatkan hasil pemeriksaan',
                    date: 'Senin, 15 Januari 2025 Pukul 15.30',
                  ),
                ],
              ),
            ),
          );
        },
      ),

      // BottomNavigationBar (ikon Flutter)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurface.withValues(alpha: .6),
        onTap: (value) {
          Navigator.pushReplacementNamed(
            context,
            ['/home', '/antrian', '/akun'][value],
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_rounded),
            label: 'Antrian',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Akun',
          ),
        ],
      ),
    );
  }

  // --- fungsi untuk tile layanan ---
  Widget _serviceTile(
    BuildContext context,
    String iconPath,
    String label,
    String routeName,
  ) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, routeName);
        },
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
                Image.asset(
                  iconPath,
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
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

// --- aktivitas terakhir ---
class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String date;
  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.date,
  });

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
                Text(
                  title,
                  style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
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
