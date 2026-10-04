import 'package:flutter/material.dart';
import '../models/blood_sugar_record.dart';
import '../services/supabase_record_service.dart';
import '../theme/app_theme.dart';
import '../widgets/blood_sugar_chart.dart';
import '../widgets/record_list_item.dart';
import '../widgets/record_modal.dart';
import 'history_screen.dart';

class DashboardScreen extends StatefulWidget {
  final SupabaseRecordService recordService;

  const DashboardScreen({
    super.key,
    required this.recordService,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<BloodSugarRecord> _recentRecords = [];
  List<BloodSugarRecord> _thirtyDaysRecords = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final recentFuture = widget.recordService.getRecentRecords(limit: 3);
      final thirtyDaysFuture = widget.recordService.get30DaysRecords();

      final results = await Future.wait([recentFuture, thirtyDaysFuture]);
      if (mounted) {
        setState(() {
          _recentRecords = results[0];
          _thirtyDaysRecords = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _openAddModal() {
    RecordModal.show(
      context,
      onSave: (record) async {
        await widget.recordService.createRecord(record);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('혈당 기록이 저장되었습니다.')),
          );
        }
      },
    );
  }

  void _openEditModal(BloodSugarRecord record) {
    RecordModal.show(
      context,
      initialRecord: record,
      onSave: (updatedRecord) async {
        await widget.recordService.updateRecord(updatedRecord);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('혈당 기록이 수정되었습니다.')),
          );
        }
      },
    );
  }

  Future<void> _deleteRecord(BloodSugarRecord record) async {
    if (record.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('기록 삭제'),
        content: const Text('이 혈당 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.recordService.deleteRecord(record.id!);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('기록이 삭제되었습니다.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제 실패: $e')),
          );
        }
      }
    }
  }

  void _navigateToHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HistoryScreen(
          recordService: widget.recordService,
        ),
      ),
    );
    // Refresh when returning from history view
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('혈당 일지'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: AppTheme.primary,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 12),
                              Text(
                                '데이터를 불러오지 못했습니다.\n$_errorMessage',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadData,
                                child: const Text('다시 시도'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // 30 Days Trend Chart Card
                          BloodSugarChart(records: _thirtyDaysRecords),
                          const SizedBox(height: 24),

                          // Recent Records Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              const Text(
                                '최근 기록',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF555555),
                                ),
                              ),
                              TextButton(
                                onPressed: _navigateToHistory,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  '전체보기 >',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(
                            color: Color(0xFFF4F7F6),
                            thickness: 2,
                            height: 16,
                          ),

                          // Recent Records List Card
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE1E8ED)),
                            ),
                            child: _recentRecords.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 36),
                                    child: Center(
                                      child: Text(
                                        '기록된 혈당 데이터가 없습니다.\n우측 하단 + 버튼을 눌러 추가해보세요!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: _recentRecords.map((record) {
                                      return RecordListItem(
                                        record: record,
                                        onEdit: () => _openEditModal(record),
                                        onDelete: () => _deleteRecord(record),
                                      );
                                    }).toList(),
                                  ),
                          ),
                          const SizedBox(height: 80), // Space for FAB
                        ],
                      ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddModal,
        tooltip: '혈당 기록 추가',
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }
}
