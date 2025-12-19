// lib/widgets/planb_button.dart
import 'package:flutter/material.dart';

class PlanBButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onPressed;

  const PlanBButton({
    super.key,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final label = enabled ? 'PLAN B' : 'PLAN B USED';

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1.0 : 0.5,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          backgroundColor:
              enabled ? colorScheme.secondary : colorScheme.secondary.withOpacity(0.4),
          foregroundColor: Colors.black,
          elevation: enabled ? 4 : 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.replay, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
