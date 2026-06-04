import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';

class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  factory ReviewService() => _instance;
  ReviewService._internal();

  Future<String> _generateReviewId() async {
    final counterRef = _firestore.collection('counters').doc('review_counter');

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);
      final currentCount = snapshot.data()?['count'];
      final nextCount = currentCount is num ? currentCount.toInt() + 1 : 1;
      final safeCount = nextCount < 1 ? 1 : nextCount;

      transaction.set(
        counterRef,
        {'count': safeCount},
        SetOptions(merge: true),
      );

      return 'RVW-${safeCount.toString().padLeft(7, '0')}';
    });
  }

  Stream<List<Map<String, dynamic>>> streamRestaurantReviews(
    String restaurantId,
  ) {
    return _firestore
        .collection('reviews')
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .map((snapshot) {
      final reviews = snapshot.docs
          .map((doc) => _reviewCardData(doc.id, doc.data()))
          .toList();
      reviews.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
      );
      return reviews;
    });
  }

  Future<Map<String, dynamic>> submitRestaurantReview({
    required String restaurantId,
    required String restaurantName,
    required int rating,
    required String review,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('Silakan login untuk memberikan review.');
    }

    final userData = await _authService.getUserData(user.uid);
    final userName = (userData?.fullName.trim().isNotEmpty == true)
        ? userData!.fullName.trim()
        : (user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : 'User');

    final reviewId = await _generateReviewId();
    final now = DateTime.now();
    final docRef = _firestore.collection('reviews').doc(reviewId);
    final data = {
      'id': reviewId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'userId': user.uid,
      'customUserId': userData?.uid,
      'userName': userName,
      'rating': rating.toDouble(),
      'review': review.trim(),
      'likes': 0,
      'likedByUsers': [],
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };

    await docRef.set(data);
    await _syncRestaurantRating(restaurantId);
    return _reviewCardData(reviewId, data);
  }

  Future<void> _syncRestaurantRating(String restaurantId) async {
    try {
      final reviews = await _firestore
          .collection('reviews')
          .where('restaurantId', isEqualTo: restaurantId)
          .get();

      var total = 0.0;
      var count = 0;
      for (final doc in reviews.docs) {
        final rating = doc.data()['rating'];
        if (rating is num) {
          total += rating.toDouble();
          count++;
        }
      }

      await _firestore.collection('restaurants').doc(restaurantId).set(
        {
          'averageRating': count == 0 ? null : total / count,
          'reviewCount': count,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      print('[ReviewService] sync restaurant rating failed: $e');
    }
  }

  Map<String, dynamic> _reviewCardData(String id, Map<String, dynamic> data) {
    final date = _parseDate(data['createdAt']) ?? DateTime.now();
    final rating = data['rating'];
    final likes = data['likes'];

    return {
      'id': id,
      'restaurantId': data['restaurantId']?.toString() ?? '',
      'userId': data['userId']?.toString() ?? '',
      'name': data['userName']?.toString().trim().isNotEmpty == true
          ? data['userName'].toString().trim()
          : 'User',
      'date': date,
      'timeAgo': _timeAgo(date),
      'rating': rating is num ? rating.toDouble() : 0.0,
      'review': data['review']?.toString() ?? '',
      'likes': likes is num ? likes.toInt() : 0,
    };
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _timeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    }
    if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    }
    return '${(difference.inDays / 365).floor()}y ago';
  }

  /// Toggle like review - add/remove current user from likedByUsers array
  Future<bool> toggleReviewLike(String reviewId) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('Silakan login untuk memberikan like pada review.');
    }

    try {
      final reviewRef = _firestore.collection('reviews').doc(reviewId);
      final reviewDoc = await reviewRef.get();

      if (!reviewDoc.exists) {
        throw Exception('Review tidak ditemukan.');
      }

      final data = reviewDoc.data()!;
      final likedByUsers = List<String>.from(data['likedByUsers'] ?? []);
      final currentLikes = data['likes'] ?? 0;

      bool isLiked = false;

      if (likedByUsers.contains(user.uid)) {
        // Unlike: remove user from array and decrement likes
        likedByUsers.remove(user.uid);
        await reviewRef.update({
          'likedByUsers': likedByUsers,
          'likes': (currentLikes as num).toInt() - 1,
          'updatedAt': Timestamp.now(),
        });
        isLiked = false;
      } else {
        // Like: add user to array and increment likes
        likedByUsers.add(user.uid);
        await reviewRef.update({
          'likedByUsers': likedByUsers,
          'likes': (currentLikes as num).toInt() + 1,
          'updatedAt': Timestamp.now(),
        });
        isLiked = true;
      }

      return isLiked;
    } catch (e) {
      throw Exception('Toggle like review failed: ${e.toString()}');
    }
  }

  /// Check if current user has liked a review
  Future<bool> hasUserLikedReview(String reviewId) async {
    final user = _authService.currentUser;
    if (user == null) return false;

    try {
      final reviewDoc =
          await _firestore.collection('reviews').doc(reviewId).get();

      if (!reviewDoc.exists) return false;

      final likedByUsers =
          List<String>.from(reviewDoc.data()?['likedByUsers'] ?? []);
      return likedByUsers.contains(user.uid);
    } catch (_) {
      return false;
    }
  }
}
