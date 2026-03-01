class Attendance {
  final int id;
  final String subjectName;
  final String date;
  final String lessonTheme;
  final int hours;
  final bool isExcused; // true = sababli (11), false = sababsiz (12)
  final int totalSubjectHours;
  final Map<String, int> trainingHours;

  Attendance({
    required this.id,
    required this.subjectName,
    required this.date,
    required this.lessonTheme,
    required this.hours,
    required this.isExcused,
    this.totalSubjectHours = 0,
    this.trainingHours = const {},
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    // Handle Proxy API (Simplified) vs Direct HEMIS (Nested)
    
    // 1. Subject Name
    String subject = "Noma'lum fan";
    if (json['subject'] is String) {
      subject = json['subject'];
    } else if (json['subject'] != null && json['subject'] is Map) {
      subject = json['subject']['name'] ?? "Noma'lum fan";
    }

    // 2. Lesson Theme
    String lesson = "Mavzu kiritilmagan";
    if (json['theme'] != null) {
       lesson = json['theme'];
    } else if (json['lesson'] != null && json['lesson'] is Map) {
       lesson = json['lesson']['name'] ?? "Mavzu kiritilmagan";
    }

    // 3. Date
    final dateStr = json['date'] ?? json['details']?['date'] ?? ''; 
    
    // 4. Hours
    final hourVal = json['hours'] ?? (json['hour'] != null ? int.tryParse(json['hour'].toString()) ?? 2 : 2);
    
    // 5. Status
    bool excused = false;
    if (json.containsKey('is_excused')) {
       excused = json['is_excused'] == true;
    } else {
       // Legacy/Raw Logic
       final int status = json['absent_status'] ?? 0;
       final bool valid = json['is_valid'] == true;
       excused = status == 11 || valid;
    }

    Map<String, int> parsedTrainingHours = {};
    if (json.containsKey('total_training_hours') && json['total_training_hours'] is Map) {
         final dynamic rawMap = json['total_training_hours'];
         rawMap.forEach((k, v) {
              parsedTrainingHours[k.toString()] = int.tryParse(v.toString()) ?? 0;
         });
    }

    return Attendance(
      id: json['id'] ?? 0,
      subjectName: subject,
      date: dateStr,
      lessonTheme: lesson,
      hours: hourVal,
      isExcused: excused,
      totalSubjectHours: json['total_subject_hours'] ?? 0,
      trainingHours: parsedTrainingHours,
    );
  }
}
