import 'package:elabora_app/utils/constants.dart';
import 'package:flutter/material.dart';

class AntrianPage extends StatefulWidget {
  const AntrianPage({super.key});

  @override
  State<AntrianPage> createState() => _AntrianPageState();
}

class _AntrianPageState extends State<AntrianPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final text = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Antrian'),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nomor antrian saya',
              style: text.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: color.onSurface,
              ),
            ),
            const SizedBox(height: 10),

            Container(
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
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.access_time_rounded,
                      color: color.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nomor Antrian : 015',
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: color.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Kamis, 30 Oktober 2025 Pukul 12.30',
                          style: text.bodyMedium?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'Waktu Tunggu : 35 Menit',
                          style: text.bodyMedium?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.pushNamed(context, '/detail_antrian');
                    },
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Antrian Hari Ini',
              style: text.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: color.onSurface,
              ),
            ),
            const SizedBox(height: 10),

            // Kapasitas Antrian Hari Ini
            Container(
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
                    'Kapasitas antrian hari ini',
                    style: text.bodyMedium?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.groups_rounded,
                        color: color.primary,
                        size: 40,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '20',
                        style: text.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: color.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Nomor Antrian Saat Ini
            Container(
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
                    'Nomor antrian saat ini',
                    style: text.bodyMedium?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '013',
                        style: text.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: color.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ],
              ),
            ),

            // Jumlah Pasien yang Sudah Mendaftar
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Jumlah pasien yang sudah mendaftar',
                    style: text.bodyMedium?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.groups_rounded,
                        color: color.primary,
                        size: 40,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '15',
                        style: text.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: color.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Button Navigasi Bawah
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
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
