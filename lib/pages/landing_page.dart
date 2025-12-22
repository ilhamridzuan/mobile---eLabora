import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text(
                'eLabora',
                style: t.headlineSmall?.copyWith(color: cs.primary),
              ),
              const SizedBox(height: 6),
              Text('Unit Laboratorium RSUD KAJEN', style: t.bodyMedium),
              const SizedBox(height: 18),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/gambar-landingpage.png',
                      height: 220,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Lakukan pendaftaran pemeriksaan dan lihat hasil pemeriksaan\nLaboratorium RSUD KAJEN dalam satu aplikasi!',
                      style: t.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              Text(
                'Selamat Datang!',
                style: t.titleLarge?.copyWith(color: cs.primary),
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    debugPrint('Landing: Masuk sebagai Pasien');
                    Navigator.pushNamed(context, '/login');
                  },
                  child: const Text('Masuk sebagai Pasien'),
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    debugPrint('Landing: Masuk sebagai Dokter');
                    Navigator.pushNamed(context, '/login');
                  },
                  child: const Text('Masuk sebagai Dokter'),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Atau',
                style: t.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: .7),
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    debugPrint('Landing: Daftar Akun Baru');
                    Navigator.pushNamed(context, '/register');
                  },
                  child: const Text('Daftar Akun Baru'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
