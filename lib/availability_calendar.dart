import 'package:flutter/material.dart';

class AvailabilityCalendar extends StatefulWidget {
  final Set<String> selectedSlots;
  final ValueChanged<Set<String>>? onChanged;
  final bool isReadOnly;

  const AvailabilityCalendar({
    super.key,
    required this.selectedSlots,
    this.onChanged,
    this.isReadOnly = false,
  });

  @override
  State<AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<AvailabilityCalendar> {
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> periods = ['Morning', 'Afternoon', 'Evening'];
  
  void _toggleSlot(String day, String period) {
    if (widget.isReadOnly || widget.onChanged == null) return;
    
    final slot = '$day-$period';
    final newSelected = Set<String>.from(widget.selectedSlots);
    if (newSelected.contains(slot)) {
      newSelected.remove(slot);
    } else {
      newSelected.add(slot);
    }
    widget.onChanged!(newSelected);
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
                style: TextStyle(
                  fontWeight: FontWeight.w700, 
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
            )),
          ],
        ),
        const SizedBox(height: 12),
        ...days.map((day) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    day, 
                    style: TextStyle(
                      fontWeight: FontWeight.w700, 
                      color: Colors.black.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ),
                ...periods.map((period) {
                  final slot = '$day-$period';
                  final isSelected = widget.selectedSlots.contains(slot);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: widget.isReadOnly ? null : () => _toggleSlot(day, period),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xff448AFF) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: isSelected 
                            ? const Icon(Icons.check, color: Colors.white, size: 14)
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
