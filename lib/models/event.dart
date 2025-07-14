class Event {
  final String id;
  final String name;
  final String imageUrl;     
  final DateTime? date;
  final String? time;
  final int? pointsWorth;
  final String? qrCodeUrl;
  final int? createdBy;
  final String? description;
  final String? location;       

  Event({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.date,
    this.time,
    this.pointsWorth,
    this.qrCodeUrl,
    this.createdBy,
    this.description,
    this.location,
  });

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        imageUrl: json['image_url'] as String? ??
            'https://picsum.photos/seed/${json['id']}/600/400',
        date: json['event_date'] != null
            ? DateTime.parse(json['event_date'] as String)
            : null,
        time: json['event_time'] as String?,
        pointsWorth: json['points_worth'] as int?,
        qrCodeUrl: json['qr_code_url'] as String?,
        createdBy: json['created_by'] as int?,
        description: json['description'] as String?,
        location: json['location'] as String?,
      );
}
