import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/models/user.dart';

class ChatScreen extends StatefulWidget {
  final User friend;

  const ChatScreen({super.key, required this.friend});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class ChatMessage {
  final String text;
  final bool isMine;

  ChatMessage({
    required this.text,
    required this.isMine,
  });
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();

    // 🔥 채팅방 자동 등록 (채팅 탭에서 리스트로 보기 위함)
    if (!AppState.chatList.contains(widget.friend.id)) {
      AppState.chatList.add(widget.friend.id);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isMine: true));
      _messageController.clear();
    });
  }

  Future<void> _pickFile(FileType type) async {
    final result = await FilePicker.platform.pickFiles(type: type);
    if (result == null) return;

    final file = result.files.first;

    setState(() {
      _messages.add(
        ChatMessage(
          text: "📎 ${file.name}",
          isMine: true,
        ),
      );
    });
  }

  void _openEmojiPicker() {
    final emojis = [
      '😀', '😄', '😊', '😉', '😍', '😎', '😭', '😂', '😡', '👍',
      '🙌', '🔥', '💯', '❤️', '✨', '🤝', '🎉', '🤔', '😴', '🤯',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '이모지 선택',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: emojis.map((e) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _messages.add(ChatMessage(text: e, isMine: true));
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        e,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
            ],
          ),
        );
      },
    );
  }

  void _openAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_outlined),
                title: const Text('사진 보내기'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile(FileType.image);
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file_outlined),
                title: const Text('파일 보내기'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile(FileType.any);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.friend.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      '아직 메시지가 없어요.\n먼저 말을 걸어보세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];

                      return Align(
                        alignment: msg.isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 260),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: msg.isMine
                                ? theme.colorScheme.primary
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(msg.isMine ? 16 : 4),
                              bottomRight: Radius.circular(msg.isMine ? 4 : 16),
                            ),
                          ),
                          child: Text(
                            msg.text,
                            style: TextStyle(
                              color: msg.isMine ? Colors.white : Colors.black87,
                              fontSize: 15,
                              height: 1.35,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _openEmojiPicker,
                    icon: const Icon(Icons.emoji_emotions_outlined),
                    tooltip: '이모지',
                  ),

                  IconButton(
                    onPressed: _openAttachmentSheet,
                    icon: const Icon(Icons.attach_file),
                    tooltip: '사진/파일',
                  ),

                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: '메시지 입력…',
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: Colors.grey.shade400,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
