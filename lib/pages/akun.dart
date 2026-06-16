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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Centered Profile Header (Google M3 Style)
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        nama,
                        textAlign: TextAlign.center,
                        style: text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              color: AppColors.primary,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              roleLabel,
                              style: text.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Account Settings Group
                Text(
                  'Pengaturan Akun',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.06),
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
                      _buildSettingsItem(
                        context,
                        icon: Icons.person_outline_rounded,
                        label: 'Profile',
                        iconColor: AppColors.primary,
                        onTap: () {
                          // Aksi ke menu Profile
                        },
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.primary.withValues(alpha: 0.06),
                        indent: 56,
                      ),
                      _buildSettingsItem(
                        context,
                        icon: Icons.lock_outline_rounded,
                        label: 'Password',
                        iconColor: AppColors.secondary,
                        onTap: () {
                          // Aksi ke menu Password
                        },
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.primary.withValues(alpha: 0.06),
                        indent: 56,
                      ),
                      _buildSettingsItem(
                        context,
                        icon: Icons.notifications_none_rounded,
                        label: 'Notifications',
                        iconColor: Colors.orange,
                        onTap: () {
                          // Aksi ke menu Notifications
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // More Settings Group
                Text(
                  'Lainnya',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.06),
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
                      _buildSettingsItem(
                        context,
                        icon: Icons.star_outline_rounded,
                        label: 'Rate & Review',
                        iconColor: Colors.amber.shade700,
                        onTap: () {
                          // Aksi ke menu Rate
                        },
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.primary.withValues(alpha: 0.06),
                        indent: 56,
                      ),
                      _buildSettingsItem(
                        context,
                        icon: Icons.help_outline_rounded,
                        label: 'Help',
                        iconColor: Colors.purple,
                        onTap: () {
                          // Aksi ke menu Help
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Logout Pill Button
                Center(
                  child: TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                    label: const Text(
                      'Log out',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.08),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
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

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final t = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: t.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
