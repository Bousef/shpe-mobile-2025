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
    try {
      final List<dynamic> data = await _supabase
          .from('event_photo_reaction_stats')
          .select()
          .eq('event_id', eventId)
          .order('photo_created_at');

      return data.map((raw) {
        final row = raw as Map<String, dynamic>;

        final imgUrl = row['img_url'] as String;
        final uploaderName = row['uploader_name'] as String?;
        final createdAt = DateTime.parse(row['photo_created_at'] as String);

        final reactionsJson = (row['reactions'] as List<dynamic>).cast<Map<String, dynamic>>();
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
    } catch (e) {
      throw Exception('Unexpected error loading photos: $e');
    }
  }

  /// Adds a new reaction to a photo.
  Future<void> addReaction({
    required int photoId,
    required String reaction,
  }) async {
    final firebaseUser = FirebaseAuthService().getCurrentUser();
    if (firebaseUser == null) {
      throw Exception('You must be logged in to react.');
    }

    try {
      await _supabase
          .from('photo_reactions')
          .insert({
            'photoID': photoId,
            'userID': firebaseUser.uid,
            'reaction': reaction,
          });
    } catch (e) {
      throw Exception('Failed to add reaction: $e');
    }
  }
}
