import 'package:flutter/material.dart';

class CraftingTab extends StatelessWidget {
  const CraftingTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder data for crafting items
    final dummyCraftingItems = [
      {
        'name': 'Iron Sword',
        'type': 'Weapons',
        'cost': '3 Iron, 1 Wood',
      },
      {
        'name': 'Leather Armor',
        'type': 'Armor',
        'cost': '2 Hide, 2 Thread',
      },
      {
        'name': 'Health Potion',
        'type': 'Other',
        'cost': '2 Herbs, 1 Water',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dummyCraftingItems.length,
      itemBuilder: (context, index) {
        final item = dummyCraftingItems[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['name'] ?? '',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('💸 Cost: ${item['cost']}'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Crafting "${item['name']}" not implemented yet!')),
                      );
                    },
                    child: const Text('Craft'),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
