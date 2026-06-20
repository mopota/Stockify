import '../../core/utils/date_parser.dart';

class ReviewModel {
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime? createdAt;

  ReviewModel({
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory ReviewModel.fromFirestore(Map<String, dynamic> data) {
    return ReviewModel(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'User',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: DateParser.parse(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': DateParser.toFirestore(createdAt),
    };
  }
}
