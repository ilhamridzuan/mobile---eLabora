import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// cek hasil page — halaman daftar hasil pemeriksaan
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
    },
    {
      'kategori': 'Anatomi',
      'judul': 'Pemeriksaan Anatomi',
      'tanggal': 'Kamis, 05 Juni 2025 Pukul 12.30',
      'kode': '252432123 - 0M7346123',
    },
    {
      'kategori': 'Mikrobiologi',
      'judul': 'Pemeriksaan Mikrobiologi',
      'tanggal': 'Kamis, 05 Juni 2025 Pukul 12.30',
      'kode': '252432123 - 0M7346123',
    },
    {
      'kategori': 'Patologi',
      'judul': 'Pemeriksaan Patologi',
      'tanggal': 'Kamis, 05 Juni 2025 Pukul 12.30',
      'kode': '252432123 - 0M7346123',
    },
  ];

  List<String> categories = ['Semua', 'Patologi', 'Anatomi', 'Mikrobiologi'];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
          // Filter kategori
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
                      color: AppColors.textSecondary.withValues(alpha: 0.15),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // List hasil pemeriksaan
          Expanded(
            child: ListView.builder(
              itemCount: filteredList.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final item = filteredList[index];
                String iconPath = '';
                switch (item['kategori']) {
                  case 'Patologi':
                    iconPath = 'assets/icons/icon-patologi.png';
                    break;
                  case 'Anatomi':
                    iconPath = 'assets/icons/icon-anatomi.png';
                    break;
                  case 'Mikrobiologi':
                    iconPath = 'assets/icons/icon-mikrobiologi.png';
                    break;
                  default:
                    iconPath = 'assets/icons/icon-patologi.png';
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        iconPath,
                        width: 28,
                        height: 28,
                        color: colors.primary,
                      ),
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
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DetailHasilPage(),
                        ),
                      );
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

/// detail hasil page — halaman detail hasil pemeriksaan
class DetailHasilPage extends StatelessWidget {
  const DetailHasilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Pemeriksaan'),
        centerTitle: true,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kategori : Patologi\n'
              'Dikeluarkan tanggal : 05 Juni 2025 Pukul 12.30\n'
              'No. Lab : 235321234 - OM1231234',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 24),

            Text(
              'Preview',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outlineVariant, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/images/hasil_lab_preview.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // tombol-tombol
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.visibility),
              label: const Text('Lihat hasil pemeriksaan'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LihatHasilPage()),
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.tertiaryContainer,
                foregroundColor: cs.onTertiaryContainer,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.download),
              label: const Text('Unduh file hasil pemeriksaan'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('File berhasil di unduh.'),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.error_outline),
              label: const Text('Laporkan Kesalahan'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Laporan kesalahan dikirim.')),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// lihat hasil page — halaman detail hasil pemeriksaan
class LihatHasilPage extends StatelessWidget {
  const LihatHasilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lihat Hasil'),
        centerTitle: true,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Image.asset(
          'assets/images/hasil_lab_full.jpg',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
