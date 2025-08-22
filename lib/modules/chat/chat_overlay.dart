import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:roots_app/modules/chat/chat_message_model.dart';
import 'package:roots_app/modules/chat/chat_service.dart';
import 'package:roots_app/modules/profile/models/user_profile_model.dart';
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/tokens.dart';

class ChatOverlay extends StatefulWidget {
  final bool usePositioned;

  const ChatOverlay({super.key, this.usePositioned = true});

  @override
  State<ChatOverlay> createState() => _ChatOverlayState();
}

class _ChatOverlayState extends State<ChatOverlay> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isCollapsed = false;
  double _height = 220;
  final double _width = 380;

  void _toggleCollapsed() => setState(() => _isCollapsed = !_isCollapsed);

  void _sendMessage(String sender) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ChatService.sendMessage(sender, text);
    _controller.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🔐 Tokens
    final style = context.watch<StyleManager>().currentStyle;
    final glass = style.glass;
    final text = style.textOnGlass;

    final heroName =
        Provider.of<UserProfileModel>(context, listen: false).heroName;

    final chatPanel = _isCollapsed
        ? _CollapsedFab(onTap: _toggleCollapsed, text: text)
        : _ExpandedChat(
      width: _width,
      height: _height,
      onCollapse: _toggleCollapsed,
      controller: _controller,
      scrollController: _scrollController,
      onSend: () => _sendMessage(heroName ?? 'Unknown'),
      onDrag: (dy) => setState(() {
        _height = (_height + dy).clamp(140.0, 440.0);
      }),
      text: text,
      glass: glass,
    );

    final positionedContent = Positioned(
      right: 12,
      bottom: 12,
      child: chatPanel,
    );

    return widget.usePositioned ? positionedContent : chatPanel;
  }
}

/// Collapsed floating button (tokenized)
class _CollapsedFab extends StatelessWidget {
  final VoidCallback onTap;
  final TextOnGlassTokens text;

  const _CollapsedFab({required this.onTap, required this.text});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      onPressed: onTap,
      // No hard-coded color: let current theme decide contrast
      child: Text('💬', style: TextStyle(color: text.primary)),
    );
  }
}

/// Expanded Chat with glass/solid aware container
class _ExpandedChat extends StatelessWidget {
  final double width;
  final double height;
  final VoidCallback onCollapse;
  final TextEditingController controller;
  final ScrollController scrollController;
  final VoidCallback onSend;
  final void Function(double dy) onDrag;
  final TextOnGlassTokens text;
  final GlassTokens glass;

  const _ExpandedChat({
    required this.width,
    required this.height,
    required this.onCollapse,
    required this.controller,
    required this.scrollController,
    required this.onSend,
    required this.onDrag,
    required this.text,
    required this.glass,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = glass.borderColor ??
        text.subtle.withOpacity(glass.strokeOpacity);

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // Glassy blur if in glass mode
          if (glass.mode == SurfaceMode.glass)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: glass.blurSigma, sigmaY: glass.blurSigma),
              child: const SizedBox.expand(),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: glass.baseColor.withOpacity(glass.mode == SurfaceMode.solid ? 1.0 : glass.opacity),
              borderRadius: BorderRadius.circular(12),
              border: glass.showBorder
                  ? Border.all(color: borderColor)
                  : null,
              boxShadow: glass.mode == SurfaceMode.solid && glass.elevation > 0
                  ? [
                BoxShadow(
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                  color: Colors.black.withOpacity(0.18),
                ),
              ]
                  : null,
            ),
            child: _PanelBody(
              width: width,
              height: height,
              onCollapse: onCollapse,
              controller: controller,
              scrollController: scrollController,
              onSend: onSend,
              onDrag: onDrag,
              text: text,
              glass: glass,
            ),
          ),
        ],
      ),
    );

    return SizedBox(width: width, height: height, child: content);
  }
}

class _PanelBody extends StatelessWidget {
  final double width;
  final double height;
  final VoidCallback onCollapse;
  final TextEditingController controller;
  final ScrollController scrollController;
  final VoidCallback onSend;
  final void Function(double dy) onDrag;
  final TextOnGlassTokens text;
  final GlassTokens glass;

  const _PanelBody({
    required this.width,
    required this.height,
    required this.onCollapse,
    required this.controller,
    required this.scrollController,
    required this.onSend,
    required this.onDrag,
    required this.text,
    required this.glass,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '💬 Global Chat',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: text.primary,
                  ),
                ),
              ),
              _IconBtn(
                onTap: onCollapse,
                icon: Icons.close,
                color: text.secondary,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Messages
          Expanded(
            child: NotificationListener<ScrollUpdateNotification>(
              onNotification: (_) => false,
              child: _MessageList(
                scrollController: scrollController,
                text: text,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Input row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: glass.baseColor.withOpacity(
                      glass.mode == SurfaceMode.solid ? 1.0 : (glass.opacity + 0.06).clamp(0.0, 1.0),
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: glass.showBorder ? Border.all(color: (glass.borderColor ?? text.subtle.withOpacity(glass.strokeOpacity))) : null,
                  ),
                  child: TextField(
                    controller: controller,
                    onSubmitted: (_) => onSend(),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Type a message…',
                      hintStyle: TextStyle(color: text.subtle.withOpacity(0.8)),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(color: text.primary, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _IconBtn(
                onTap: onSend,
                icon: Icons.send,
                color: text.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  final ScrollController scrollController;
  final TextOnGlassTokens text;
  const _MessageList({required this.scrollController, required this.text});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatMessage>>(
      stream: ChatService.getMessageStream(limit: 100),
      builder: (context, snapshot) {
        final messages = snapshot.data ?? const <ChatMessage>[];

        // Group by day and render with date separators
        final widgets = <Widget>[];
        String? lastDateLabel;
        for (final msg in messages.reversed) {
          final dateLabel = DateFormat('dd.MM.yyyy').format(msg.timestamp);
          if (dateLabel != lastDateLabel) {
            widgets.add(Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Center(
                child: Text(
                  dateLabel,
                  style: TextStyle(
                    color: text.subtle,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ));
            lastDateLabel = dateLabel;
          }

          final time = DateFormat.Hm().format(msg.timestamp);
          widgets.add(Text(
            '[$time] ${msg.sender}: ${msg.content}',
            style: TextStyle(color: text.secondary, fontSize: 12),
          ));
        }

        return ListView(
          controller: scrollController,
          reverse: true,
          children: widgets,
        );
      },
    );
  }
}

class _IconBtn extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color color;
  const _IconBtn({required this.onTap, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
