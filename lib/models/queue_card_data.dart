/// Data model for Queue Card display
class QueueCardData {
  final String noAntrian;
  final String noLab;
  final String namaPasien;
  final DateTime tanggalAntrian;
  final DateTime jadwalPemeriksaan;

  QueueCardData({
    required this.noAntrian,
    required this.noLab,
    required this.namaPasien,
    required this.tanggalAntrian,
    required this.jadwalPemeriksaan,
  });

  /// Factory constructor to create QueueCardData from API response
  factory QueueCardData.fromApiResponse(
    Map<String, dynamic> response,
    String namaPasien,
  ) {
    return QueueCardData(
      noAntrian: response['no_antrian']?.toString() ?? '',
      noLab: response['no_lab']?.toString() ?? '',
      namaPasien: namaPasien,
      tanggalAntrian: _parseDateTime(response['tanggal_antrian']),
      jadwalPemeriksaan: _parseDateTime(response['jadwal_pemeriksaan_at']),
    );
  }

  /// Helper method to parse DateTime from various formats
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    
    if (value is DateTime) return value;
    
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      return DateTime.now();
    }
  }
}
