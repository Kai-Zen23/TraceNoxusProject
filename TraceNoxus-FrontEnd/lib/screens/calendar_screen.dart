import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../models/event_model.dart';
import 'create_event_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _visibleMonth = DateTime.now();
  int? _selectedDay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventProvider>(context, listen: false).fetchEvents();
    });
  }

  void _swapMonth(int offset) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + offset);
      _selectedDay = null;
    });
  }

  List<int?> _buildCalendarCells() {
    final firstDayOfMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final weekdayOffset = (firstDayOfMonth.weekday + 6) % 7; // Monday = 0
    final cells = <int?>[
      ...List<int?>.filled(weekdayOffset, null),
      ...List<int?>.generate(daysInMonth, (index) => index + 1),
    ];
    final trailing = (cells.length % 7 == 0) ? 0 : 7 - (cells.length % 7);
    cells.addAll(List<int?>.filled(trailing, null));
    return cells;
  }

  void _showSendNotificationDialog(BuildContext context, EventModel event) {
    final titleController = TextEditingController(text: 'Reminder: ${event.title}');
    final messageController = TextEditingController(text: 'Don\'t forget about ${event.title} on ${event.date} at ${event.time}!');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F3156),
        title: const Text('Send Notification', style: TextStyle(color: Colors.white)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: messageController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a message' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await Provider.of<NotificationProvider>(context, listen: false)
                      .sendNotification(titleController.text, messageController.text);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification sent successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(_visibleMonth);
    final calendarCells = _buildCalendarCells();
    final isAdmin = Provider.of<AuthProvider>(context).isAdmin;
    final eventProvider = Provider.of<EventProvider>(context);

    return Scaffold(
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateEventScreen()),
                );
              },
              backgroundColor: const Color(0xFF0F3156),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/image/background_user.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF0E1C2C)),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.55)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Color(0xFF88AEC9),
                          size: 32,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Events',
                        style: TextStyle(
                          color: Color(0xFF88AEC9),
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBFD9F4),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, size: 26),
                              color: const Color(0xFF456C9A),
                              onPressed: () => _swapMonth(-1),
                            ),
                            Text(
                              monthLabel,
                              style: const TextStyle(
                                color: Color(0xFF1C3553),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, size: 26),
                              color: const Color(0xFF456C9A),
                              onPressed: () => _swapMonth(1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            _WeekDayLabel('MON'),
                            _WeekDayLabel('TUE'),
                            _WeekDayLabel('WED'),
                            _WeekDayLabel('THU'),
                            _WeekDayLabel('FRI'),
                            _WeekDayLabel('SAT'),
                            _WeekDayLabel('SUN'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                          ),
                          itemCount: calendarCells.length,
                          itemBuilder: (context, index) {
                            final day = calendarCells[index];
                            if (day == null) {
                              return const SizedBox.shrink();
                            }
                            
                            final currentDayDate = DateTime(_visibleMonth.year, _visibleMonth.month, day);
                            final hasEvent = eventProvider.getEventsForDate(currentDayDate).isNotEmpty;
                            final isSelected = day == _selectedDay;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDay = day;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF1C3553)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$day',
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF1C3553),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (hasEvent)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.white : Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Consumer<EventProvider>(
                      builder: (context, eventProvider, child) {
                        if (eventProvider.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (eventProvider.error != null) {
                          return Center(
                            child: Text(
                              'Error: ${eventProvider.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }

                        final events = eventProvider.events;
                        
                        // Filter by selected day if needed, or show all for month
                        List<EventModel> displayEvents = events;
                        if (_selectedDay != null) {
                          final selectedDate = DateTime(_visibleMonth.year, _visibleMonth.month, _selectedDay!);
                          displayEvents = eventProvider.getEventsForDate(selectedDate);
                        }

                        if (displayEvents.isEmpty) {
                           return const Center(
                            child: Text(
                              'No events found',
                              style: TextStyle(color: Colors.white70),
                            ),
                          );
                        }

                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F3156), Color(0xFF094477)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 24),
                          child: ListView.separated(
                            itemCount: displayEvents.length,
                            separatorBuilder: (_, __) => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 18),
                              child: Divider(
                                color: Colors.white24,
                                thickness: 1,
                                height: 1,
                              ),
                            ),
                            itemBuilder: (context, index) {
                              final event = displayEvents[index];
                              return InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: const Color(0xFF0F3156),
                                      title: Text(event.title, style: const TextStyle(color: Colors.white)),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Date: ${event.date}', style: const TextStyle(color: Colors.white70)),
                                            const SizedBox(height: 4),
                                            Text('Time: ${event.time}', style: const TextStyle(color: Colors.white70)),
                                            const SizedBox(height: 8),
                                            Text('Location: ${event.location}', style: const TextStyle(color: Colors.white70)),
                                            const SizedBox(height: 16),
                                            const Text('Description:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            Text(event.description, style: const TextStyle(color: Colors.white)),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        if (isAdmin)
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => CreateEventScreen(event: event),
                                                ),
                                              );
                                            },
                                            child: const Text('Edit', style: TextStyle(color: Colors.orange)),
                                          ),
                                        if (isAdmin)
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _showSendNotificationDialog(context, event);
                                            },
                                            child: const Text('Notify', style: TextStyle(color: Colors.green)),
                                          ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Close', style: TextStyle(color: Colors.blue)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          event.time,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          event.date,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      event.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      event.location,
                                      style: const TextStyle(
                                        color: Color(0xFFD2E8FF),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekDayLabel extends StatelessWidget {
  const _WeekDayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF4B6688),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}