import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CariPasienPage extends StatefulWidget {
  const CariPasienPage({super.key});

  @override
  State<CariPasienPage> createState() => _CariPasienState();
}

class _CariPasienState extends State<CariPasienPage> {
  final List<Map<String, String>> dataPasien = [
    {
      'nama': 'Ahmad Fauzi',
      'nik': '3201010101990001',
      'telepon': '+62 812-3456-7001',
    },
    {
      'nama': 'Siti Nurhaliza',
      'nik': '3201021503910002',
      'telepon': '+62 813-4567-7002',
    },
    {
      'nama': 'Budi Santoso',
      'nik': '3201032304980003',
      'telepon': '+62 814-5678-7003',
    },
    {
      'nama': 'Rina Maharani',
      'nik': '3201040502850004',
      'telepon': '+62 815-6789-7004',
    },
    {
      'nama': 'Teguh Prasetya',
      'nik': '3201051203720005',
      'telepon': '+62 816-7890-7005',
    },
    {
      'nama': 'Wulan Ayu',
      'nik': '3201063005990006',
      'telepon': '+62 817-8901-7006',
    },
    {
      'nama': 'Rizky Ramadhan',
      'nik': '3201070706760007',
      'telepon': '+62 818-9012-7007',
    },
  ];

  List<Map<String, String>> items = [];

  @override
  Widget build(BuildContext context) {
    items = dataPasien;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('Data Pasien'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Cari pasien...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide().copyWith(color: AppColors.textSecondary)
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  if (value.isEmpty) {
                    items = dataPasien;
                  } else {
                    items = dataPasien
                        .where(
                          (element) =>
                              element['nama']!.toLowerCase().contains(
                                value.toLowerCase(),
                              ) ||
                              element['nik']!.toLowerCase().contains(
                                value.toLowerCase(),
                              ),
                        )
                        .toList();
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) => _buildPasienItem(items[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasienItem(Map<String, String> items) {
    String iconPath = 'assets/icons/icon-pasien.png';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withValues(alpha: 0.15),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              iconPath,
              width: 28,
              height: 28,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  items['nama']!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  items['nik']!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  items['telepon']!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),

          GestureDetector(
            onTap: () {
              
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Icon(Icons.chevron_right_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
