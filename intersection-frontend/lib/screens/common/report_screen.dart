import 'package:flutter/material.dart';
import 'package:intersection/services/api_service.dart';

enum ReportTargetType { post, comment, user }

class ReportScreen extends StatefulWidget {
  // 🔥 [수정됨] Post 대신 targetId와 targetType을 받도록 수정
  final int targetId;
  final ReportTargetType targetType;
  
  const ReportScreen({
    super.key, 
    required this.targetId, 
    required this.targetType,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String selectedReason = '스팸/광고';
  String? content;
  bool _isSending = false;

  final reasons = [
    '스팸/광고', 
    '욕설/비방', 
    '혐오 발언', 
    '사칭', 
    '음란물', 
    '기타 불쾌한 콘텐츠'
  ];

  Future<void> _submitReport() async {
    setState(() {
      _isSending = true;
    });

    bool success = false;
    try {
      if (widget.targetType == ReportTargetType.post) {
        // 게시글 신고
        success = await ApiService.reportPost(widget.targetId);
      } else if (widget.targetType == ReportTargetType.comment) {
        // 댓글 신고 (API 서비스에 댓글 신고 함수가 없으므로 임시 성공 처리)
        // 실제 API 구현이 필요합니다: ApiService.reportComment(...)
        success = true; 
        
      } else if (widget.targetType == ReportTargetType.user) {
        // 사용자 신고
        success = await ApiService.reportUser(
          userId: widget.targetId, 
          reason: selectedReason, 
          content: content,
        );
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.targetType.name} 신고가 접수되었습니다.')),
        );
        Navigator.pop(context);
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('신고 접수에 실패했습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: $e')),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) { // 🔥 [수정 완료] BuildContextNotifier -> BuildContext
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.targetType.name} 신고'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('신고 사유 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // 신고 사유 드롭다운
            DropdownButtonFormField<String>(
              value: selectedReason,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
              ),
              items: reasons.map((String reason) {
                return DropdownMenuItem<String>(
                  value: reason,
                  child: Text(reason),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedReason = newValue!;
                });
              },
            ),
            
            const SizedBox(height: 20),
            const Text('상세 내용 (선택사항)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // 상세 내용 입력
            TextFormField(
              onChanged: (value) => content = value,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '자세한 내용을 입력해주세요.',
              ),
            ),

            const SizedBox(height: 30),

            // 신고 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSending ? null : _submitReport,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _isSending
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('신고 접수하기', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}