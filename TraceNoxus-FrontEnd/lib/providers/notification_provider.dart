import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  int _seenCount = 0;
  String? _userId;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get badgeCount =>
      (_notifications.length - _seenCount).clamp(0, _notifications.length);

  void setUserId(int id) {
    _userId = id.toString();
  }

  Future<void> markAsSeen() async {
    _seenCount = _notifications.length;
    if (_userId != null) {
      await _storage.write(
          key: 'seen_notifications_$_userId', value: _seenCount.toString());
    }
    notifyListeners();
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _notificationService.fetchNotifications();

      if (_userId != null) {
        final savedSeen =
            await _storage.read(key: 'seen_notifications_$_userId');
        if (savedSeen != null) {
          _seenCount = int.tryParse(savedSeen) ?? 0;
        } else {
          _seenCount = 0;
        }
      }

      if (_notifications.length < _seenCount) {
        _seenCount = _notifications.length;
        if (_userId != null) {
          await _storage.write(
              key: 'seen_notifications_$_userId', value: _seenCount.toString());
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendNotification(String title, String message,
      {int? recipientId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newNotification = await _notificationService
          .createNotification(title, message, recipientId: recipientId);
      // If we are sending to ourselves or broadcast, we might want to add it to the list locally.
      // But usually the sender doesn't receive their own notification unless it's broadcast?
      // The backend logic returns notifications where recipient=user OR recipient=null.
      // If admin sends broadcast (recipient=null), they should see it too.
      // So let's refresh the list or add it.
      // Adding it locally is faster.
      _notifications.insert(0, newNotification);
    } catch (e) {
      _error = e.toString();
      rethrow; // Let the UI handle the error display
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
