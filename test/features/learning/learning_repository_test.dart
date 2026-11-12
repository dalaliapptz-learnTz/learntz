import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:learntz/features/learners/learner_models.dart';
import 'package:learntz/features/learning/learning_repository.dart';

class _FakeSupabaseServer {
  _FakeSupabaseServer._(this._server, this._handler) {
    _server.listen((request) async {
      final rawBody = await utf8.decoder.bind(request).join();
      final decodedBody = rawBody.isEmpty ? null : jsonDecode(rawBody);
      await _handler(request, decodedBody);
    });
  }

  final HttpServer _server;
  final Future<void> Function(HttpRequest request, dynamic body) _handler;

  String get baseUrl => 'http://127.0.0.1:${_server.port}';

  static Future<_FakeSupabaseServer> start(
    Future<void> Function(HttpRequest request, dynamic body) handler,
  ) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return _FakeSupabaseServer._(server, handler);
  }

  Future<void> close() => _server.close(force: true);
}

void _writeJson(HttpRequest request, int statusCode, Object body) {
  request.response
    ..statusCode = statusCode
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(body));
  request.response.close();
}

Map<String, dynamic> _sessionPayload() => {
  'access_token': 'header.payload.signature',
  'token_type': 'bearer',
  'expires_in': 3600,
  'refresh_token': 'fake-refresh-token',
  'user': {
    'id': '00000000-0000-0000-0000-000000000501',
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'parent@example.com',
    'created_at': '2026-11-12T00:00:00Z',
    'app_metadata': {'provider': 'email'},
    'user_metadata': {'full_name': 'Parent User', 'country_code': 'TZ'},
  },
};

void main() {
  setUp(() {
    HttpOverrides.global = null;
  });

  test('LearningRepository drives catalog load, lesson completion, and quiz grading', () async {
    int completedCount = 0;
    int masteryPercent = 0;
    final server = await _FakeSupabaseServer.start((request, body) async {
      final path = request.uri.path;
      if (path == '/auth/v1/token') {
        _writeJson(request, 200, _sessionPayload());
      } else if (path == '/rest/v1/subjects') {
        _writeJson(request, 200, [
          {
            'id': 'subj-1',
            'country_code': 'TZ',
            'curriculum_id': 'curr-1',
            'education_level_id': 'lvl-1',
            'grade_id': null,
            'code': 'tie-kiswahili',
            'name': 'Kiswahili',
            'description': 'Kusoma na kuandika',
            'display_order': 1,
          },
        ]);
      } else if (path == '/rest/v1/topics') {
        _writeJson(request, 200, [
          {
            'id': 'topic-1',
            'subject_id': 'subj-1',
            'title': 'Irabu na Silabi',
            'summary': 'Misingi',
            'display_order': 1,
          },
        ]);
      } else if (path == '/rest/v1/lessons') {
        _writeJson(request, 200, [
          {
            'id': 'lesson-1',
            'topic_id': 'topic-1',
            'title': 'Sauti za Irabu',
            'body_markdown': '# Sauti\n\nIrabu tano za Kiswahili.',
            'estimated_minutes': 8,
            'is_free_preview': true,
            'display_order': 1,
          },
        ]);
      } else if (path == '/rest/v1/learner_progress') {
        _writeJson(request, 200, []);
      } else if (path == '/rest/v1/rpc/get_learner_learning_summary') {
        _writeJson(request, 200, {
          'learner_id': 'learner-1',
          'total_lessons': 1,
          'completed_lessons': completedCount,
          'in_progress_lessons': 0,
          'average_quiz_score_percent': completedCount == 0 ? 0 : 100,
          'mastery_percent': masteryPercent,
          'has_active_subscription': true,
        });
      } else if (path == '/rest/v1/rpc/submit_learner_quiz_attempt') {
        completedCount = 1;
        masteryPercent = 100;
        _writeJson(request, 200, {
          'quiz_id': 'quiz-1',
          'lesson_id': 'lesson-1',
          'score_percent': 100,
          'correct_count': 2,
          'total_questions': 2,
          'passed': true,
          'pass_score_percent': 70,
          'best_quiz_score_percent': 100,
          'lesson_status': 'completed',
          'attempts_count': 1,
          'results': [
            {
              'question_id': 'q1',
              'selected_index': 1,
              'correct_index': 1,
              'is_correct': true,
              'explanation': 'Irabu tano ni a, e, i, o, u.',
            },
          ],
        });
      } else {
        _writeJson(request, 404, {'message': 'Not found: $path'});
      }
    });

    final client = SupabaseClient(server.baseUrl, 'anon-key');
    await client.auth.signInWithPassword(
      email: 'parent@example.com',
      password: 'password123',
    );
    final repo = LearningRepository(client);
    final learner = Learner(
      id: 'learner-1',
      firstName: 'Amani',
      middleName: null,
      lastName: 'Mushi',
      dateOfBirth: DateTime(2016, 5, 1),
      gender: 'female',
      countryCode: 'TZ',
      educationSystemId: 'sys-1',
      curriculumId: 'curr-1',
      educationLevelId: 'lvl-1',
      gradeId: 'grade-1',
      schoolId: null,
      status: 'active',
      createdAt: DateTime.utc(2026, 11, 12),
      updatedAt: DateTime.utc(2026, 11, 12),
    );

    final initialBundle = await repo.loadCatalogForLearner(learner);
    expect(initialBundle.subjects.length, 1);
    expect(initialBundle.summary.masteryPercent, 0);

    final quizResult = await repo.submitQuizAttempt(
      learnerId: learner.id,
      quizId: 'quiz-1',
      selectedIndices: const [1, 0],
    );
    expect(quizResult.passed, isTrue);
    expect(quizResult.scorePercent, 100);
    expect(quizResult.lessonStatus, 'completed');

    final updatedSummary = await repo.getLearningSummary(learner.id);
    expect(updatedSummary.completedLessons, 1);
    expect(updatedSummary.masteryPercent, 100);

    await client.dispose();
    await server.close();
  });
}
