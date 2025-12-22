import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../data/api_client.dart';
import '../data/exams_api.dart';
import '../utils/constants.dart';
import '../utils/date_id.dart';

class HasilDetailPage extends StatefulWidget {
  final int id;
  const HasilDetailPage({super.key, required this.id});

  @override
  State<HasilDetailPage> createState() => _HasilDetailPageState();
}

class _HasilDetailPageState extends State<HasilDetailPage> {
  late final ApiClient _client;
  late final ExamsApi _examsApi;

  late Future<Map<String, dynamic>> _futureDetail;
  final Map<String, bool> _downloading = {}; // per-file

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _examsApi = ExamsApi(_client);
    _futureDetail = _examsApi.detail(widget.id);
  }

  String _formatTanggal(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateId.formatFullWithTime(dt);
    } catch (_) {
      return iso.isEmpty ? '-' : iso;
    }
  }

  String _makeFileUrl(String filePath) {
    final p = filePath.trim();
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    final base = _client.dio.options.baseUrl;
    return p.startsWith('/') ? '$base$p' : '$base/$p';
  }

  bool _isImage(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png');
  }

  bool _isPdf(String path) => path.toLowerCase().endsWith('.pdf');

  String _fileNameFromPath(String path) {
    final clean = path.split('?').first;
    return clean.split('/').last;
  }

  /// ✅ Download file → Snackbar ada tombol "Buka"
  Future<void> _downloadFile({
    required String url,
    required String saveAsName,
  }) async {
    setState(() => _downloading[url] = true);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/$saveAsName';

      await _client.dio.download(url, savePath);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File berhasil diunduh: $saveAsName'),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Buka',
            onPressed: () async {
              final result = await OpenFilex.open(savePath);
              if (!mounted) return;

              if (result.type != ResultType.done) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result.message ?? 'Gagal membuka file',
                    ),
                  ),
                );
              }
            },
          ),
        ),
      );
    } on DioException catch (e) {
      final msg = (e.response?.data is Map &&
              e.response?.data['message'] != null)
          ? e.response?.data['message'].toString()
          : (e.message ?? 'Gagal download file');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg ?? 'Terjadi Kesalahan.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _downloading[url] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final text = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pemeriksaan')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: () => setState(
                () => _futureDetail = _examsApi.detail(widget.id),
              ),
            );
          }

          final data = snapshot.data ?? {};
          final kategori = (data['kategori_nama'] ?? '-').toString();
          final tglRaw = (data['tgl_pemeriksaan'] ?? '').toString();
          final statusValidasi =
              (data['status_validasi'] ?? '-').toString();
          final catatan = (data['catatan'] ?? '-').toString();
          final tanggal = _formatTanggal(tglRaw);

          final files =
              (data['files'] is List) ? data['files'] as List : <dynamic>[];
          final fileMaps = files
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ===== Info Pemeriksaan =====
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color:
                          AppColors.textSecondary.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kategori',
                        style: text.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(kategori,
                        style: text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),

                    Text('Tanggal Pemeriksaan',
                        style: text.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(tanggal,
                        style: text.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),

                    Text('Status Validasi',
                        style: text.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    _StatusChip(label: statusValidasi),

                    const SizedBox(height: 12),
                    Text('Catatan',
                        style: text.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(catatan, style: text.bodyLarge),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Text('File Pemeriksaan',
                  style: text.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),

              if (fileMaps.isEmpty)
                const Text('Belum ada file pemeriksaan.')
              else
                ...fileMaps.map((f) {
                  final rawPath = (f['file_path'] ?? '').toString();
                  final url = _makeFileUrl(rawPath);
                  final name = _fileNameFromPath(rawPath);
                  final downloading = _downloading[url] == true;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.outline.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isImage(rawPath))
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(url),
                          )
                        else
                          Row(
                            children: [
                              Icon(
                                _isPdf(rawPath)
                                    ? Icons.picture_as_pdf_rounded
                                    : Icons.insert_drive_file_rounded,
                                color: color.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  name,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: downloading
                                ? null
                                : () => _downloadFile(
                                      url: url,
                                      saveAsName: name,
                                    ),
                            icon: downloading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.download_rounded),
                            label: Text(
                                downloading ? 'Mengunduh...' : 'Download'),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final upper = label.toUpperCase();
    Color bg = AppColors.textSecondary;
    if (upper == 'TERVALIDASI') bg = Colors.green.shade400;
    if (upper == 'DITOLAK') bg = Theme.of(context).colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
