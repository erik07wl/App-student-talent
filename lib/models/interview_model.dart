class InterviewModel {
  final String id;
  final String studentId;
  final String employerId;
  final DateTime timestamp;
  final String status; // z.B. 'pending', 'accepted', 'declined'

  InterviewModel({
    required this.id,
    required this.studentId,
    required this.employerId,
    required this.timestamp,
    required this.status,
  });

  factory InterviewModel.fromMap(Map<String, dynamic> data, String documentId) {
    return InterviewModel(
      id: documentId,
      studentId: data['studentId'] ?? '',
      employerId: data['employerId'] ?? '',
      timestamp: data['timestamp'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['timestamp']) 
          : DateTime.now(),
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'employerId': employerId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status,
    };
  }
}