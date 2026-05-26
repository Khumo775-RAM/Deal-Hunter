class User {
  final String username;
  final String email;
  final bool emailNotifications;
  final bool isVerified;

  const User({
    required this.username,
    required this.email,
    this.emailNotifications = false,
    this.isVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        username: json['username'] ?? '',
        email: json['email'] ?? '',
        emailNotifications: json['email_notifications'] as bool? ?? false,
        isVerified: json['is_verified'] as bool? ?? false,
      );

  User copyWith({bool? emailNotifications, bool? isVerified}) => User(
        username: username,
        email: email,
        emailNotifications: emailNotifications ?? this.emailNotifications,
        isVerified: isVerified ?? this.isVerified,
      );
}
