import 'dart:io';
import 'package:flutter/material.dart';

/// Form state model for Login page
class LoginFormState {
  final String username;
  final String password;
  final Map<String, String> errors;
  final bool isValid;
  final bool isLoading;

  LoginFormState({
    this.username = '',
    this.password = '',
    this.errors = const {},
    this.isValid = false,
    this.isLoading = false,
  });

  LoginFormState copyWith({
    String? username,
    String? password,
    Map<String, String>? errors,
    bool? isValid,
    bool? isLoading,
  }) {
    return LoginFormState(
      username: username ?? this.username,
      password: password ?? this.password,
      errors: errors ?? this.errors,
      isValid: isValid ?? this.isValid,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Form state model for Register page
class RegisterFormState {
  final String username;
  final String email;
  final String password;
  final String nik;
  final String nama;
  final String? jenisKelamin;
  final DateTime? tglLahir;
  final String? noTelepon;
  final String? alamat;
  final Map<String, String> errors;
  final bool isValid;
  final bool isLoading;

  RegisterFormState({
    this.username = '',
    this.email = '',
    this.password = '',
    this.nik = '',
    this.nama = '',
    this.jenisKelamin,
    this.tglLahir,
    this.noTelepon,
    this.alamat,
    this.errors = const {},
    this.isValid = false,
    this.isLoading = false,
  });

  RegisterFormState copyWith({
    String? username,
    String? email,
    String? password,
    String? nik,
    String? nama,
    String? jenisKelamin,
    DateTime? tglLahir,
    String? noTelepon,
    String? alamat,
    Map<String, String>? errors,
    bool? isValid,
    bool? isLoading,
  }) {
    return RegisterFormState(
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      nik: nik ?? this.nik,
      nama: nama ?? this.nama,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      tglLahir: tglLahir ?? this.tglLahir,
      noTelepon: noTelepon ?? this.noTelepon,
      alamat: alamat ?? this.alamat,
      errors: errors ?? this.errors,
      isValid: isValid ?? this.isValid,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Form state model for Pendaftaran page
class PendaftaranFormState {
  final DateTime? tanggalPeriksa;
  final TimeOfDay? waktuPeriksa;
  final File? suratRujukan;
  final String? suratRujukanName;
  final Map<String, String> errors;
  final bool isValid;
  final bool isLoading;

  PendaftaranFormState({
    this.tanggalPeriksa,
    this.waktuPeriksa,
    this.suratRujukan,
    this.suratRujukanName,
    this.errors = const {},
    this.isValid = false,
    this.isLoading = false,
  });

  PendaftaranFormState copyWith({
    DateTime? tanggalPeriksa,
    TimeOfDay? waktuPeriksa,
    File? suratRujukan,
    String? suratRujukanName,
    Map<String, String>? errors,
    bool? isValid,
    bool? isLoading,
  }) {
    return PendaftaranFormState(
      tanggalPeriksa: tanggalPeriksa ?? this.tanggalPeriksa,
      waktuPeriksa: waktuPeriksa ?? this.waktuPeriksa,
      suratRujukan: suratRujukan ?? this.suratRujukan,
      suratRujukanName: suratRujukanName ?? this.suratRujukanName,
      errors: errors ?? this.errors,
      isValid: isValid ?? this.isValid,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
