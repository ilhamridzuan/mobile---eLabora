import 'package:flutter/material.dart';
import 'package:elabora_app/utils/constants.dart';

import '../data/api_client.dart';
import '../data/auth_api.dart';
import '../data/token_storage.dart';

class AkunDokterPage extends StatefulWidget {
  const AkunDokterPage({super.key});

  @override
  State<AkunDokterPage> createState() => _AkunDokterPageState();
}

class _AkunDokterPageState extends State<AkunDokterPage> {
  late final ApiClient _client;
  late final TokenStorage _tokenStorage;
  late final AuthApi _authApi;

  late Future<Map<String, dynamic>> _futureMe;

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _tokenStorage = TokenStorage();
    _authApi = AuthApi(_client);

    _futureMe = _authApi.me();
  }

  String _formatRole(String role) {
    final r = role.replaceAll('_', ' ').toLowerCase();
    if (r.isEmpty) return '-';
    return r[0].toUpperCase() + r.substring(1);
  }

  Future<void> _logout() async {
    await _tokenStorage.clear();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Akun Dokter'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: color.surface,
        foregroundColor: color.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureMe,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: () => setState(() => _futureMe = _authApi.me()),
            );
          }

          final me = snapshot.data ?? {};
          final user = (me['user'] as Map?)?.cast<String, dynamic>() ?? {};
          final profil = (me['profil'] as Map?)?.cast<String, dynamic>() ?? {};

          // Ambil nama dari profil dulu, fallback ke user
          final nama =
              (profil['nama'] ?? user['nama'] ?? user['username'] ?? '-')
                  .toString();

          // Role dari user
          final role = (user['role'] ?? 'DOKTER').toString();
          final roleLabel = _formatRole(role);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textSecondary.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: color.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.local_hospital_rounded,
                        color: color.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nama,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: color.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            roleLabel,
                            style: textTheme.bodyMedium?.copyWith(
                              color: color.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textSecondary.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.logout_rounded, color: color.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Keluar',
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: color.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Logout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),

      // ===== Bottom navbar khusus dokter =====
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (value) {
          // Sesuaikan route ini dengan route dokter Anda.
          // Saya asumsikan:
          // 0: doctor home
          // 1: cari pasien
          // 2: akun dokter
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
            label: 'Cari Pasien',
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}
