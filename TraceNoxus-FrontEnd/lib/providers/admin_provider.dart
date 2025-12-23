import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();
  
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _dashboardStats;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;

  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _adminService.getDashboardStats();
      if (result.containsKey('error')) {
        _error = result['error'];
      } else {
        _dashboardStats = result;
      }
    } catch (e) {
      _error = 'Failed to load dashboard stats: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
