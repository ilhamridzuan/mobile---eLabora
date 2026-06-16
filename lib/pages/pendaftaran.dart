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

  // --- Form state ---
  String? _jenisKelamin; // 'L' / 'P'
  DateTime? _tanggalLahir;
  DateTime? _tanggalPeriksa;
  TimeOfDay? _waktuPeriksa;

  File? _referralLetter;
  String? _referralFileName;
  int _currentStep = 1;

  // Controller untuk identitas (autofill dari /auth/me)
  final TextEditingController _namaC = TextEditingController();
  final TextEditingController _nikC = TextEditingController();

  // Untuk menampilkan value di TextFormField readOnly
  final TextEditingController _tglLahirC = TextEditingController();
  final TextEditingController _tglPeriksaC = TextEditingController();
  final TextEditingController _waktuPeriksaC = TextEditingController();

  // API client
  late final ApiClient _client;

  bool _submitting = false;
  bool _loadingProfile = false;

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _prefillFromMe();
  }

  @override
  void dispose() {
    _namaC.dispose();
    _nikC.dispose();
    _tglLahirC.dispose();
    _tglPeriksaC.dispose();
    _waktuPeriksaC.dispose();
    super.dispose();
  }

  Future<void> _prefillFromMe() async {
    setState(() => _loadingProfile = true);

    try {
      final res = await _client.dio.get('/auth/me');
      final body = (res.data is Map) ? Map<String, dynamic>.from(res.data) : <String, dynamic>{};
      final profil = (body['profil'] is Map) ? Map<String, dynamic>.from(body['profil']) : null;

      if (profil == null) return;

      final nama = (profil['nama'] ?? '').toString();
      final nik = (profil['nik'] ?? '').toString();
      final jk = (profil['jenis_kelamin'] ?? '').toString(); // biasanya 'L'/'P'
      final tglLahirRaw = profil['tgl_lahir']; // bisa null atau ISO

      DateTime? tglLahir;
      if (tglLahirRaw != null && tglLahirRaw.toString().isNotEmpty) {
        try {
          tglLahir = DateTime.parse(tglLahirRaw.toString()).toLocal();
        } catch (_) {
          tglLahir = null;
        }
      }

      if (!mounted) return;

      setState(() {
        _namaC.text = nama;
        _nikC.text = nik;

        // jenis kelamin
        if (jk == 'L' || jk == 'P') {
          _jenisKelamin = jk;
        }

        // tanggal lahir
        _tanggalLahir = tglLahir;
        _tglLahirC.text = (tglLahir != null) ? _displayDate(tglLahir) : '';
      });
    } catch (_) {
      // kalau gagal, biarkan saja (user masih bisa isi manual)
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  String _yyyyMmDd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }

  String _jadwalPemeriksaanAt(DateTime date, TimeOfDay time) {
    // format backend: "2025-12-25 10:00:00" (Local Jakarta, tanpa offset)
    // API otomatis menormalkan ke WIB — jangan kirim +07:00 agar tidak double-convert
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

  void _nextStep() {
    if (_namaC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama lengkap wajib diisi.')),
      );
      return;
    }
    if (_nikC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NIK wajib diisi.')),
      );
      return;
    }
    if (_tanggalLahir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal lahir terlebih dahulu.')),
      );
      return;
    }
    if (_jenisKelamin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jenis kelamin terlebih dahulu.')),
      );
      return;
    }
    setState(() {
      _currentStep = 2;
    });
  }

  Widget _buildStepIndicator({
    required int step,
    required String title,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.primary
                : isActive
                    ? AppColors.primary
                    : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.primary : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 14)
              : Text(
                  step.toString(),
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isActive ? AppColors.textPrimary : Colors.grey.shade500,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
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
    debugPrint('DEBUG_SUBMIT: _submit has been called');
    if (_tanggalPeriksa == null || _waktuPeriksa == null) {
      debugPrint('DEBUG_SUBMIT: tanggalPeriksa or waktuPeriksa is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal & waktu pemeriksaan terlebih dahulu.')),
      );
      return;
    }

    if (_referralLetter == null || _referralFileName == null) {
      debugPrint('DEBUG_SUBMIT: referralLetter or referralFileName is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload surat rujukan (pdf/jpg/png) terlebih dahulu.')),
      );
      return;
    }

    debugPrint('DEBUG_SUBMIT: setting submitting to true');
    setState(() => _submitting = true);

    try {
      final tanggalAntrian = _yyyyMmDd(_tanggalPeriksa!);
      final jadwal = _jadwalPemeriksaanAt(_tanggalPeriksa!, _waktuPeriksa!);
      debugPrint('DEBUG_SUBMIT: tanggalAntrian=$tanggalAntrian, jadwal=$jadwal');

      final fileExists = await _referralLetter!.exists();
      debugPrint('DEBUG_SUBMIT: Referral letter path=${_referralLetter!.path}, exists=$fileExists');

      debugPrint('DEBUG_SUBMIT: Preparing FormData...');
      final formData = FormData.fromMap({
        'tanggal_antrian': tanggalAntrian,
        'jadwal_pemeriksaan_at': jadwal,
        'surat_rujukan': await MultipartFile.fromFile(
          _referralLetter!.path,
          filename: _referralFileName!,
        ),
      });

      debugPrint('DEBUG_SUBMIT: Posting to /registrations/ ...');
      final res = await _client.dio.post(
        '/registrations/',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      debugPrint('DEBUG_SUBMIT: POST response status code: ${res.statusCode}');
      debugPrint('DEBUG_SUBMIT: POST response data: ${res.data}');

      final resMap = (res.data is Map) ? Map<String, dynamic>.from(res.data) : <String, dynamic>{};
      final data = (resMap['data'] is Map)
          ? Map<String, dynamic>.from(resMap['data'])
          : resMap;

      final noAntrian = data['no_antrian']?.toString() ?? '-';
      final noLab = data['no_lab']?.toString() ?? '-';
      debugPrint('DEBUG_SUBMIT: noAntrian=$noAntrian, noLab=$noLab');

      if (!mounted) {
        debugPrint('DEBUG_SUBMIT: Widget not mounted after response');
        return;
      }

      debugPrint('DEBUG_SUBMIT: Showing success SnackBar');
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pendaftaran berhasil! No antrian: $noAntrian | $noLab'),
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (se) {
        debugPrint('DEBUG_SUBMIT: Error showing success SnackBar: $se');
      }

      debugPrint('DEBUG_SUBMIT: Resetting step to 1');
      setState(() {
        _currentStep = 1;
      });

      debugPrint('DEBUG_SUBMIT: Navigating to /antrian...');
      Navigator.pushReplacementNamed(
        context,
        '/antrian',
        arguments: {'date': tanggalAntrian},
      );
      debugPrint('DEBUG_SUBMIT: Navigation completed');
    } on DioException catch (e) {
      debugPrint('DEBUG_SUBMIT: DioException caught: $e');
      debugPrint('DEBUG_SUBMIT: DioException response: ${e.response?.data}');
      final msg = (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response?.data['message'].toString()
          : (e.message ?? 'Gagal melakukan pendaftaran');

      if (!mounted) return;
      try {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? 'Gagal melakukan pendaftaran')));
      } catch (se) {
        debugPrint('DEBUG_SUBMIT: Error showing Dio SnackBar: $se');
      }
    } catch (e, stack) {
      debugPrint('DEBUG_SUBMIT: Generic exception caught: $e');
      debugPrint('DEBUG_SUBMIT: Stack trace: $stack');
      if (!mounted) return;
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      } catch (se) {
        debugPrint('DEBUG_SUBMIT: Error showing Generic SnackBar: $se');
      }
    } finally {
      debugPrint('DEBUG_SUBMIT: setting submitting to false in finally block');
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pendaftaran'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (_currentStep == 2) {
              setState(() => _currentStep = 1);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Form Pendaftaran',
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lengkapi data di bawah ini untuk memesan nomor antrian lab.',
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Wizard Progress Indicator
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.04),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStepIndicator(
                        step: 1,
                        title: 'Data Pasien',
                        isActive: _currentStep >= 1,
                        isCompleted: _currentStep > 1,
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 1.5,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: _currentStep > 1 ? AppColors.primary : Colors.grey.shade300,
                    ),
                    Expanded(
                      child: _buildStepIndicator(
                        step: 2,
                        title: 'Jadwal & Rujukan',
                        isActive: _currentStep >= 2,
                        isCompleted: _currentStep > 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_loadingProfile)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Memuat data profil...',
                          style: text.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ================= STEP 1: DATA PASIEN =================
              if (_currentStep == 1) ...[
                Container(
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Data Pasien',
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      Text('Nama Lengkap *', style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _namaC,
                        readOnly: true,
                        decoration: const InputDecoration(
                          hintText: 'Nama Lengkap',
                          prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text('NIK / No. Identitas *', style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nikC,
                        readOnly: true,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'NIK / No. Identitas',
                          prefixIcon: Icon(Icons.credit_card_rounded, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text('Tanggal Lahir', style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _tglLahirC,
                        readOnly: true,
                        decoration: const InputDecoration(
                          hintText: 'Pilih tanggal lahir',
                          prefixIcon: Icon(Icons.cake_outlined, color: AppColors.textSecondary),
                          suffixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 18),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _tanggalLahir ?? DateTime.now(),
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
                      const SizedBox(height: 16),

                      Text('Jenis Kelamin *', style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _jenisKelamin,
                        decoration: const InputDecoration(
                          hintText: 'Pilih jenis kelamin',
                          prefixIcon: Icon(Icons.wc_rounded, color: AppColors.textSecondary),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                          DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                        ],
                        onChanged: (v) => setState(() => _jenisKelamin = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Button Next
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      elevation: 2,
                      shadowColor: AppColors.primary.withValues(alpha: 0.3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Lanjut',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ]

              // ================= STEP 2: JADWAL & RUJUKAN =================
              else ...[
                // CARD 2: JADWAL PEMERIKSAAN
                Container(
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.calendar_month_outlined,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Jadwal Pemeriksaan',
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      Text('Tanggal Pemeriksaan *', style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _tglPeriksaC,
                        readOnly: true,
                        decoration: const InputDecoration(
                          hintText: 'Pilih tanggal pemeriksaan',
                          prefixIcon: Icon(Icons.event_note_rounded, color: AppColors.textSecondary),
                          suffixIcon: Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                        ),
                        onTap: () async {
                          final now = DateTime.now();
                          final todayMidnight = DateTime(now.year, now.month, now.day);
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _tanggalPeriksa ?? todayMidnight,
                            firstDate: todayMidnight,
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
                      const SizedBox(height: 16),

                      Text('Waktu Pemeriksaan *', style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _waktuPeriksaC,
                        readOnly: true,
                        decoration: const InputDecoration(
                          hintText: 'Pilih waktu pemeriksaan',
                          prefixIcon: Icon(Icons.watch_later_outlined, color: AppColors.textSecondary),
                          suffixIcon: Icon(Icons.access_time_rounded, color: AppColors.primary, size: 18),
                        ),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _waktuPeriksa ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _waktuPeriksa = picked;
                              _waktuPeriksaC.text = _displayTime(picked);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // CARD 3: SURAT RUJUKAN
                Container(
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.description_outlined,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Surat Rujukan *',
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Silakan unggah foto atau file PDF surat rujukan dari dokter pemeriksa.',
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Custom Premium Uploader Container
                      InkWell(
                        onTap: _submitting ? null : _pickReferralLetter,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          decoration: BoxDecoration(
                            color: _referralFileName != null
                                ? Colors.green.withValues(alpha: 0.04)
                                : AppColors.primary.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _referralFileName != null
                                  ? Colors.green.withValues(alpha: 0.3)
                                  : AppColors.primary.withValues(alpha: 0.15),
                              width: 1.5,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _referralFileName != null
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : AppColors.primary.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _referralFileName != null
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.cloud_upload_outlined,
                                  color: _referralFileName != null ? Colors.green : AppColors.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _referralFileName ?? 'Pilih Berkas Rujukan',
                                textAlign: TextAlign.center,
                                style: text.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _referralFileName != null ? Colors.green.shade700 : AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _referralFileName != null
                                    ? 'Berkas berhasil dipilih. Ketuk untuk mengganti.'
                                    : 'Mendukung format PDF, JPG, JPEG, PNG (Maks. 5MB)',
                                textAlign: TextAlign.center,
                                style: text.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Button Row (Back & Submit)
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 54,
                        child: OutlinedButton(
                          onPressed: () => setState(() => _currentStep = 1),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          child: const Text(
                            'Kembali',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                            elevation: 2,
                            shadowColor: AppColors.primary.withValues(alpha: 0.3),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Daftar Sekarang',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
