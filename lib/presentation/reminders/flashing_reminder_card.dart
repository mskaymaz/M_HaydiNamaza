import 'dart:async';

import 'package:flutter/material.dart';

class FlashingReminderCard extends StatefulWidget {
  final String prayerLabel;
  final String message;

  const FlashingReminderCard({
    super.key,
    required this.prayerLabel,
    required this.message,
  });

  @override
  State<FlashingReminderCard> createState() => _FlashingReminderCardState();
}

class _FlashingReminderCardState extends State<FlashingReminderCard> {
  Timer? _timer;
  bool _isBright = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 320), (_) {
      if (!mounted) return;
      setState(() {
        _isBright = !_isBright;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isBright ? const Color(0xFFF4FFD8) : const Color(0xFFFFFEF7);
    final borderColor = _isBright
        ? const Color(0xFF7CB342)
        : const Color(0xFFD4AF37).withValues(alpha: 0.72);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 110),
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isBright
              ? const [Color(0xFFFFFFFF), Color(0xFFFFF59D), Color(0xFFC8E6C9)]
              : [backgroundColor, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: _isBright ? 3 : 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFEB3B).withValues(alpha: _isBright ? 0.38 : 0.10),
            blurRadius: _isBright ? 34 : 8,
            spreadRadius: _isBright ? 7 : 0,
          ),
          BoxShadow(
            color: const Color(0xFF66BB6A).withValues(alpha: _isBright ? 0.30 : 0.12),
            blurRadius: _isBright ? 24 : 10,
            spreadRadius: _isBright ? 4 : 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.prayerLabel,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
