import 'package:flutter/material.dart';
import 'package:elabora_app/utils/constants.dart'; // untuk AppColors

class DoctorHomePage extends StatelessWidget {
  const DoctorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand
              RichText(
                text: TextSpan(
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  children: [
                    TextSpan(
                      text: 'e',
                      style: TextStyle(color: color.secondary),
                    ),
                    TextSpan(
                      text: 'Labora',
                      style: TextStyle(color: color.primary),
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
                        radius: 26,
                        backgroundColor: color.primary.withValues(alpha: .08),
                        child: Icon(
                          Icons.person_outline_rounded,
                          size: 34,
                          color: color.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jon',
                            style: text.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text('Dokter', style: text.bodyMedium),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.notifications_none_rounded,
                      color: color.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Layanan
              Text('Layanan', style: text.titleLarge),
              const SizedBox(height: 12),

              Row(
                children: const [
                  _ServiceTile(
                    icon: Icons.biotech_rounded,
                    label: 'Hasil\nPemeriksaan',
                  ),
                  _ServiceTile(icon: Icons.view_list_rounded, label: 'Pasien'),
                ],
              ),

              const SizedBox(height: 24),

              // Data Laboratorium
              Text('Data Laboratorium Hari ini', style: text.titleLarge),
              const SizedBox(height: 12),

              // Kapasitas antrian hari ini
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
                padding: const EdgeInsets.symmetric(
                  vertical: 30,
                  horizontal: 22,
                ),
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
                padding: const EdgeInsets.symmetric(
                  vertical: 30,
                  horizontal: 22,
                ),
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
                          13.toString().padLeft(3, '0'),
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
                padding: const EdgeInsets.symmetric(
                  vertical: 30,
                  horizontal: 22,
                ),
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
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedItemColor: color.primary,
        unselectedItemColor: color.onSurface.withValues(alpha: .6),
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
        onTap: (index) {
          // nanti bisa diisi navigasi di sini
        },
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ServiceTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Expanded(
      child: GestureDetector(
        onTap: () {},
        child: Container(
          height: 112,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: color.secondary.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: color.primary),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: color.onSurface,
                  fontSize: (text.bodyMedium?.fontSize ?? 14) - 1,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
