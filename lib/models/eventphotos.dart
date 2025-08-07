class EventPhotos{
  final String id;
  final String eventId;
  final String userId;
  final String? imageUrl;
  final DateTime? createdAt;

    EventPhotos({
      required this.id,
      required this.eventId,
      required this.userId,
      this.imageUrl,
      this.createdAt,

    });

    factory EventPhotos.fromJson(Map<String, dynamic> json) => EventPhotos(
      id: json['id'] as String,
      eventId: json['eventID'] as String,
      userId: json['userID'] as String,
      imageUrl: json['imgURL'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
}