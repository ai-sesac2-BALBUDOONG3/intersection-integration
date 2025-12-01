import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/chat_message.dart';
import '../../services/api_service.dart';
import '../../data/app_state.dart';
import '../../config/api_config.dart';
import 'dart:async';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

// ✅ 다운로드 관련 추가
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:io' show File, Directory;
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

// ✅ 웹용 (조건부 import)
import 'dart:html' as html show Blob, Url, AnchorElement, window;

class ChatScreen extends StatefulWidget {
  final int roomId;
  final int friendId;
  final String friendName;
  final String? friendProfileImage;  // ✅ 추가

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.friendId,
    required this.friendName,
    this.friendProfileImage,  // ✅ 추가
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

  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

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

  // ========================================
  // ✅ 파일 업로드 관련 메서드 (웹 지원 추가)
  // ========================================

  /// 이미지 선택 및 전송 (웹/모바일 통합)
  Future<void> _pickAndSendImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;
      setState(() => _isUploading = true);

      // ✅ 웹과 모바일 구분
      if (kIsWeb) {
        // 웹: XFile의 readAsBytes 사용
        final bytes = await image.readAsBytes();
        
        if (bytes.length > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('이미지 크기는 10MB 이하여야 합니다')),
            );
          }
          setState(() => _isUploading = false);
          return;
        }

        final newMessage = await ApiService.sendImageMessageWeb(
          widget.roomId, 
          bytes, 
          image.name,
        );

        if (mounted) {
          setState(() {
            _messages.add(newMessage);
            _isUploading = false;
          });
          _scrollToBottom();
        }
      } else {
        // 모바일: File 사용
        final file = File(image.path);
        final fileSize = await file.length();
        
        if (fileSize > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('이미지 크기는 10MB 이하여야 합니다')),
            );
          }
          setState(() => _isUploading = false);
          return;
        }

        final newMessage = await ApiService.sendImageMessage(widget.roomId, file);

        if (mounted) {
          setState(() {
            _messages.add(newMessage);
            _isUploading = false;
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint("이미지 전송 오류: $e");
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("이미지 전송 실패: $e")),
        );
      }
    }
  }

  /// 사진 촬영 및 전송 (모바일만 지원)
  Future<void> _takePictureAndSend() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('웹에서는 카메라 촬영을 지원하지 않습니다')),
      );
      return;
    }

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo == null) return;
      setState(() => _isUploading = true);

      final file = File(photo.path);
      final newMessage = await ApiService.sendImageMessage(widget.roomId, file);

      if (mounted) {
        setState(() {
          _messages.add(newMessage);
          _isUploading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("사진 전송 오류: $e");
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("사진 전송 실패: $e")),
        );
      }
    }
  }

  /// 파일 선택 및 전송 (웹/모바일 통합)
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'pdf', 'doc', 'docx', 'txt', 'zip'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;
      final platformFile = result.files.first;
      
      if (platformFile.size > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('파일 크기는 10MB 이하여야 합니다')),
          );
        }
        return;
      }

      setState(() => _isUploading = true);

      // ✅ 웹과 모바일 구분
      if (kIsWeb) {
        // 웹: bytes 사용
        final bytes = platformFile.bytes;
        if (bytes == null) {
          throw Exception('파일을 읽을 수 없습니다');
        }

        final newMessage = await ApiService.sendFileMessageWeb(
          widget.roomId, 
          bytes, 
          platformFile.name,
        );

        if (mounted) {
          setState(() {
            _messages.add(newMessage);
            _isUploading = false;
          });
          _scrollToBottom();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${platformFile.name} 전송 완료')),
          );
        }
      } else {
        // 모바일: File 사용
        final file = File(platformFile.path!);
        final newMessage = await ApiService.sendFileMessage(widget.roomId, file);

        if (mounted) {
          setState(() {
            _messages.add(newMessage);
            _isUploading = false;
          });
          _scrollToBottom();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${platformFile.name} 전송 완료')),
          );
        }
      }
    } catch (e) {
      debugPrint('파일 선택 오류: $e');
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파일 전송 실패: $e')),
        );
      }
    }
  }

  /// 첨부 옵션 표시
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage();
              },
            ),
            // 웹에서는 카메라 옵션 숨김
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('사진 촬영'),
                onTap: () {
                  Navigator.pop(context);
                  _takePictureAndSend();
                },
              ),
            ListTile(
              leading: const Icon(Icons.attach_file, color: Colors.orange),
              title: const Text('파일 선택'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.grey),
              title: const Text('취소'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  /// 이미지 뷰어
  void _showImageViewer(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network("${ApiConfig.baseUrl}$imageUrl"),
            ),
          ),
        ),
      ),
    );
  }

  /// 파일 다운로드 (PC/폰에 실제 저장)
  Future<void> _downloadFile(String fileUrl, String fileName) async {
    try {
      final url = "${ApiConfig.baseUrl}$fileUrl";
      
      if (kIsWeb) {
        // ========================================
        // 웹: PC에 실제 저장
        // ========================================
        
        // 1. 파일 다운로드
        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) {
          throw Exception('파일 다운로드 실패');
        }
        
        // 2. Blob 생성
        final blob = html.Blob([response.bodyBytes]);
        
        // 3. 다운로드 URL 생성
        final downloadUrl = html.Url.createObjectUrlFromBlob(blob);
        
        // 4. 가상 <a> 태그로 다운로드 트리거
        final anchor = html.AnchorElement(href: downloadUrl)
          ..setAttribute('download', fileName)
          ..click();
        
        // 5. 메모리 해제
        html.Url.revokeObjectUrl(downloadUrl);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$fileName 다운로드 완료!')),
          );
        }
      } else {
        // ========================================
        // 모바일: 갤러리/다운로드 폴더에 저장
        // ========================================
        
        // 1. 저장 권한 확인
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('저장 권한이 필요합니다')),
              );
            }
            return;
          }
        }
        
        // 2. 파일 다운로드
        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) {
          throw Exception('파일 다운로드 실패');
        }
        
        // 3. 이미지인지 확인
        final isImage = fileName.toLowerCase().endsWith('.png') ||
                        fileName.toLowerCase().endsWith('.jpg') ||
                        fileName.toLowerCase().endsWith('.jpeg') ||
                        fileName.toLowerCase().endsWith('.gif');
        
        if (isImage) {
          // 이미지 → 갤러리 저장
          final result = await ImageGallerySaver.saveImage(
            Uint8List.fromList(response.bodyBytes),
            name: fileName.split('.').first,
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$fileName\n갤러리에 저장 완료!')),
            );
          }
        } else {
          // 일반 파일 → 다운로드 폴더 저장
          final downloadsPath = '/storage/emulated/0/Download';
          
          // 파일 저장
          final file = File('$downloadsPath/$fileName');
          await file.writeAsBytes(response.bodyBytes);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$fileName\n다운로드 폴더에 저장 완료!')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('파일 다운로드 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('다운로드 실패: $e')),
        );
      }
    }
  }

  // ========================================
  // 기존 메서드들
  // ========================================

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
            // ========================================
            // ✅ 프로필 이미지 표시
            // ========================================
            widget.friendProfileImage != null
                ? CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(
                      "${ApiConfig.baseUrl}${widget.friendProfileImage}",
                    ),
                    onBackgroundImageError: (_, __) {},
                  )
                : CircleAvatar(
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

          if (_isUploading)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.blue.shade50,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('파일 업로드 중...', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),

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
                if (!_isBlocked && !_iReportedThem)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                    onPressed: _isUploading ? null : _showAttachmentOptions,
                  ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_isBlocked && !_iReportedThem && !_isUploading,
                    decoration: InputDecoration(
                      hintText: _isUploading
                          ? "파일 업로드 중..."
                          : (_isBlocked || _iReportedThem)
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
                  onTap: _isSending || _isBlocked || _iReportedThem || _isUploading ? null : _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isSending || _isBlocked || _iReportedThem || _isUploading ? Colors.grey : Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: _isSending || _isUploading
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
    // ✅ 디버깅: 메시지 정보 출력
    debugPrint("=== 메시지 디버그 ===");
    debugPrint("ID: ${message.id}");
    debugPrint("Content: ${message.content}");
    debugPrint("MessageType: ${message.messageType}");
    debugPrint("FileUrl: ${message.fileUrl}");
    debugPrint("FileName: ${message.fileName}");
    debugPrint("FileType: ${message.fileType}");
    debugPrint("isImage: ${message.isImage}");
    debugPrint("==================");
    
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
          if (isMe) ...[
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.isImage && message.fileUrl != null) ...[
                  GestureDetector(
                    onTap: () => _showImageViewer(message.fileUrl!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        "${ApiConfig.baseUrl}${message.fileUrl}",
                        width: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 200,
                          height: 150,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.broken_image, size: 50),
                        ),
                        loadingBuilder: (_, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 200,
                            height: 150,
                            color: Colors.grey.shade300,
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        },
                      ),
                    ),
                  ),
                  if (message.content != "[이미지]") ...[
                    const SizedBox(height: 8),
                    Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 15,
                        color: isMe ? Colors.white : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ]
                else if (message.messageType == "file" && message.fileUrl != null) ...[
                  GestureDetector(
                    onTap: () => _downloadFile(message.fileUrl!, message.fileName ?? "파일"),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue.shade700 : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.insert_drive_file,
                            color: isMe ? Colors.white : Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.fileName ?? "파일",
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (message.fileSize != null)
                                  Text(
                                    message.fileSizeFormatted,
                                    style: TextStyle(
                                      color: isMe ? Colors.white70 : Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.download,
                            color: isMe ? Colors.white : Colors.blue,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ]
                else ...[
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: isMe ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),

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
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return "$hour:$minute";
    } catch (e) {
      return "";
    }
  }

  // 나머지 다이얼로그 메서드들은 동일하므로 생략...
  // (기존 코드 그대로 사용)

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('사용자 차단', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  await _checkBlockStatus();
                }
              },
              child: const Text('차단', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showReportDialog() {
    String selectedReason = "스팸";
    final TextEditingController contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.report, color: Colors.orange, size: 24),
                  SizedBox(width: 8),
                  Text('사용자 신고'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${widget.friendName}님을 신고하는 이유를 선택해주세요', style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedReason,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: "스팸", child: Text("스팸")),
                        DropdownMenuItem(value: "욕설", child: Text("욕설 및 혐오 발언")),
                        DropdownMenuItem(value: "허위정보", child: Text("허위 정보")),
                        DropdownMenuItem(value: "기타", child: Text("기타")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedReason = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: contentController,
                      decoration: InputDecoration(
                        hintText: '신고 사유를 자세히 적어주세요',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                      content: contentController.text.trim().isEmpty ? null : contentController.text.trim(),
                    );
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('신고가 접수되었습니다. 검토 후 조치하겠습니다.')),
                      );
                      await _checkReportStatus();
                      setState(() {
                        _iReportedThem = true;
                      });
                    }
                  },
                  child: const Text('신고', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLeaveChatDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.exit_to_app, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text('채팅방 나가기'),
            ],
          ),
          content: const Text(
            '채팅방을 나가시겠습니까?\n\n나가면:\n• 채팅방 목록에서 사라집니다\n• 상대방에게 나간 사실이 알려집니다\n• 다시 들어올 수 없습니다',
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
                  Navigator.pop(context);
                }
              },
              child: const Text('나가기', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showUnblockDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              SizedBox(width: 8),
              Text('차단 해제'),
            ],
          ),
          content: Text(
            '${widget.friendName}님의 차단을 해제하시겠습니까?\n\n해제하면:\n• 다시 메시지를 주고받을 수 있습니다\n• 친구 목록에 다시 추가할 수 있습니다\n• 게시글을 볼 수 있습니다',
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
                  await _checkBlockStatus();
                }
              },
              child: const Text('해제', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showUnreportDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.undo, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Text('신고 취소'),
            ],
          ),
          content: const Text(
            '신고를 취소하시겠습니까?\n\n관리자 검토가 진행 중인 경우\n취소할 수 없습니다.',
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
                    await _checkReportStatus();
                  }
                }
              },
              child: const Text('취소하기', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}