import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../services/api_service.dart';
import '../../data/app_state.dart';
import 'dart:async';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';

class ChatScreen extends StatefulWidget {
  final int roomId;
  final int friendId;
  final String friendName;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.friendId,
    required this.friendName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isBlocked = false;
  bool _iBlockedThem = false;
  bool _theyBlockedMe = false;
  bool _iReportedThem = false;
  bool _showEmojiPicker = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _checkBlockStatus();
    _checkReportStatus();
    _loadMessages();
    // 3초마다 새 메시지 확인 (실시간처럼 동작)
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadMessages(showLoading: false);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkBlockStatus() async {
    try {
      final result = await ApiService.checkIfBlocked(widget.friendId);
      if (mounted) {
        setState(() {
          _isBlocked = result['is_blocked'] ?? false;
          _iBlockedThem = result['i_blocked_them'] ?? false;
          _theyBlockedMe = result['they_blocked_me'] ?? false;
        });
      }
    } catch (e) {
      debugPrint("차단 상태 확인 오류: $e");
    }
  }

  int? _reportId;

  Future<void> _checkReportStatus() async {
    try {
      final result = await ApiService.checkMyReport(widget.friendId);
      if (mounted) {
        setState(() {
          _iReportedThem = result['has_reported'] ?? false;
          _reportId = result['report_id'];
        });
      }
    } catch (e) {
      debugPrint("신고 상태 확인 오류: $e");
    }
  }

  Future<void> _loadMessages({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final messages = await ApiService.getChatMessages(widget.roomId);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("메시지 불러오기 오류: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_isBlocked || _iReportedThem) {
      _showBlockedDialog();
      return;
    }

    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final newMessage = await ApiService.sendChatMessage(widget.roomId, content);
      
      if (mounted) {
        setState(() {
          _messages.add(newMessage);
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("메시지 전송 오류: $e");
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("메시지 전송 실패: $e")),
        );
        // 실패 시 텍스트 복원
        _messageController.text = content;
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showBlockedDialog() {
    String message;
    if (_iReportedThem) {
      message = "신고한 사용자에게는 메시지를 보낼 수 없습니다.\n신고를 취소하려면 메뉴에서 신고 취소를 선택해주세요.";
    } else if (_iBlockedThem) {
      message = "차단한 사용자에게는 메시지를 보낼 수 없습니다.\n차단을 해제하려면 프로필 설정에서 해제해주세요.";
    } else if (_theyBlockedMe) {
      message = "상대방이 회원님을 차단하여 메시지를 보낼 수 없습니다.";
    } else {
      message = "이 사용자와 메시지를 주고받을 수 없습니다.";
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('메시지 전송 불가', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                widget.friendName.substring(0, 1),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(widget.friendName),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'block') {
                _showBlockDialog();
              } else if (value == 'unblock') {
                _showUnblockDialog();
              } else if (value == 'report') {
                _showReportDialog();
              } else if (value == 'unreport') {
                _showUnreportDialog();
              } else if (value == 'leave') {
                _showLeaveChatDialog();
              }
            },
            itemBuilder: (context) => [
              // 차단하지 않았고 차단당하지 않았을 때만 차단 버튼 표시
              if (!_theyBlockedMe && !_iBlockedThem && !_iReportedThem)
                const PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(Icons.block, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('차단하기'),
                    ],
                  ),
                ),
              // 차단했을 때 차단 해제 버튼 표시
              if (_iBlockedThem)
                const PopupMenuItem(
                  value: 'unblock',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 20, color: Colors.green),
                      SizedBox(width: 12),
                      Text('차단 해제'),
                    ],
                  ),
                ),
              // 신고하지 않았고 차단당하지 않았을 때만 신고 버튼 표시
              if (!_theyBlockedMe && !_iReportedThem && !_iBlockedThem)
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.report, size: 20, color: Colors.orange),
                      SizedBox(width: 12),
                      Text('신고하기'),
                    ],
                  ),
                ),
              // 신고했을 때 신고 해제 버튼 표시 (관리자 검토 전까지만)
              if (_iReportedThem)
                const PopupMenuItem(
                  value: 'unreport',
                  child: Row(
                    children: [
                      Icon(Icons.undo, size: 20, color: Colors.blue),
                      SizedBox(width: 12),
                      Text('신고 취소'),
                    ],
                  ),
                ),
              // 채팅방 나가기는 항상 표시
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, size: 20, color: Colors.grey),
                    SizedBox(width: 12),
                    Text('채팅방 나가기'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 차단/신고 상태 안내
          if (_isBlocked || _iReportedThem)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: _iReportedThem ? Colors.orange.shade50 : Colors.red.shade50,
              child: Row(
                children: [
                  Icon(
                    _iReportedThem ? Icons.report : Icons.block,
                    color: _iReportedThem ? Colors.orange.shade700 : Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _iReportedThem
                          ? "신고한 사용자입니다. 메시지를 보낼 수 없습니다."
                          : _iBlockedThem
                              ? "차단한 사용자입니다. 메시지를 보낼 수 없습니다."
                              : "상대방이 회원님을 차단하여 메시지를 보낼 수 없습니다.",
                      style: TextStyle(
                        color: _iReportedThem ? Colors.orange.shade700 : Colors.red.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 메시지 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              (_isBlocked || _iReportedThem)
                                  ? "대화가 차단되었습니다"
                                  : "첫 메시지를 보내보세요!",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(_messages[index]);
                        },
                      ),
          ),

          // 이모지 피커
          if (_showEmojiPicker)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  setState(() {
                    _messageController.text += emoji.emoji;
                  });
                },
                config: const Config(
                  height: 256,
                  checkPlatformCompatibility: true,
                ),
              ),
            ),

          // 메시지 입력 영역
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // 이모지 버튼
                if (!_isBlocked && !_iReportedThem)
                  IconButton(
                    icon: Icon(
                      _showEmojiPicker 
                          ? Icons.keyboard 
                          : Icons.emoji_emotions_outlined,
                      color: _showEmojiPicker ? Colors.blue : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _showEmojiPicker = !_showEmojiPicker;
                      });
                      if (_showEmojiPicker) {
                        FocusScope.of(context).unfocus();
                      }
                    },
                  ),
                // 파일 첨부 버튼
                if (!_isBlocked && !_iReportedThem)
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.grey),
                    onPressed: _pickFile,
                  ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_isBlocked && !_iReportedThem,
                    decoration: InputDecoration(
                      hintText: (_isBlocked || _iReportedThem)
                          ? "메시지를 보낼 수 없습니다"
                          : "메시지를 입력하세요...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    onTap: () {
                      if (_showEmojiPicker) {
                        setState(() {
                          _showEmojiPicker = false;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _isSending || _isBlocked || _iReportedThem ? null : _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isSending || _isBlocked || _iReportedThem ? Colors.grey : Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 24,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    // 시스템 메시지 처리
    if (message.messageType == "system") {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message.content,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isMe = message.senderId == AppState.currentUser?.id;
    final time = _formatTime(message.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 내가 보낸 메시지: 읽음 표시 + 시간
          if (isMe) ...[
            // 읽음 여부 표시 (1 = 안 읽음, 안 보임 = 읽음)
            if (!message.isRead)
              Padding(
                padding: const EdgeInsets.only(right: 4, bottom: 2),
                child: Text(
                  '1',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            // 시간
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 2),
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],

          // 메시지 말풍선
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
            ),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue : Colors.grey.shade200,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
              ),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 15,
                color: isMe ? Colors.white : Colors.black87,
                height: 1.4,
              ),
            ),
          ),

          // 상대방 메시지: 시간만
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 2),
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      // KST 시간으로 표시 (이미 백엔드에서 KST로 저장되어 옴)
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return "$hour:$minute";
    } catch (e) {
      return "";
    }
  }

  /// 차단 확인 다이얼로그
  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '사용자 차단',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            '${widget.friendName}님을 차단하시겠습니까?\n\n'
            '차단하면:\n'
            '• 메시지를 주고받을 수 없습니다\n'
            '• 친구 목록에서 제거됩니다\n'
            '• 게시글이 보이지 않습니다',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                
                final success = await ApiService.blockUser(widget.friendId);
                
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${widget.friendName}님을 차단했습니다')),
                  );
                  // 차단 상태 갱신
                  await _checkBlockStatus();
                }
              },
              child: const Text(
                '차단',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 신고 다이얼로그
  void _showReportDialog() {
    String selectedReason = '스팸/광고';
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                '사용자 신고',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.friendName}님을 신고합니다',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '신고 사유:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedReason,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: '스팸/광고',
                          child: Text('스팸/광고'),
                        ),
                        DropdownMenuItem(
                          value: '욕설/비방',
                          child: Text('욕설/비방'),
                        ),
                        DropdownMenuItem(
                          value: '허위정보',
                          child: Text('허위정보'),
                        ),
                        DropdownMenuItem(
                          value: '불법정보',
                          child: Text('불법정보'),
                        ),
                        DropdownMenuItem(
                          value: '기타',
                          child: Text('기타'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedReason = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '상세 내용 (선택):',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: contentController,
                      decoration: InputDecoration(
                        hintText: '신고 사유를 자세히 적어주세요',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    
                    final success = await ApiService.reportUser(
                      userId: widget.friendId,
                      reason: selectedReason,
                      content: contentController.text.trim().isEmpty
                          ? null
                          : contentController.text.trim(),
                    );
                    
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('신고가 접수되었습니다. 검토 후 조치하겠습니다.'),
                        ),
                      );
                      // 신고 후 채팅창 비활성화 (차단과 동일하게 처리)
                      await _checkReportStatus();
                      setState(() {
                        _iReportedThem = true;
                      });
                    }
                  },
                  child: const Text(
                    '신고',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 채팅방 나가기 다이얼로그
  void _showLeaveChatDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.exit_to_app, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text('채팅방 나가기'),
            ],
          ),
          content: const Text(
            '채팅방을 나가시겠습니까?\n\n'
            '나가면:\n'
            '• 채팅방 목록에서 사라집니다\n'
            '• 상대방에게 나간 사실이 알려집니다\n'
            '• 다시 들어올 수 없습니다',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                
                final success = await ApiService.deleteChatRoom(widget.roomId);
                
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('채팅방을 나갔습니다')),
                  );
                  Navigator.pop(context); // 채팅 화면 닫기
                }
              },
              child: const Text(
                '나가기',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 차단 해제 다이얼로그
  void _showUnblockDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              SizedBox(width: 8),
              Text('차단 해제'),
            ],
          ),
          content: Text(
            '${widget.friendName}님의 차단을 해제하시겠습니까?\n\n'
            '해제하면:\n'
            '• 다시 메시지를 주고받을 수 있습니다\n'
            '• 친구 목록에 다시 추가할 수 있습니다\n'
            '• 게시글을 볼 수 있습니다',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                
                final success = await ApiService.unblockUser(widget.friendId);
                
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${widget.friendName}님의 차단을 해제했습니다')),
                  );
                  // 차단 상태 갱신
                  await _checkBlockStatus();
                }
              },
              child: const Text(
                '해제',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 신고 취소 다이얼로그
  void _showUnreportDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.undo, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Text('신고 취소'),
            ],
          ),
          content: const Text(
            '신고를 취소하시겠습니까?\n\n'
            '관리자 검토가 진행 중인 경우\n'
            '취소할 수 없습니다.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('닫기'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                
                if (_reportId != null) {
                  final success = await ApiService.cancelReport(_reportId!);
                  
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('신고를 취소했습니다')),
                    );
                    // 신고 상태 갱신
                    await _checkReportStatus();
                  }
                }
              },
              child: const Text(
                '취소하기',
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 파일 선택
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'pdf', 'doc', 'docx', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // 파일 크기 제한 (10MB)
        if (file.size > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('파일 크기는 10MB 이하여야 합니다')),
            );
          }
          return;
        }

        // TODO: 실제 파일 업로드 구현
        // 현재는 파일 이름만 메시지로 전송
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('파일 선택됨: ${file.name}\n\n파일 업로드 기능은 서버에 업로드 API가 필요합니다.'),
              duration: const Duration(seconds: 3),
            ),
          );
          
          // 파일 이름을 메시지로 전송 (임시)
          setState(() {
            _messageController.text = '[파일] ${file.name}';
          });
        }
      }
    } catch (e) {
      debugPrint('파일 선택 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파일 선택 실패: $e')),
        );
      }
    }
  }
}
