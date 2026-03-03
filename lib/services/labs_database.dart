import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../models/lab_result.dart';

class LabsDatabase {
  final SupabaseClient supabase = Supabase.instance.client;

  /// Save lab result to Supabase
  Future<LabResult?> saveLabResult(LabResult result) async {
    try {
      final response = await supabase
          .from('labs_results')
          .insert(result.toJson())
          .select()
          .single();

      return LabResult.fromJson(response);
    } catch (e) {
      throw Exception('Failed to save lab result: $e');
    }
  }

  /// Get all lab results for user
  Future<List<LabResult>> getUserLabResults(String userId) async {
    try {
      print('DEBUG (LabsDatabase): getUserLabResults START for userId: $userId');
      
      // Wrap query with timeout
      final queryFuture = supabase
          .from('labs_results')
          .select()
          .eq('user_id', userId)
          .order('upload_date', ascending: false);
      
      final response = await queryFuture.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('DEBUG (LabsDatabase): Query TIMEOUT after 10 seconds');
          throw TimeoutException('Lab results query timed out');
        },
      );

      print('DEBUG (LabsDatabase): Query succeeded. Response: $response');
      if (response.isEmpty) {
        print('DEBUG (LabsDatabase): Response is empty, returning []');
        return [];
      }
      
      final results = (response as List)
          .map((json) => LabResult.fromJson(json))
          .toList();
      print('DEBUG (LabsDatabase): Mapped ${results.length} results');
      return results;
    } on TimeoutException catch (e) {
      print('DEBUG (LabsDatabase): TIMEOUT: $e');
      return [];
    } catch (e, stackTrace) {
      print('DEBUG (LabsDatabase): Error: $e');
      print('DEBUG (LabsDatabase): StackTrace: $stackTrace');
      return []; // Return empty list instead of throwing
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
    } catch (e) {
      return null;
    }
  }
}
