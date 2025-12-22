import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/date_id.dart';
import '../data/api_client.dart';
import '../data/exams_api.dart';
import 'hasil_detail_page.dart';

class SemuaPemeriksaanPage extends StatefulWidget {
  const SemuaPemeriksaanPage({super.key});

  @override
  State<SemuaPemeriksaanPage> createState() => _SemuaPemeriksaanPageState();
}

class _SemuaPemeriksaanPageState extends State<SemuaPemeriksaanPage> {
  String selectedCategory = 'Semua';

  late final ApiClient _client;
  late final ExamsApi _examsApi;

  late Future<List<Map<String, dynamic>>> _futureRows;

  final TextEditingController _searchC = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _examsApi = ExamsApi(_client);
    _futureRows = _load();

    _searchC.addListener(() {
      setState(() => _query = _searchC.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await _examsApi.listAll(); // ✅ GET /exams/all

    // ✅ Filter sama seperti cek_hasil_page.dart: hanya HASIL_TERSEDIA
    return rows.where((e) {
      final status = (e['status_hasil'] ?? '').toString().toUpperCase();
      return status == 'HASIL_TERSEDIA';
    }).toList();
  }

  bool _matchSearch(Map<String, dynamic> e) {
    if (_query.isEmpty) return true;

    final haystack = <String>[
      (e['kategori_nama'] ?? '').toString(),
      (e['tgl_pemeriksaan'] ?? '').toString(),
      (e['pasien_nama'] ?? '').toString(),
      (e['nik'] ?? '').toString(),
      (e['no_antrian'] ?? '').toString(),
      (e['no_lab'] ?? '').toString(),
      (e['catatan'] ?? '').toString(),
      (e['status_validasi'] ?? '').toString(),
      (e['status_hasil'] ?? '').toString(),
      (e['pemeriksaan_id'] ?? '').toString(),
    ].join(' ').toLowerCase();

    return haystack.contains(_query);
  }

  Future<void> _refresh() async {
    setState(() {
      _futureRows = _load();
    });
    await _futureRows;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('Semua Pemeriksaan'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _futureRows,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(
                message: snapshot.error.toString(),
                onRetry: () {
                  setState(() {
                    _futureRows = _load();
                  });
                },
              );
            }

            final rows = snapshot.data ?? [];

            // kategori chip: "Semua" + kategori unik dari API (yang sudah HASIL_TERSEDIA)
            final categories = <String>{
              'Semua',
              ...rows
                  .map((e) => (e['kategori_nama'] ?? '').toString())
                  .where((s) => s.isNotEmpty),
            }.toList();

            // filter data sesuai chip kategori
            final byCategory = selectedCategory == 'Semua'
                ? rows
                : rows
                    .where((e) =>
                        (e['kategori_nama'] ?? '').toString() ==
                        selectedCategory)
                    .toList();

            // filter data sesuai search bar
            final filtered = byCategory.where(_matchSearch).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Search Bar
                TextField(
                  controller: _searchC,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Cari pemeriksaan (nama/NIK/kategori/no lab)...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => _searchC.clear(),
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ✅ Chips kategori (tetap seperti cek_hasil_page.dart)
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
                          onSelected: (_) =>
                              setState(() => selectedCategory = cat),
                          selectedColor: Theme.of(context).primaryColor,
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          labelStyle: TextStyle(
                            color:
                                isSelected ? Colors.white : AppColors.textSecondary,
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

                const SizedBox(height: 16),

                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text('Tidak ada pemeriksaan yang cocok.'),
                        )
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          child: ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              return _buildClickableItem(filtered[index]);
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildClickableItem(Map<String, dynamic> row) {
    // endpoint /exams/all mengembalikan pemeriksaan_id
    final pemeriksaanId = row['pemeriksaan_id'];
    if (pemeriksaanId == null) {
      return _buildCard(row, showChevron: false, onTap: null);
    }

    final id = (pemeriksaanId is int)
        ? pemeriksaanId
        : int.tryParse(pemeriksaanId.toString()) ?? 0;

    return _buildCard(
      row,
      showChevron: true,
      onTap: id == 0
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HasilDetailPage(id: id),
                ),
              );
            },
    );
  }

  Widget _buildCard(
    Map<String, dynamic> row, {
    required bool showChevron,
    required VoidCallback? onTap,
  }) {
    final jenis = (row['kategori_nama'] ?? '-').toString();
    final tglRaw = (row['tgl_pemeriksaan'] ?? '').toString();

    // jika /exams/all tidak mengirim no_antrian/no_lab pada beberapa query,
    // fallback tetap aman
    final noAntrian = row['no_antrian']?.toString() ?? '-';
    final noLab = row['no_lab']?.toString() ?? '-';

    // (opsional) info pasien jika tersedia
    final pasienNama = (row['pasien_nama'] ?? '').toString();
    final nik = (row['nik'] ?? '').toString();

    final tanggal = _formatTanggal(tglRaw);
    final kode = '$noAntrian - $noLab';
    final iconPath = _iconForCategory(jenis);

    final card = Container(
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
              errorBuilder: (_, __, ___) => Icon(
                Icons.medical_services_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pemeriksaan $jenis',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(tanggal, style: Theme.of(context).textTheme.bodyMedium),

                // kode seperti cek_hasil_page.dart
                Text(kode, style: Theme.of(context).textTheme.bodyMedium),

                // tambahan info pasien (tidak mengubah fungsi lama, hanya info)
                if (pasienNama.isNotEmpty || nik.isNotEmpty)
                  Text(
                    [
                      if (pasienNama.isNotEmpty) pasienNama,
                      if (nik.isNotEmpty) 'NIK: $nik',
                    ].join(' • '),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
          ),

          if (showChevron) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 28,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return card;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: card,
    );
  }

  String _iconForCategory(String jenis) {
    switch (jenis) {
      case 'Patologi':
        return 'assets/icons/icon-patologi.png';
      case 'Anatomi':
        return 'assets/icons/icon-anatomi.png';
      case 'Mikrobiologi':
        return 'assets/icons/icon-mikrobiologi.png';
      default:
        return 'assets/icons/icon-patologi.png';
    }
  }

  String _formatTanggal(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateId.formatFullWithTime(dt);
    } catch (_) {
      return iso.isEmpty ? '-' : iso;
    }
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}
