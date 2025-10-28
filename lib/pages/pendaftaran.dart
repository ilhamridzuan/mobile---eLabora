import 'package:flutter/material.dart';

class PendaftaranPage extends StatefulWidget {
  const PendaftaranPage({super.key});

  @override
  State<PendaftaranPage> createState() => _PendaftaranPageState();
}

class _PendaftaranPageState extends State<PendaftaranPage> {
  final _formKey = GlobalKey<FormState>();
  String? _jenisKelamin;
  DateTime? _tanggalLahir;
  DateTime? _tanggalPeriksa;
  TimeOfDay? _waktuPeriksa;

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
                'Isi formulir di bawah ini untuk mendaftar pemeriksaan laboratorium',
                style: text.bodyMedium,
              ),
              const SizedBox(height: 28),
              Text(
                'Data Pasien',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
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
                decoration: const InputDecoration(hintText: 'Masukkan NIK'),
              ),
              const SizedBox(height: 14),
              Text(
                'Tanggal Lahir *',
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
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
                  if (picked != null) setState(() => _tanggalLahir = picked);
                },
              ),
              const SizedBox(height: 14),
              Text(
                'Jenis Kelamin *',
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _jenisKelamin,
                decoration: const InputDecoration(
                  hintText: 'Pilih jenis kelamin',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Laki-laki',
                    child: Text('Laki-laki'),
                  ),
                  DropdownMenuItem(
                    value: 'Perempuan',
                    child: Text('Perempuan'),
                  ),
                ],
                onChanged: (v) => setState(() => _jenisKelamin = v),
              ),
              const SizedBox(height: 14),

              Text(
                'No. Telepon *',
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '08xxxxxxxxxx'),
              ),
              const SizedBox(height: 14),

              Text(
                'Email',
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'email@example.com',
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Alamat',
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Masukkan alamat lengkap',
                ),
              ),
              const SizedBox(height: 28),

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
                    firstDate: DateTime(1950),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _tanggalPeriksa = picked);
                },
              ),
              const SizedBox(height: 14),

              Text(
                'Waktu Pemeriksaan',
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Pilih waktu pemeriksaan',
                  suffixIcon: Icon(
                    Icons.access_time_outlined,
                    color: color.primary,
                  ),
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) setState(() => _waktuPeriksa = picked);
                },
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Pendaftaran berhasil! Mengalihkan ke halaman antrian...',
                          style: text.bodyMedium?.copyWith(
                            color: color.onPrimary,
                          ),
                        ),
                        backgroundColor: color.primary,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                    Future.delayed(const Duration(seconds: 1), () {
                      Navigator.pushReplacementNamed(context, '/antrian');
                    });
                  },
                  child: const Text('Daftar Sekarang'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
