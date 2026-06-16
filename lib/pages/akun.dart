import 'package:flutter/material.dart';
import 'package:elabora_app/utils/constants.dart';

import '../data/api_client.dart';
import '../data/auth_api.dart';
import '../data/token_storage.dart';

class AkunPage extends StatefulWidget {
  const AkunPage({super.key});

  @override
  State<AkunPage> createState() => _AkunPageState();
}

class _AkunPageState extends State<AkunPage> {
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
    // role backend: "PASIEN", "DOKTER", "PETUGAS", "PETUGAS_LAB", dll
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
    final text = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Akun'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: color.surface,
        foregroundColor: color.onSurface,
        automaticallyImplyLeading: false,
      ),

      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureMe,
        builder: (context, snapshot) {
          // default values (sebelum data datang)
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

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Profile
                Container(
                  padding: const EdgeInsets.all(16),
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
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: color.primary.withValues(alpha: 0.08),
                        child: Icon(
                          Icons.person_outline_rounded,
                          size: 34,
                          color: color.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nama,
                              style: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: color.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              roleLabel,
                              style: text.bodyMedium?.copyWith(
                                color: color.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.notifications_none_rounded,
                        color: color.primary,
                        size: 26,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                Text(
                  'Account',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                // Profile
                Row(
                  children: [
                    Icon(Icons.person_outline, color: color.onSurfaceVariant),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Profile',
                        style: text.bodyLarge?.copyWith(
                          color: color.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: color.onSurfaceVariant,
                    ),
                  ],
                ),
                Divider(
                  color: color.outline.withValues(alpha: 0.4),
                  thickness: 0.4,
                ),

                // Password
                Row(
                  children: [
                    Icon(Icons.lock_outline, color: color.onSurfaceVariant),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Password',
                        style: text.bodyLarge?.copyWith(
                          color: color.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: color.onSurfaceVariant,
                    ),
                  ],
                ),
                Divider(
                  color: color.outline.withValues(alpha: 0.4),
                  thickness: 0.4,
                ),

                // Notifications
                Row(
                  children: [
                    Icon(Icons.notifications_none_rounded, color: color.onSurfaceVariant),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Notifications',
                        style: text.bodyLarge?.copyWith(
                          color: color.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: color.onSurfaceVariant,
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // More Section
                Text(
                  'More',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                // Rate & Review
                Row(
                  children: [
                    Icon(Icons.star_outline_rounded, color: color.onSurfaceVariant),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Rate & Review',
                        style: text.bodyLarge?.copyWith(
                          color: color.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: color.onSurfaceVariant,
                    ),
                  ],
                ),
                Divider(
                  color: color.outline.withValues(alpha: 0.4),
                  thickness: 0.4,
                ),

                // Help
                Row(
                  children: [
                    Icon(Icons.help_outline_rounded, color: color.onSurfaceVariant),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Help',
                        style: text.bodyLarge?.copyWith(
                          color: color.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: color.onSurfaceVariant,
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Logout (dibuat clickable)
                Center(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _logout,
                    child: Card(
                      color: color.errorContainer.withValues(alpha: 0.15),
                      elevation: 0.8,
                      shadowColor: AppColors.textSecondary.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 100),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.logout_rounded, color: color.error),
                            const SizedBox(width: 8),
                            Text(
                              'Log out',
                              style: text.bodyLarge?.copyWith(
                                color: color.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: NavigationBar(
        selectedIndex: 3,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        onDestinationSelected: (value) {
          if (value == 3) return;
          if (value == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (value == 1) {
            Navigator.pushReplacementNamed(context, '/cek_hasil');
          } else if (value == 2) {
            Navigator.pushReplacementNamed(context, '/riwayat');
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
