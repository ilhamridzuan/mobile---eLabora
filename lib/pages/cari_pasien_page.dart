import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../data/api_client.dart';
import '../data/patients_api.dart';
import 'cek_hasil_page.dart';

class CariPasienPage extends StatefulWidget {
  const CariPasienPage({super.key});

  @override
  State<CariPasienPage> createState() => _CariPasienState();
}

class _CariPasienState extends State<CariPasienPage> {
  late final ApiClient _client;
  late final PatientsApi _patientsApi;

  late Future<List<Map<String, dynamic>>> _futureRows;

  final TextEditingController _searchC = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _patientsApi = PatientsApi(_client);
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
    return await _patientsApi.listPatients();
  }

  Future<void> _refresh() async {
    setState(() => _futureRows = _load());
    await _futureRows;
  }

  bool _match(Map<String, dynamic> p) {
    if (_query.isEmpty) return true;

    final haystack = <String>[
      (p['nama'] ?? '').toString(),
      (p['nik'] ?? '').toString(),
      (p['username'] ?? '').toString(),
      (p['email'] ?? '').toString(),
      (p['no_telepon'] ?? '').toString(),
      (p['id'] ?? '').toString(),
    ].join(' ').toLowerCase();

    return haystack.contains(_query);
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || name.isEmpty) return 'P';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  // Highlight matches inside result card strings
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
        maxLines: 1,
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
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  // Material 3 layout for no results State
  Widget _buildNoResultsState() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'Pasien tidak ditemukan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Coba kata kunci ejaan lain atau gunakan NIK/ID Pasien.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
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
          'Cari Pasien',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Column(
          children: [
            // Sleek Material 3 rounded Search Bar with shadow
            Container(
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
                textInputAction: TextInputAction.search,
                style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Cari pasien (nama / NIK / username / email)...',
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
                          onPressed: () => _searchC.clear(),
                        ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _futureRows,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _ErrorState(
                      message: snapshot.error.toString(),
                      onRetry: () => setState(() => _futureRows = _load()),
                    );
                  }

                  final rows = (snapshot.data ?? []).where(_match).toList();

                  if (rows.isEmpty) {
                    return _buildNoResultsState();
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        return _buildPatientCard(rows[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Redesigned Patient Card: Modern profile list component
  Widget _buildPatientCard(Map<String, dynamic> p) {
    final pasienId = (p['id'] is int)
        ? p['id'] as int
        : int.tryParse((p['id'] ?? '').toString()) ?? 0;

    final nama = (p['nama'] ?? 'Pasien').toString();
    final nik = (p['nik'] ?? '-').toString();
    final telp = (p['no_telepon'] ?? '-').toString();
    final email = (p['email'] ?? '').toString();
    final username = (p['username'] ?? '').toString();

    final baseNameStyle = const TextStyle(
      color: AppColors.textPrimary,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );

    final highlightNameStyle = const TextStyle(
      color: AppColors.primary,
      fontSize: 15,
      fontWeight: FontWeight.bold,
    );

    final baseDetailStyle = const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 12,
    );

    final highlightDetailStyle = const TextStyle(
      color: AppColors.textPrimary,
      fontSize: 12,
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
                    _highlightText(nama, _query, baseNameStyle, highlightNameStyle),
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
                          child: _highlightText(
                            'NIK: $nik',
                            _query,
                            baseDetailStyle,
                            highlightDetailStyle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_rounded,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _highlightText(
                            'Telp: $telp',
                            _query,
                            baseDetailStyle,
                            highlightDetailStyle,
                          ),
                        ),
                      ],
                    ),
                    if (username.isNotEmpty || email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.alternate_email_rounded,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _highlightText(
                              [
                                if (username.isNotEmpty) '@$username',
                                if (email.isNotEmpty) email,
                              ].join(' • '),
                              _query,
                              baseDetailStyle,
                              highlightDetailStyle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),
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
