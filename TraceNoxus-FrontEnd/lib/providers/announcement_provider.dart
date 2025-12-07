import 'package:flutter/material.dart';
import '../models/announcement_model.dart';
import '../services/announcement_service.dart';

class AnnouncementProvider with ChangeNotifier {
  final AnnouncementService _announcementService = AnnouncementService();
  List<Announcement> _announcements = [];
  bool _isLoading = false;
  String? _error;

  List<Announcement> get announcements => _announcements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAnnouncements() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _announcements = await _announcementService.getAnnouncements();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAnnouncement(String title, String content) async {
    try {
      final newAnnouncement = await _announcementService.createAnnouncement(title, content);
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
