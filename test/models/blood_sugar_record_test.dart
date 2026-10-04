import 'package:flutter_test/flutter_test.dart';
import 'package:blood_sugar_tracker/models/blood_sugar_record.dart';

void main() {
  group('BloodSugarRecord Model Tests', () {
    test('fromJson and toJson should correctly serialize and deserialize', () {
      final now = DateTime.parse('2026-10-06T13:30:00.000Z');
      final json = {
        'id': 'test-uuid-1',
        'user_id': 'user-123',
        'sugar_value': 142,
        'measure_time': now.toIso8601String(),
        'tag': '식후',
        'memo': '점심 식후',
        'created_at': now.toIso8601String(),
      };

      final record = BloodSugarRecord.fromJson(json);

      expect(record.id, 'test-uuid-1');
      expect(record.userId, 'user-123');
      expect(record.sugarValue, 142);
      expect(record.tag, '식후');
      expect(record.memo, '점심 식후');

      final serialized = record.toJson();
      expect(serialized['sugar_value'], 142);
      expect(serialized['tag'], '식후');
      expect(serialized['memo'], '점심 식후');
      expect(serialized['id'], 'test-uuid-1');
      expect(serialized['user_id'], 'user-123');
    });

    test('copyWith creates a new instance with updated properties', () {
      final record = BloodSugarRecord(
        id: '1',
        sugarValue: 100,
        measureTime: DateTime(2026, 10, 6, 8, 0),
        tag: '공복',
      );

      final updated = record.copyWith(
        sugarValue: 110,
        memo: '아침 공복',
      );

      expect(updated.id, '1');
      expect(updated.sugarValue, 110);
      expect(updated.tag, '공복');
      expect(updated.memo, '아침 공복');
    });
  });
}
