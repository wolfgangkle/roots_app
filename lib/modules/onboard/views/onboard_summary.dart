import 'package:flutter/material.dart';

class OnboardSummaryScreen extends StatelessWidget {
  final String heroName;
  final String race;
  final String villageName;
  final String startZone;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;

  const OnboardSummaryScreen({
    Key? key,
    required this.heroName,
    required this.race,
    required this.villageName,
    required this.startZone,
    required this.onConfirm,
    required this.onEdit,
  }) : super(key: key);

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Review Your Choices")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Please review your choices before finalizing:",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            _buildSummaryRow("Hero Name", heroName),
            _buildSummaryRow("Race", race),
            _buildSummaryRow("Village Name", villageName),
            _buildSummaryRow("Starting Zone", startZone),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onEdit,
                    child: const Text("Edit"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    child: const Text("Confirm"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
