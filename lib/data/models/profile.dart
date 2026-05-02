import 'package:equatable/equatable.dart';

class Profile extends Equatable {
  final String username;
  final String? displayName;
  final String? bio;
  final String? profilePictureUrl;
  final String? email;

  const Profile({
    required this.username,
    this.displayName,
    this.bio,
    this.profilePictureUrl,
    this.email,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      username: json['username'] as String,
      displayName: json['displayName'] as String?,
      bio: json['bio'] as String?,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'bio': bio,
      };

  Profile copyWith({
    String? username,
    String? displayName,
    String? bio,
    String? profilePictureUrl,
    String? email,
  }) {
    return Profile(
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      email: email ?? this.email,
    );
  }

  @override
  List<Object?> get props => [
        username,
        displayName,
        bio,
        profilePictureUrl,
        email,
      ];
}
