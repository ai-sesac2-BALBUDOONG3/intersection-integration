// lib/models/chat_message.dart - 완전 수정본

class ChatMessage {
  final int id;
  final int roomId;
  final int senderId;
  final String content;
  final String messageType; // normal, system, file, image
  final bool isRead;
  final String createdAt;
  
  // ✅ 파일 관련 필드
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? fileType;

  // ✅ 고정 여부
  final bool isPinned;  // 메시지 고정 여부

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.messageType,
    required this.isRead,
    required this.createdAt,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.fileType,
    this.isPinned = false,  // ✅ 고정 여부
  });

  // ✅ 이미지 여부 확인 (더 강력한 감지)
  bool get isImage {
    // 1. message_type이 "image"면 무조건 이미지
    if (messageType == "image") return true;
    
    // 2. fileType으로 확인
    if (fileType != null) {
      final type = fileType!.toLowerCase();
      if (type.contains('image') || 
          type.contains('png') || 
          type.contains('jpg') || 
          type.contains('jpeg') ||
          type.contains('gif') ||
          type.contains('webp')) {
        return true;
      }
    }
    
    // 3. fileName으로 확인
    if (fileName != null) {
      final name = fileName!.toLowerCase();
      if (name.endsWith('.png') || 
          name.endsWith('.jpg') || 
          name.endsWith('.jpeg') ||
          name.endsWith('.gif') ||
          name.endsWith('.webp')) {
        return true;
      }
    }
    
    // 4. fileUrl로 확인
    if (fileUrl != null) {
      final url = fileUrl!.toLowerCase();
      if (url.endsWith('.png') || 
          url.endsWith('.jpg') || 
          url.endsWith('.jpeg') ||
          url.endsWith('.gif') ||
          url.endsWith('.webp')) {
        return true;
      }
    }
    
    return false;
  }

  // ✅ 파일 크기 포맷
  String get fileSizeFormatted {
    if (fileSize == null) return '';
    final kb = fileSize! / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    } else {
      final mb = kb / 1024;
      return '${mb.toStringAsFixed(1)} MB';
    }
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      roomId: json['room_id'] as int,
      senderId: json['sender_id'] as int,
      content: json['content'] as String,
      messageType: json['message_type'] as String? ?? 'normal',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] as String,
      fileUrl: json['file_url'] as String?,
      fileName: json['file_name'] as String?,
      fileSize: json['file_size'] as int?,
      fileType: json['file_type'] as String?,
      isPinned: json['is_pinned'] as bool? ?? false,  // ✅ 고정 여부
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType,
      'is_read': isRead,
      'created_at': createdAt,
      if (fileUrl != null) 'file_url': fileUrl,
      if (fileName != null) 'file_name': fileName,
      if (fileSize != null) 'file_size': fileSize,
      if (fileType != null) 'file_type': fileType,
      'is_pinned': isPinned,  // ✅ 고정 여부
    };
  }
}