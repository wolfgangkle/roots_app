import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:async';
import 'package:provider/provider.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/tokens.dart';

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
  State<UpgradeProgressIndicator> createState() => _UpgradeProgressIndicatorState();
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
        : (rawDuration <= Duration.zero ? const Duration(seconds: 1) : rawDuration);

    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final rem = widget.endsAt.difference(DateTime.now());
    setState(() {
      remaining = rem > Duration.zero ? rem : Duration.zero;
    });

    if (remaining <= Duration.zero && !_calledFinish && widget.villageId != null) {
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
    final ms = totalDuration.inMilliseconds;
    if (ms <= 0) return 1.0;
    final elapsed = (totalDuration - remaining).inMilliseconds;
    return (elapsed / ms).clamp(0.0, 1.0);
  }

  String _formatTime(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    return h > 0
        ? '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // 🔄 Live tokens
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;

    final bg = glass.baseColor.withValues(alpha: glass.mode == SurfaceMode.solid ? 0.10 : 0.08);
    final upgradeColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: bg,
            color: upgradeColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '⏳ ${_formatTime(remaining)} remaining',
          style: TextStyle(fontSize: 12, color: text.subtle),
        ),
      ],
    );
  }
}
