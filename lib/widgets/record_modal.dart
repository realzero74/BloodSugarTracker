import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/blood_sugar_record.dart';
import '../theme/app_theme.dart';

class RecordModal extends StatefulWidget {
  final BloodSugarRecord? initialRecord;
  final List<BloodSugarRecord>? existingRecords;
  final Future<void> Function(BloodSugarRecord record) onSave;

  const RecordModal({
    super.key,
    this.initialRecord,
    this.existingRecords,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    BloodSugarRecord? initialRecord,
    List<BloodSugarRecord>? existingRecords,
    required Future<void> Function(BloodSugarRecord record) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecordModal(
        initialRecord: initialRecord,
        existingRecords: existingRecords,
        onSave: onSave,
      ),
    );
  }

  @override
  State<RecordModal> createState() => _RecordModalState();
}

class _RecordModalState extends State<RecordModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _sugarValController;
  late TextEditingController _memoController;
  late DateTime _selectedTime;
  String? _selectedTag;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final rec = widget.initialRecord;
    _sugarValController = TextEditingController(
      text: rec != null ? rec.sugarValue.toString() : '',
    );
    _memoController = TextEditingController(text: rec?.memo ?? '');
    _selectedTime = rec?.measureTime ?? DateTime.now();
    _selectedTag = rec?.tag;
  }

  @override
  void dispose() {
    _sugarValController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  static const List<String> _tags = ['공복', '운동후', '취침전', '예외'];

  Set<String> _getDisabledTags() {
    if (widget.existingRecords == null || widget.existingRecords!.isEmpty) {
      return {};
    }

    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedTime);
    final Set<String> disabled = {};

    for (final rec in widget.existingRecords!) {
      // If editing, skip the record currently being edited
      if (widget.initialRecord != null && widget.initialRecord!.id != null && rec.id == widget.initialRecord!.id) {
        continue;
      }
      if (rec.tag == null || rec.tag == '예외') {
        continue;
      }
      final recDateStr = DateFormat('yyyy-MM-dd').format(rec.measureTime);
      if (recDateStr == selectedDateStr) {
        disabled.add(rec.tag!);
      }
    }

    return disabled;
  }

  void _onTagTap(String tag) {
    final disabledTags = _getDisabledTags();
    if (disabledTags.contains(tag)) return;

    setState(() {
      if (_selectedTag == tag) {
        _selectedTag = null; // toggle off
      } else {
        _selectedTag = tag;
      }
    });
  }

  Future<void> _pickDateTime() async {
    final firstDate = DateTime(2000);
    final lastDate = DateTime(2100);
    DateTime initialDate = _selectedTime;
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('ko', 'KR'),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      // If previously selected tag is now disabled on newly picked date, unselect it
      final disabledTags = _getDisabledTags();
      if (_selectedTag != null && disabledTags.contains(_selectedTag)) {
        _selectedTag = null;
      }
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final sugarValue = int.tryParse(_sugarValController.text.trim());
    if (sugarValue == null || sugarValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('유효한 혈당 수치를 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final record = BloodSugarRecord(
        id: widget.initialRecord?.id,
        userId: widget.initialRecord?.userId,
        sugarValue: sugarValue,
        measureTime: _selectedTime,
        tag: _selectedTag,
        memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
      );

      await widget.onSave(record);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.startsWith('Exception: ')) {
          msg = msg.substring('Exception: '.length);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialRecord != null;
    final timeFormat = DateFormat('yyyy-MM-dd HH:mm');
    final formattedTime = timeFormat.format(_selectedTime);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  isEditing ? '혈당 기록 수정' : '혈당 기록 추가',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Blood Sugar Value Input
                const Text(
                  '혈당 수치 (mg/dL) *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF444444),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _sugarValController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '100',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: const Color(0xFFFAFAFA),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return '수치를 입력해주세요.';
                    }
                    final num = int.tryParse(val.trim());
                    if (num == null || num <= 0) {
                      return '0보다 큰 숫자를 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Measurement Time Picker
                const Text(
                  '측정 시간',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF444444),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDateTime,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDDDDDD)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formattedTime,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Status Tag Group
                const Text(
                  '상태 태그 (선택)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF444444),
                  ),
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final disabledTags = _getDisabledTags();
                    return Row(
                      children: _tags.map((tag) {
                        final isDisabled = disabledTags.contains(tag);
                        final isSelected = _selectedTag == tag;
                        final activeColor = AppTheme.getTagTextColor(tag);

                        Color bgColor;
                        Color borderColor;
                        Color textColor;

                        if (isDisabled) {
                          bgColor = const Color(0xFFF1F1F1);
                          borderColor = const Color(0xFFE2E2E2);
                          textColor = const Color(0xFFB0B0B0);
                        } else if (isSelected) {
                          bgColor = activeColor;
                          borderColor = activeColor;
                          textColor = Colors.white;
                        } else {
                          bgColor = Colors.white;
                          borderColor = const Color(0xFFDDDDDD);
                          textColor = const Color(0xFF666666);
                        }

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Tooltip(
                              message: isDisabled ? '해당 날짜에 이미 등록된 태그입니다.' : '',
                              child: InkWell(
                                onTap: isDisabled ? null : () => _onTagTap(tag),
                                borderRadius: BorderRadius.circular(10),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: borderColor,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: textColor,
                                      decoration: isDisabled ? TextDecoration.none : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Memo Input
                const Text(
                  '메모 (선택)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF444444),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _memoController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: '간단한 메모 (선택사항)',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFFFAFAFA),
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF0F0F0),
                          foregroundColor: const Color(0xFF555555),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                '저장',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
