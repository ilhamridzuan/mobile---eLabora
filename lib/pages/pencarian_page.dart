import 'package:flutter/material.dart';
import '../utils/constants.dart';

class PencarianPage extends StatefulWidget {
  const PencarianPage({super.key});

  @override
  State<PencarianPage> createState() => _PencarianState();
}

class _PencarianState extends State<PencarianPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pencarian'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Cari pasien...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide().copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textPrimary.withValues(alpha: .6),
         onTap: (value) {
          Navigator.pushReplacementNamed(
            context,
            ['/doctor_home', '/pencarian'][value],
          );
        },
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
      ),
    );
  }
}
