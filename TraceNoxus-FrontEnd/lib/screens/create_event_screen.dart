import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/event_provider.dart';
import '../providers/auth_provider.dart';
import '../models/event_model.dart';
import '../widgets/styled_back_button.dart';

class CreateEventScreen extends StatefulWidget {
  final EventModel? event; // Optional event for editing

  const CreateEventScreen({super.key, this.event});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late bool _isReminderOn;
  XFile? _pickedImage;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController =
        TextEditingController(text: event?.description ?? '');
    _locationController = TextEditingController(text: event?.location ?? '');

    if (event != null) {
      _selectedDate = DateFormat('yyyy-MM-dd').parse(event.date);
      // Parse time "HH:MM:SS"
      final timeParts = event.time.split(':');
      _selectedTime = TimeOfDay(
          hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
      _isReminderOn = event.isReminderOn;
    } else {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
      _isReminderOn = false;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image =
        await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    final eventProvider = Provider.of<EventProvider>(context, listen: false);

    // Format date and time for backend
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    // Format time as HH:MM:SS
    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00';

    final Map<String, dynamic> eventData = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'date': dateStr,
      'time': timeStr,
      'location': _locationController.text.trim(),
      'is_reminder_on': _isReminderOn,
    };

    if (_pickedImage != null) {
      eventData['background_image'] = _pickedImage!.path;
    }

    bool success;
    if (widget.event != null) {
      success = await eventProvider.updateEvent(widget.event!.id, eventData);
    } else {
      success = await eventProvider.createEvent(eventData);
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.event != null
                ? 'Event updated successfully'
                : 'Event created successfully')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(eventProvider.error ?? 'Failed to save event'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    // RBAC Check
    final isAdmin = Provider.of<AuthProvider>(context, listen: false).isAdmin;
    if (!isAdmin) {
      // Redirect or show error
      return Scaffold(
        body: Center(child: Text("Access Denied")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.event != null ? 'Edit Event' : 'Create Event'),
        centerTitle: true,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: StyledBackButton(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/image/background_user.png',
              fit: BoxFit.fill,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF0F172A)),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField('Title', _titleController,
                        validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    _buildTextField('Description', _descriptionController,
                        maxLines: 3),
                    const SizedBox(height: 16),
                    _buildTextField('Location', _locationController,
                        validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white10,
                                labelStyle: TextStyle(color: Colors.white70),
                              ),
                              child: Text(
                                DateFormat('yyyy-MM-dd').format(_selectedDate),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Time',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white10,
                                labelStyle: TextStyle(color: Colors.white70),
                              ),
                              child: Text(
                                _selectedTime.format(context),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    SwitchListTile(
                      title: const Text('Reminder',
                          style: TextStyle(color: Colors.white)),
                      value: _isReminderOn,
                      onChanged: (val) => setState(() => _isReminderOn = val),
                      activeColor: Colors.blue,
                    ),
                    const SizedBox(height: 16),

                    // Image Picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: _pickedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(_pickedImage!.path),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add_photo_alternate,
                                      color: Colors.white54, size: 40),
                                  SizedBox(height: 8),
                                  Text('Add Background Image',
                                      style: TextStyle(color: Colors.white54)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: eventProvider.isLoading ? null : _saveEvent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: eventProvider.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                widget.event != null
                                    ? 'Update Event'
                                    : 'Create Event',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1E293B).withOpacity(0.8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24)),
      ),
    );
  }
}
