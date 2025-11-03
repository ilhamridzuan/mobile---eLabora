import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  void _goLogin(BuildContext context, String role) {
    Navigator.pushNamed(context, '/login', arguments: role);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: t.displayLarge?.copyWith(
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
                  const SizedBox(height: 4),
                  Text(
                    'Unit Laboratorium RSUD KAJEN',
                    style: t.bodyMedium,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/gambar-landingpage.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'Lakukan pendaftaran pemeriksaan dan lihat hasil\n'
                    'pemeriksaan Laboratorium RSUD KAJEN\n'
                    'dalam satu aplikasi!',
                    style: t.bodyMedium,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'Selamat Datang!',
                    style: t.titleLarge?.copyWith(color: cs.primary),
                  ),

                  const SizedBox(height: 14),

                  // Tombol
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _goLogin(context, 'Pasien'),
                      child: const Text('Masuk sebagai Pasien'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _goLogin(context, 'Dokter'),
                      child: const Text('Masuk sebagai Dokter'),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text('Atau', style: t.bodyMedium),
                  const SizedBox(height: 12),

                  // OutlinedButton
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('Daftar Akun Baru'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
