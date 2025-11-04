import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import 'login_screen.dart';
import 'user_profile_screen.dart';
import '../models/lesson_model.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';




class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    Provider.of<UserProvider>(context, listen: false).loadUserData();
    Provider.of<LessonProvider>(context, listen: false).fetchLessons();
  });
}
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final lessonProvider = Provider.of<LessonProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFD3E3EA),
      endDrawer: _DashboardDrawer(
        onLogout: () async {
          await authProvider.logout();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        },
        onUserProfile: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UserProfileScreen()),
          );
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B4267).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white, size: 40),
                          onPressed: () => Scaffold.of(context).openEndDrawer(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Search Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCE0EA),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 28, color: Colors.black54),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search bar',
                            border: InputBorder.none,
                            hintStyle: TextStyle(fontSize: 20, color: Colors.black54),
                          ),
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 28, color: Colors.black54),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Explore lessons header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Explore lessons',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Arial',
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 20,
                          color: Color(0xFF2B4267),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Dynamic lesson cards
                if (lessonProvider.isLoading)
                  const Center(child: CircularProgressIndicator()),
                if (lessonProvider.error != null)
                  Center(child: Text(lessonProvider.error!)),
                if (!lessonProvider.isLoading && lessonProvider.error == null)
                  Column(
                    children: lessonProvider.lessons.map((lesson) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () async {
                          final play = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Play Lesson'),
                              content: const Text('Do you want to play this lesson?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Play'),
                                ),
                              ],
                            ),
                          );
                          if (play == true) {
                            // Show loading screen for 1 second
                            await showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const _LoadingDialog(),
                            );
                            // Force landscape
                            await SystemChrome.setPreferredOrientations([
                              DeviceOrientation.landscapeLeft,
                              DeviceOrientation.landscapeRight,
                            ]);
                            await showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => QuizDialog(lesson: lesson),
                            );
                            // Restore orientation
                            await SystemChrome.setPreferredOrientations([
                              DeviceOrientation.portraitUp,
                              DeviceOrientation.portraitDown,
                            ]);
                          }
                        },
                        child: _LessonCard(
                          lesson: lesson,
                          onEdit: () async {
                            final result = await showDialog<Lesson>(
                              context: context,
                              builder: (context) => AddLessonDialog(lesson: lesson),
                            );
                            if (result != null) {
                              await Provider.of<LessonProvider>(context, listen: false).updateLesson(result);
                            }
                          },
                          onDelete: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Lesson'),
                                content: const Text('Are you sure you want to delete this lesson?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await Provider.of<LessonProvider>(context, listen: false).deleteLesson(lesson.id!);
                            }
                          },
                        ),
                      ),
                    )).toList(),
                  ),
                const SizedBox(height: 32),
                // Floating plus button
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B4267),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white, size: 48),
                      onPressed: () async {
                        final result = await showDialog<Lesson>(
                          context: context,
                          builder: (context) => const AddLessonDialog(),
                        );
                        if (result != null) {
                          await Provider.of<LessonProvider>(context, listen: false).addLesson(result);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LessonCard({
    required this.lesson,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFCCE0EA),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  lesson.code,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF2B4267),
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lesson.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 32,
              color: Color(0xFF2B4267),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lesson.teacher,
            style: const TextStyle(
              fontSize: 20,
              color: Color(0xFF5A6B7A),
            ),
          ),
        ],
      ),
    );
  }
}

// Drawer widget
class _DashboardDrawer extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onUserProfile;

  const _DashboardDrawer({
    required this.onLogout,
    required this.onUserProfile,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    return Drawer(
      backgroundColor: const Color(0xFF2B4267),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Menu icon (for symmetry, not functional)
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 24.0),
                child: Icon(Icons.menu, color: Colors.white, size: 36),
              ),
            ),
            const SizedBox(height: 24),
            // Profile image
            CircleAvatar(
              radius: 70,
              backgroundColor: Colors.white,
              backgroundImage: user != null ? NetworkImage(user.profileImageUrl) : null,
              child: user == null
                  ? const Icon(Icons.person, size: 70, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 24),
            // User name
            Text(
              user?.name ?? 'Loading...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                fontFamily: 'Serif',
              ),
            ),
            const SizedBox(height: 24),
            // User Details button
            _DrawerButton(
              text: 'User Profile',
              onTap: onUserProfile,
            ),
            const SizedBox(height: 32),
            // Settings button
            _DrawerButton(
              text: 'Settings',
              onTap: () {
                // Navigate to settings
              },
            ),
            const SizedBox(height: 24),
            // Help & Support button
            _DrawerButton(
              text: 'Help & Support',
              onTap: () {
                // Navigate to help & support
              },
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _DrawerButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color? textColor;

  const _DrawerButton({
    required this.text,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF9CB3C9),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: textColor ?? const Color(0xFF2B4267),
                fontSize: 26,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// AddLessonDialog widget
class AddLessonDialog extends StatefulWidget {
  final Lesson? lesson;
  const AddLessonDialog({Key? key, this.lesson}) : super(key: key);

  @override
  State<AddLessonDialog> createState() => _AddLessonDialogState();
}

class _AddLessonDialogState extends State<AddLessonDialog> {
  int _step = 0;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _titleController;
  late TextEditingController _teacherController;
  late List<TextEditingController> _questionControllers;
  late List<TextEditingController> _answerControllers;
  bool _posted = false;

  @override
  void initState() {
    super.initState();
    _step = 0; // Always start at step 0 for new or edit
    _codeController = TextEditingController(text: widget.lesson?.code ?? '');
    _titleController = TextEditingController(text: widget.lesson?.title ?? '');
    _teacherController = TextEditingController(text: widget.lesson?.teacher ?? '');
    _questionControllers = (widget.lesson?.questions.isNotEmpty ?? false)
      ? widget.lesson!.questions.map((q) => TextEditingController(text: q.text)).toList()
      : [TextEditingController()];
    _answerControllers = (widget.lesson?.questions.isNotEmpty ?? false)
      ? widget.lesson!.questions.map((q) => TextEditingController(text: q.answer)).toList()
      : [TextEditingController()];
  }

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _teacherController.dispose();
    for (var c in _questionControllers) {
      c.dispose();
    }
    for (var c in _answerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _nextStep() {
    setState(() => _step++);
  }

  void _prevStep() {
    setState(() => _step--);
  }

  void _resetDialog() {
    setState(() {
      _step = 0;
      _codeController.clear();
      _titleController.clear();
      _teacherController.clear();
      _questionControllers = [TextEditingController()];
      _answerControllers = [TextEditingController()];
      _posted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 350,
          child: [
            _buildStep1(),
            _buildStep2(),
            _buildStep3(),
            _buildStep4(),
            _buildStep5(),
          ][_step],
        ),
      ),
    );
  }

  Widget _buildStep1() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('Course Info', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      TextField(controller: _codeController, decoration: const InputDecoration(labelText: 'Course Code')),
      TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Topic Name')),
      TextField(controller: _teacherController, decoration: const InputDecoration(labelText: 'Prof Name (Optional)')),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            if (_codeController.text.isNotEmpty && _titleController.text.isNotEmpty) {
              _nextStep();
            }
          }, child: const Text('Proceed')),
        ],
      ),
    ],
  );

  Widget _buildStep2() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('Questions', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      ..._questionControllers.asMap().entries.map((entry) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            controller: entry.value,
            decoration: InputDecoration(labelText: 'Question ${entry.key + 1}'),
          ),
        ),
      ),
      TextButton(
        onPressed: () {
          setState(() => _questionControllers.add(TextEditingController()));
        },
        child: const Text('Add more'),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(onPressed: _prevStep, child: const Text('Back')),
          ElevatedButton(onPressed: () {
            if (_questionControllers.any((c) => c.text.isNotEmpty)) {
              if (_answerControllers.length < _questionControllers.length) {
                _answerControllers = List.generate(_questionControllers.length, (i) => i < _answerControllers.length ? _answerControllers[i] : TextEditingController());
              }
              _nextStep();
            }
          }, child: const Text('Done')),
        ],
      ),
    ],
  );

  Widget _buildStep3() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('Answers', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      ..._answerControllers.asMap().entries.map((entry) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            controller: entry.value,
            decoration: InputDecoration(labelText: 'Answer for Q${entry.key + 1}'),
          ),
        ),
      ),
      TextButton(
        onPressed: () {
          setState(() => _answerControllers.add(TextEditingController()));
        },
        child: const Text('Add more'),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(onPressed: _prevStep, child: const Text('Back')),
          ElevatedButton(onPressed: () {
            if (_answerControllers.any((c) => c.text.isNotEmpty)) {
              _nextStep();
            }
          }, child: const Text('Done')),
        ],
      ),
    ],
  );

  Widget _buildStep4() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('Save or Post', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: () async {
          // Collect questions/answers
          final questions = <Question>[];
          for (int i = 0; i < _questionControllers.length; i++) {
            final q = _questionControllers[i].text.trim();
            final a = (i < _answerControllers.length) ? _answerControllers[i].text.trim() : '';
            if (q.isNotEmpty && a.isNotEmpty) {
              questions.add(Question(text: q, answer: a));
            }
          }
          final lesson = Lesson(
            id: widget.lesson?.id,
            code: _codeController.text.trim(),
            title: _titleController.text.trim(),
            teacher: _teacherController.text.trim(),
            questions: questions,
          );
          final prefs = await SharedPreferences.getInstance();
          final saved = prefs.getStringList('saved_lessons') ?? [];
          final updated = List<String>.from(saved)..add(jsonEncode(lesson.toJson()));
          await prefs.setStringList('saved_lessons', updated);
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Saved'),
                content: const Text('Lesson saved to phone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        },
        child: const Text('Save to Phone'),
      ),
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: () {
          // Collect questions/answers
          final questions = <Question>[];
          for (int i = 0; i < _questionControllers.length; i++) {
            final q = _questionControllers[i].text.trim();
            final a = (i < _answerControllers.length) ? _answerControllers[i].text.trim() : '';
            if (q.isNotEmpty && a.isNotEmpty) {
              questions.add(Question(text: q, answer: a));
            }
          }
          final lesson = Lesson(
            id: widget.lesson?.id,
            code: _codeController.text.trim(),
            title: _titleController.text.trim(),
            teacher: _teacherController.text.trim(),
            questions: questions,
          );
          Navigator.pop(context, lesson);
        },
        child: Text(widget.lesson == null ? 'Post Online' : 'Update Online'),
      ),
      const SizedBox(height: 12),
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
    ],
  );

  Widget _buildStep5() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Posted successfully!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    ),
  );
}

// Add QuizDialog widget
class QuizDialog extends StatefulWidget {
  final Lesson lesson;
  const QuizDialog({Key? key, required this.lesson}) : super(key: key);

  @override
  State<QuizDialog> createState() => _QuizDialogState();
}

class _QuizDialogState extends State<QuizDialog> {
  int _current = 0;
  int _score = 0;
  bool? _isCorrect;
  bool _showResult = false;
  bool _showFeedback = false;
  List<String> _userAnswers = [];

  @override
  void initState() {
    super.initState();
    _userAnswers = [];
  }

  void _handleSwipe(bool right) {
    final q = widget.lesson.questions[_current];
    final isCorrect = right;
    setState(() {
      _isCorrect = isCorrect;
      if (isCorrect) _score++;
      _showFeedback = true;
      _userAnswers.add(right ? 'Correct' : 'Incorrect');
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (_current < widget.lesson.questions.length - 1) {
        setState(() {
          _current++;
          _isCorrect = null;
          _showFeedback = false;
        });
      } else {
        setState(() {
          _showResult = true;
          _showFeedback = false;
        });
      }
    });
  }

  void _tryAgain() {
    setState(() {
      _current = 0;
      _score = 0;
      _isCorrect = null;
      _showResult = false;
      _showFeedback = false;
      _userAnswers = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showResult) {
      final passed = _score >= (widget.lesson.questions.length / 2).ceil();
      return Dialog(
        child: Container(
          color: const Color(0xFF2B4267),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: const Color(0xFFB0C4DE),
                padding: const EdgeInsets.all(16),
                child: Text('TOTAL SCORE: $_score/${widget.lesson.questions.length}', style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(height: 24),
              Text(passed ? 'YOU PASSED!' : 'NICE TRY!', style: const TextStyle(fontSize: 32, color: Colors.white, fontFamily: 'Serif')),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _tryAgain,
                    child: const Text('Try Again'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Exit'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => _ReviewDialog(
                          questions: widget.lesson.questions,
                          userAnswers: _userAnswers,
                        ),
                      );
                    },
                    child: const Text('Review'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    final q = widget.lesson.questions[_current];
    if (_showFeedback) {
      return Dialog(
        child: Container(
          color: _isCorrect! ? Colors.green : Colors.red,
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              _isCorrect! ? 'GREAT JOB!\n(Correct)' : 'BETTER LUCK NEXT TIME!\n(Incorrect)',
              style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return Dialog(
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! > 0) {
              _handleSwipe(true); // Right swipe = correct
            } else if (details.primaryVelocity! < 0) {
              _handleSwipe(false); // Left swipe = incorrect
            }
          }
        },
        child: Container(
          color: const Color(0xFF2B4267),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFFB0C4DE),
                child: Text(q.text, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(height: 24),
              const Text('Swipe right for Correct, left for Incorrect', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

// Add _LoadingDialog widget
class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).pop();
    });
    return Dialog(
      child: Container(
        color: const Color(0xFF2B4267),
        padding: const EdgeInsets.all(32),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

// Add _ReviewDialog widget
class _ReviewDialog extends StatelessWidget {
  final List<Question> questions;
  final List<String> userAnswers;
  const _ReviewDialog({Key? key, required this.questions, required this.userAnswers}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        color: const Color(0xFF2B4267),
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxHeight: 400, minWidth: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Review', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...List.generate(questions.length, (i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Q: ${questions[i].text}\nYour Answer: ${userAnswers.length > i ? userAnswers[i] : ''}\nCorrect: Correct',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
} 