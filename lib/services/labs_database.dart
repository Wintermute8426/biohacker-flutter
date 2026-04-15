import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/lab_result.dart';

class LabsDatabase {
  final SupabaseClient supabase = Supabase.instance.client;

  /// Save lab result to Supabase
  Future<LabResult?> saveLabResult(LabResult result) async {
    try {
      if (kDebugMode) {
        print('[LabsDatabase] saveLabResult: inserting id=${result.id} user_id=${result.userId}');
        print('[LabsDatabase] Current auth uid: ${supabase.auth.currentUser?.id}');
        print('[LabsDatabase] Payload: ${result.toJson()}');
      }
      final response = await supabase
          .from('labs_results')
          .insert(result.toJson())
          .select()
          .single();

      if (kDebugMode) print('[LabsDatabase] saveLabResult SUCCESS: ${response['id']}');
      return LabResult.fromJson(response);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[LabsDatabase] saveLabResult FAILED: $e');
        print('[LabsDatabase] Error type: ${e.runtimeType}');
        print('[LabsDatabase] Stack: $stackTrace');
      }
      // Re-throw with original error preserved (not wrapped) so callers see real message
      rethrow;
    }
  }

  /// Get all lab results for user
  Future<List<LabResult>> getUserLabResults(String userId) async {
    try {
      if (kDebugMode) {
        print('[LabsDatabase] getUserLabResults START for userId: $userId');
      }

      // Wrap query with timeout
      final queryFuture = supabase
          .from('labs_results')
          .select()
          .eq('user_id', userId)
          .order('upload_date', ascending: false);

      final response = await queryFuture.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (kDebugMode) {
            print('[LabsDatabase] Query TIMEOUT after 10 seconds');
          }
          throw TimeoutException('Lab results query timed out');
        },
      );

      if (kDebugMode) {
        print('[LabsDatabase] Query succeeded. Response: $response');
      }
      if (response.isEmpty) {
        if (kDebugMode) {
          print('[LabsDatabase] Response is empty, returning []');
        }
        return [];
      }

      final results = (response as List)
          .map((json) => LabResult.fromJson(json))
          .toList();
      if (kDebugMode) {
        print('[LabsDatabase] Mapped ${results.length} results');
      }
      return results;
    } on TimeoutException catch (e, stackTrace) {
      if (kDebugMode) {
        print('[LabsDatabase] TIMEOUT: $e');
        if (kDebugMode) {
          print('[LabsDatabase] Stack trace: $stackTrace');
        }
      }
      rethrow;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[LabsDatabase] Error: $e');
        if (kDebugMode) {
          print('[LabsDatabase] Stack trace: $stackTrace');
        }
      }
      rethrow;
    }
  }

  /// Get lab results for specific cycle
  Future<List<LabResult>> getCycleLabResults(String cycleId) async {
    try {
      final response = await supabase
          .from('labs_results')
          .select()
          .eq('cycle_id', cycleId)
          .order('upload_date', ascending: false);

      if (response.isEmpty) return [];
      
      return (response as List)
          .map((json) => LabResult.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch cycle lab results: $e');
    }
  }

  /// Get single lab result
  Future<LabResult?> getLabResult(String id) async {
    try {
      final response = await supabase
          .from('labs_results')
          .select()
          .eq('id', id)
          .single();

      return LabResult.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch lab result: $e');
    }
  }

  /// Update lab result
  Future<LabResult?> updateLabResult(LabResult result) async {
    try {
      final response = await supabase
          .from('labs_results')
          .update(result.toJson())
          .eq('id', result.id)
          .select()
          .single();

      return LabResult.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update lab result: $e');
    }
  }

  /// Delete lab result
  Future<void> deleteLabResult(String id) async {
    try {
      await supabase
          .from('labs_results')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete lab result: $e');
    }
  }

  /// Get latest lab result (most recent)
  Future<LabResult?> getLatestLabResult(String userId) async {
    try {
      final response = await supabase
          .from('labs_results')
          .select()
          .eq('user_id', userId)
          .order('upload_date', ascending: false)
          .limit(1)
          .single();

      return LabResult.fromJson(response);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[LabsDatabase] Failed to get latest lab result: $e');
        if (kDebugMode) {
          print('[LabsDatabase] Stack trace: $stackTrace');
        }
      }
      return null;
    }
  }
}

// Riverpod Providers
final labsDatabaseProvider = Provider<LabsDatabase>((ref) {
  return LabsDatabase();
});

final userLabResultsProvider = FutureProvider.family<List<LabResult>, String>((ref, userId) async {
  final db = ref.watch(labsDatabaseProvider);
  return db.getUserLabResults(userId);
});
