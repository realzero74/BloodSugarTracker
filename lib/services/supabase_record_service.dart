import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/blood_sugar_record.dart';

class SupabaseRecordService {
  static const String supabaseUrl = 'https://ubixbhzaidovvkvbkkjs.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InViaXhiaHphaWRvdnZrdmJra2pzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEwODc1NjYsImV4cCI6MjEwNjY2MzU2Nn0.3HQlRQW4SSgSs8lplpims2k4JcfWeXufW0krYpMtm-o';
  static const String functionUrl = '$supabaseUrl/functions/v1/records';

  final http.Client _httpClient;

  SupabaseRecordService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  Map<String, String> _buildHeaders() {
    String? token;
    try {
      final session = Supabase.instance.client.auth.currentSession;
      token = session?.accessToken;
    } catch (_) {}

    final authHeader = token != null ? 'Bearer $token' : 'Bearer $supabaseAnonKey';
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'apikey': supabaseAnonKey,
      'Authorization': authHeader,
    };
  }

  /// 최근 기록 조회 (기본 3개)
  Future<List<BloodSugarRecord>> getRecentRecords({int limit = 3}) async {
    final uri = Uri.parse('$functionUrl?type=recent&limit=$limit');
    final response = await _httpClient.get(uri, headers: _buildHeaders());

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final List list = decoded['data'] ?? [];
      return list.map((item) => BloodSugarRecord.fromJson(item)).toList();
    } else {
      throw Exception('최근 기록 조회 실패: ${response.statusCode} - ${response.body}');
    }
  }

  /// 최근 30일치 기록 조회 (차트용)
  Future<List<BloodSugarRecord>> get30DaysRecords({String? tag}) async {
    final queryParams = <String, String>{'type': '30days'};
    if (tag != null && tag.isNotEmpty) queryParams['tag'] = tag;
    final uri = Uri.parse(functionUrl).replace(queryParameters: queryParams);

    final response = await _httpClient.get(uri, headers: _buildHeaders());

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final List list = decoded['data'] ?? [];
      return list.map((item) => BloodSugarRecord.fromJson(item)).toList();
    } else {
      throw Exception('30일 기록 조회 실패: ${response.statusCode} - ${response.body}');
    }
  }

  /// 전체 기록 페이징 조회
  Future<PagedResult<BloodSugarRecord>> getPagedRecords({
    int page = 1,
    int pageSize = 10,
    String? tag,
  }) async {
    final queryParams = <String, String>{
      'type': 'paged',
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (tag != null && tag.isNotEmpty) queryParams['tag'] = tag;
    final uri = Uri.parse(functionUrl).replace(queryParameters: queryParams);

    final response = await _httpClient.get(uri, headers: _buildHeaders());

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final List list = decoded['data'] ?? [];
      final records = list.map((item) => BloodSugarRecord.fromJson(item)).toList();
      return PagedResult<BloodSugarRecord>(
        data: records,
        count: decoded['count'] ?? records.length,
        page: decoded['page'] ?? page,
        pageSize: decoded['pageSize'] ?? pageSize,
        totalPages: decoded['totalPages'] ?? 1,
      );
    } else {
      throw Exception('페이징 기록 조회 실패: ${response.statusCode} - ${response.body}');
    }
  }

  /// 혈당 기록 생성 (Edge Function POST)
  Future<BloodSugarRecord> createRecord(BloodSugarRecord record) async {
    final uri = Uri.parse(functionUrl);
    final response = await _httpClient.post(
      uri,
      headers: _buildHeaders(),
      body: utf8.encode(jsonEncode(record.toJson())),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return BloodSugarRecord.fromJson(decoded['data']);
    } else {
      String errorMessage = '혈당 기록 추가 실패';
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['error'] != null) {
          errorMessage = decoded['error'];
        }
      } catch (_) {
        errorMessage = '혈당 기록 추가 실패: ${response.statusCode} - ${response.body}';
      }
      throw Exception(errorMessage);
    }
  }

  /// 혈당 기록 수정 (Edge Function PUT/PATCH)
  Future<BloodSugarRecord> updateRecord(BloodSugarRecord record) async {
    if (record.id == null) {
      throw Exception('수정할 기록의 ID가 필요합니다.');
    }
    final uri = Uri.parse('$functionUrl?id=${record.id}');
    final response = await _httpClient.put(
      uri,
      headers: _buildHeaders(),
      body: utf8.encode(jsonEncode(record.toJson())),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return BloodSugarRecord.fromJson(decoded['data']);
    } else {
      String errorMessage = '혈당 기록 수정 실패';
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['error'] != null) {
          errorMessage = decoded['error'];
        }
      } catch (_) {
        errorMessage = '혈당 기록 수정 실패: ${response.statusCode} - ${response.body}';
      }
      throw Exception(errorMessage);
    }
  }

  /// 혈당 기록 삭제 (Edge Function DELETE)
  Future<bool> deleteRecord(String id) async {
    final uri = Uri.parse('$functionUrl?id=$id');
    final response = await _httpClient.delete(uri, headers: _buildHeaders());

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded['success'] == true;
    } else {
      throw Exception('혈당 기록 삭제 실패: ${response.statusCode} - ${response.body}');
    }
  }
}
