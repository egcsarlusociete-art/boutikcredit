import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  final String id;
  final String youtubeId;
  final String title;
  final String description;
  final String thumbnail;
  final int views;
  final int likes;
  final int comments;
  final bool isNew;
  final DateTime? publishedAt;

  const VideoModel({
    required this.id,
    required this.youtubeId,
    required this.title,
    this.description = '',
    this.thumbnail = '',
    this.views = 0,
    this.likes = 0,
    this.comments = 0,
    this.isNew = false,
    this.publishedAt,
  });

  factory VideoModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return VideoModel(
      id: doc.id,
      youtubeId: d['youtubeId'] ?? '',
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      thumbnail: d['thumbnail'] ?? '',
      views: (d['views'] ?? 0).toInt(),
      likes: (d['likes'] ?? 0).toInt(),
      comments: (d['comments'] ?? 0).toInt(),
      isNew: d['isNew'] ?? false,
      publishedAt: (d['publishedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class VideoComment {
  final String id;
  final String videoId;
  final String userId;
  final String userName;
  final String text;
  final int likes;
  final String? parentId;
  final DateTime? createdAt;

  const VideoComment({
    required this.id,
    required this.videoId,
    required this.userId,
    required this.userName,
    required this.text,
    this.likes = 0,
    this.parentId,
    this.createdAt,
  });

  factory VideoComment.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return VideoComment(
      id: doc.id,
      videoId: d['videoId'] ?? '',
      userId: d['userId'] ?? '',
      userName: d['userName'] ?? '',
      text: d['text'] ?? '',
      likes: (d['likes'] ?? 0).toInt(),
      parentId: d['parentId'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
