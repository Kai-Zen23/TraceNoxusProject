import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _notificationService.fetchNotifications();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendNotification(String title, String message, {int? recipientId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newNotification = await _notificationService.createNotification(title, message, recipientId: recipientId);
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
