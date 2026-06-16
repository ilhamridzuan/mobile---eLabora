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
  String _selectedFilter = 'Semua';

  final List<String> _filters = [
    'Semua',
    'Pasien',
    'Pemeriksaan',
    'Patologi',
    'Anatomi',
    'Mikrobiologi',
  ];

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

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || name.isEmpty) return 'P';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
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

  // Substring highlight utility for search efficiency
  Widget _highlightText(
    String text,
    String query,
    TextStyle baseStyle,
    TextStyle highlightStyle,
  ) {
    if (query.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    final normalizedText = text.toLowerCase();
    final normalizedQuery = query.toLowerCase();

    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = normalizedText.indexOf(normalizedQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + normalizedQuery.length),
          style: highlightStyle,
        ),
      );

      start = index + normalizedQuery.length;
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  // Material 3 style badge helper
  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }



  // Style chips using Material 3 guidelines
  Widget _buildFilterChips() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;

          Color accentColor = AppColors.primary;
          IconData icon = Icons.search_rounded;

          switch (filter) {
            case 'Semua':
              accentColor = AppColors.primary;
              icon = Icons.grid_view_rounded;
              break;
            case 'Pasien':
              accentColor = AppColors.secondary;
              icon = Icons.person_rounded;
              break;
            case 'Pemeriksaan':
              accentColor = const Color(0xFF8E7EFE);
              icon = Icons.assignment_rounded;
              break;
            case 'Patologi':
              accentColor = const Color(0xFF48C0B8);
              icon = Icons.science_rounded;
              break;
            case 'Anatomi':
              accentColor = const Color(0xFFEF6C00);
              icon = Icons.biotech_rounded;
              break;
            case 'Mikrobiologi':
              accentColor = const Color(0xFF2E7D77);
              icon = Icons.bug_report_rounded;
              break;
          }

          final activeColor = isSelected ? accentColor : AppColors.textSecondary;
          final bgColor = isSelected ? accentColor.withValues(alpha: 0.08) : Colors.white;
          final borderC = isSelected ? accentColor : Colors.grey.shade300;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border.all(color: borderC, width: 1.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 15, color: activeColor),
                    const SizedBox(width: 5),
                    Text(
                      filter,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? accentColor : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }



  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 8),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Material 3 layout for no results State
  Widget _buildNoResultsState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              children: [
                const TextSpan(text: 'Tidak ada hasil untuk kata kunci '),
                TextSpan(
                  text: '"$_query"',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tips Pencarian:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _bulletPoint('Periksa kembali ejaan kata kunci Anda.'),
          _bulletPoint('Coba kata kunci nama pasien yang lain.'),
          _bulletPoint('Cari menggunakan NIK atau ID Pasien secara spesifik.'),
          _bulletPoint(
            'Gunakan kategori filter di atas untuk melihat jenis laboratorium tertentu.',
          ),
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 44,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Redesigned Patient Card: Modern profile design
  Widget _patientCard(Map<String, dynamic> p) {
    final pasienId = _pickInt(p, ['id', 'pasien_id']);
    final nama = _pick(p, ['nama', 'pasien_nama', 'name'], fallback: 'Pasien');
    final nik = _pick(p, ['nik'], fallback: '-');

    final baseStyle = const TextStyle(
      color: AppColors.textPrimary,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );

    final highlightStyle = const TextStyle(
      color: AppColors.primary,
      fontSize: 15,
      fontWeight: FontWeight.bold,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Initials Avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _getInitials(nama),
                  style: const TextStyle(
                    color: AppColors.secondaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _highlightText(nama, _query, baseStyle, highlightStyle),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.badge_rounded,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'NIK: $nik',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.fingerprint_rounded,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ID Pasien: $pasienId',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Redesigned Exam Card: Modern clinic component with status badges
  Widget _examCard(Map<String, dynamic> e) {
    final pemeriksaanId = _pickInt(e, ['pemeriksaan_id', 'id']);
    final kategori = _pick(e, ['kategori_nama'], fallback: '-');
    final pasienNama = _pick(e, ['pasien_nama'], fallback: 'Pasien');
    final nik = _pick(e, ['nik'], fallback: '-');
    final tglIso = _pick(e, ['tgl_pemeriksaan'], fallback: '-');
    final tanggal = (tglIso == '-' ? '-' : _fmtDate(tglIso));
    final statusValidasi = _pick(e, ['status_validasi'], fallback: '-');
    final statusHasil = _pick(e, ['status_hasil'], fallback: '-');

    Color catColor;
    IconData catIcon;
    switch (kategori) {
      case 'Patologi':
        catColor = const Color(0xFF48C0B8);
        catIcon = Icons.science_rounded;
        break;
      case 'Anatomi':
        catColor = const Color(0xFFEF6C00);
        catIcon = Icons.biotech_rounded;
        break;
      case 'Mikrobiologi':
        catColor = const Color(0xFF2E7D77);
        catIcon = Icons.bug_report_rounded;
        break;
      default:
        catColor = AppColors.primary;
        catIcon = Icons.science_rounded;
    }

    final isValidated = statusValidasi.toLowerCase().contains('sudah') ||
        statusValidasi.toLowerCase().contains('valid');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circle Category Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(catIcon, color: catColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pemeriksaan $kategori',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _highlightText(
                      'Pasien: $pasienNama',
                      _query,
                      const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NIK: $nik',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tanggal,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Status Badges
                    Row(
                      children: [
                        _buildBadge(
                          statusValidasi,
                          isValidated ? const Color(0xFF2E7D32) : const Color(0xFFF57C00),
                        ),
                        const SizedBox(width: 8),
                        _buildBadge(statusHasil, AppColors.textSecondary),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Pencarian',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Sleek Material 3 rounded Search Bar with shadow
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.grey.shade200, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchC,
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Cari pasien atau hasil pemeriksaan...',
                hintStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchC.clear();
                        },
                      ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // Category scrolling chips
          _buildFilterChips(),
          const SizedBox(height: 8),

          // Main Search Results View
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

                final patients = bundle.patients.where((p) {
                  if (_selectedFilter != 'Semua' && _selectedFilter != 'Pasien') {
                    return false;
                  }
                  return _matchPatient(p);
                }).toList();

                final exams = bundle.exams.where((e) {
                  if (_selectedFilter != 'Semua' && _selectedFilter != 'Pemeriksaan') {
                    final cat = _pick(e, ['kategori_nama'], fallback: '');
                    if (_selectedFilter != cat) return false;
                  }
                  return _matchExam(e);
                }).toList();

                if (patients.isEmpty && exams.isEmpty) {
                  return _buildNoResultsState();
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(0, 2, 0, 16),
                    children: [
                      const SizedBox(height: 8),

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


