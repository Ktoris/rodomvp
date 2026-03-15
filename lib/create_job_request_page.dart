import 'package:flutter/material.dart';

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

  String jobCategory = 'Lawn Care';
  final jobCategories = [
    'Lawn Care',
    'Car Wash',
    'Babysitting',
    'Tutoring',
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
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _validateAndSubmit() {
    if (!_validateForm()) {
      return;
    }

    // Combine date and time
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
      'jobDescription': descriptionController.text.trim(), // Optional
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

  void _openMapPicker() {
    // Simulated Map Picker Dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simulated Map Picker'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text('Tap on the map to set a location.'),
            Text('(Simulation: Random coordinates generated)',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                locationData = {
                  'lat': 40.7128 + (0.01 * (0.5 - (0.5))), // Randomish
                  'lng': -74.0060 + (0.01 * (0.5 - (0.5))),
                  'address': 'Simulated Address, Park Ave',
                };
                locationController.text = locationData!['address'];
              });
              Navigator.pop(context);
            },
            child: const Text('Confirm Location'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Job')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // 🔹 TITLE
            TextField(
              controller: titleController,
              maxLength: 60,
              decoration: const InputDecoration(labelText: 'Job Title *'),
            ),
            const SizedBox(height: 10),

            // 🔹 CATEGORY
            DropdownButtonFormField<String>(
              value: jobCategory,
              decoration: const InputDecoration(labelText: 'Job Category *'),
              items: jobCategories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => jobCategory = val);
              },
            ),
            const SizedBox(height: 20),

            // 🔹 DESCRIPTION (OPTIONAL)
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Job Description (Optional)'),
            ),
            const SizedBox(height: 20),

            // 🔹 LOCATION
            const Text('Location *', style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile(
              value: 'my_address',
              groupValue: locationType,
              title: const Text('My Address'),
              onChanged: (v) => setState(() => locationType = v!),
            ),
            RadioListTile(
              value: 'other_location',
              groupValue: locationType,
              title: const Text('Other Location'),
              onChanged: (v) => setState(() => locationType = v!),
            ),
            RadioListTile(
              value: 'remote',
              groupValue: locationType,
              title: const Text('Remote'),
              onChanged: (v) => setState(() => locationType = v!),
            ),
            if (locationType == 'other_location')
              Column(
                children: [
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Specific Location',
                      hintText: 'e.g. 123 Main St',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _openMapPicker,
                    icon: const Icon(Icons.map),
                    label: const Text('Set on Map'),
                  ),
                ],
              ),
            const SizedBox(height: 20),

            // 🔹 DATE & TIME
            const Text('Date & Time *', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                        initialDate: selectedDate ?? DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: Text(selectedDate == null ? 'Select Date' : _formatDate(selectedDate!)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime ?? TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setState(() => selectedTime = picked);
                      }
                    },
                    child: Text(selectedTime == null ? 'Select Time' : selectedTime!.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 🔹 DURATION
            DropdownButtonFormField<String>(
              value: duration,
              decoration: const InputDecoration(labelText: 'Estimated Duration *'),
              items: durations.map((d) {
                return DropdownMenuItem(value: d, child: Text(d));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => duration = val);
              },
            ),
            const SizedBox(height: 20),

            // 🔹 BUDGET / PAY
            TextField(
              controller: budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Offered Pay *',
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 NUMBER OF TEENS
            const Text('Teens Needed', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: List.generate(3, (index) {
                final count = index + 1;
                return Expanded(
                  child: RadioListTile<int>(
                    title: Text('$count'),
                    value: count,
                    groupValue: numTeens,
                    onChanged: (v) => setState(() => numTeens = v!),
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),

            // 🔹 SUBMIT
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _validateAndSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Send Hire Request', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
