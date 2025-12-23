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
    return await _patientsApi.listPatients(); // GET /patients -> items[]
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Pasien'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            //  Search bar
            TextField(
              controller: _searchC,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari pasien (nama / NIK / username / email)...',
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
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          Icon(Icons.inbox_rounded, size: 56),
                          SizedBox(height: 12),
                          Center(child: Text('Pasien tidak ditemukan.')),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
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

  Widget _buildPatientCard(Map<String, dynamic> p) {
    final pasienId = (p['id'] is int)
        ? p['id'] as int
        : int.tryParse((p['id'] ?? '').toString()) ?? 0;

    final nama = (p['nama'] ?? 'Pasien').toString();
    final nik = (p['nik'] ?? '-').toString();
    final telp = (p['no_telepon'] ?? '-').toString();
    final email = (p['email'] ?? '').toString();
    final username = (p['username'] ?? '').toString();

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: pasienId == 0
          ? null
          : () {
              //  buka cek_hasil_page berdasarkan pasienId
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
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text('NIK: $nik', style: Theme.of(context).textTheme.bodyMedium),
                  Text('Telp: $telp', style: Theme.of(context).textTheme.bodyMedium),
                  if (username.isNotEmpty || email.isNotEmpty)
                    Text(
                      [
                        if (username.isNotEmpty) '@$username',
                        if (email.isNotEmpty) email,
                      ].join(' • '),
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
