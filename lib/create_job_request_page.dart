import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

class CreateJobRequestPage extends StatefulWidget {
  const CreateJobRequestPage({super.key});

  @override
  State<CreateJobRequestPage> createState() => _CreateJobRequestPageState();
}

class _CreateJobRequestPageState extends State<CreateJobRequestPage> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final budgetController = TextEditingController();
  Map<String, dynamic>? locationData;

  String jobCategory = 'Tutoring';
  final jobCategories = [
    'Tutoring',
    'Lawn Care',
    'Car Wash',
    'Babysitting',
    'Design',
    'Errands',
    'Events',
    'Other'
  ];

  String locationType = 'remote'; // remote | my_address | other_location
  String duration = '1hr';
  final durations = ['1hr', '2hr', 'Half Day', 'Full Day', 'Ongoing'];

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  int numTeens = 1;

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _validateForm() {
    if (titleController.text.trim().isEmpty) {
      _showError('Please enter a job title');
      return false;
    }
    if (selectedDate == null || selectedTime == null) {
      _showError('Please select a date and time');
      return false;
    }
    if (budgetController.text.trim().isEmpty) {
      _showError('Please enter a budget / offered pay');
      return false;
    }
    if (locationType == 'other_location' && locationController.text.trim().isEmpty) {
      _showError('Please enter a location');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _validateAndSubmit() {
    if (!_validateForm()) {
      return;
    }

    final completeDate = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    Navigator.pop(context, {
      'jobTitle': titleController.text.trim(),
      'jobCategory': jobCategory,
      'jobDescription': descriptionController.text.trim(),
      'locationType': locationType,
      'locationText': locationType == 'remote'
          ? 'Remote'
          : (locationType == 'my_address' ? 'My Address' : locationController.text.trim()),
      'locationData': locationData,
      'date': completeDate,
      'duration': duration,
      'budget': double.tryParse(budgetController.text.trim()) ?? 0.0,
      'numTeens': numTeens,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: Text('New Job Request', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: AppTheme.darkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Engagement Details'),
            const SizedBox(height: 16),
            _buildTextField(titleController, 'Job Title *', 'e.g. Math Tutoring Session'),
            const SizedBox(height: 16),
            _buildDropdown('Category *', jobCategory, jobCategories, (val) => setState(() => jobCategory = val!)),
            const SizedBox(height: 16),
            _buildTextField(descriptionController, 'Short Description', 'What needs to be done?', maxLines: 3),
            
            const SizedBox(height: 32),
            _buildSectionTitle('Time & Budget'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildPickerButton(selectedDate == null ? 'Set Date' : _formatDate(selectedDate!), Icons.calendar_today_rounded, _selectDate)),
                const SizedBox(width: 12),
                Expanded(child: _buildPickerButton(selectedTime == null ? 'Set Time' : selectedTime!.format(context), Icons.access_time_rounded, _selectTime)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDropdown('Duration', duration, durations, (val) => setState(() => duration = val!))),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(budgetController, 'Pay (\$)', '0.00', keyboardType: TextInputType.number)),
              ],
            ),

            const SizedBox(height: 32),
            _buildSectionTitle('Location'),
            const SizedBox(height: 12),
            _buildLocationTypeSelector(),
            if (locationType == 'other_location') ...[
              const SizedBox(height: 12),
              _buildTextField(locationController, 'Address', 'Enter address or venue'),
            ],

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _validateAndSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.darkBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text('Confirm & Send Request', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppTheme.teal,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.darkBlue)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.darkBlue)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.black),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.teal),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTypeSelector() {
    return Wrap(
      spacing: 8,
      children: [
        _buildChoiceChip('Remote', 'remote'),
        _buildChoiceChip('My Address', 'my_address'),
        _buildChoiceChip('Other', 'other_location'),
      ],
    );
  }

  Widget _buildChoiceChip(String label, String type) {
    final isSelected = locationType == type;
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
      selected: isSelected,
      onSelected: (val) => setState(() => locationType = type),
      selectedColor: AppTheme.teal.withOpacity(0.2),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(color: isSelected ? AppTheme.teal : Colors.black54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide.none),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: selectedDate ?? DateTime.now(),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => selectedTime = picked);
  }
}
