import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // Clipboard 사용
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/chat_message.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../data/app_state.dart';
import '../../config/api_config.dart';
import '../friends/friend_profile_screen.dart';
import 'utils/chat_formatters.dart';
import 'widgets/status_banner.dart';
import 'widgets/pinned_message_bar.dart';
import 'widgets/message_input_field.dart';
import 'widgets/chat_header.dart';
import 'dialogs/block_dialogs.dart';
import 'dialogs/report_dialogs.dart';
import 'dialogs/leave_chat_dialog.dart';
import 'dialogs/message_menu_dialog.dart';
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
  final String? friendProfileImage;
  final bool iReportedThem;  // ✅ 통합: 내가 신고/차단함
  final bool theyBlockedMe;  // ✅ 통합: 상대방이 나를 신고/차단함
  final bool theyLeft;  // ✅ 상대방이 채팅방을 나감

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.friendId,
    required this.friendName,
    this.friendProfileImage,
    this.iReportedThem = false,
    this.theyBlockedMe = false,
    this.theyLeft = false,  // ✅ 추가
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<ChatMessage> _messages = [];
  List<ChatMessage> _filteredMessages = [];
  List<ChatMessage> _pinnedMessages = [];  // 고정된 메시지 목록
  int _currentPinnedIndex = 0;  // 현재 표시 중인 고정 메시지 인덱스
  final Map<int, GlobalKey> _messageKeys = {};  // 메시지 ID별 GlobalKey
  bool _isLoading = true;
  bool _isUserScrolling = false;  // 사용자가 스크롤 중인지 여부
  double _lastScrollPosition = 0;  // 마지막 스크롤 위치
  bool _isSending = false;
  final Map<int, Timer> _messageTimers = {};  // 메시지별 타이머 (60초 카운트다운)
  final Map<int, int> _messageCountdowns = {};  // 메시지별 남은 시간 (초)
  bool _isBlocked = false;
  bool _iBlockedThem = false;
  bool _theyBlockedMe = false;
  bool _iReportedThem = false;
  bool _showEmojiPicker = false;
  bool _isSearchMode = false;
  Timer? _pollingTimer;

  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // 위젯의 초기값으로 로컬 상태 초기화
    _iReportedThem = widget.iReportedThem;
    _theyBlockedMe = widget.theyBlockedMe;
    _checkBlockStatus();
    _checkReportStatus();
    _loadMessages();
    // 3초마다 새 메시지 확인 (실시간처럼 동작)
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // 사용자가 스크롤을 올려서 보고 있으면 자동으로 맨 밑으로 가지 않음
      final shouldScrollToBottom = !_isUserScrolling && 
          _scrollController.hasClients &&
          (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100);
      _loadMessages(showLoading: false, scrollToBottom: shouldScrollToBottom);
    });
    
    // 스크롤 리스너 추가
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    // 모든 메시지 타이머 취소
    for (var timer in _messageTimers.values) {
      timer.cancel();
    }
    _messageTimers.clear();
    _messageCountdowns.clear();
    super.dispose();
  }

  void _filterMessages(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMessages = _messages;
      } else {
        _filteredMessages = _messages.where((message) {
          return message.content.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _updateFilteredMessages() {
    if (_searchController.text.isEmpty) {
      _filteredMessages = _messages;
    } else {
      _filterMessages(_searchController.text);
    }
  }

  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        _searchController.clear();
        _filteredMessages = _messages;
      }
    });
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
      
      // 이미지 미리보기 데이터 준비
      Uint8List? imageBytes;
      if (kIsWeb) {
        imageBytes = await image.readAsBytes();
      } else {
        final file = File(image.path);
        imageBytes = await file.readAsBytes();
      }
      
      // 확인 다이얼로그 표시
      final shouldUpload = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.image, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Text('이미지 업로드'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 이미지 미리보기
                if (imageBytes != null)
                  Container(
                    constraints: const BoxConstraints(
                      maxHeight: 300,
                      maxWidth: 300,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        imageBytes,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  '이 이미지를 업로드하시겠습니까?',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '파일명: ${image.name}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                '업로드',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

      if (shouldUpload != true) return;
      
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
            _filteredMessages = _messages;
            _isUploading = false;
          });
          _scrollToBottom();
          // 60초 카운트다운 시작
          _startMessageCountdown(newMessage.id);
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
            _filteredMessages = _messages;
            _isUploading = false;
          });
          _scrollToBottom();
          // 60초 카운트다운 시작
          _startMessageCountdown(newMessage.id);
        }
      }
    } catch (e) {
      debugPrint("이미지 전송 오류: $e");
      if (mounted) {
        setState(() => _isUploading = false);
        
        // ✅ 신고/차단 에러 메시지 처리
        String errorMessage = "이미지 전송 실패: $e";
        if (e.toString().contains("차단된 사용자")) {
          errorMessage = "차단된 사용자와는 채팅할 수 없습니다";
          _checkBlockStatus();
        } else if (e.toString().contains("신고된 사용자")) {
          errorMessage = "신고된 사용자와는 채팅할 수 없습니다";
          _checkReportStatus();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
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
          _updateFilteredMessages();
          _isUploading = false;
        });
        _scrollToBottom();
        // 60초 카운트다운 시작
        _startMessageCountdown(newMessage.id);
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

      // 파일 크기 포맷팅
      String fileSizeText;
      if (platformFile.size < 1024) {
        fileSizeText = '${platformFile.size} B';
      } else if (platformFile.size < 1024 * 1024) {
        fileSizeText = '${(platformFile.size / 1024).toStringAsFixed(1)} KB';
      } else {
        fileSizeText = '${(platformFile.size / (1024 * 1024)).toStringAsFixed(1)} MB';
      }

      // 확인 다이얼로그 표시
      final shouldUpload = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.insert_drive_file, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text('파일 업로드'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '이 파일을 업로드하시겠습니까?',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Text(
                '파일명: ${platformFile.name}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '파일 크기: $fileSizeText',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                '업로드',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

      if (shouldUpload != true) return;

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
            _filteredMessages = _messages;
            _isUploading = false;
          });
          _scrollToBottom();
          // 60초 카운트다운 시작
          _startMessageCountdown(newMessage.id);
          
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
            _filteredMessages = _messages;
            _isUploading = false;
          });
          _scrollToBottom();
          // 60초 카운트다운 시작
          _startMessageCountdown(newMessage.id);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${platformFile.name} 전송 완료')),
          );
        }
      }
    } catch (e) {
      debugPrint('파일 선택 오류: $e');
      if (mounted) {
        setState(() => _isUploading = false);
        
        // ✅ 신고/차단 에러 메시지 처리
        String errorMessage = '파일 전송 실패: $e';
        if (e.toString().contains("차단된 사용자")) {
          errorMessage = "차단된 사용자와는 채팅할 수 없습니다";
          _checkBlockStatus();
        } else if (e.toString().contains("신고된 사용자")) {
          errorMessage = "신고된 사용자와는 채팅할 수 없습니다";
          _checkReportStatus();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
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
              leading: const Icon(Icons.phone, color: Colors.purple),
              title: const Text('내 번호 보내기'),
              onTap: () {
                Navigator.pop(context);
                _sendPhoneNumber();
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

  /// 메시지 60초 카운트다운 시작
  void _startMessageCountdown(int messageId) {
    // 기존 타이머가 있으면 취소
    _messageTimers[messageId]?.cancel();
    
    // 60초로 초기화하고 즉시 UI 업데이트
    if (mounted) {
      setState(() {
        _messageCountdowns[messageId] = 60;
      });
    }
    
    // 1초마다 카운트다운
    _messageTimers[messageId] = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_messageCountdowns.containsKey(messageId)) {
            _messageCountdowns[messageId] = _messageCountdowns[messageId]! - 1;
            
            // 0초가 되면 타이머 취소 및 카운트다운 제거
            if (_messageCountdowns[messageId]! <= 0) {
              timer.cancel();
              _messageTimers.remove(messageId);
              _messageCountdowns.remove(messageId);
            }
          } else {
            timer.cancel();
            _messageTimers.remove(messageId);
          }
        });
      } else {
        timer.cancel();
        _messageTimers.remove(messageId);
        _messageCountdowns.remove(messageId);
      }
    });
  }

  /// 메시지 삭제
  Future<void> _deleteMessage(int messageId) async {
    // 확인 다이얼로그
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('메시지 삭제'),
          ],
        ),
        content: const Text(
          '이 메시지를 삭제하시겠습니까?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '삭제',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      final success = await ApiService.deleteChatMessage(widget.roomId, messageId);
      
      if (success && mounted) {
        // 타이머 취소
        _messageTimers[messageId]?.cancel();
        _messageTimers.remove(messageId);
        _messageCountdowns.remove(messageId);
        
        // 메시지 목록에서 제거
        setState(() {
          _messages.removeWhere((m) => m.id == messageId);
          _updateFilteredMessages();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('메시지가 삭제되었습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("메시지 삭제 오류: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('메시지 삭제 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 내 전화번호 전송
  Future<void> _sendPhoneNumber() async {
    final currentUser = AppState.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      return;
    }

    // 전화번호가 없으면 안내
    if (currentUser.phone == null || currentUser.phone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('등록된 전화번호가 없습니다')),
      );
      return;
    }

    // 확인 다이얼로그 표시
    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.phone, color: Colors.purple, size: 24),
            SizedBox(width: 8),
            Text('전화번호 전송'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.friendName}님에게 내 전화번호를 보내시겠습니까?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '이름: ${currentUser.name}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '전화번호: ${currentUser.phone}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '전송',
              style: TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldSend != true) return;

    // 메시지 전송
    final messageContent = '📱 ${currentUser.name}\n${currentUser.phone}';
    
    setState(() => _isSending = true);

    try {
      final newMessage = await ApiService.sendChatMessage(
        widget.roomId,
        messageContent,
      );

      if (mounted) {
        setState(() {
          _messages.add(newMessage);
          _updateFilteredMessages();
          _isSending = false;
        });
        _scrollToBottom();
        // 60초 카운트다운 시작
        _startMessageCountdown(newMessage.id);
      }
    } catch (e) {
      debugPrint("전화번호 전송 오류: $e");
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('전화번호 전송 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  Future<void> _loadMessages({bool showLoading = true, bool scrollToBottom = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final messages = await ApiService.getChatMessages(widget.roomId);
      if (mounted) {
        setState(() {
          _messages = messages;
          // 시간 순서대로만 정렬 (고정 여부와 관계없이 원래 위치 유지)
          _messages.sort((a, b) {
            return a.createdAt.compareTo(b.createdAt);
          });
          
          // 고정된 메시지 목록 추출 (상단 표시용) - 시간 역순으로 정렬 (가장 최신이 먼저)
          _pinnedMessages = _messages.where((m) => m.isPinned).toList();
          _pinnedMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          // 현재 인덱스가 범위를 벗어나면 0으로 리셋
          if (_currentPinnedIndex >= _pinnedMessages.length) {
            _currentPinnedIndex = 0;
          }
          
          // 각 메시지에 GlobalKey 생성
          for (var msg in _messages) {
            if (!_messageKeys.containsKey(msg.id)) {
              _messageKeys[msg.id] = GlobalKey();
            }
          }
          
          _updateFilteredMessages();
          _isLoading = false;
        });
        // scrollToBottom이 true이고 사용자가 스크롤하지 않을 때만 마지막으로 스크롤
        if (scrollToBottom && !_isUserScrolling) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              final maxScroll = _scrollController.position.maxScrollExtent;
              final currentPosition = _scrollController.position.pixels;
              // 맨 밑 근처에 있을 때만 자동 스크롤
              if (currentPosition >= maxScroll - 100) {
        _scrollToBottom();
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint("메시지 불러오기 오류: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    // 로컬 상태와 위젯 상태를 모두 확인
    final isBlocked = _iReportedThem || _iBlockedThem || widget.iReportedThem || widget.theyBlockedMe || widget.theyLeft;
    if (isBlocked) {
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
          _updateFilteredMessages();
          _isSending = false;
        });
        _scrollToBottom();
        // 60초 카운트다운 시작
        _startMessageCountdown(newMessage.id);
      }
    } catch (e) {
      debugPrint("메시지 전송 오류: $e");
      if (mounted) {
        setState(() => _isSending = false);
        
        // ✅ 신고/차단 에러 메시지 처리
        String errorMessage = "메시지 전송 실패: $e";
        if (e.toString().contains("차단된 사용자")) {
          errorMessage = "차단된 사용자와는 채팅할 수 없습니다";
          // 차단 상태 다시 확인
          _checkBlockStatus();
        } else if (e.toString().contains("신고된 사용자")) {
          errorMessage = "신고된 사용자와는 채팅할 수 없습니다";
          // 신고 상태 다시 확인
          _checkReportStatus();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
        _messageController.text = content;
      }
    }
  }

  // 스크롤 리스너
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final currentPosition = _scrollController.position.pixels;
    final maxScroll = _scrollController.position.maxScrollExtent;
    
    // 사용자가 스크롤을 올렸는지 확인 (100px 이상 위로 올렸으면 사용자가 스크롤 중)
    if (currentPosition < maxScroll - 100) {
      _isUserScrolling = true;
      _lastScrollPosition = currentPosition;
    } else {
      // 맨 밑 근처에 있으면 사용자가 스크롤하지 않는 것으로 간주
      _isUserScrolling = false;
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
        // 스크롤 후 상태 업데이트
        _isUserScrolling = false;
      }
    });
  }

  // 고정된 메시지로 스크롤 이동
  void _scrollToMessage(int messageId) {
    // 검색 모드인 경우 검색 모드 해제
    if (_isSearchMode) {
      setState(() {
        _isSearchMode = false;
        _searchController.clear();
        _filteredMessages = _messages;
      });
    }
    
    // 메시지 찾기
    final messageIndex = _messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) {
      // 메시지를 찾을 수 없으면 메시지 다시 로드 (스크롤은 하지 않음)
      _loadMessages(showLoading: false, scrollToBottom: false).then((_) {
        _scrollToMessageAfterLoad(messageId);
      });
      return;
    }
    
    // GlobalKey로 스크롤 이동
    final key = _messageKeys[messageId];
    if (key?.currentContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.15,  // 화면 상단 15% 위치에 표시
        );
      });
    } else {
      // GlobalKey가 없으면 인덱스로 스크롤
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          // 대략적인 위치 계산 (메시지당 평균 높이 80px 가정)
          final estimatedOffset = messageIndex * 80.0;
          _scrollController.animateTo(
            estimatedOffset,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  // 메시지 로드 후 스크롤 이동
  void _scrollToMessageAfterLoad(int messageId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _messageKeys[messageId];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.15,
        );
      }
    });
  }

  void _showBlockedDialog() {
    BlockDialogs.showBlockedDialog(context);
  }

  void _showBlockedDialogOld() {
    String message;
    final isReportedOrBlocked = _iReportedThem || _iBlockedThem || widget.iReportedThem;
    final isBlockedByThem = _theyBlockedMe || widget.theyBlockedMe;
    
    if (isReportedOrBlocked) {
      // ✅ 통합: 내가 신고/차단함
      message = "신고 또는 차단한 사용자에게는 메시지를 보낼 수 없습니다.";
    } else if (isBlockedByThem) {
      // ✅ 통합: 상대방이 나를 신고/차단함  
      message = "상대방이 회원님을 신고 또는 차단하여 메시지를 보낼 수 없습니다.";
    } else if (widget.theyLeft) {
      // ✅ 상대방이 채팅방을 나감
      message = "상대방이 채팅방을 나가서 메시지를 보낼 수 없습니다.";
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
      appBar: ChatHeader(
        friendId: widget.friendId,
        friendName: widget.friendName,
        friendProfileImage: widget.friendProfileImage,
        isSearchMode: _isSearchMode,
        searchController: _searchController,
        theyBlockedMe: _theyBlockedMe || widget.theyBlockedMe,
        iBlockedThem: _iBlockedThem,
        iReportedThem: _iReportedThem,
        onToggleSearchMode: _toggleSearchMode,
        onSearchChanged: _filterMessages,
        onBlock: _showBlockDialog,
        onUnblock: _showUnblockDialog,
        onReport: _showReportDialog,
        onUnreport: _showUnreportDialog,
        onLeaveChat: _showLeaveChatDialog,
      ),
      body: Column(
          children: [
          // 상태 배너
          StatusBanner(
            iReportedThem: _iReportedThem || widget.iReportedThem,
            iBlockedThem: _iBlockedThem,
            theyBlockedMe: _theyBlockedMe || widget.theyBlockedMe,
            theyLeft: widget.theyLeft,
          ),

          // 고정된 메시지 표시
          if (_pinnedMessages.isNotEmpty && !_isSearchMode)
            PinnedMessageBar(
              pinnedMessages: _pinnedMessages,
              currentPinnedIndex: _currentPinnedIndex,
              friendName: widget.friendName,
              onTap: () {
                // 클릭 시 현재 표시된 고정 메시지로 이동
                final currentMsg = _pinnedMessages[_currentPinnedIndex];
                _scrollToMessage(currentMsg.id);
                
                // 이동 후 이전 고정 메시지로 순환
                setState(() {
                  _currentPinnedIndex = (_currentPinnedIndex + 1) % _pinnedMessages.length;
                });
              },
                  ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isSearchMode && _searchController.text.trim().isNotEmpty && _filteredMessages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey.shade300,
                  ),
                            const SizedBox(height: 16),
                            Text(
                              "검색 결과가 없어요",
                      style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                      ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "다른 검색어를 입력해보세요",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
                      )
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            itemCount: _filteredMessages.length,
                        itemBuilder: (context, index) {
                              final message = _filteredMessages[index];
                              final key = _messageKeys[message.id] ?? GlobalKey();
                              _messageKeys[message.id] = key;
                              return _buildMessageBubble(message, key: key);
                        },
                      ),
          ),

          Builder(
            builder: (context) {
              // 로컬 상태와 위젯 상태를 모두 확인
              final isBlockedForInput = _iReportedThem || _iBlockedThem || widget.iReportedThem || _theyBlockedMe || widget.theyBlockedMe || widget.theyLeft;
              
              return MessageInputField(
                messageController: _messageController,
                showEmojiPicker: _showEmojiPicker,
                isBlockedForInput: isBlockedForInput,
                isUploading: _isUploading,
                isSending: _isSending,
                onToggleEmojiPicker: () {
                      setState(() {
                        _showEmojiPicker = !_showEmojiPicker;
                      });
                      if (_showEmojiPicker) {
                        FocusScope.of(context).unfocus();
                      }
                    },
                onShowAttachmentOptions: _showAttachmentOptions,
                onSendMessage: _sendMessage,
                onEmojiSelected: (emoji) {
                        setState(() {
                    _messageController.text += emoji;
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, {GlobalKey? key}) {
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
    final time = ChatFormatters.formatTime(message.createdAt);

    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onLongPress: () => MessageMenuDialog.showPinMenu(
          context,
          message,
          widget.roomId,
          () => _loadMessages(showLoading: false),
        ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isMe) ...[
            // 60초 카운트다운 중이면 삭제 버튼과 카운트다운 표시
            if (_messageCountdowns.containsKey(message.id) && _messageCountdowns[message.id]! > 0)
              Padding(
                padding: const EdgeInsets.only(right: 4, bottom: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Colors.red.shade400,
                      ),
                      onPressed: () => _deleteMessage(message.id),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_messageCountdowns[message.id]}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              )
            else if (!message.isRead)
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
      ),
    );
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
                  // 즉시 로컬 상태 업데이트
                  setState(() {
                    _iBlockedThem = true;
                  });
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
                      // 즉시 로컬 상태 업데이트
                      setState(() {
                        _iReportedThem = true;
                      });
                      await _checkReportStatus();
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
    LeaveChatDialog.showLeaveChatDialog(
      context,
      widget.roomId,
      () {
        Navigator.pop(context);
      },
    );
  }

  void _showUnblockDialog() {
    BlockDialogs.showUnblockDialog(
      context,
      widget.friendName,
      widget.friendId,
      () {
        // 즉시 로컬 상태 업데이트하여 UI 활성화
        setState(() {
          _iBlockedThem = false;
          _isBlocked = false;
        });
        // 서버 상태 확인 (비동기로 실행되지만 이미 UI는 활성화됨)
        _checkBlockStatus();
      },
    );
  }

  void _showUnreportDialog() {
    ReportDialogs.showUnreportDialog(
      context,
      _reportId,
      () {
        // 즉시 로컬 상태 업데이트하여 UI 활성화
          setState(() {
          _iReportedThem = false;
          _reportId = null;
          });
        // 서버 상태 확인 (비동기로 실행되지만 이미 UI는 활성화됨)
        _checkReportStatus();
      },
        );
  }
}
