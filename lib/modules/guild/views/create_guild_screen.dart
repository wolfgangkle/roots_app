import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/modules/guild/views/guild_dashboard_view.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:flutter/services.dart';


// 🔹 Add this wrapper widget
class CreateGuildScreen extends StatefulWidget {
  const CreateGuildScreen({super.key});

  @override
  State<CreateGuildScreen> createState() => _CreateGuildScreenState();
}

// 🔹 This is your stateful logic
class _CreateGuildScreenState extends State<CreateGuildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _tagController = TextEditingController();
  final _descController = TextEditingController();

  bool _isSubmitting = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final name = _nameController.text.trim();
    final tag = _tagController.text.trim();
    final desc = _descController.text.trim();

    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('createGuild');
      final result = await callable.call({
        'name': name,
        'tag': tag,
        'description': desc,
      });

      final data = result.data;
      final String guildId = data['guildId'];

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Guild '${data['name']}' created!")),
      );

      final controller = Provider.of<MainContentController>(context, listen: false);
      controller.setCustomContent(GuildDashboardView(guildId: guildId));
    } catch (e) {
      debugPrint("🔥 Error creating guild: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create guild: $e")),
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
    // Your form code goes here
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            const Text("Create a Guild", style: TextStyle(fontSize: 22)),
            const SizedBox(height: 24),
            const Text("Guild Name", style: TextStyle(fontSize: 16)),
            TextFormField(
              controller: _nameController,
              maxLength: 30,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Guild name is required";
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text("Guild Tag (2–4 letters)", style: TextStyle(fontSize: 16)),
            TextFormField(
              controller: _tagController,
              inputFormatters: [
                LengthLimitingTextInputFormatter(4),
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
              ],
              textCapitalization: TextCapitalization.characters, // optional: keep to help users
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Guild tag is required";
                }
                final tag = value.trim();
                if (tag.length < 2 || tag.length > 4) {
                  return "Tag must be 2 to 4 letters";
                }
                if (!RegExp(r'^[a-zA-Z]+$').hasMatch(tag)) {
                  return "Only letters allowed (A–Z or a–z)";
                }
                return null;
              },
            ),

            const SizedBox(height: 24),
            const Text("Description (optional)", style: TextStyle(fontSize: 16)),
            TextFormField(
              controller: _descController,
              maxLines: 4,
              maxLength: 300,
            ),
            const SizedBox(height: 36),
            ElevatedButton.icon(
              icon: _isSubmitting
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.check),
              label: Text(_isSubmitting ? "Creating..." : "Create Guild"),
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
