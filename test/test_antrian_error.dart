import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:io';

void main() {
  test('Debug antrian load logic', () async {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://elabora-api.azurewebsites.net',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    final randomNum = DateTime.now().millisecondsSinceEpoch % 10000;
    final username = 'tester$randomNum';
    final email = 'tester$randomNum@mail.com';

    try {
      print('1. Registering patient $username...');
      final regRes = await dio.post('/auth/register', data: {
        'username': username,
        'email': email,
        'password': 'P@ssword123!',
        'nik': '123456789012${randomNum.toString().padLeft(4, '0')}',
        'nama': 'Tester $randomNum',
        'jenis_kelamin': 'L',
        'tgl_lahir': '1995-05-15',
        'alamat': 'Test Alamat',
        'no_telepon': '0812345${randomNum.toString().padLeft(4, '0')}',
      });

      print('Register status: ${regRes.statusCode}');
      
      // Extract token from registration response or log in
      print('2. Logging in as $username...');
      final loginRes = await dio.post('/auth/login', data: {
        'username': username,
        'password': 'P@ssword123!',
      });
      
      final token = loginRes.data['token'];
      print('Login successful! Token: $token');
      
      dio.options.headers['Authorization'] = 'Bearer $token';

      // Get profile info
      print('\n3. Getting user profile...');
      final meRes = await dio.get('/auth/me');
      print('Profile info: ${jsonEncode(meRes.data)}');
      final profil = meRes.data['profil'];
      final pasienId = profil != null ? profil['id'] : null;
      print('Profile Pasien ID: $pasienId');

      // Create a dummy referral file
      final dummyFile = File('dummy_rujukan_test.pdf');
      await dummyFile.writeAsString('Dummy PDF content');

      // Create a registration for today
      final now = DateTime.now();
      final yyyyMmDd = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final jadwal = '$yyyyMmDd 11:00:00+07:00';

      print('\n4. Creating queue registration for today: $yyyyMmDd...');
      final createRes = await dio.post(
        '/registrations/',
        data: FormData.fromMap({
          'tanggal_antrian': yyyyMmDd,
          'jadwal_pemeriksaan_at': jadwal,
          'surat_rujukan': await MultipartFile.fromFile(
            dummyFile.path,
            filename: 'dummy_rujukan_test.pdf',
          ),
        }),
        options: Options(contentType: 'multipart/form-data'),
      );

      print('Registration response: ${jsonEncode(createRes.data)}');

      // Query /queue/today
      print('\n5. Querying /queue/today for date: $yyyyMmDd...');
      final queueRes = await dio.get('/queue/today?date=$yyyyMmDd');
      print('Queue Today Response: ${jsonEncode(queueRes.data)}');

      final queueData = queueRes.data['data'] as List?;
      if (queueData != null) {
        print('Number of items in queue: ${queueData.length}');
        for (var i = 0; i < queueData.length; i++) {
          final item = queueData[i];
          final itemPasienId = item['pasien_id'];
          final itemNoAntrian = item['no_antrian'];
          print('Item #$i: No Antrian = $itemNoAntrian, Pasien ID = $itemPasienId');
          
          if (itemPasienId == pasienId) {
            print('-> SUCCESS: Found user queue entry matching patient ID $pasienId!');
          }
        }
      } else {
        print('-> WARNING: No queue list returned or it is null.');
      }

      // Cleanup
      if (await dummyFile.exists()) {
        await dummyFile.delete();
      }
    } catch (e) {
      print('ERROR encountered during debug test: $e');
      if (e is DioException) {
        print('Dio response data: ${e.response?.data}');
      }
      fail(e.toString());
    }
  });
}
