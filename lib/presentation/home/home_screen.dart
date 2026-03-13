import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('MHaydiNamaza'),
      ),
      body: Center(
        child: Text(
          'Namaz vakitleri yakinda burada.',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
      ),
    );
  }
}
