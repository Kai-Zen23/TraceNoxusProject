import 'package:flutter/material.dart';
import '../models/announcement_model.dart';
import '../services/announcement_service.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AnnouncementProvider with ChangeNotifier {
  final AnnouncementService _announcementService = AnnouncementService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<Announcement> _announcements = [];
  bool _isLoading = false;
  String? _error;

  int _seenCount = 0;
  String? _userId;

  List<Announcement> get announcements => _announcements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get badgeCount =>
      (_announcements.length - _seenCount).clamp(0, _announcements.length);

  void setUserId(int id) {
    _userId = id.toString();
  }

  Future<void> markAsSeen() async {
    _seenCount = _announcements.length;
    if (_userId != null) {
      await _storage.write(
          key: 'seen_announcements_$_userId', value: _seenCount.toString());
    }
    notifyListeners();
  }

  Future<void> fetchAnnouncements() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _announcements = await _announcementService.getAnnouncements();

      if (_userId != null) {
        final savedSeen =
            await _storage.read(key: 'seen_announcements_$_userId');
        if (savedSeen != null) {
          _seenCount = int.tryParse(savedSeen) ?? 0;
        } else {
          _seenCount = 0;
        }
      }

      if (_announcements.length < _seenCount) {
        _seenCount = _announcements.length;
        if (_userId != null) {
          await _storage.write(
              key: 'seen_announcements_$_userId', value: _seenCount.toString());
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAnnouncement(String title, String content) async {
    try {
      final newAnnouncement =
          await _announcementService.createAnnouncement(title, content);
      _announcements.insert(0, newAnnouncement); // Add to top of list
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteAnnouncement(int id) async {
    try {
      await _announcementService.deleteAnnouncement(id);
      _announcements.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
