import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/intl.dart';
import 'package:blood_sugar_tracker/models/blood_sugar_record.dart';
import 'package:blood_sugar_tracker/screens/dashboard_screen.dart';
import 'package:blood_sugar_tracker/screens/history_screen.dart';
import 'package:blood_sugar_tracker/services/supabase_record_service.dart';
import 'package:blood_sugar_tracker/widgets/blood_sugar_chart.dart';
import 'package:blood_sugar_tracker/widgets/record_list_item.dart';
import 'package:blood_sugar_tracker/widgets/record_modal.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  Widget createLocalizedApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ko', 'KR'),
      home: child,
    );
  }

  testWidgets('RecordListItem renders record details properly', (tester) async {
    final record = BloodSugarRecord(
      id: '1',
      sugarValue: 142,
      measureTime: DateTime(2026, 10, 6, 13, 30),
      tag: '운동후',
      memo: '조깅 후 측정',
    );

    await tester.pumpWidget(
      createLocalizedApp(
        Scaffold(
          body: RecordListItem(record: record),
        ),
      ),
    );

    expect(find.text('142'), findsOneWidget);
    expect(find.text('mg/dL'), findsOneWidget);
    expect(find.text('운동후'), findsOneWidget);
    expect(find.text('조깅 후 측정'), findsOneWidget);
    expect(find.text('2026-10-06 13:30'), findsOneWidget);
  });

  testWidgets('BloodSugarChart renders filter buttons, average line on top-right, date data header, and updates on touch without tooltip', (tester) async {
    final now = DateTime.now();
    final twoDaysAgo = now.subtract(const Duration(days: 2));
    final twoDaysAgoLabel = DateFormat('M/d').format(twoDaysAgo);
    final records = [
      BloodSugarRecord(
        sugarValue: 95,
        measureTime: now,
        tag: '공복',
      ),
      BloodSugarRecord(
        sugarValue: 102,
        measureTime: now,
        tag: '운동후',
      ),
      BloodSugarRecord(
        sugarValue: 118,
        measureTime: now,
        tag: '취침전',
      ),
      BloodSugarRecord(
        sugarValue: 100,
        measureTime: twoDaysAgo,
        tag: '공복',
      ),
      BloodSugarRecord(
        sugarValue: 220,
        measureTime: now.subtract(const Duration(days: 1)),
        tag: '예외',
      ),
    ];

    await tester.pumpWidget(
      createLocalizedApp(
        Scaffold(
          body: BloodSugarChart(records: records),
        ),
      ),
    );

    expect(find.text('공복'), findsOneWidget);
    expect(find.text('운동후'), findsOneWidget);
    expect(find.text('취침전'), findsOneWidget);
    // '예외' should NOT be a filter button on the chart
    expect(find.text('예외'), findsNothing);

    // Verify today's data is displayed at the top header by default
    expect(find.textContaining('95mg/dl'), findsOneWidget);
    expect(find.textContaining('102mg/dl'), findsOneWidget);
    expect(find.textContaining('118mg/dl'), findsOneWidget);

    // Verify LineChart has HorizontalLine with Alignment.topRight for average
    final lineChartFinder = find.byType(LineChart);
    expect(lineChartFinder, findsOneWidget);
    final LineChart lineChart = tester.widget(lineChartFinder);
    final extraLines = lineChart.data.extraLinesData;
    expect(extraLines.horizontalLines.isNotEmpty, isTrue);
    final avgLine = extraLines.horizontalLines.first;
    expect(avgLine.label.alignment, Alignment.topRight);

    // Verify touch is enabled but tooltip balloon is disabled (getTooltipItems returns nulls)
    expect(lineChart.data.lineTouchData.enabled, isTrue);
    final dummySpots = [
      TouchLineBarSpot(
        LineChartBarData(spots: const [FlSpot(27, 100)]),
        0,
        const FlSpot(27, 100),
        0.0,
      ),
    ];
    final tooltipItems = lineChart.data.lineTouchData.touchTooltipData.getTooltipItems(dummySpots);
    expect(tooltipItems.every((item) => item == null), isTrue);

    // Simulate touch/tap on 2 days ago (spot x = 27)
    final touchCallback = lineChart.data.lineTouchData.touchCallback;
    expect(touchCallback, isNotNull);
    touchCallback!(
      FlTapDownEvent(TapDownDetails(globalPosition: const Offset(100, 100), localPosition: const Offset(100, 100))),
      LineTouchResponse(
        lineBarSpots: dummySpots,
        touchChartCoordinate: const Offset(27, 100),
        touchLocation: const Offset(100, 100),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header changed to 2 days ago data
    expect(find.textContaining('$twoDaysAgoLabel '), findsOneWidget);
    expect(find.textContaining('100mg/dl'), findsOneWidget);

    // Simulate touch/tap on 3 days ago (has no data) via localPosition dx
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    final threeDaysAgoLabel = DateFormat('M/d').format(threeDaysAgo);
    final emptyDayDx = (26 / 29) * 900;
    touchCallback(
      FlTapDownEvent(TapDownDetails(globalPosition: Offset(emptyDayDx, 100), localPosition: Offset(emptyDayDx, 100))),
      LineTouchResponse(
        lineBarSpots: [],
        touchChartCoordinate: Offset(26, 100),
        touchLocation: Offset(emptyDayDx, 100),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header displays '기록 없음' for empty day
    expect(find.textContaining('$threeDaysAgoLabel '), findsOneWidget);
    expect(find.textContaining('기록 없음'), findsOneWidget);

    // Tap filter button to toggle
    await tester.tap(find.text('공복'));
    await tester.pumpAndSettle();
  });

  testWidgets('DashboardScreen renders recent records and title 혈당 일지', (tester) async {
    final mockClient = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'data': [
            {
              'id': 'rec-1',
              'sugar_value': 142,
              'measure_time': '2026-10-06T13:30:00.000Z',
              'tag': '운동후',
              'memo': '운동 직후',
            }
          ]
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final mockService = SupabaseRecordService(httpClient: mockClient);

    await tester.pumpWidget(
      createLocalizedApp(
        DashboardScreen(recordService: mockService),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('혈당 일지'), findsOneWidget);
    expect(find.text('최근 기록'), findsOneWidget);
    expect(find.text('전체보기 >'), findsOneWidget);
    expect(find.text('142'), findsOneWidget);
  });

  testWidgets('RecordModal displays 4 tags and opens DatePicker without error', (tester) async {
    await tester.pumpWidget(
      createLocalizedApp(
        Scaffold(
          body: RecordModal(
            onSave: (record) async {},
          ),
        ),
      ),
    );

    // Verify 4 tags are displayed
    expect(find.text('공복'), findsOneWidget);
    expect(find.text('운동후'), findsOneWidget);
    expect(find.text('취침전'), findsOneWidget);
    expect(find.text('예외'), findsOneWidget);

    // Tap '운동후' tag
    await tester.tap(find.text('운동후'));
    await tester.pumpAndSettle();

    // Tap date/time picker (Calendar icon / date container)
    final datePickerFinder = find.byIcon(Icons.calendar_today);
    expect(datePickerFinder, findsOneWidget);
    await tester.tap(datePickerFinder);
    await tester.pumpAndSettle();

    // Verify DatePicker dialog is opened successfully without error
    expect(find.byType(DatePickerDialog), findsOneWidget);

    // Select OK on date picker dialog
    final okButton = find.text('확인');
    if (okButton.evaluate().isNotEmpty) {
      await tester.tap(okButton);
      await tester.pumpAndSettle();
    }
  });

  testWidgets('RecordModal enters value and saves successfully with exception tag', (tester) async {
    BloodSugarRecord? savedRecord;

    await tester.pumpWidget(
      createLocalizedApp(
        Scaffold(
          body: RecordModal(
            onSave: (record) async {
              savedRecord = record;
            },
          ),
        ),
      ),
    );

    // Enter value
    await tester.enterText(find.byType(TextFormField).first, '165');
    // Select '예외' tag
    await tester.tap(find.text('예외'));
    await tester.pumpAndSettle();

    // Tap Save button
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(savedRecord, isNotNull);
    expect(savedRecord!.sugarValue, 165);
    expect(savedRecord!.tag, '예외');
  });

  testWidgets('RecordModal displays duplicate error message via SnackBar when onSave fails', (tester) async {
    await tester.pumpWidget(
      createLocalizedApp(
        Scaffold(
          body: RecordModal(
            onSave: (record) async {
              throw Exception("해당 날짜에 이미 '공복' 기록이 존재합니다. (공복, 운동후, 취침전은 하루에 한 번만 입력 가능합니다)");
            },
          ),
        ),
      ),
    );

    // Enter value
    await tester.enterText(find.byType(TextFormField).first, '108');
    // Select '공복' tag
    await tester.tap(find.text('공복'));
    await tester.pumpAndSettle();

    // Tap Save button
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.textContaining("이미 '공복' 기록이 존재합니다"), findsOneWidget);
  });

  testWidgets('HistoryScreen displays 5 filter buttons (전체, 공복, 운동후, 취침전, 예외) and filters by tag with pageSize 7', (tester) async {
    String? requestedTag;
    String? requestedPageSize;

    final mockClient = MockClient((request) async {
      requestedTag = request.url.queryParameters['tag'];
      requestedPageSize = request.url.queryParameters['pageSize'];
      return http.Response(
        jsonEncode({
          'data': [
            {
              'id': 'rec-1',
              'sugar_value': 105,
              'measure_time': '2026-10-06T08:00:00.000Z',
              'tag': requestedTag ?? '공복',
              'memo': '태그: $requestedTag',
            },
          ],
          'count': 1,
          'page': 1,
          'pageSize': 7,
          'totalPages': 1,
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final mockService = SupabaseRecordService(httpClient: mockClient);

    await tester.pumpWidget(
      createLocalizedApp(
        HistoryScreen(recordService: mockService),
      ),
    );

    await tester.pumpAndSettle();

    expect(requestedPageSize, '7');

    // Verify all 5 filter buttons are present
    expect(find.text('전체'), findsOneWidget);
    expect(find.text('공복'), findsWidgets);
    expect(find.text('운동후'), findsOneWidget);
    expect(find.text('취침전'), findsOneWidget);
    expect(find.text('예외'), findsOneWidget);

    // Tap '운동후' filter button
    await tester.tap(find.text('운동후'));
    await tester.pumpAndSettle();

    expect(requestedTag, '운동후');

    // Tap '취침전' filter button
    await tester.tap(find.text('취침전'));
    await tester.pumpAndSettle();

    expect(requestedTag, '취침전');

    // Tap '예외' filter button
    await tester.tap(find.text('예외'));
    await tester.pumpAndSettle();

    expect(requestedTag, '예외');

    // Tap '전체' filter button
    await tester.tap(find.text('전체'));
    await tester.pumpAndSettle();

    expect(requestedTag, isNull);
  });
}
