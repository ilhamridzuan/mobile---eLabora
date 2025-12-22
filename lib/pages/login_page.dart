import 'package:flutter/material.dart';
import '../data/api_client.dart';
import '../data/auth_api.dart';
import '../data/token_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  late final AuthApi _authApi;

  @override
  void initState() {
    super.initState();
    final client = ApiClient();
    _authApi = AuthApi(client);
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    if (_loading) return;

    final username = _username.text.trim();
    final password = _password.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username dan password wajib diisi')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await _authApi.login(
        username: username,
        password: password,
      );

      final token = result['token'] as String?;
      final role = result['role'] as String?;

      if (token == null || role == null) {
        throw Exception('Login gagal: data tidak lengkap');
      }

      // simpan token
      final storage = TokenStorage();
      await storage.saveToken(token);

      if (!mounted) return;

      if (role == 'DOKTER') {
        Navigator.pushReplacementNamed(context, '/doctor_home');
      } else if (role == 'PASIEN') {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        throw Exception('Role tidak dikenali');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _username,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              onSubmitted: (_) => _doLogin(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _doLogin,
                child: Text(_loading ? 'Loading...' : 'Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
