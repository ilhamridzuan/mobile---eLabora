import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/exams_api.dart';
import '../data/patients_api.dart';
import '../utils/constants.dart';
import '../utils/date_id.dart';
import 'cek_hasil_page.dart';
import 'hasil_detail_page.dart';

class PencarianPage extends StatefulWidget {
  const PencarianPage({super.key});

  @override
  State<PencarianPage> createState() => _PencarianPageState();
}

class _PencarianPageState extends State<PencarianPage> {
  late final ApiClient _client;
  late final ExamsApi _examsApi;
  late final PatientsApi _patientsApi;

  late Future<_SearchBundle> _future;

  final TextEditingController _searchC = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _examsApi = ExamsApi(_client);
    _patientsApi = PatientsApi(_client);

    _future = _loadAll();

    _searchC.addListener(() {
      setState(() => _query = _searchC.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<_SearchBundle> _loadAll() async {
    final results = await Future.wait([
      _patientsApi.listPatients(),
      _examsApi.listAll(),
    ]);

    return _SearchBundle(
      patients: results[0] as List<Map<String, dynamic>>,
      exams: results[1] as List<Map<String, dynamic>>,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _loadAll());
    await _future;
  }

  // ==== helpers ====

  String _pick(
    Map<String, dynamic> m,
    List<String> keys, {
    String fallback = '-',
  }) {
    for (final k in keys) {
      final v = m[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return fallback;
  }

  int _pickInt(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      if (v is int) return v;
      final parsed = int.tryParse(v.toString());
      if (parsed != null) return parsed;
    }
    return 0;
  }

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateId.formatFullWithTime(dt);
    } catch (_) {
      return iso.isEmpty ? '-' : iso;
    }
  }

  bool _matchPatient(Map<String, dynamic> p) {
    if (_query.isEmpty) return true;

    final haystack = <String>[
      _pick(p, ['nama', 'pasien_nama', 'name']),
      _pick(p, ['nik']),
      _pick(p, ['no_rm', 'no_rekam_medis']),
      _pick(p, ['email']),
      _pick(p, ['phone', 'no_hp', 'telp']),
      _pick(p, ['alamat']),
      _pick(p, ['id']),
    ].join(' ').toLowerCase();

    return haystack.contains(_query);
  }

  bool _matchExam(Map<String, dynamic> e) {
    if (_query.isEmpty) return true;

    final haystack = <String>[
      _pick(e, ['pasien_nama']),
      _pick(e, ['nik']),
      _pick(e, ['kategori_nama']),
      _pick(e, ['status_validasi']),
      _pick(e, ['status_hasil']),
      _pick(e, ['catatan']),
      _pick(e, ['tgl_pemeriksaan']),
      _pick(e, ['pemeriksaan_id']),
    ].join(' ').toLowerCase();

    return haystack.contains(_query);
  }

  // ==== UI cards (mengikuti gaya card cek_hasil_page.dart) ====

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

  Widget _patientCard(Map<String, dynamic> p) {
    final pasienId = _pickInt(p, ['id', 'pasien_id']);
    final nama = _pick(p, ['nama', 'pasien_nama', 'name'], fallback: 'Pasien');
    final nik = _pick(p, ['nik'], fallback: '-');

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: pasienId == 0
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CekHasilPage(pasienId: pasienId),
                ),
              );
            },
      child: Container(
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
              child: Icon(
                Icons.person_rounded,
                size: 28,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NIK: $nik',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'ID Pasien: $pasienId',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _examCard(Map<String, dynamic> e) {
    final pemeriksaanId = _pickInt(e, ['pemeriksaan_id', 'id']);
    final kategori = _pick(e, ['kategori_nama'], fallback: '-');
    final pasienNama = _pick(e, ['pasien_nama'], fallback: 'Pasien');
    final nik = _pick(e, ['nik'], fallback: '-');
    final tglIso = _pick(e, ['tgl_pemeriksaan'], fallback: '-');
    final tanggal = (tglIso == '-' ? '-' : _fmtDate(tglIso));
    final statusValidasi = _pick(e, ['status_validasi'], fallback: '-');
    final statusHasil = _pick(e, ['status_hasil'], fallback: '-');

    final iconPath = _iconForCategory(kategori);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: pemeriksaanId == 0
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HasilDetailPage(id: pemeriksaanId),
                ),
              );
            },
      child: Container(
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
                    'Pemeriksaan $kategori',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pasienNama,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'NIK: $nik',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(tanggal, style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    '$statusValidasi • $statusHasil',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ==== build ====

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pencarian')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchC,
              decoration: InputDecoration(
                hintText: 'Cari pasien atau hasil pemeriksaan...',
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
          ),
          Expanded(
            child: FutureBuilder<_SearchBundle>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _ErrorState(
                    message: snapshot.error.toString(),
                    onRetry: _refresh,
                  );
                }

                final bundle = snapshot.data!;
                final patients = bundle.patients.where(_matchPatient).toList();
                final exams = bundle.exams.where(_matchExam).toList();

                if (patients.isEmpty && exams.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Icon(Icons.inbox_rounded, size: 56),
                        SizedBox(height: 12),
                        Center(child: Text('Tidak ada hasil pencarian.')),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(0, 6, 0, 16),
                    children: [
                      if (patients.isNotEmpty) _sectionTitle('Profil Pasien'),
                      if (patients.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: patients.map(_patientCard).toList(),
                          ),
                        ),

                      if (exams.isNotEmpty) _sectionTitle('Hasil Pemeriksaan'),
                      if (exams.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: exams.map(_examCard).toList(),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (value) {
          Navigator.pushReplacementNamed(
            context,
            ['/doctor_home', '/pencarian', '/akun_dokter'][value],
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

class _SearchBundle {
  final List<Map<String, dynamic>> patients;
  final List<Map<String, dynamic>> exams;

  _SearchBundle({required this.patients, required this.exams});
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
