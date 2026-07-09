import 'package:flutter/material.dart';

import '../core/app_action_theme.dart';

class BeautifulSubmitButton extends StatelessWidget {
  const BeautifulSubmitButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.idleLabel,
    this.loadingLabel = 'Submitting...',
    this.icon = Icons.save_outlined,
    this.backgroundColor = AppActionTheme.primary,
  });

  final bool isLoading;
  final VoidCallback? onPressed;
  final String idleLabel;
  final String loadingLabel;
  final IconData icon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.75),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppActionTheme.submitButtonRadius),
          ),
          elevation: 1.5,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1).animate(animation),
                child: child,
              ),
            );
          },
          child: Row(
            key: ValueKey<bool>(isLoading),
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Icon(icon, size: 20),
              const SizedBox(width: 10),
              Text(
                isLoading ? loadingLabel : idleLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
