import 'package:equatable/equatable.dart';

class PresenceStatus extends Equatable {
  final String username;
  final bool online;

  const PresenceStatus({
    required this.username,
    required this.online,
  });

  factory PresenceStatus.fromJson(Map<String, dynamic> json) {
    return PresenceStatus(
      username: json['username'] as String,
      online: json['online'] as bool,
    );
  }

  @override
  List<Object?> get props => [username, online];
}
