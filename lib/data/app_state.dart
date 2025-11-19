import 'package:intersection/models/user.dart';
import 'package:intersection/models/post.dart';

class AppState {
  /// 현재 로그인/회원가입한 유저
  static User? currentUser;

  /// 전체 유저 더미 데이터
  static final List<User> allUsers = [
    const User(
      id: 'u1',
      name: '김민수',
      birthYear: 1998,
      region: '서울 강서구',
      school: 'A초등학교',
    ),
    const User(
      id: 'u2',
      name: '박지영',
      birthYear: 1998,
      region: '서울 강서구',
      school: 'A초등학교',
    ),
    const User(
      id: 'u3',
      name: '이현우',
      birthYear: 1997,
      region: '서울 강서구',
      school: 'A초등학교',
    ),
    const User(
      id: 'u4',
      name: '최서연',
      birthYear: 1998,
      region: '부산 해운대구',
      school: 'B중학교',
    ),
  ];

  /// 내가 팔로우한 사람들 id
  static final Set<String> followingIds = {};

  /// 더미 포스트들
  static final List<Post> allPosts = [
    Post(
      id: 'p1',
      authorId: 'u1',
      content: 'A초에서 같이 뛰어놀던 친구들 아직도 기억나?',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    Post(
      id: 'p2',
      authorId: 'u2',
      content: '그때 매점 떡꼬치 진짜 레전드였는데 ㅋㅋ',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Post(
      id: 'p3',
      authorId: 'u4',
      content: '부산 B중 사람들 있나? 한 번 모여보자.',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  /// 추천친구: 지역 + 학교 + 나이 모두 같은 사람만
  static List<User> get recommendedFriends {
    final me = currentUser;
    if (me == null) return [];
    return allUsers.where((u) {
      if (u.id == me.id) return false;
      if (followingIds.contains(u.id)) return false;
      return u.region == me.region &&
          u.school == me.school &&
          u.birthYear == me.birthYear;
    }).toList();
  }

  /// 친구 목록: 내가 팔로우한 사람들
  static List<User> get friends {
    return allUsers.where((u) => followingIds.contains(u.id)).toList();
  }

  /// 커뮤니티 피드: 같은 조건(지역, 학교, 나이)의 글만
  static List<Post> get communityPosts {
    final me = currentUser;
    if (me == null) return [];
    final allowedAuthorIds = allUsers.where((u) {
      return u.region == me.region &&
          u.school == me.school &&
          u.birthYear == me.birthYear;
    }).map((u) => u.id).toSet();

    return allPosts
        .where((p) => allowedAuthorIds.contains(p.authorId))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 친구 추가(팔로우)
  static void follow(User user) {
    followingIds.add(user.id);
  }

  /// 팔로우 해제
  static void unfollow(User user) {
    followingIds.remove(user.id);
  }
}
