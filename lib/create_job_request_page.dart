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

  String locationType = 'remote'; // remote | location
  String dateType = 'anytime'; // anytime | range
  DateTime? startDate;
  DateTime? endDate;

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _validateForm() {
    // Check job title
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a job title'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    // Check job description
    if (descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a job description'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    // Check location if specific location is selected
    if (locationType == 'location' &&
        locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a location'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    // Check dates if range is selected
    if (dateType == 'range') {
      if (startDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a start date'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
      if (endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an end date'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
      if (endDate!.isBefore(startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End date must be after start date'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }

    return true;
  }

  void _validateAndSubmit() {
    if (!_validateForm()) {
      return;
    }

    Navigator.pop(context, {
      'jobTitle': titleController.text.trim(),
      'jobDescription': descriptionController.text.trim(),
      'locationType': locationType,
      'locationText': locationController.text.trim(),
      'dateType': dateType,
      'startDate': startDate,
      'endDate': endDate,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Job')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Job Title'),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration:
                  const InputDecoration(labelText: 'Job Description'),
            ),
            const SizedBox(height: 20),

            // LOCATION
            const Text('Location'),
            RadioListTile(
              value: 'remote',
              groupValue: locationType,
              title: const Text('Remote'),
              onChanged: (v) => setState(() => locationType = v!),
            ),
            RadioListTile(
              value: 'location',
              groupValue: locationType,
              title: const Text('Specific Location'),
              onChanged: (v) => setState(() => locationType = v!),
            ),
            if (locationType == 'location')
              TextField(
                controller: locationController,
                decoration:
                    const InputDecoration(labelText: 'Location'),
              ),

            const SizedBox(height: 20),

            // DATE
            const Text('Date'),
            RadioListTile(
              value: 'anytime',
              groupValue: dateType,
              title: const Text('Anytime'),
              onChanged: (v) => setState(() => dateType = v!),
            ),
            RadioListTile(
              value: 'range',
              groupValue: dateType,
              title: const Text('Specific Range'),
              onChanged: (v) => setState(() => dateType = v!),
            ),

            if (dateType == 'range') ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          initialDate: startDate ?? DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            startDate = picked;
                            // If end date is before start date, clear it
                            if (endDate != null && endDate!.isBefore(picked)) {
                              endDate = null;
                            }
                          });
                        }
                      },
                      child: const Text('Select Start Date'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: startDate ?? DateTime.now(),
                          lastDate: DateTime(2100),
                          initialDate: endDate ?? startDate ?? DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            endDate = picked;
                          });
                        }
                      },
                      child: const Text('Select End Date'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (startDate != null || endDate != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (startDate != null)
                        Text(
                          'From: ${_formatDate(startDate!)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      if (endDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'To: ${_formatDate(endDate!)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _validateAndSubmit,
              child: const Text('Send Hire Request'),
            ),
          ],
        ),
      ),
    );
  }
}
