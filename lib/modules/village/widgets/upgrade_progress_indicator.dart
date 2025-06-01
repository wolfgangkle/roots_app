import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:async';


// 🌿 Use the same green as UpgradeButton
const Color kAccentGreenLight = Color(0xFF3B5743);

class UpgradeProgressIndicator extends StatefulWidget {
  final DateTime startedAt;
  final DateTime endsAt;
  final String? villageId;

  const UpgradeProgressIndicator({
    super.key,
    required this.startedAt,
    required this.endsAt,
    this.villageId,
  });

  @override
  State<UpgradeProgressIndicator> createState() =>
      _UpgradeProgressIndicatorState();
}

class _UpgradeProgressIndicatorState extends State<UpgradeProgressIndicator> {
  late Timer _timer;
  Duration totalDuration = const Duration(seconds: 10);
  Duration remaining = Duration.zero;
  bool _calledFinish = false;

  @override
  void initState() {
    super.initState();

    final rawDuration = widget.endsAt.difference(widget.startedAt);
    totalDuration = rawDuration > const Duration(days: 1)
        ? const Duration(seconds: 10)
        : rawDuration;

    _updateRemaining();
    _timer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final rem = widget.endsAt.difference(now);

    setState(() {
      remaining = rem > Duration.zero ? rem : Duration.zero;
    });

    if (remaining <= Duration.zero &&
        !_calledFinish &&
        widget.villageId != null) {
      _calledFinish = true;
      FirebaseFunctions.instance
          .httpsCallable('finishBuildingUpgrade')
          .call({'villageId': widget.villageId}).then((result) {
        debugPrint('✅ finishBuildingUpgrade success: ${result.data}');
      }).catchError((e) {
        debugPrint('❌ Error calling finishBuildingUpgrade: $e');
        _calledFinish = false;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  double get progress {
    final elapsed = totalDuration - remaining;
    return (elapsed.inMilliseconds / totalDuration.inMilliseconds)
        .clamp(0.0, 1.0);
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
          color: kAccentGreenLight, // 🌿 Thematic upgrade color!
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
