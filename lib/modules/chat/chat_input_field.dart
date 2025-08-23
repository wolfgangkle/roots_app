// lib/modules/chat/chat_input_field.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_service.dart';

import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';

class ChatInputField extends StatefulWidget {
  final String sender;

  const ChatInputField({super.key, required this.sender});

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final _controller = TextEditingController();

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ChatService.sendMessage(widget.sender, text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final style = context.watch<StyleManager>().currentStyle;
    final glass = style.glass;
    final text = style.textOnGlass;
    final btn = style.buttons;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: TokenPanel(
        glass: glass,
        text: text,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        borderRadius: style.radius.card.toDouble(),
        child: Row(
          children: [
            // Borderless tokenized text field
            Expanded(
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Type your message…',
                  hintStyle:
                  TextStyle(color: text.subtle.withValues(alpha: 0.8)),
                  border: InputBorder.none,
                ),
                style: TextStyle(color: text.primary, fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            // Token button (primary)
            TokenButton(
              variant: TokenButtonVariant.primary,
              onPressed: _send,
              glass: glass,
              text: text,
              buttons: btn,
              child: const Icon(Icons.send, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
