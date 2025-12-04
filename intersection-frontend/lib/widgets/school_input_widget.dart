import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import '../models/school_info.dart';
import '../services/api_service.dart';

/// 학교 정보 입력 위젯 (자동완성 + 여러 개 추가 가능)
class SchoolInputWidget extends StatefulWidget {
  final List<SchoolInfo> schools;
  final Function(List<SchoolInfo>) onSchoolsChanged;

  const SchoolInputWidget({
    super.key,
    required this.schools,
    required this.onSchoolsChanged,
  });

  @override
  State<SchoolInputWidget> createState() => _SchoolInputWidgetState();
}

class _SchoolInputWidgetState extends State<SchoolInputWidget> {
  final List<String> schoolLevels = ['초등학교', '중학교', '고등학교'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '학교 정보',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
              onPressed: () {
                final newSchools = List<SchoolInfo>.from(widget.schools);
                newSchools.add(SchoolInfo(name: ''));
                widget.onSchoolsChanged(newSchools);
              },
              tooltip: '학교 추가',
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(widget.schools.length, (index) {
          return _buildSchoolInput(index);
        }),
      ],
    );
  }

  Widget _buildSchoolInput(int index) {
    final school = widget.schools[index];
    // 입학년도 컨트롤러만 생성 (학교명은 Autocomplete가 자체 관리)
    final entryYearController = TextEditingController(
      text: school.admissionYear?.toString() ?? '',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 (학교 번호 + 삭제 버튼)
          Row(
            children: [
              Text(
                '학교 ${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              if (widget.schools.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    final newSchools = List<SchoolInfo>.from(widget.schools);
                    newSchools.removeAt(index);
                    widget.onSchoolsChanged(newSchools);
                  },
                  tooltip: '삭제',
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // 학교급
          const Text(
            '학교급',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: school.schoolType,
            hint: const Text('초/중/고'),
            items: schoolLevels
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) {
              final newSchools = List<SchoolInfo>.from(widget.schools);
              newSchools[index] = school.copyWith(schoolType: v);
              widget.onSchoolsChanged(newSchools);
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.school_outlined, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            isExpanded: true,
          ),
          const SizedBox(height: 12),

          // 학교명 (자동완성)
          const Text(
            '학교명',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) async {
              final query = textEditingValue.text.trim();
              // 최소 2글자 이상 입력해야 검색 (debounce 효과)
              if (query.isEmpty || query.length < 2) {
                return const Iterable<String>.empty();
              }
              
              // 입력 후 약간의 지연 (debounce)
              await Future.delayed(const Duration(milliseconds: 300));
              
              // 입력이 변경되었는지 확인 (debounce 중에 텍스트가 바뀌었으면 취소)
              if (textEditingValue.text.trim() != query) {
                return const Iterable<String>.empty();
              }
              
              debugPrint('🔍 학교 검색 시작: "$query"');
              
              try {
                final results = await ApiService.searchSchools(query);
                debugPrint('✅ 학교 검색 결과: ${results.length}개 - $results');
                
                if (results.isEmpty) {
                  return const Iterable<String>.empty();
                }
                
                return results;
              } catch (e) {
                debugPrint('❌ 자동완성 오류: $e');
                return const Iterable<String>.empty();
              }
            },
            displayStringForOption: (String option) => option,
            onSelected: (String selection) {
              debugPrint('✅ 선택된 학교: $selection');
              final newSchools = List<SchoolInfo>.from(widget.schools);
              newSchools[index] = school.copyWith(name: selection);
              widget.onSchoolsChanged(newSchools);
            },
            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
              // 초기값 설정
              if (school.name.isNotEmpty && controller.text != school.name) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (controller.text != school.name) {
                    controller.text = school.name;
                  }
                });
              }

              return TextField(
                controller: controller,
                focusNode: focusNode,
                readOnly: school.name.isNotEmpty,
                decoration: InputDecoration(
                  hintText: '학교명을 검색하세요 (최소 2글자)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: school.name.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            final newSchools = List<SchoolInfo>.from(widget.schools);
                            newSchools[index] = school.copyWith(name: '');
                            widget.onSchoolsChanged(newSchools);
                            controller.clear();
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  filled: true,
                  fillColor: school.name.isNotEmpty ? Colors.grey.shade100 : Colors.white,
                  helperText: school.name.isEmpty
                      ? '목록에서 학교를 선택해주세요'
                      : '선택됨: ${school.name}',
                  helperStyle: TextStyle(
                    fontSize: 11, 
                    color: school.name.isEmpty ? Colors.blue.shade700 : Colors.green.shade700,
                    fontWeight: school.name.isEmpty ? FontWeight.normal : FontWeight.w600,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // 입학년도
          const Text(
            '입학년도',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _showEntryYearPicker(context, index, entryYearController),
            child: AbsorbPointer(
              child: TextField(
                controller: entryYearController,
                decoration: InputDecoration(
                  hintText: '연도 선택',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.calendar_month_outlined, size: 20),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEntryYearPicker(
    BuildContext context,
    int index,
    TextEditingController controller,
  ) {
    final currentYear = DateTime.now().year;
    final years = List<String>.generate(
      currentYear - 1980 + 1,
      (i) => (1980 + i).toString(),
    ).reversed.toList();

    int initialIndex = 0;
    if (controller.text.isNotEmpty) {
      initialIndex = years.indexOf(controller.text);
      if (initialIndex == -1) initialIndex = 0;
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[100],
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    "완료",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 32.0,
                  scrollController: FixedExtentScrollController(
                    initialItem: initialIndex,
                  ),
                  onSelectedItemChanged: (int selectedIndex) {
                    controller.text = years[selectedIndex];
                    final newSchools = List<SchoolInfo>.from(widget.schools);
                    newSchools[index] = widget.schools[index].copyWith(
                      admissionYear: int.tryParse(years[selectedIndex]),
                    );
                    widget.onSchoolsChanged(newSchools);
                  },
                  children: years.map((year) => Center(child: Text(year))).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

