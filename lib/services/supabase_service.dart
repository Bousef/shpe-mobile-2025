import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert'; // for utf8.encode
import 'dart:typed_data'; // for Uint8List, more effieicent than List<int>
import 'package:crypto/crypto.dart'; // for md5 or sha256
import '../models/event.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  /// Insert a new user into Supabase
  Future<void> insertUser({
    required String firebaseUid,
    required String? email,
    required String firstname,
    required String lastname,
    required int ucfid,
    required String birthday,
  }) async {
    final bool isAdmin = email!.trim().toLowerCase().endsWith('@shpeucf.com');

    await client.from('users').insert({
      'firebase_uid': firebaseUid,
      'email': email,
      'firstname': firstname,
      'lastname': lastname,
      'ucfid': ucfid,
      'birthday': birthday,
      'is_admin': isAdmin,
    });
  }

  /// Get user by Firebase UID
  Future<Map<String, dynamic>?> getUserByFirebaseUid(String firebaseUid) async {
    final data = await client
        .from('users')
        .select()
        .eq('firebase_uid', firebaseUid)
        .single();

    return data;
  }

  /// Update user’s email
  Future<void> updateUserEmail(String firebaseUid, String newEmail) async {
    await client
        .from('users')
        .update({'email': newEmail})
        .eq('firebase_uid', firebaseUid);
  }

  /// Fetch all users (admin use case)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final data = await client.from('users').select();
    return List<Map<String, dynamic>>.from(data);
  }

  // Fetch admin and position
  Future<Map<String, dynamic>?> fetchUserRole(String firebase_uid) async {
    final row = await client
        .from('users')
        .select('is_admin,position')
        .eq('firebase_uid', firebase_uid)
        .maybeSingle();

    return row;
  }

  // Fetch all rows from events
  Future<List<Event>> fetchEvents() async {
    final data = await client
        .from('Events')
        .select('*')
        .order('event_date', ascending: true)
        .limit(10);

    return (data as List)
        .map((row) => Event.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  // Deterministically assign profile picture based on name
  String getAvatarUrl(String name) {
    final avatars = List.generate(
      9,
      (i) =>
          'https://lexgvoiyqbltlhlicebj.supabase.co/storage/v1/object/public/avatars/profile$i.svg',
    );

    final hash = md5.convert(utf8.encode(name)).bytes;
    final index = hash[0] % 9;

    return avatars[index];
  }

  /// Create a new event in the Events table
  Future<String> createEvent({
    required String name,
    required String description,
    required String eventDate,
    required String eventTime,
    required int pointsWorth,
    required int createdBy,
    String? location,
    String? eventUrl,
    String? imageUrl,
    String? qrCodeUrl,
  }) async {
    final data = await client.from('Events').insert({
      'name': name,
      'description': description,
      'event_date': eventDate,
      'event_time': eventTime,
      'points_worth': pointsWorth,
      'created_by': createdBy,
      'location': location,
      'event_url': eventUrl,
      'image_url': imageUrl,
      'qr_code_url': qrCodeUrl,
    }).select('id').single();

    return data['id'] as String;
  }

  /// Get user ID by Firebase UID (needed for created_by field)
  Future<int> getUserIdByFirebaseUid(String firebaseUid) async {
    final data = await client
        .from('users')
        .select('id')
        .eq('firebase_uid', firebaseUid)
        .single();

    return data['id'] as int;
  }

  /// Upload image to Supabase storage bucket
  Future<String> uploadEventImage(Uint8List imageBytes, String fileName) async {
    final path = 'events_thumbnail/$fileName';
    
    await client.storage
        .from('event-photos')
        .uploadBinary(path, imageBytes);
    
    final publicUrl = client.storage
        .from('event-photos')
        .getPublicUrl(path);
    
    return publicUrl;
  }
}
