import 'package:flutter/material.dart';

class CekHasilPage extends StatefulWidget {
  const CekHasilPage({super.key});

  @override
  State<CekHasilPage> createState() => _CekHasilPageState();
}

class _CekHasilPageState extends State<CekHasilPage> {
  String selectedCategory = 'Semua';

  final List<Map<String, dynamic>> hasilList = [
    {
      'kategori': 'Patologi',
      'judul': 'Pemeriksaan Patologi',
      'tanggal': 'Kamis, 05 Juni 2025 Pukul 12.30',
      'kode': '252432123 - 0M7346123',
      'icon': Icons.science_outlined,
    },
    {
      'kategori': 'Anatomi',
      'judul': 'Pemeriksaan Anatomi',
      'tanggal': 'Kamis, 05 Juni 2025 Pukul 12.30',
      'kode': '252432123 - 0M7346123',
      'icon': Icons.psychology_outlined,
    },
    {
      'kategori': 'Mikrobiologi',
      'judul': 'Pemeriksaan Mikrobiologi',
      'tanggal': 'Kamis, 05 Juni 2025 Pukul 12.30',
      'kode': '252432123 - 0M7346123',
      'icon': Icons.biotech_outlined,
    },
    {
      'kategori': 'Patologi',
      'judul': 'Pemeriksaan Patologi',
      'tanggal': 'Kamis, 05 Juni 2025 Pukul 12.30',
      'kode': '252432123 - 0M7346123',
      'icon': Icons.science_outlined,
    },
  ];

  List<String> categories = ['Semua', 'Patologi', 'Anatomi', 'Mikrobiologi'];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Filter list
    List<Map<String, dynamic>> filteredList = selectedCategory == 'Semua'
        ? hasilList
        : hasilList.where((e) => e['kategori'] == selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Pemeriksaan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: categories.map((kategori) {
                final bool isSelected = kategori == selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(kategori),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => selectedCategory = kategori);
                    },
                    selectedColor: colors.primary,
                    backgroundColor: colors.surfaceVariant,
                    labelStyle: TextStyle(
                      color: isSelected ? colors.onPrimary : colors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // List Pemeriksaan
          Expanded(
            child: ListView.builder(
              itemCount: filteredList.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final item = filteredList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: colors.secondary.withOpacity(0.15),
                      child: Icon(item['icon'], color: colors.primary, size: 26),
                    ),
                    title: Text(
                      item['judul'],
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${item['tanggal']}\n${item['kode']}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: colors.outline),
                    onTap: () {
                      // nanti diarahkan ke halaman detail hasil
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
