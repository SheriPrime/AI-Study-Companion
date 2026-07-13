/// Represents an authenticated user in the app.
class AppUser {
  final String id;
  final String name;
  final String email;
  final String university;
  final String department;
  final String timeline;
  final String? avatarUrl;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.university,
    required this.department,
    required this.timeline,
    this.avatarUrl,
  });
}
