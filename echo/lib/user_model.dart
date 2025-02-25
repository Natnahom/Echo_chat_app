class UserModel {
  final String id;
  final String username;
  final String email; // If applicable

  UserModel({required this.id, required this.username, required this.email});

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      username: data['username'] ?? 'Unknown', // Provide a default value
      email: data['email'] ?? 'No email', // Provide a default value
    );
  }
}