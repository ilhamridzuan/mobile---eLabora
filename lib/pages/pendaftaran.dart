import 'package:elabora_app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';

import '../data/api_client.dart';

class PendaftaranPage extends StatefulWidget {
  const PendaftaranPage({super.key});

  @override
  State<PendaftaranPage> createState() => _PendaftaranPageState();
}

class _PendaftaranPageState extends State<PendaftaranPage> {
  final _formKey = GlobalKey<FormState>();

  // --- Form state (UI kamu) ---
  String? _jenisKelamin;
  DateTime? _tanggalLahir;
  DateTime? _tanggalPeriksa;
  TimeOfDay? _waktuPeriksa;

  File? _referralLetter;
  String? _referralFileName;

  // Untuk menampilkan value di TextFormField readOnly
  final TextEditingController _tglLahirC = TextEditingController();
  final TextEditingController _tglPeriksaC = TextEditingController();
  final TextEditingController _waktuPeriksaC = TextEditingController();

  // API client
  late final ApiClient _client;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
  }

  @override
  void dispose() {
    _tglLahirC.dispose();
    _tglPeriksaC.dispose();
    _waktuPeriksaC.dispose();
    super.dispose();
  }

  String _yyyyMmDd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }

  String _jadwalPemeriksaanAt(DateTime date, TimeOfDay time) {
    // format yang backend kamu pakai contoh: "2025-12-25 10:00:00"
    final ymd = _yyyyMmDd(date);
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$ymd $hh:$mm:00';
  }

  String _displayDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd-$mm-${d.year}';
  }

  String _displayTime(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _pickReferralLetter() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _referralLetter = File(result.files.single.path!);
        _referralFileName = result.files.single.name;
      });
    }
  }

  Future<void> _submit() async {
    // Validasi minimal yang benar-benar dibutuhkan endpoint
    if (_tanggalPeriksa == null || _waktuPeriksa == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tanggal & waktu pemeriksaan terlebih dahulu.'),
        ),
      );
      return;
    }

    if (_referralLetter == null || _referralFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload surat rujukan (pdf/jpg/png) terlebih dahulu.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      // ✅ tanggal_antrian = tanggal yang sama dengan jadwal pemeriksaan
      final tanggalAntrian = _yyyyMmDd(_tanggalPeriksa!);

      // ✅ jadwal_pemeriksaan_at = tanggal + waktu yang dipilih
      final jadwal = _jadwalPemeriksaanAt(_tanggalPeriksa!, _waktuPeriksa!);

      final formData = FormData.fromMap({
        'tanggal_antrian': tanggalAntrian,
        'jadwal_pemeriksaan_at': jadwal,
        // Field upload sesuai Express: multer.single("surat_rujukan")
        'surat_rujukan': await MultipartFile.fromFile(
          _referralLetter!.path,
          filename: _referralFileName!,
        ),
      });

      final res = await _client.dio.post(
        '/registrations/',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final data = (res.data is Map)
          ? Map<String, dynamic>.from(res.data)
          : <String, dynamic>{};

      final noAntrian = data['no_antrian']?.toString() ?? '-';
      final noLab = data['no_lab']?.toString() ?? '-';

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pendaftaran berhasil! No antrian: $noAntrian | $noLab',
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.pushReplacementNamed(context, '/antrian');
    } on DioException catch (e) {
      final msg =
          e.response?.data is Map && (e.response?.data['message'] != null)
          ? e.response?.data['message'].toString()
          : (e.message ?? 'Gagal melakukan pendaftaran');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg!)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final text = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Pendaftaran'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: color.surface,
        foregroundColor: color.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Form Pendaftaran Pemeriksaan Lab',
                style: text.displayLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Lengkapi data pendaftaran dan upload surat rujukan.',
                style: text.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              // ====== (Bagian identitas tetap seperti file kamu; tidak dipakai ke endpoint) ======
              Text(
                'Nama Lengkap *',
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Masukkan nama lengkap',
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'NIK / No. Identitas *',
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Masukkan NIK / No. Identitas',
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Tanggal Lahir',
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _tglLahirC,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Pilih tanggal lahir',
                  suffixIcon: Icon(
                    Icons.calendar_today_outlined,
                    color: color.primary,
                  ),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1950),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _tanggalLahir = picked;
                      _tglLahirC.text = _displayDate(picked);
                    });
                  }
                },
              ),
              const SizedBox(height: 14),

              Text(
                'Jenis Kelamin *',
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _jenisKelamin,
                decoration: const InputDecoration(
                  hintText: 'Pilih jenis kelamin',
                ),
                items: const [
                  DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                  DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                ],
                onChanged: (v) => setState(() => _jenisKelamin = v),
              ),

              const SizedBox(height: 24),
              Text(
                'Jadwal Pemeriksaan *',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              Text(
                'Tanggal Pemeriksaan',
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _tglPeriksaC,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Pilih tanggal pemeriksaan',
                  suffixIcon: Icon(
                    Icons.calendar_today_outlined,
                    color: color.primary,
                  ),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate:
                        DateTime.now(), // pendaftaran untuk tanggal sekarang dan seterusnya
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _tanggalPeriksa = picked;
                      _tglPeriksaC.text = _displayDate(picked);
                    });
                  }
                },
              ),
              const SizedBox(height: 14),

              Text(
                'Waktu Pemeriksaan',
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _waktuPeriksaC,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Pilih waktu pemeriksaan',
                  suffixIcon: Icon(
                    Icons.access_time_rounded,
                    color: color.primary,
                  ),
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _waktuPeriksa = picked;
                      _waktuPeriksaC.text = _displayTime(picked);
                    });
                  }
                },
              ),

              const SizedBox(height: 24),
              Text(
                'Surat Rujukan *',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Text(
                'Upload surat rujukan (pdf/jpg/png).',
                style: text.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),

              InkWell(
                onTap: _submitting ? null : _pickReferralLetter,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.outline.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.upload_file_rounded, color: color.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _referralFileName ?? 'Pilih file surat rujukan',
                          style: text.bodyMedium?.copyWith(
                            color: _referralFileName == null
                                ? AppColors.textSecondary
                                : color.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: color.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: Text(_submitting ? 'Memproses...' : 'Daftar Sekarang'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
