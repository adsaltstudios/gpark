import 'package:google_sign_in/google_sign_in.dart';

class UserProfile {
  final String displayName;
  final String email;
  final String ldap;
  final String? photoUrl;

  const UserProfile({
    required this.displayName,
    required this.email,
    required this.ldap,
    this.photoUrl,
  });

  factory UserProfile.fromGoogleSignIn(GoogleSignInAccount account) {
    final email = account.email;
    return UserProfile(
      displayName: account.displayName ?? email.split('@').first,
      email: email,
      ldap: email.split('@').first,
      photoUrl: account.photoUrl,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      ldap: json['ldap'] as String,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'email': email,
        'ldap': ldap,
        'photoUrl': photoUrl,
      };
}
