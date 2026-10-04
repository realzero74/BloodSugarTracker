class BloodSugarRecord {
  final String? id;
  final String? userId;
  final int sugarValue;
  final DateTime measureTime;
  final String? tag; // '공복', '운동후', '취침전', '예외'
  final String? memo;
  final DateTime? createdAt;

  const BloodSugarRecord({
    this.id,
    this.userId,
    required this.sugarValue,
    required this.measureTime,
    this.tag,
    this.memo,
    this.createdAt,
  });

  factory BloodSugarRecord.fromJson(Map<String, dynamic> json) {
    return BloodSugarRecord(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      sugarValue: json['sugar_value'] is int
          ? json['sugar_value'] as int
          : int.tryParse(json['sugar_value'].toString()) ?? 0,
      measureTime: json['measure_time'] != null
          ? DateTime.parse(json['measure_time'] as String).toLocal()
          : DateTime.now(),
      tag: json['tag'] as String?,
      memo: json['memo'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'sugar_value': sugarValue,
      'measure_time': measureTime.toUtc().toIso8601String(),
    };
    if (id != null) map['id'] = id;
    if (userId != null) map['user_id'] = userId;
    if (tag != null && tag!.isNotEmpty) map['tag'] = tag;
    if (memo != null && memo!.isNotEmpty) map['memo'] = memo;
    return map;
  }

  BloodSugarRecord copyWith({
    String? id,
    String? userId,
    int? sugarValue,
    DateTime? measureTime,
    String? tag,
    String? memo,
    DateTime? createdAt,
  }) {
    return BloodSugarRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sugarValue: sugarValue ?? this.sugarValue,
      measureTime: measureTime ?? this.measureTime,
      tag: tag ?? this.tag,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PagedResult<T> {
  final List<T> data;
  final int count;
  final int page;
  final int pageSize;
  final int totalPages;

  const PagedResult({
    required this.data,
    required this.count,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });
}
