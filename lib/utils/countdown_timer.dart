import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CountdownTimer extends StatefulWidget {
  final String eventDate;
  final String eventTime;
  final TextStyle? style;

  const CountdownTimer({
    super.key,
    required this.eventDate,
    required this.eventTime,
    this.style,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late DateTime _eventDateTime;
  Duration _timeUntil = Duration.zero;

  @override
  void initState() {
    super.initState();
    _parseEventDateTime();
    _updateCountdown();
  }

  void _parseEventDateTime() {
    try {
      // Parse date and time (format: YYYY-MM-DD and HH:MM AM/PM)
      final datePart = widget.eventDate;
      final timePart = widget.eventTime;

      // Combine date and time
      final dateTimeString = '$datePart $timePart';

      // Parse with intl package
      final format = DateFormat('yyyy-MM-dd hh:mm a');
      _eventDateTime = format.parse(dateTimeString);
    } catch (e) {
      // Fallback if parsing fails
      _eventDateTime = DateTime.now().add(const Duration(days: 7));
    }
  }

  void _updateCountdown() {
    setState(() {
      _timeUntil = _eventDateTime.difference(DateTime.now());
    });

    // Update every second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _updateCountdown();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_timeUntil.isNegative) {
      return Text(
        'Event started',
        style: widget.style ?? const TextStyle(fontSize: 12, color: Colors.red),
      );
    }

    final days = _timeUntil.inDays;
    final hours = _timeUntil.inHours % 24;
    final minutes = _timeUntil.inMinutes % 60;

    String countdownText;
    Color countdownColor;

    if (days > 0) {
      countdownText = '$days day${days > 1 ? 's' : ''} left';
      countdownColor = Colors.green;
    } else if (hours > 0) {
      countdownText = '$hours hour${hours > 1 ? 's' : ''} left';
      countdownColor = Colors.orange;
    } else {
      countdownText = '$minutes minute${minutes > 1 ? 's' : ''} left';
      countdownColor = Colors.red;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.timer,
          size: 14,
          color: countdownColor,
        ),
        const SizedBox(width: 4),
        Text(
          countdownText,
          style: (widget.style ?? const TextStyle(fontSize: 12)).copyWith(
            color: countdownColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}