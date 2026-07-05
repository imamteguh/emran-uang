class AuthUser {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String? authProvider;

  AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.authProvider,
  });

  factory AuthUser.fromJson(Map<dynamic, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      authProvider: json['authProvider'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'authProvider': authProvider,
    };
  }
}
