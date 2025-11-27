import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';

class EventProvider with ChangeNotifier {
  final EventService _eventService = EventService();
  List<EventModel> _events = [];
  bool _isLoading = false;
  String? _error;

  List<EventModel> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _events = await _eventService.fetchEvents();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createEvent(Map<String, dynamic> eventData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newEvent = await _eventService.createEvent(eventData);
      _events.add(newEvent);
      // Sort events by date and time? Or rely on backend order?
      // Backend orders by date, time. But we just appended.
      // For now, appending is fine, or we can re-fetch.
      // Let's re-fetch to be safe and get correct order, or just insert and sort.
      // Re-fetching is safer but slower. Let's just append for now.
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateEvent(int id, Map<String, dynamic> eventData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedEvent = await _eventService.updateEvent(id, eventData);
      final index = _events.indexWhere((e) => e.id == id);
      if (index != -1) {
        _events[index] = updatedEvent;
      }
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<EventModel> getEventsForDate(DateTime date) {
    return _events.where((event) {
      // Parse event.date (YYYY-MM-DD) and compare
      // Assuming event.date is "YYYY-MM-DD"
      // We can compare strings if we format the date
      final dateString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      return event.date == dateString;
    }).toList();
  }
}
