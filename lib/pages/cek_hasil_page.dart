import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/date_id.dart';
import '../data/api_client.dart';
import '../data/auth_api.dart';
import '../data/exams_api.dart';

class CekHasilPage extends StatefulWidget {
  const CekHasilPage({super.key});

  @override
  State<CekHasilPage> createState() => _CekHasilPageState();
}

class _CekHasilPageState extends State<CekHasilPage> {
  String selectedCategory = 'Semua';

  late final ApiClient _client;
  late final AuthApi _authApi;
  late final ExamsApi _examsApi;

  late Future<List<Map<String, dynamic>>> _futureRows;

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _authApi = AuthApi(_client);
    _examsApi = ExamsApi(_client);
    _futureRows = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final me = await _authApi.me();
    final profil = me['profil'] as Map<String, dynamic>?;
    if (profil == null || profil['id'] == null) {
      throw Exception('Profil pasien tidak ditemukan dari /auth/me');
    }

    final pasienId = profil['id'] as int;
    final rows = await _examsApi.listByPatient(pasienId);

    // ✅ Filter: hanya hasil tersedia
    return rows.where((e) {
      final status = (e['status_hasil'] ?? '').toString().toUpperCase();
      return status == 'HASIL_TERSEDIA';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('Hasil Pemeriksaan'),
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

            // kategori chip: "Semua" + kategori unik dari API (yang sudah hasil tersedia)
            final categories = <String>{
              'Semua',
              ...rows
                  .map((e) => (e['kategori_nama'] ?? '').toString())
                  .where((s) => s.isNotEmpty),
            }.toList();

            // filter data sesuai chip
            final filtered = selectedCategory == 'Semua'
                ? rows
                : rows
                      .where(
                        (e) =>
                            (e['kategori_nama'] ?? '').toString() ==
                            selectedCategory,
                      )
                      .toList();

            return Column(
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
                          onSelected: (_) =>
                              setState(() => selectedCategory = cat),
                          selectedColor: Theme.of(context).primaryColor,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.15,
                            ),
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
                          child: Text('Belum ada hasil pemeriksaan tersedia.'),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            setState(() {
                              _futureRows = _load();
                            });
                            await _futureRows;
                          },
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
    // list endpoint mengembalikan pemeriksaan_id
    final pemeriksaanId = row['pemeriksaan_id'];
    if (pemeriksaanId == null) {
      // fallback kalau data tidak sesuai
      return _buildCard(row, showChevron: false, onTap: null);
    }

    return _buildCard(
      row,
      showChevron: true,
      onTap: () {
        // ✅ Pindah ke detail (pastikan route ini ada)
        Navigator.pushNamed(
          context,
          '/exam_detail',
          arguments: {'id': pemeriksaanId},
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
    final noAntrian = row['no_antrian']?.toString() ?? '-';
    final noLab = row['no_lab']?.toString() ?? '-';

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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(tanggal, style: Theme.of(context).textTheme.bodyMedium),
                Text(kode, style: Theme.of(context).textTheme.bodyMedium),
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
