import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/date_id.dart';
import '../data/api_client.dart';
import '../data/auth_api.dart';
import '../data/exams_api.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
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
    return await _examsApi.listByPatient(pasienId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pemeriksaan'),
        automaticallyImplyLeading: false,
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

            // kategori chip: "Semua" + kategori unik dari API
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
                          child: Text('Belum ada riwayat pemeriksaan.'),
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
                              return _buildRiwayatItem(filtered[index]);
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        onDestinationSelected: (value) {
          if (value == 2) return;
          if (value == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (value == 1) {
            Navigator.pushReplacementNamed(context, '/cek_hasil');
          } else if (value == 3) {
            Navigator.pushReplacementNamed(context, '/akun');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.biotech_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.biotech_rounded, color: AppColors.primary),
            label: 'Hasil',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.history_rounded, color: AppColors.primary),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatItem(Map<String, dynamic> row) {
    // API fields:
    // kategori_nama, tgl_pemeriksaan, no_antrian, no_lab, status_hasil, status_antrian
    final jenis = (row['kategori_nama'] ?? '-').toString();
    final tglRaw = (row['tgl_pemeriksaan'] ?? '').toString();
    final noAntrian = row['no_antrian']?.toString() ?? '-';
    final noLab = row['no_lab']?.toString() ?? '-';

    final statusHasil = (row['status_hasil'] ?? '').toString();
    final statusAntrian = (row['status_antrian'] ?? '').toString();

    final tanggal = _formatTanggal(tglRaw);
    final kode = '$noAntrian - $noLab';

    final statusLabel = _mapStatusLabel(
      statusHasil: statusHasil,
      statusAntrian: statusAntrian,
    );
    final statusColor = _mapStatusColor(statusLabel);

    final iconPath = _iconForCategory(jenis);

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
                    statusLabel,
                    style: const TextStyle(
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

  String _mapStatusLabel({
    required String statusHasil,
    required String statusAntrian,
  }) {
    // Prioritas: dibatalkan
    if (statusAntrian.toUpperCase() == 'DIBATALKAN') return 'dibatalkan';

    // hasil tersedia
    if (statusHasil.toUpperCase() == 'HASIL_TERSEDIA') return 'hasil tersedia';

    // default
    return 'menunggu hasil';
  }

  Color _mapStatusColor(String label) {
    switch (label) {
      case 'hasil tersedia':
        return Colors.green.shade400;
      case 'dibatalkan':
        return Theme.of(context).colorScheme.error;
      case 'menunggu hasil':
      default:
        return AppColors.textSecondary;
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
