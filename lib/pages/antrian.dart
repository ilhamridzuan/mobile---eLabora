import 'package:elabora_app/utils/constants.dart';
import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/auth_api.dart';
import '../data/queue_api.dart';
import '../utils/date_id.dart';

class AntrianPage extends StatefulWidget {
  const AntrianPage({super.key});

  @override
  State<AntrianPage> createState() => _AntrianPageState();
}

class _AntrianPageState extends State<AntrianPage> {
  late final ApiClient _client;
  late final QueueApi _queueApi;
  late final AuthApi _authApi;

  late Future<Map<String, dynamic>> _future;

  bool _initialized = false;
  String? _routeDate;

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _queueApi = QueueApi(_client);
    _authApi = AuthApi(_client);
    _future = Future.value({});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        _routeDate = args['date']?.toString();
      }
      _future = _load(date: _routeDate);
      _initialized = true;
    }
  }

  String _yyyyMmDd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }

  Future<Map<String, dynamic>> _load({String? date}) async {
    final me = await _authApi.me();
    final profil = me['profil'] as Map<String, dynamic>?;
    final pasienId = (profil?['id'] as int?);

    final targetDate = date ?? _yyyyMmDd(DateTime.now());

    final today = await _queueApi.today(date: targetDate);
    final statsWrap = await _queueApi.stats(date: targetDate);

    return {
      'me': me,
      'pasienId': pasienId,
      'today': today,
      'statsWrap': statsWrap,
    };
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  String _pad3(dynamic v) => _toInt(v).toString().padLeft(3, '0');

  String _fmtDateTime(dynamic isoOrStr) {
    final raw = (isoOrStr ?? '').toString();
    if (raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateId.formatFullWithTime(dt);
    } catch (_) {
      return raw;
    }
  }

  //  ambil no_antrian “saat ini” berdasarkan status
  // prioritas: DILAYANI -> MENUNGGU terkecil -> null
  String? _currentNoFromItems(List<Map<String, dynamic>> items) {
    Map<String, dynamic>? current;

    // 1) cari item DILAYANI
    for (final e in items) {
      final st = (e['status'] ?? '').toString().toUpperCase();
      if (st == 'DILAYANI') {
        current = e;
        break;
      }
    }
    if (current != null) return _pad3(current['no_antrian']);

    // 2) fallback: kalau belum ada DILAYANI, ambil MENUNGGU yang no_antrian paling kecil
    final waiting = items
        .where((e) => (e['status'] ?? '').toString().toUpperCase() == 'MENUNGGU')
        .toList();

    if (waiting.isEmpty) return null;

    waiting.sort((a, b) => _toInt(a['no_antrian']).compareTo(_toInt(b['no_antrian'])));
    return _pad3(waiting.first['no_antrian']);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Antrian'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snap.hasError) {
            return _ErrorState(
              message: snap.error.toString(),
              onRetry: () => setState(() => _future = _load(date: _routeDate)),
            );
          }

          final root = snap.data ?? {};
          final pasienId = root['pasienId'] as int?;

          final today = (root['today'] as Map<String, dynamic>? ?? {});
          final items = (today['data'] is List)
              ? (today['data'] as List).whereType<Map<String, dynamic>>().toList()
              : <Map<String, dynamic>>[];

          final statsWrap = (root['statsWrap'] as Map<String, dynamic>? ?? {});
          final stats = (statsWrap['stats'] as Map<String, dynamic>? ?? {});

          final total = _toInt(stats['total']);
          final menunggu = _toInt(stats['menunggu']);

          // Nomor antrian saat ini dari item status DILAYANI
          final currentNo = _currentNoFromItems(items) ?? '-';

          // ambil antrian user berdasarkan pasien_id
          Map<String, dynamic>? my;
          if (pasienId != null) {
            try {
              my = items.firstWhere((e) => _toInt(e['pasien_id']) == pasienId);
            } catch (_) {
              my = null;
            }
          }

          final myNo = my == null ? null : _pad3(my['no_antrian']);
          final myStatus = my == null ? null : (my['status'] ?? '').toString();
          final myJadwal = my == null ? null : _fmtDateTime(my['jadwal_pemeriksaan_at']);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              setState(() => _future = _load(date: _routeDate));
              await _future;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Section 1: Nomor Antrian Saya
                  Text(
                    'Nomor Antrian Saya',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (my != null)
                    IntrinsicHeight(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF745CFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.18),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            Positioned(
                              right: -15,
                              bottom: -15,
                              child: Icon(
                                Icons.biotech_rounded,
                                size: 110,
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Left ticket body
                                Expanded(
                                  flex: 7,
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(100),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                myStatus == 'DILAYANI'
                                                    ? Icons.play_arrow_rounded
                                                    : myStatus == 'DIBATALKAN'
                                                        ? Icons.cancel_outlined
                                                        : Icons.hourglass_empty_rounded,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                myStatus ?? 'MENUNGGU',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          'Nomor Antrian Anda',
                                          style: text.bodySmall?.copyWith(
                                            color: Colors.white.withValues(alpha: 0.7),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          myNo ?? '-',
                                          style: text.headlineLarge?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 38,
                                            letterSpacing: -1,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            const Icon(Icons.event_note_rounded, color: Colors.white, size: 14),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                myJadwal ?? '-',
                                                style: text.bodySmall?.copyWith(color: Colors.white),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Dashed Divider & Cutouts
                                SizedBox(
                                  width: 20,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Cutout top
                                      Positioned(
                                        top: -10,
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: const BoxDecoration(
                                            color: AppColors.background,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                      // Cutout bottom
                                      Positioned(
                                        bottom: -10,
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: const BoxDecoration(
                                            color: AppColors.background,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          mainAxisSize: MainAxisSize.max,
                                          children: List.generate(
                                            12,
                                            (index) => SizedBox(
                                              width: 1.5,
                                              height: 4,
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.35),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Right ticket body (stub)
                                Expanded(
                                  flex: 3,
                                  child: InkWell(
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/detail_antrian',
                                      arguments: my,
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.15),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.qr_code_2_rounded,
                                              color: Colors.white,
                                              size: 26,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Detail',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
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
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.assignment_turned_in_outlined,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum Ada Antrian',
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Anda tidak memiliki antrian aktif untuk tanggal ini.',
                            textAlign: TextAlign.center,
                            style: text.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/pendaftaran'),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Daftar Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Section 2: Info Antrian Hari Ini
                  Text(
                    'Informasi Antrian',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Hero Card: Nomor Antrian Saat Ini
                  Container(
                    padding: const EdgeInsets.all(24),
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
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.campaign_outlined,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Nomor Antrian Saat Ini',
                              style: text.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentNo,
                          style: text.displayLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            fontSize: 56,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentNo == '-' ? 'Belum ada antrian yang dipanggil' : 'Silakan bersiap di dekat ruang tunggu',
                          style: text.bodySmall?.copyWith(
                            color: currentNo == '-' ? AppColors.textSecondary : Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Row for Total & Sisa Antrian
                  Row(
                    children: [
                      // Card Total Antrian
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.people_alt_outlined,
                                  color: Colors.blue,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Total Antrian',
                                style: text.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                total.toString(),
                                style: text.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  fontSize: 22,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Card Sisa Antrian
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.hourglass_empty_rounded,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Sisa Antrian',
                                style: text.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                menunggu.toString(),
                                style: text.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  fontSize: 22,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}
