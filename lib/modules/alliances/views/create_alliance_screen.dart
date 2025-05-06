import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/modules/alliances/views/alliance_members_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:flutter/services.dart';

class CreateAllianceScreen extends StatefulWidget {
  const CreateAllianceScreen({super.key});

  @override
  State<CreateAllianceScreen> createState() => _CreateAllianceScreenState();
}

class _CreateAllianceScreenState extends State<CreateAllianceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _tagController = TextEditingController();
  final _descController = TextEditingController();

  bool _isSubmitting = false;

  void _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final name = _nameController.text.trim();
    final tag = _tagController.text.trim(); // ⬅️ preserve case
    final desc = _descController.text.trim();

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('createAlliance');
      final result = await callable.call({
        'name': name,
        'tag': tag,
        'description': desc,
      });

      final data = result.data;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Alliance '${data['name']}' created!")),
      );

      final controller = Provider.of<MainContentController>(context, listen: false);
      controller.setCustomContent(const AllianceMembersScreen());
    } catch (e) {
      debugPrint("🔥 Error creating alliance: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create alliance: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            const Text("Create an Alliance", style: TextStyle(fontSize: 22)),
            const SizedBox(height: 24),
            const Text("Alliance Name", style: TextStyle(fontSize: 16)),
            TextFormField(
              controller: _nameController,
              enabled: !_isSubmitting,
              maxLength: 40,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Alliance name is required";
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text("Alliance Tag (2–4 letters)", style: TextStyle(fontSize: 16)),
            TextFormField(
              controller: _tagController,
              enabled: !_isSubmitting,
              inputFormatters: [
                LengthLimitingTextInputFormatter(4),
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
              ],
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Alliance tag is required";
                }
                if (value.length < 2 || value.length > 4) {
                  return "Tag must be 2 to 4 letters (a–z or A–Z)";
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text("Description (optional)", style: TextStyle(fontSize: 16)),
            TextFormField(
              controller: _descController,
              enabled: !_isSubmitting,
              maxLines: 4,
              maxLength: 300,
            ),
            const SizedBox(height: 36),
            ElevatedButton.icon(
              icon: _isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: Text(_isSubmitting ? "Creating..." : "Create Alliance"),
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
