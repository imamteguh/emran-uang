class AuthUser {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String? authProvider;
  final DateTime? createdAt;

  AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.authProvider,
    this.createdAt,
  });

  factory AuthUser.fromJson(Map<dynamic, dynamic> json) {
    DateTime? parsedCreatedAt;
    if (json['createdAt'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['createdAt'].toString());
    }

    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      authProvider: json['authProvider'] as String?,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'authProvider': authProvider,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
