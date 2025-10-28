import 'package:flutter/material.dart';
import '../utils/constants.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  String selectedCategory = 'Semua';

  final List<String> categories = [
    'Semua',
    'Patologi',
    'Anatomi',
    'Mikrobiologi',
  ];

  final List<Map<String, String>> dataRiwayat = [
    {
      'jenis': 'Patologi',
      'tanggal': 'Kamis, 05 Juni 2025 Pukul 12.30',
      'kode': '252342123 - OM7346123',
      'status': 'menunggu hasil',
    },
    {
      'jenis': 'Patologi',
      'tanggal': 'Kamis, 05 Juni 2025 Pukul 12.30',
      'kode': '252342123 - OM7346123',
      'status': 'hasil tersedia',
    },
    {
      'jenis': 'Patologi',
      'tanggal': 'Kamis, 05 Juni 2025 Pukul 12.30',
      'kode': '252342123 - OM7346123',
      'status': 'dibatalkan',
    },
    {
      'jenis': 'Anatomi',
      'tanggal': 'Kamis, 05 Juni 2025 Pukul 12.30',
      'kode': '252342123 - OM7346123',
      'status': 'hasil tersedia',
    },
    {
      'jenis': 'Mikrobiologi',
      'tanggal': 'Kamis, 05 Juni 2025 Pukul 12.30',
      'kode': '252342123 - OM7346123',
      'status': 'menunggu hasil',
    },
  ];
  @override
  Widget build(BuildContext context) {
    final filteredData = selectedCategory == 'Semua'
        ? dataRiwayat
        : dataRiwayat
              .where((item) => item['jenis'] == selectedCategory)
              .toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: (){
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded)
          ),
        title: const Text('Riwayat Pemeriksaan')
        ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final isSelected = cat == selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          selectedCategory = cat;
                        });
                      },
                      selectedColor: Theme.of(context).primaryColor,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: AppColors.textSecondary.withValues(alpha: 0.15)
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: filteredData.length,
                itemBuilder: (context, index) {
                  final item = filteredData[index];
                  return _buildRiwayatItem(item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayatItem(Map<String, dynamic> item) {
    String iconPath = '';
    switch (item['jenis']) {
      case 'Patologi':
        iconPath = 'assets/icons/icon-patologi.png';
        break;
      case 'Anatomi':
        iconPath = 'assets/icons/icon-anatomi.png';
        break;
      case 'Mikrobiologi':
        iconPath = 'assets/icons/icon-mikrobiologi.png';
        break;
    }

    Color statusColor;
    switch (item['status']) {
      case 'hasil tersedia':
        statusColor = Colors.green.shade400;
        break;
      case 'dibatalkan':
        statusColor = Theme.of(context).colorScheme.error;
        break;
      case 'menunggu hasil':
        statusColor = AppColors.textSecondary;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }

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
                  'Pemeriksaan ${item['jenis']}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  item['tanggal'],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  item['kode'],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item['status'],
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
