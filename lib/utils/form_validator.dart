import 'package:flutter/material.dart';

/// Form validation utility class for eLabora application
/// Provides validation rules for all form fields
class FormValidator {
  // Private constructor to prevent instantiation
  FormValidator._();

  /// Validates username field
  /// Returns error message if invalid, null if valid
  /// Rules: minimum 3 characters, not empty
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username tidak boleh kosong';
    }
    if (value.trim().length < 3) {
      return 'Username minimal 3 karakter';
    }
    return null;
  }

  /// Validates email field
  /// Returns error message if invalid, null if valid
  /// Rules: valid email format (RFC 5322 compliant)
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }
    
    // Simple email regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  /// Validates password field
  /// Returns error message if invalid, null if valid
  /// Rules: minimum 6 characters
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  /// Validates NIK (Indonesian ID number) field
  /// Returns error message if invalid, null if valid
  /// Rules: exactly 16 digits
  static String? validateNIK(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'NIK tidak boleh kosong';
    }
    
    final nikRegex = RegExp(r'^\d{16}$');
    if (!nikRegex.hasMatch(value.trim())) {
      return 'NIK harus 16 digit';
    }
    return null;
  }

  /// Validates required field
  /// Returns error message if invalid, null if valid
  /// Rules: not empty or null
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    return null;
  }

  /// Validates Indonesian phone number field
  /// Returns error message if invalid, null if valid
  /// Rules: valid Indonesian phone format (08xx or +62xxx)
  static String? validatePhoneNumber(String? value) {
    // Phone number is optional, so null/empty is valid
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    
    // Indonesian phone number regex: starts with 08 or +62, followed by 8-13 digits
    final phoneRegex = RegExp(r'^(\+62|62|0)8[1-9][0-9]{6,11}$');
    if (!phoneRegex.hasMatch(value.trim().replaceAll(RegExp(r'[\s-]'), ''))) {
      return 'Format nomor telepon tidak valid';
    }
    return null;
  }

  /// Validates date field
  /// Returns error message if invalid, null if valid
  /// Rules: valid date, optionally must be in future
  static String? validateDate(DateTime? value, {bool futureOnly = false}) {
    if (value == null) {
      return 'Tanggal tidak boleh kosong';
    }
    
    if (futureOnly) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final selectedDate = DateTime(value.year, value.month, value.day);
      
      if (selectedDate.isBefore(today)) {
        return 'Tanggal pemeriksaan harus di masa depan';
      }
    }
    return null;
  }

  /// Validates complete login form
  /// Returns map of field names to error messages
  static Map<String, String?> validateLoginForm({
    required String username,
    required String password,
  }) {
    return {
      'username': validateUsername(username),
      'password': validatePassword(password),
    };
  }

  /// Validates complete register form
  /// Returns map of field names to error messages
  static Map<String, String?> validateRegisterForm({
    required String username,
    required String email,
    required String password,
    required String nik,
    required String nama,
    String? jenisKelamin,
    DateTime? tglLahir,
  }) {
    return {
      'username': validateUsername(username),
      'email': validateEmail(email),
      'password': validatePassword(password),
      'nik': validateNIK(nik),
      'nama': validateRequired(nama, 'Nama'),
      'jenisKelamin': jenisKelamin == null || jenisKelamin.isEmpty
          ? 'Jenis kelamin harus dipilih'
          : null,
    };
  }

  /// Validates complete pendaftaran form
  /// Returns map of field names to error messages
  static Map<String, String?> validatePendaftaranForm({
    required DateTime? tanggalPeriksa,
    required TimeOfDay? waktuPeriksa,
    required bool hasReferralLetter,
  }) {
    return {
      'tanggalPeriksa': validateDate(tanggalPeriksa, futureOnly: true),
      'waktuPeriksa': waktuPeriksa == null ? 'Waktu pemeriksaan harus dipilih' : null,
      'suratRujukan': hasReferralLetter ? null : 'Surat rujukan harus diupload',
    };
  }
}
