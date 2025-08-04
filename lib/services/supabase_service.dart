import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert'; // for utf8.encode
import 'package:crypto/crypto.dart'; // for md5 or sha256
import '../models/event.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

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

  await _client.from('users').insert({
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
    final data = await _client
        .from('users')
        .select()
        .eq('firebase_uid', firebaseUid)
        .single();

    return data;

  }

  /// Update user’s email
  Future<void> updateUserEmail(String firebaseUid, String newEmail) async {
    await _client
        .from('users')
        .update({'email': newEmail})
        .eq('firebase_uid', firebaseUid);

  }

  /// Fetch all users (admin use case)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final data = await _client.from('users').select();
    return List<Map<String, dynamic>>.from(data);
  }

  // Fetch admin and position
  Future<Map<String, dynamic>?> fetchUserRole(String firebase_uid) async {
    final row = await _client
      .from('users')
      .select('is_admin,position')
      .eq('firebase_uid',firebase_uid)
      .maybeSingle();
    
    return row;

  }

  // Fetch all rows from events
  Future<List<Event>> fetchEvents() async {
    final data = await _client
        .from('Events')
        .select('*')       // grab everything for now
        .order('event_date', ascending: true)
        .limit(10);        // keep the list short

    // Supabase returns a List<dynamic>; cast & map to Event
    return (data as List)
        .map((row) => Event.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  
  // Deterministically assign profile picture based on name
  String getAvatarUrl(String name) {
    final avatars = List.generate(9, (i) => 'https://lexgvoiyqbltlhlicebj.supabase.co/storage/v1/object/public/avatars//profile$i.svg');

     final hash = md5.convert(utf8.encode(name)).bytes;
     final index = hash[0] % 9;

     return avatars[index];

  }

  /// Check if email exists in the users table
  Future<bool> emailExists(String email) async {
    final data = await _client
        .from('users')
        .select('email')
        .eq('email', email)
        .maybeSingle();
    
    return data != null;
  }
}

