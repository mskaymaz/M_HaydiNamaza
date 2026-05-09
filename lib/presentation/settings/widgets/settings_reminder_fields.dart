import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsReminderTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final int maxLines;

  const SettingsReminderTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      minLines: maxLines,
      maxLines: maxLines,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF4F1EA),
        hintStyle: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade400),
        labelStyle: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
        alignLabelWithHint: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class SettingsReminderNumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const SettingsReminderNumberField({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF4F1EA),
        labelStyle: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class SettingsReminderOptionToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsReminderOptionToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(value: value, onChanged: (next) => onChanged(next ?? false)),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.black87),
        ),
      ],
    );
  }
}
