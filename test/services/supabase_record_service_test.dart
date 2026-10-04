import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:blood_sugar_tracker/models/blood_sugar_record.dart';
import 'package:blood_sugar_tracker/services/supabase_record_service.dart';

void main() {
  group('SupabaseRecordService Tests', () {
    test('getRecentRecords returns list of records', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['type'], 'recent');
        expect(request.url.queryParameters['limit'], '3');

        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 'rec-1',
                'sugar_value': 142,
                'measure_time': '2026-10-06T13:30:00.000Z',
                'tag': '취침전',
                'memo': '취침 전 측정',
              },
              {
                'id': 'rec-2',
                'sugar_value': 100,
                'measure_time': '2026-10-06T08:00:00.000Z',
                'tag': '공복',
                'memo': '기상 직후',
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SupabaseRecordService(httpClient: mockClient);
      final records = await service.getRecentRecords(limit: 3);

      expect(records.length, 2);
      expect(records.first.sugarValue, 142);
      expect(records.first.tag, '취침전');
    });

    test('get30DaysRecords returns 30 days data', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['type'], '30days');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 'rec-1',
                'sugar_value': 120,
                'measure_time': '2026-10-05T12:00:00.000Z',
                'tag': '운동후',
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SupabaseRecordService(httpClient: mockClient);
      final records = await service.get30DaysRecords();

      expect(records.length, 1);
      expect(records.first.sugarValue, 120);
      expect(records.first.tag, '운동후');
    });

    test('getPagedRecords passes page, pageSize and tag parameter', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['type'], 'paged');
        expect(request.url.queryParameters['page'], '2');
        expect(request.url.queryParameters['pageSize'], '8');
        expect(request.url.queryParameters['tag'], '운동후');

        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 'rec-page-2',
                'sugar_value': 135,
                'measure_time': '2026-10-04T16:00:00.000Z',
                'tag': '운동후',
              }
            ],
            'count': 12,
            'page': 2,
            'pageSize': 8,
            'totalPages': 2,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SupabaseRecordService(httpClient: mockClient);
      final result = await service.getPagedRecords(
        page: 2,
        pageSize: 8,
        tag: '운동후',
      );

      expect(result.data.length, 1);
      expect(result.data.first.tag, '운동후');
      expect(result.count, 12);
      expect(result.page, 2);
      expect(result.totalPages, 2);
    });

    test('createRecord sends POST and returns created record', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        final body = jsonDecode(request.body);
        expect(body['sugar_value'], 150);
        expect(body['tag'], '취침전');

        return http.Response(
          jsonEncode({
            'data': {
              'id': 'new-id-123',
              'sugar_value': 150,
              'measure_time': '2026-10-06T19:00:00.000Z',
              'tag': '취침전',
              'memo': '취침전',
            }
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SupabaseRecordService(httpClient: mockClient);
      final created = await service.createRecord(
        BloodSugarRecord(
          sugarValue: 150,
          measureTime: DateTime.parse('2026-10-06T19:00:00.000Z'),
          tag: '취침전',
          memo: '취침전',
        ),
      );

      expect(created.id, 'new-id-123');
      expect(created.sugarValue, 150);
      expect(created.tag, '취침전');
    });

    test('createRecord throws exception with server error message on duplicate tag error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': "해당 날짜(2026-10-06)에 이미 '공복' 기록이 존재합니다. (공복, 운동후, 취침전은 하루에 한 번만 입력 가능합니다)",
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SupabaseRecordService(httpClient: mockClient);
      expect(
        () => service.createRecord(
          BloodSugarRecord(
            sugarValue: 110,
            measureTime: DateTime.parse('2026-10-06T08:00:00.000Z'),
            tag: '공복',
          ),
        ),
        throwsA(
          predicate((e) =>
              e is Exception &&
              e.toString().contains("이미 '공복' 기록이 존재합니다")),
        ),
      );
    });

    test('updateRecord throws exception on duplicate tag error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': "해당 날짜(2026-10-06)에 이미 '운동후' 기록이 존재합니다. (공복, 운동후, 취침전은 하루에 한 번만 입력 가능합니다)",
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SupabaseRecordService(httpClient: mockClient);
      expect(
        () => service.updateRecord(
          BloodSugarRecord(
            id: 'edit-123',
            sugarValue: 130,
            measureTime: DateTime.parse('2026-10-06T14:00:00.000Z'),
            tag: '운동후',
          ),
        ),
        throwsA(
          predicate((e) =>
              e is Exception &&
              e.toString().contains("이미 '운동후' 기록이 존재합니다")),
        ),
      );
    });

    test('deleteRecord sends DELETE request', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.queryParameters['id'], 'del-123');
        return http.Response(
          jsonEncode({'success': true, 'id': 'del-123'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SupabaseRecordService(httpClient: mockClient);
      final success = await service.deleteRecord('del-123');
      expect(success, isTrue);
    });
  });
}
