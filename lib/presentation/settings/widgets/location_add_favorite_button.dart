import 'package:flutter/material.dart';

class LocationAddFavoriteButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const LocationAddFavoriteButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: const Icon(Icons.star_border),
      label: Text(label),
    );
  }
}
