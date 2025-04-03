import 'dart:async';
import 'package:flutter/material.dart';

class UpgradeProgressIndicator extends StatefulWidget {
  final DateTime startedAt;
  final DateTime endsAt;

  const UpgradeProgressIndicator({
    super.key,
    required this.startedAt,
    required this.endsAt,
  });

  @override
  State<UpgradeProgressIndicator> createState() => _UpgradeProgressIndicatorState();
}

class _UpgradeProgressIndicatorState extends State<UpgradeProgressIndicator> {
  late Timer _timer;
  late Duration totalDuration;
  Duration remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    totalDuration = widget.endsAt.difference(widget.startedAt);
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final rem = widget.endsAt.difference(now);
    setState(() {
      remaining = rem > Duration.zero ? rem : Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  double get progress {
    final elapsed = totalDuration - remaining;
    return (elapsed.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0);
  }

  String formatTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progress,
          minHeight: 12,
          backgroundColor: Colors.grey.shade300,
          color: Colors.blueAccent,
        ),
        const SizedBox(height: 4),
        Text(
          '⏳ ${formatTime(remaining)} remaining',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
