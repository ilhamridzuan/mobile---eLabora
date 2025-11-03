import 'package:flutter/material.dart';
import 'package:elabora_app/utils/constants.dart';

class AkunPage extends StatelessWidget {
  const AkunPage({super.key});

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      body: SingleChildScrollView(
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
                          'Prabowo Subianto',
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: color.onSurface,
                          ),
                        ),
                        Text(
                          'Pasien',
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
                Icon(
                  Icons.notifications_none_rounded,
                  color: color.onSurfaceVariant,
                ),
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

            // Logout
            Center(
              child: Card(
                color: color.errorContainer.withValues(alpha: 0.15),
                elevation: 0.8,
                shadowColor: AppColors.textSecondary.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 100,
                  ),
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
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: color.primary,
        unselectedItemColor: color.onSurface.withValues(alpha: 0.6),
        backgroundColor: color.surface,
        showUnselectedLabels: true,
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
}
