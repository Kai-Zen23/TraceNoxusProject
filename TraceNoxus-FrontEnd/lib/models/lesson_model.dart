class Question {
  final String text;
  final String answer;
  final List<String>? options;

  Question({required this.text, required this.answer, this.options});

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      text: json['text'],
      answer: json['answer'],
      options: (json['options'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'text': text,
    'answer': answer,
    if (options != null) 'options': options,
  };
}

class Lesson {
  final int? id;
  final String code;
  final String title;
  final String teacher;
  final List<Question> questions;

  Lesson({this.id, required this.code, required this.title, required this.teacher, required this.questions});

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'],
      code: json['code'],
      title: json['title'],
      teacher: json['teacher'],
      questions: (json['questions'] as List<dynamic>?)?.map((q) => Question.fromJson(q)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'code': code,
    'title': title,
    'teacher': teacher,
    'questions': questions.map((q) => q.toJson()).toList(),
  };
}