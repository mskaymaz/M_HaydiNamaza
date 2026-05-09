import 'package:flutter/material.dart';

List<DropdownMenuItem<String>> buildStringDropdownItems<T>({
  required Iterable<T> items,
  required String Function(T item) valueOf,
  required String Function(T item) labelOf,
}) {
  return items
      .map(
        (item) => DropdownMenuItem<String>(
          value: valueOf(item),
          child: Text(labelOf(item)),
        ),
      )
      .toList();
}
