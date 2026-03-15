import 'package:flutter/material.dart';

class AvailabilityCalendar extends StatefulWidget {
  final Set<String> selectedSlots;
  final ValueChanged<Set<String>> onChanged;

  const AvailabilityCalendar({
    super.key,
    required this.selectedSlots,
    required this.onChanged,
  });

  @override
  State<AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<AvailabilityCalendar> {
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> periods = ['Morning', 'Afternoon', 'Evening'];
  
  void _toggleSlot(String day, String period) {
    final slot = '$day-$period';
    final newSelected = Set<String>.from(widget.selectedSlots);
    if (newSelected.contains(slot)) {
      newSelected.remove(slot);
    } else {
      newSelected.add(slot);
    }
    widget.onChanged(newSelected);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 40), // spacer for row labels
            ...periods.map((p) => Expanded(
              child: Text(
                p, 
                textAlign: TextAlign.center, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            )),
          ],
        ),
        const SizedBox(height: 8),
        ...days.map((day) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 40,
                  child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                ...periods.map((period) {
                  final slot = '$day-$period';
                  final isSelected = widget.selectedSlots.contains(slot);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: InkWell(
                        onTap: () => _toggleSlot(day, period),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          height: 30,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blueAccent : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: isSelected 
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
