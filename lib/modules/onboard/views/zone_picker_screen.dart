

import 'package:flutter/material.dart';

class ZonePickerScreen extends StatelessWidget {
  final void Function(String zone) onNext;

  const ZonePickerScreen({super.key, required this.onNext});

  final List<Map<String, String>> zones = const [
    { 'id': 'north', 'label': 'North', 'desc': 'Cold, mountainous terrain' },
    { 'id': 'south', 'label': 'South', 'desc': 'Fertile plains and rivers' },
    { 'id': 'east',  'label': 'East',  'desc': 'Forests and mystic ruins' },
    { 'id': 'west',  'label': 'West',  'desc': 'Windswept coastlines' },
    { 'id': 'center','label': 'Center','desc': 'Ancient battlegrounds' },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Starting Zone')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Choose where you want to begin your journey.\n'
                  'This will determine your starting area on the world map.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ...zones.map((zone) {
              return Card(
                child: ListTile(
                  title: Text(zone['label']!),
                  subtitle: Text(zone['desc']!),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => onNext(zone['id']!),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
