import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Schedule picker with quick-schedule presets, manual date/time,
/// and live countdown — mirrors the web SchedulePostModal picker.
class QuickSchedulePicker extends StatefulWidget {
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final ValueChanged<DateTime?> onDateChanged;
  final ValueChanged<TimeOfDay?> onTimeChanged;

  const QuickSchedulePicker({
    super.key,
    this.selectedDate,
    this.selectedTime,
    required this.onDateChanged,
    required this.onTimeChanged,
  });

  @override
  State<QuickSchedulePicker> createState() => _QuickSchedulePickerState();
}

class _QuickSchedulePickerState extends State<QuickSchedulePicker> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  DateTime? get _fullDateTime {
    if (widget.selectedDate == null || widget.selectedTime == null) return null;
    return DateTime(
      widget.selectedDate!.year,
      widget.selectedDate!.month,
      widget.selectedDate!.day,
      widget.selectedTime!.hour,
      widget.selectedTime!.minute,
    );
  }

  List<_QuickPreset> _buildPresets() {
    final now = DateTime.now();
    final presets = <_QuickPreset>[];

    // In 1 hour (only if before 11 PM)
    if (now.hour < 23) {
      final t = now.add(const Duration(hours: 1));
      presets.add(_QuickPreset('In 1 hour', t));
    }

    // In 3 hours (only if result is same day)
    final threeH = now.add(const Duration(hours: 3));
    if (threeH.day == now.day) {
      presets.add(_QuickPreset('In 3 hours', threeH));
    }

    // Tomorrow 9 AM
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 9, 0);
    presets.add(_QuickPreset('Tomorrow 9 AM', tomorrow));

    // Tomorrow 6 PM
    final tomorrowEve = DateTime(now.year, now.month, now.day + 1, 18, 0);
    presets.add(_QuickPreset('Tomorrow 6 PM', tomorrowEve));

    // Next Saturday 10 AM (if > tomorrow)
    var sat = now;
    while (sat.weekday != DateTime.saturday) {
      sat = sat.add(const Duration(days: 1));
    }
    if (sat.isAfter(DateTime(now.year, now.month, now.day + 1))) {
      presets.add(_QuickPreset(
        'Sat 10 AM',
        DateTime(sat.year, sat.month, sat.day, 10, 0),
      ));
    }

    // Next Monday 9 AM (if > tomorrow)
    var mon = now;
    while (mon.weekday != DateTime.monday) {
      mon = mon.add(const Duration(days: 1));
    }
    if (mon.isAfter(DateTime(now.year, now.month, now.day + 1))) {
      presets.add(_QuickPreset(
        'Mon 9 AM',
        DateTime(mon.year, mon.month, mon.day, 9, 0),
      ));
    }

    return presets;
  }

  void _selectPreset(_QuickPreset preset) {
    widget.onDateChanged(preset.dateTime);
    widget.onTimeChanged(
      TimeOfDay(hour: preset.dateTime.hour, minute: preset.dateTime.minute),
    );
  }

  void _clearSelection() {
    widget.onDateChanged(null);
    widget.onTimeChanged(null);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          widget.selectedDate ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      widget.onDateChanged(date);
    }
  }

  void _showTimePicker() {
    final now = DateTime.now();
    final isToday = widget.selectedDate != null &&
        widget.selectedDate!.year == now.year &&
        widget.selectedDate!.month == now.month &&
        widget.selectedDate!.day == now.day;

    // Build 30-min interval options (48 slots)
    final slots = <TimeOfDay>[];
    for (int h = 0; h < 24; h++) {
      for (int m = 0; m < 60; m += 30) {
        final slot = TimeOfDay(hour: h, minute: m);
        // Disable past times for today
        if (isToday) {
          final slotDt = DateTime(now.year, now.month, now.day, h, m);
          if (slotDt.isBefore(now.add(const Duration(minutes: 5)))) continue;
        }
        slots.add(slot);
      }
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select Time',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: slots.length,
                  itemBuilder: (_, i) {
                    final slot = slots[i];
                    final label = _formatTimeOfDay(slot);
                    final isSelected = widget.selectedTime != null &&
                        widget.selectedTime!.hour == slot.hour &&
                        widget.selectedTime!.minute == slot.minute;
                    return ListTile(
                      title: Text(label),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Color(0xFF307777))
                          : null,
                      selected: isSelected,
                      selectedTileColor:
                          const Color(0xFF307777).withValues(alpha: 0.08),
                      onTap: () {
                        widget.onTimeChanged(slot);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final min = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    final presets = _buildPresets();
    final fullDt = _fullDateTime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF307777).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Color(0xFF307777)),
              const SizedBox(width: 8),
              const Text(
                'Schedule Date & Time',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF307777),
                ),
              ),
              const Spacer(),
              if (fullDt != null)
                GestureDetector(
                  onTap: _clearSelection,
                  child: const Icon(Icons.close, size: 18, color: Colors.grey),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Quick presets label
        Text(
          'QUICK SCHEDULE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),

        // Quick preset chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((p) {
            final isSelected = fullDt != null &&
                fullDt!.year == p.dateTime.year &&
                fullDt!.month == p.dateTime.month &&
                fullDt!.day == p.dateTime.day &&
                fullDt!.hour == p.dateTime.hour &&
                fullDt!.minute == p.dateTime.minute;
            return GestureDetector(
              onTap: () => _selectPreset(p),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF307777)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF307777)
                        : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  p.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // "or pick manually" divider
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey[300])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'or pick manually',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey[300])),
          ],
        ),
        const SizedBox(height: 12),

        // Date + Time row
        Row(
          children: [
            // Date picker
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('Date', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Text(
                        widget.selectedDate != null
                            ? DateFormat('MM/dd/yyyy')
                                .format(widget.selectedDate!)
                            : 'mm/dd/yyyy',
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.selectedDate != null
                              ? Colors.black87
                              : Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Time picker
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('Time', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: widget.selectedDate != null ? _showTimePicker : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                        color: widget.selectedDate != null
                            ? Colors.white
                            : Colors.grey[50],
                      ),
                      child: Text(
                        widget.selectedTime != null
                            ? _formatTimeOfDay(widget.selectedTime!)
                            : 'Select time',
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.selectedTime != null
                              ? Colors.black87
                              : Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Live countdown
        if (fullDt != null) ...[
          const SizedBox(height: 14),
          _CountdownDisplay(scheduledFor: fullDt!),
        ],
      ],
    );
  }
}

class _QuickPreset {
  final String label;
  final DateTime dateTime;
  _QuickPreset(this.label, this.dateTime);
}

/// Inline countdown display for the schedule picker.
class _CountdownDisplay extends StatefulWidget {
  final DateTime scheduledFor;
  const _CountdownDisplay({required this.scheduledFor});

  @override
  State<_CountdownDisplay> createState() => _CountdownDisplayState();
}

class _CountdownDisplayState extends State<_CountdownDisplay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diff = widget.scheduledFor.difference(DateTime.now());
    if (diff.isNegative) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red[600]),
            const SizedBox(width: 8),
            Text(
              'Selected time is in the past',
              style: TextStyle(fontSize: 13, color: Colors.red[600]),
            ),
          ],
        ),
      );
    }

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    final parts = <String>[];
    if (days > 0) parts.add('$days day${days > 1 ? 's' : ''}');
    if (hours > 0) parts.add('$hours hour${hours > 1 ? 's' : ''}');
    parts.add('$minutes min');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF307777).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF307777)),
          const SizedBox(width: 8),
          Text(
            'Posting in ${parts.join(', ')}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF307777),
            ),
          ),
        ],
      ),
    );
  }
}
