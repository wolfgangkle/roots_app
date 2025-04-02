import 'package:flutter/material.dart';

class FilterBar extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final void Function(String) onFilterSelected;

  const FilterBar({
    super.key,
    required this.filters,
    required this.selected,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: filters.map((filter) {
        final isSelected = filter == selected;

        return ChoiceChip(
          label: Text(filter),
          selected: isSelected,
          onSelected: (_) => onFilterSelected(filter),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          selectedColor: Theme.of(context).colorScheme.primary,
          backgroundColor: Colors.grey.shade200,
        );
      }).toList(),
    );
  }
}
