import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/modules/chat/chat_service.dart';
import 'package:roots_app/modules/chat/chat_message_model.dart';
import 'package:roots_app/modules/profile/models/user_profile_model.dart';
import 'package:intl/intl.dart';

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
    final heroName =
        Provider.of<UserProfileModel>(context, listen: false).heroName;

    final chatContent = _isCollapsed
        ? FloatingActionButton(
      mini: true,
      backgroundColor: Colors.black.withAlpha(217),
      onPressed: () {
        setState(() {
          _isCollapsed = false;
        });
      },
      child: const Icon(Icons.chat_bubble, color: Colors.white),
    )
        : GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _height -= details.delta.dy;
          _height = _height.clamp(120.0, 400.0);
        });
      },
      child: Container(
        width: _width,
        height: _height,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(217),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('💬 Global Chat',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.minimize,
                      color: Colors.white, size: 16),
                  onPressed: () {
                    setState(() {
                      _isCollapsed = true;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: ChatService.getMessageStream(limit: 20),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();

                  final messages = snapshot.data!;
                  _scrollToBottom();

                  return ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    reverse: true,
                    children:
                    _buildGroupedMessages(messages).reversed.toList(),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Type message...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 6),
                    ),
                    onSubmitted: (_) => _sendMessage(heroName),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () => _sendMessage(heroName),
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                )
              ],
            )
          ],
        ),
      ),
    );

    // ➤ Wrap in a Stack+Positioned only if required
    if (widget.usePositioned) {
      return Stack(
        children: [
          Positioned(
            right: 16,
            bottom: 16,
            child: chatContent,
          ),
        ],
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 16),
        child: chatContent,
      );
    }
  }

  List<Widget> _buildGroupedMessages(List<ChatMessage> messages) {
    final List<Widget> widgets = [];
    String? lastDateLabel;

    for (final msg in messages) {
      final now = DateTime.now();
      final isToday = msg.timestamp.year == now.year &&
          msg.timestamp.month == now.month &&
          msg.timestamp.day == now.day;

      final isYesterday = msg.timestamp.year == now.year &&
          msg.timestamp.month == now.month &&
          msg.timestamp.day == now.day - 1;

      final dateLabel = isToday
          ? 'Today'
          : isYesterday
          ? 'Yesterday'
          : DateFormat('dd.MM.yyyy').format(msg.timestamp);

      if (dateLabel != lastDateLabel) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
          child: Text(
            dateLabel,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ));
        lastDateLabel = dateLabel;
      }

      final time = DateFormat.Hm().format(msg.timestamp);
      widgets.add(Text(
        '[$time] ${msg.sender}: ${msg.content}',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ));
    }

    return widgets;
  }
}
