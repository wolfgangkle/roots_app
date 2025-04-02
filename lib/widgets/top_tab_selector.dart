import 'package:flutter/material.dart';

class TopTabSelector extends StatelessWidget {
  final List<String> tabs;
  final String current;
  final void Function(String) onTabChanged;

  const TopTabSelector({
    super.key,
    required this.tabs,
    required this.current,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: tabs.map((tab) {
        final isSelected = tab == current;

        return ChoiceChip(
          label: Text(tab),
          selected: isSelected,
          onSelected: (_) => onTabChanged(tab),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
          selectedColor: Theme.of(context).colorScheme.primary,
          backgroundColor: Colors.grey.shade300,
        );
      }).toList(),
    );
  }
}
