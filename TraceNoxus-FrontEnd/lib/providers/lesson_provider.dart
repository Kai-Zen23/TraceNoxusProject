import 'package:flutter/material.dart';
import '../models/lesson_model.dart';
import '../services/lesson_service.dart';

class LessonProvider extends ChangeNotifier {
  final LessonService _lessonService = LessonService();
  List<Lesson> _lessons = [];
  bool _isLoading = false;
  String? _error;

  List<Lesson> get lessons => _lessons;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchLessons() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _lessons = await _lessonService.fetchLessons();
    } catch (e) {
      _error = 'Failed to load lessons: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addLesson(Lesson lesson) async {
    await _lessonService.addLesson(lesson);
    await fetchLessons(); // Refresh the list
  }

  Future<void> updateLesson(Lesson lesson) async {
    await _lessonService.updateLesson(lesson);
    await fetchLessons(); // Refresh the list
  }

  Future<void> deleteLesson(int lessonId) async {
    await _lessonService.deleteLesson(lessonId);
    await fetchLessons(); // Refresh the list
  }
}