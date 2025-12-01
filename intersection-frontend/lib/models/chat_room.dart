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
  
  // ✅ 신고 상태
  final bool iWasReported;  // 내가 신고당했는지 (상대방이 나를 신고함)

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
    this.iWasReported = false,  // ✅ 추가
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
      iWasReported: json['i_was_reported'] ?? false,  // ✅ 추가
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
      'i_was_reported': iWasReported,  // ✅ 추가
    };
  }
}