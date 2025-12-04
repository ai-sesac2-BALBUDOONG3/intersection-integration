class ChatRoom {
  final int id;
  final int user1Id;
  final int user2Id;
  final int friendId;
  final String? friendName;
  final String? lastMessage;
  final String? lastMessageTime;
  final int unreadCount;
  final String createdAt;
  
  // ✅ 마지막 메시지 상세 정보
  final String? lastMessageType;
  final String? lastFileUrl;
  final String? lastFileName;
  
  // ✅ 상대방 프로필 이미지
  final String? friendProfileImage;
  
  // ✅ 신고/차단 상태 (통합)
  final bool iReportedThem;  // 내가 상대방을 신고/차단함
  final bool theyBlockedMe;  // 상대방이 나를 신고/차단함
  
  // ✅ 채팅방 나가기 상태
  final bool theyLeft;  // 상대방이 채팅방을 나감

  // ✅ 고정 여부
  final bool isPinned;  // 채팅방 고정 여부

  ChatRoom({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.friendId,
    this.friendName,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    required this.createdAt,
    this.lastMessageType,
    this.lastFileUrl,
    this.lastFileName,
    this.friendProfileImage,
    this.iReportedThem = false,
    this.theyBlockedMe = false,
    this.theyLeft = false,  // ✅ 추가
    this.isPinned = false,  // ✅ 고정 여부
  });

  // ✅ 마지막 메시지가 이미지인지 확인
  bool get isLastMessageImage {
    if (lastMessageType == "image") return true;
    
    if (lastFileName != null) {
      final name = lastFileName!.toLowerCase();
      return name.endsWith('.png') || 
             name.endsWith('.jpg') || 
             name.endsWith('.jpeg') ||
             name.endsWith('.gif') ||
             name.endsWith('.webp');
    }
    
    if (lastFileUrl != null) {
      final url = lastFileUrl!.toLowerCase();
      return url.endsWith('.png') || 
             url.endsWith('.jpg') || 
             url.endsWith('.jpeg') ||
             url.endsWith('.gif') ||
             url.endsWith('.webp');
    }
    
    return false;
  }

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      user1Id: json['user1_id'],
      user2Id: json['user2_id'],
      friendId: json['friend_id'],
      friendName: json['friend_name'],
      lastMessage: json['last_message'],
      lastMessageTime: json['last_message_time'],
      unreadCount: json['unread_count'] ?? 0,
      createdAt: json['created_at'],
      lastMessageType: json['last_message_type'],
      lastFileUrl: json['last_file_url'],
      lastFileName: json['last_file_name'],
      friendProfileImage: json['friend_profile_image'],
      iReportedThem: json['i_reported_them'] ?? false,
      theyBlockedMe: json['they_blocked_me'] ?? false,
      theyLeft: json['they_left'] ?? false,  // ✅ 추가
      isPinned: json['is_pinned'] ?? false,  // ✅ 고정 여부
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1_id': user1Id,
      'user2_id': user2Id,
      'friend_id': friendId,
      'friend_name': friendName,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime,
      'unread_count': unreadCount,
      'created_at': createdAt,
      'last_message_type': lastMessageType,
      'last_file_url': lastFileUrl,
      'last_file_name': lastFileName,
      'friend_profile_image': friendProfileImage,
      'i_reported_them': iReportedThem,
      'they_blocked_me': theyBlockedMe,
      'they_left': theyLeft,  // ✅ 추가
      'is_pinned': isPinned,  // ✅ 고정 여부
    };
  }
}