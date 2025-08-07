// photo_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shpeucfmobile/services/supabase_service.dart';
import 'package:shpeucfmobile/services/firebase_auth_service.dart';


/// Simple model for a single reaction count.
class Reaction {
  final String type;
  final int count;
  Reaction(this.type, this.count);
}

/// Combines photo metadata with its reaction stats.
class PhotoWithReactions {
  final int photoId;
  final String imgUrl;
  final String? uploaderName;
  final DateTime createdAt;
  final List<Reaction> reactions;

  PhotoWithReactions({
    required this.photoId,
    required this.imgUrl,
    required this.uploaderName,
    required this.createdAt,
    required this.reactions,
  });
}

class PhotoService {
  final SupabaseClient _supabase;

  PhotoService(this._supabase);

  /// Fetches all photos for [eventId] along with pre-aggregated reaction stats.
  Future<List<PhotoWithReactions>> fetchEventPhotosWithReactions(String eventId) async {
    // 1️⃣ Query the materialized view for this event
    final res = await _supabase
        .from('event_photo_reaction_stats')
        .select()
        .eq('event_id', eventId)
        .order('photo_created_at')
        .execute();

    // 2️⃣ Error handling
    if (res.status < 200 || res.status >= 300 || res.data == null) {
      throw Exception('Failed to load photos: ${res.data}');
    }

    // 3️⃣ Parse the raw JSON list into our Dart models
    final List data = res.data as List<dynamic>;
    return data.map((raw) {
      final row = raw as Map<String, dynamic>;

      // a) The image URL
      final imgUrl = row['img_url'] as String;

      // b) Who uploaded it (nullable)
      final uploaderName = row['uploader_name'] as String?;

      // c) When it was posted
      final createdAt = DateTime.parse(row['photo_created_at'] as String);

      // d) The reactions array: [{reaction, count}, …]
      final reactionsJson = (row['reactions'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final reactions = reactionsJson
          .map((j) => Reaction(j['reaction'] as String, j['count'] as int))
          .toList();

      return PhotoWithReactions(
        photoId: row['photo_id'] as int,
        imgUrl: imgUrl,
        uploaderName: uploaderName,
        createdAt: createdAt,
        reactions: reactions,
      );
    }).toList();
  }

  Future<void> addReaction({
    required int photoId,
    required String reaction,
  }) async {
    
    final firebaseUser = FirebaseAuthService().getCurrentUser();
    if (firebaseUser == null) {
       throw Exception('You must be logged in to react.');
    }

    
    final res = await _supabase
        .from('photo_reactions')
        .insert({
          'photoID': photoId,
          'userID': firebaseUser.uid,
          'reaction': reaction,
        })
        .execute();

    
    if (res.status < 200 || res.status >= 300 || res.data == null) {
      throw Exception('Failed to add reaction: ${res.data!.message}');
    }
  }
}