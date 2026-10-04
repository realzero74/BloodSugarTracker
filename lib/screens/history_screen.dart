import 'package:flutter/material.dart';
import '../models/blood_sugar_record.dart';
import '../services/supabase_record_service.dart';
import '../theme/app_theme.dart';
import '../widgets/record_list_item.dart';
import '../widgets/record_modal.dart';

class HistoryScreen extends StatefulWidget {
  final SupabaseRecordService recordService;

  const HistoryScreen({
    super.key,
    required this.recordService,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<BloodSugarRecord> _records = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  static const int _pageSize = 7;
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedFilterTag; // null indicates '전체'

  @override
  void initState() {
    super.initState();
    _loadPage(_currentPage);
  }

  Future<void> _loadPage(int page) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.recordService.getPagedRecords(
        page: page,
        pageSize: _pageSize,
        tag: _selectedFilterTag,
      );

      if (mounted) {
        setState(() {
          _records = result.data;
          _currentPage = result.page;
          _totalPages = result.totalPages > 0 ? result.totalPages : 1;
          _totalCount = result.count;
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

  void _onFilterSelected(String? tag) {
    if (_selectedFilterTag == tag) return;
    setState(() {
      _selectedFilterTag = tag;
      _currentPage = 1;
    });
    _loadPage(1);
  }

  void _openEditModal(BloodSugarRecord record) {
    RecordModal.show(
      context,
      initialRecord: record,
      existingRecords: _records,
      onSave: (updatedRecord) async {
        await widget.recordService.updateRecord(updatedRecord);
        await _loadPage(_currentPage);
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
        // If current page becomes empty after deletion, go to previous page if possible
        if (_records.length == 1 && _currentPage > 1) {
          await _loadPage(_currentPage - 1);
        } else {
          await _loadPage(_currentPage);
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('모든 기록'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '전체 기록',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF555555),
                      ),
                    ),
                    Text(
                      '총 $_totalCount개',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Divider(
                  color: Color(0xFFF4F7F6),
                  thickness: 2,
                  height: 16,
                ),

                // Filter Buttons (전체, 공복, 운동후, 취침전, 예외)
                Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFilterBtn(
                          title: '전체',
                          isActive: _selectedFilterTag == null,
                          activeColor: AppTheme.primary,
                          onTap: () => _onFilterSelected(null),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterBtn(
                          title: '공복',
                          isActive: _selectedFilterTag == '공복',
                          activeColor: AppTheme.chartFasting,
                          onTap: () => _onFilterSelected('공복'),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterBtn(
                          title: '운동후',
                          isActive: _selectedFilterTag == '운동후',
                          activeColor: AppTheme.chartExercise,
                          onTap: () => _onFilterSelected('운동후'),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterBtn(
                          title: '취침전',
                          isActive: _selectedFilterTag == '취침전',
                          activeColor: AppTheme.chartBedtime,
                          onTap: () => _onFilterSelected('취침전'),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterBtn(
                          title: '예외',
                          isActive: _selectedFilterTag == '예외',
                          activeColor: AppTheme.tagExceptionText,
                          onTap: () => _onFilterSelected('예외'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Records List Container
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE1E8ED)),
                    ),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.error_outline,
                                          size: 40, color: Colors.red),
                                      const SizedBox(height: 8),
                                      Text(
                                        _errorMessage!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: () => _loadPage(_currentPage),
                                        child: const Text('다시 시도'),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : _records.isEmpty
                                ? const Center(
                                    child: Text(
                                      '등록된 기록이 없습니다.',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 15,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _records.length,
                                    itemBuilder: (context, index) {
                                      final record = _records[index];
                                      return RecordListItem(
                                        record: record,
                                        onEdit: () => _openEditModal(record),
                                        onDelete: () => _deleteRecord(record),
                                      );
                                    },
                                  ),
                  ),
                ),
                const SizedBox(height: 16),

                // Pagination Navigation Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: (_isLoading || _currentPage <= 1)
                          ? null
                          : () => _loadPage(_currentPage - 1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primary,
                        disabledForegroundColor: Colors.grey.shade400,
                        disabledBackgroundColor: Colors.grey.shade100,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: _currentPage <= 1
                                ? Colors.grey.shade300
                                : const Color(0xFFDDDDDD),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        '이전',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '$_currentPage / $_totalPages',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF555555),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: (_isLoading || _currentPage >= _totalPages)
                          ? null
                          : () => _loadPage(_currentPage + 1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primary,
                        disabledForegroundColor: Colors.grey.shade400,
                        disabledBackgroundColor: Colors.grey.shade100,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: _currentPage >= _totalPages
                                ? Colors.grey.shade300
                                : const Color(0xFFDDDDDD),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        '다음',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBtn({
    required String title,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.transparent : const Color(0xFFDDDDDD),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : const Color(0xFF888888),
          ),
        ),
      ),
    );
  }
}
