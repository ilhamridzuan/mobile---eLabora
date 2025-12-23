import 'package:flutter/material.dart';
import '../data/api_client.dart';
import '../data/register_api.dart';
import '../data/token_storage.dart'; 

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
  bool _loading = false;

  late final RegisterApi _registerApi;

  @override
  void initState() {
    super.initState();
    _registerApi = RegisterApi(ApiClient());
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

  bool _isValidDate(String s) {
    final r = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    return r.hasMatch(s);
  }

  Future<void> _submit() async {
    if (_loading) return;

    final username = _username.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    final nama = _nama.text.trim();
    final nik = _nik.text.trim();
    final noHp = _noHp.text.trim();
    final alamat = _alamat.text.trim();
    final tglLahir = _tglLahir.text.trim().isEmpty
        ? null
        : _tglLahir.text.trim();

    // ===== VALIDASI =====
    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        nama.isEmpty ||
        nik.isEmpty ||
        _jk == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Field wajib: username, email, password, nik, nama, jenis kelamin',
          ),
        ),
      );
      return;
    }

    if (nik.length != 16) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('NIK harus 16 digit')));
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password minimal 6 karakter')),
      );
      return;
    }

    if (tglLahir != null && !_isValidDate(tglLahir)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format tgl lahir harus YYYY-MM-DD')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // ===== REGISTER =====
      final res = await _registerApi.registerPasien(
        username: username,
        email: email,
        password: password,
        nik: nik,
        nama: nama,
        jenisKelamin: _jk!, // "L" / "P"
        tglLahir: tglLahir,
        alamat: alamat.isEmpty ? null : alamat,
        noTelepon: noHp.isEmpty ? null : noHp,
      );

      // ===== AUTO LOGIN =====
      final token = res['token'] as String?;
      if (token != null) {
        final storage = TokenStorage();
        await storage.saveToken(token);
      }

      if (!mounted) return;

      // langsung masuk ke HOME
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun (Pasien)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _username,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password (min 6)'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _nama,
            decoration: const InputDecoration(labelText: 'Nama'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _nik,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'NIK (16 digit)'),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: _jk,
            decoration: const InputDecoration(labelText: 'Jenis Kelamin'),
            items: const [
              DropdownMenuItem(value: 'L', child: Text('Laki-laki (L)')),
              DropdownMenuItem(value: 'P', child: Text('Perempuan (P)')),
            ],
            onChanged: (v) => setState(() => _jk = v),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _tglLahir,
            decoration: const InputDecoration(
              labelText: 'Tanggal Lahir (YYYY-MM-DD) (opsional)',
              hintText: '2004-01-31',
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _noHp,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'No Telepon (opsional)',
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _alamat,
            decoration: const InputDecoration(labelText: 'Alamat (opsional)'),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? 'Loading...' : 'Daftar'),
            ),
          ),
        ],
      ),
    );
  }
}
