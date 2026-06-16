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
    final rows = await _examsApi.listAll(); // GET /exams/all

    // hanya HASIL_TERSEDIA
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
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: const Text('Semua Pemeriksaan'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureRows,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Bar & Filter Section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchC,
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Cari pemeriksaan (nama/NIK/kategori)...',
                        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                                onPressed: () => _searchC.clear(),
                              ),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Chips kategori
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
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
                              selectedColor: AppColors.primary,
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              showCheckmark: false,
                              side: BorderSide(
                                color: isSelected ? AppColors.primary : Colors.grey.shade300,
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                              elevation: 0,
                              pressElevation: 0,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Cards List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'Tidak ada pemeriksaan yang cocok.',
                          style: text.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _refresh,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.05),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.015),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon circle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    iconPath,
                    width: 24,
                    height: 24,
                    color: AppColors.primary,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.medical_services_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Data details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pemeriksaan $jenis',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, color: AppColors.textSecondary, size: 12),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              tanggal,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.qr_code_2_rounded, color: AppColors.textSecondary, size: 12),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              kode,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (pasienNama.isNotEmpty || nik.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                [
                                  if (pasienNama.isNotEmpty) pasienNama,
                                  if (nik.isNotEmpty) '($nik)',
                                ].join(' '),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                if (showChevron) ...[
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return card;
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
