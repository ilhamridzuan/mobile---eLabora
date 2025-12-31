import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime receivedAt;
  bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    required this.receivedAt,
    this.read = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'data': data,
        'receivedAt': receivedAt.toIso8601String(),
        'read': read,
      };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        body: (j['body'] ?? '').toString(),
        data: (j['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
        receivedAt: DateTime.parse((j['receivedAt'] ?? DateTime.now().toIso8601String()).toString()),
        read: (j['read'] ?? false) as bool,
      );
}

class NotificationStore {
  static const _key = 'inbox_notifications';
  static const _maxItems = 50;

  static Future<List<AppNotification>> list() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    final arr = (jsonDecode(raw) as List).cast<dynamic>();
    final items = arr
        .map((e) => AppNotification.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    items.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return items;
  }

  static Future<void> add(AppNotification n) async {
    final items = await list();
    if (items.any((x) => x.id == n.id)) return;

    items.insert(0, n);
    if (items.length > _maxItems) items.removeRange(_maxItems, items.length);

    await _save(items);
  }

  static Future<void> markRead(String id) async {
    final items = await list();
    for (final n in items) {
      if (n.id == id) {
        n.read = true;
        break;
      }
    }
    await _save(items);
  }

  static Future<void> markAllRead() async {
    final items = await list();
    for (final n in items) {
      n.read = true;
    }
    await _save(items);
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key);
  }

  static Future<int> unreadCount() async {
    final items = await list();
    return items.where((e) => !e.read).length;
  }

  static Future<void> _save(List<AppNotification> items) async {
    final sp = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await sp.setString(_key, raw);
  }
}
