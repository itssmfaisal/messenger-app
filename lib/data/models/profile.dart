class Profile {
  final String username;
  final String? displayName;
  final String? bio;
  final String? profilePictureUrl;
  final String? email;

  Profile({
    required this.username,
    this.displayName,
    this.bio,
    this.profilePictureUrl,
    this.email,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      username: json['username'],
      displayName: json['displayName'],
      bio: json['bio'],
      profilePictureUrl: json['profilePictureUrl'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() => {'displayName': displayName, 'bio': bio};
}
