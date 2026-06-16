import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../data/api_client.dart';
import '../data/register_api.dart';
import '../data/token_storage.dart';
import '../utils/constants.dart';
import '../utils/form_validator.dart';
import '../utils/api_error_mapper.dart';
import '../widgets/validated_text_field.dart';
import '../widgets/validated_dropdown.dart';
import '../widgets/loading_button.dart';

class RegisterPatientPage extends StatefulWidget {
  const RegisterPatientPage({super.key});

  @override
  State<RegisterPatientPage> createState() => _RegisterPatientPageState();
}

class _RegisterPatientPageState extends State<RegisterPatientPage> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nama = TextEditingController();
  final _nik = TextEditingController();
  final _noHp = TextEditingController();
  final _alamat = TextEditingController();
  final _tglLahir = TextEditingController(); // YYYY-MM-DD

  String? _jk; // "L" atau "P"
  DateTime? _selectedDate;
  bool _loading = false;
  bool _obscurePassword = true;
  final Map<String, String> _errors = {};
  bool _isNetworkError = false;

  late final RegisterApi _registerApi;

  @override
  void initState() {
    super.initState();
    _registerApi = RegisterApi(ApiClient());

    // Real-time validation listeners
    _username.addListener(_validateUsername);
    _email.addListener(_validateEmail);
    _password.addListener(_validatePassword);
    _nama.addListener(_validateNama);
    _nik.addListener(_validateNIK);
    _noHp.addListener(_validateNoHp);
    _tglLahir.addListener(_validateTglLahir);
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _nama.dispose();
    _nik.dispose();
    _noHp.dispose();
    _alamat.dispose();
    _tglLahir.dispose();
    super.dispose();
  }

  void _validateUsername() {
    setState(() {
      final error = FormValidator.validateUsername(_username.text);
      if (error != null) {
        _errors['username'] = error;
      } else {
        _errors.remove('username');
      }
    });
  }

  void _validateEmail() {
    setState(() {
      final error = FormValidator.validateEmail(_email.text);
      if (error != null) {
        _errors['email'] = error;
      } else {
        _errors.remove('email');
      }
    });
  }

  void _validatePassword() {
    setState(() {
      final error = FormValidator.validatePassword(_password.text);
      if (error != null) {
        _errors['password'] = error;
      } else {
        _errors.remove('password');
      }
    });
  }

  void _validateNama() {
    setState(() {
      final error = FormValidator.validateRequired(_nama.text, 'Nama');
      if (error != null) {
        _errors['nama'] = error;
      } else {
        _errors.remove('nama');
      }
    });
  }

  void _validateNIK() {
    setState(() {
      final error = FormValidator.validateNIK(_nik.text);
      if (error != null) {
        _errors['nik'] = error;
      } else {
        _errors.remove('nik');
      }
    });
  }

  void _validateNoHp() {
    setState(() {
      final error = FormValidator.validatePhoneNumber(_noHp.text);
      if (error != null) {
        _errors['noHp'] = error;
      } else {
        _errors.remove('noHp');
      }
    });
  }

  void _validateTglLahir() {
    setState(() {
      if (_tglLahir.text.trim().isNotEmpty) {
        final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
        if (!dateRegex.hasMatch(_tglLahir.text.trim())) {
          _errors['tglLahir'] = 'Format tanggal harus YYYY-MM-DD';
        } else {
          _errors.remove('tglLahir');
        }
      } else {
        _errors.remove('tglLahir');
      }
    });
  }

  void _onGenderChanged(String? val) {
    setState(() {
      _jk = val;
      if (val == null || val.isEmpty) {
        _errors['jenisKelamin'] = 'Jenis kelamin harus dipilih';
      } else {
        _errors.remove('jenisKelamin');
      }
    });
  }

  bool _isFormValid() {
    if (_username.text.isEmpty ||
        _email.text.isEmpty ||
        _password.text.isEmpty ||
        _nama.text.isEmpty ||
        _nik.text.isEmpty ||
        _jk == null) {
      return false;
    }
    return _errors.isEmpty;
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(1900);
    final lastDate = now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000, 1, 1),
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        final monthStr = pickedDate.month.toString().padLeft(2, '0');
        final dayStr = pickedDate.day.toString().padLeft(2, '0');
        _tglLahir.text = '${pickedDate.year}-$monthStr-$dayStr';
      });
    }
  }

  Future<void> _submit() async {
    if (_loading) return;

    // Trigger validation on all fields
    _validateUsername();
    _validateEmail();
    _validatePassword();
    _validateNama();
    _validateNIK();
    _validateNoHp();
    _validateTglLahir();
    _onGenderChanged(_jk);

    if (_errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan periksa kembali formulir Anda')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _isNetworkError = false;
    });

    final username = _username.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    final nama = _nama.text.trim();
    final nik = _nik.text.trim();
    final noHp = _noHp.text.trim();
    final alamat = _alamat.text.trim();
    final tglLahir = _tglLahir.text.trim().isEmpty ? null : _tglLahir.text.trim();

    try {
      // API Registration call
      final res = await _registerApi.registerPasien(
        username: username,
        email: email,
        password: password,
        nik: nik,
        nama: nama,
        jenisKelamin: _jk!,
        tglLahir: tglLahir,
        alamat: alamat.isEmpty ? null : alamat,
        noTelepon: noHp.isEmpty ? null : noHp,
      );

      // Auto Login with token returned
      final token = res['token'] as String?;
      if (token != null) {
        final storage = TokenStorage();
        await storage.saveToken(token);
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on DioException catch (e) {
      if (!mounted) return;
      final apiErrors = ApiErrorMapper.mapErrorToFields(e);
      setState(() {
        _errors.addAll(apiErrors);
        _isNetworkError = ApiErrorMapper.isNetworkError(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errors['_form'] = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top navigation / back button row
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 1,
                    shadowColor: AppColors.textPrimary.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Google-inspired clinical illustration circle
              Center(
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Decorative background circle inside
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                      ),
                      // Main person add icon
                      const Icon(
                        Icons.person_add_rounded,
                        color: AppColors.primary,
                        size: 56,
                      ),
                      // Floating bubble 1
                      Positioned(
                        top: 24,
                        right: 28,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Floating bubble 2
                      Positioned(
                        bottom: 28,
                        left: 24,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title and Subtitle
              Center(
                child: Column(
                  children: [
                    Text(
                      'Daftar Akun Baru',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lengkapi profil Anda untuk membuat akun pasien',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Network Error Alerts
              if (_isNetworkError)
                _buildAlertBanner(
                  icon: Icons.wifi_off_rounded,
                  message: 'Koneksi internet bermasalah. Periksa koneksi Anda.',
                  color: Colors.orange,
                ),

              // Form Level Errors
              if (_errors.containsKey('_form'))
                _buildAlertBanner(
                  icon: Icons.error_outline_rounded,
                  message: _errors['_form']!,
                  color: Colors.red,
                ),

              // CARD 1: INFORMASI AKUN
              Card(
                elevation: 1,
                shadowColor: AppColors.textPrimary.withValues(alpha: 0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.vpn_key_outlined, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Informasi Akun',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 0.8),
                      
                      // Username
                      ValidatedTextField(
                        controller: _username,
                        label: 'Username',
                        hint: 'Pilih username unik',
                        errorText: _errors['username'],
                        enabled: !_loading,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),

                      // Email
                      ValidatedTextField(
                        controller: _email,
                        label: 'Email',
                        hint: 'Contoh: email@anda.com',
                        keyboardType: TextInputType.emailAddress,
                        errorText: _errors['email'],
                        enabled: !_loading,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),

                      // Password
                      ValidatedTextField(
                        controller: _password,
                        label: 'Password',
                        hint: 'Minimal 6 karakter',
                        obscureText: _obscurePassword,
                        errorText: _errors['password'],
                        enabled: !_loading,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // CARD 2: INFORMASI PRIBADI
              Card(
                elevation: 1,
                shadowColor: AppColors.textPrimary.withValues(alpha: 0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.assignment_ind_outlined, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Informasi Pribadi',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 0.8),

                      // Nama Lengkap
                      ValidatedTextField(
                        controller: _nama,
                        label: 'Nama Lengkap',
                        hint: 'Masukkan nama sesuai KTP',
                        errorText: _errors['nama'],
                        enabled: !_loading,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),

                      // NIK
                      ValidatedTextField(
                        controller: _nik,
                        label: 'NIK (Nomor Induk Kependudukan)',
                        hint: '16 digit angka KTP',
                        keyboardType: TextInputType.number,
                        errorText: _errors['nik'],
                        enabled: !_loading,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.credit_card_outlined, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),

                      // Jenis Kelamin
                      ValidatedDropdown<String>(
                        value: _jk,
                        label: 'Jenis Kelamin',
                        hint: 'Pilih jenis kelamin',
                        errorText: _errors['jenisKelamin'],
                        enabled: !_loading,
                        items: const [
                          DropdownMenuItem(value: 'L', child: Text('Laki-laki (L)')),
                          DropdownMenuItem(value: 'P', child: Text('Perempuan (P)')),
                        ],
                        onChanged: _onGenderChanged,
                      ),
                      const SizedBox(height: 16),

                      // Tanggal Lahir (with DatePicker modal)
                      ValidatedTextField(
                        controller: _tglLahir,
                        label: 'Tanggal Lahir',
                        hint: 'Pilih Tanggal Lahir',
                        readOnly: true,
                        errorText: _errors['tglLahir'],
                        enabled: !_loading,
                        onTap: () => _selectDate(context),
                        prefixIcon: const Icon(Icons.calendar_month_outlined, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),

                      // No HP
                      ValidatedTextField(
                        controller: _noHp,
                        label: 'No. Telepon (Opsional)',
                        hint: 'Contoh: 081234567890',
                        keyboardType: TextInputType.phone,
                        errorText: _errors['noHp'],
                        enabled: !_loading,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),

                      // Alamat
                      ValidatedTextField(
                        controller: _alamat,
                        label: 'Alamat Tempat Tinggal (Opsional)',
                        hint: 'Masukkan alamat lengkap Anda',
                        enabled: !_loading,
                        textInputAction: TextInputAction.done,
                        prefixIcon: const Icon(Icons.home_outlined, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Register Button
              LoadingButton(
                isLoading: _loading,
                text: 'Daftar Akun',
                loadingText: 'Mendaftarkan akun...',
                onPressed: _isFormValid() ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 36),

              // Back to Login text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sudah memiliki akun? ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (!_loading) {
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      'Masuk Sekarang',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertBanner({
    required IconData icon,
    required String message,
    required MaterialColor color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
