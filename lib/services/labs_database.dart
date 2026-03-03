import 'package:supabase_flutter/supabase_flutter.dart';
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
      final response = await supabase
          .from('labs_results')
          .select()
          .eq('user_id', userId)
          .order('upload_date', ascending: false);

      if (response.isEmpty) return [];
      
      return (response as List)
          .map((json) => LabResult.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch lab results: $e');
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
