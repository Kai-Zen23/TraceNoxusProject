// d:\Software Engineering Project\TraceNoxusProject\TraceNoxus-FrontEnd\lib\screens\calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _visibleMonth = DateTime.now();
  int? _selectedDay;

  final List<_EventItem> _events = const [
    _EventItem(
      time: '01:00 PM',
      title: 'Mobile Legends Rank Push Marathon',
      detail: 'Squad A vs Squad B, Location: Arena Net Cafe.',
    ),
    _EventItem(
      time: '03:00 PM',
      title: 'Valorant Ranked Grind Session',
      detail: 'Squad Alpha vs Squad Bravo, Location: Online Lobby.',
    ),
    _EventItem(
      time: '04:00 PM',
      title: 'Tekken 8 Tournament',
      detail: 'Register now through the posted link! Location: Grand Central.',
    ),
  ];

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

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(_visibleMonth);
    final calendarCells = _buildCalendarCells();

    return Scaffold(
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
                                child: Text(
                                  '$day',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF1C3553),
                                    fontWeight: FontWeight.w600,
                                  ),
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
                    child: Container(
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
                        itemCount: _events.length,
                        separatorBuilder: (_, __) => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Divider(
                            color: Colors.white24,
                            thickness: 1,
                            height: 1,
                          ),
                        ),
                        itemBuilder: (context, index) {
                          final event = _events[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.time,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
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
                                event.detail,
                                style: const TextStyle(
                                  color: Color(0xFFD2E8FF),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
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

class _EventItem {
  final String time;
  final String title;
  final String detail;

  const _EventItem({
    required this.time,
    required this.title,
    required this.detail,
  });
}