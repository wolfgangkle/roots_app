import 'package:flutter/material.dart';
import 'package:roots_app/screens/auth/check_user_profile.dart';

class OnboardSummaryScreen extends StatelessWidget {
  final String heroName;
  final String race;
  final String villageName;
  final String startZone;
  final Future<void> Function() onConfirm;
  final VoidCallback onEdit;
  final bool isLoading; // ✅ NEW

  const OnboardSummaryScreen({
    super.key,
    required this.heroName,
    required this.race,
    required this.villageName,
    required this.startZone,
    required this.onConfirm,
    required this.onEdit,
    this.isLoading = false, // ✅ Default to false
  });

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

  void _handleConfirm(BuildContext context) async {
    try {
      await onConfirm(); // Wait for Firestore update to finish

      if (!context.mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CheckUserProfile()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error finalizing onboarding: $e")),
      );
    }
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
                    onPressed: isLoading ? null : onEdit,
                    child: const Text("Edit"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => _handleConfirm(context),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Confirm"),
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
