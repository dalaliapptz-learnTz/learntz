import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:learntz/features/learners/learner_models.dart';
import 'package:learntz/features/learning/learning_models.dart';
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

Future<SupabaseClient> _signedInClient(_FakeSupabaseServer server) async {
  final client = SupabaseClient(server.baseUrl, 'anon-key');
  await client.auth.signInWithPassword(
    email: 'parent@example.com',
    password: 'password123',
  );
  return client;
}

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

  test('LearningRepository invokes Phase 2 dashboard and explorer RPCs correctly', () async {
    final server = await _FakeSupabaseServer.start((request, body) async {
      final path = request.uri.path;
      if (path == '/auth/v1/token') {
        _writeJson(request, 200, _sessionPayload());
        return;
      }
      if (path == '/rest/v1/rpc/get_parent_dashboard_overview') {
        _writeJson(request, 200, [
          {
            'learner_id': 'learner-1',
            'first_name': 'Baraka',
            'last_name': 'Parent',
            'full_name': 'Baraka Parent',
            'country_code': 'TZ',
            'status': 'active',
            'grade_name': 'Grade 1',
            'level_name': 'Primary',
            'curriculum_name': 'TIE',
            'system_name': 'National',
            'school_name': 'Independent Learner',
            'total_lessons': 5,
            'completed_lessons': 3,
            'in_progress_lessons': 1,
            'average_quiz_score_percent': 85,
            'mastery_percent': 60,
            'streak_days': 4,
            'last_accessed_at': '2026-11-13T02:00:00Z',
            'last_lesson_accessed': {
              'lesson_id': 'les-1',
              'lesson_title': 'Kusoma Herufi',
              'subject_name': 'Kiswahili',
              'reading_progress_percent': 70,
              'is_completed': false,
            },
            'subjects_overview': [
              {
                'subject_id': 'sub-1',
                'subject_name': 'Kiswahili',
                'total_lessons': 5,
                'completed_lessons': 3,
                'average_quiz_score': 85,
                'status': 'excelling',
              },
            ],
          },
        ]);
        return;
      }
      if (path == '/rest/v1/rpc/get_learner_dashboard_data') {
        _writeJson(request, 200, {
          'learner_id': 'learner-1',
          'first_name': 'Baraka',
          'last_name': 'Parent',
          'full_name': 'Baraka Parent',
          'country_code': 'TZ',
          'status': 'active',
          'grade_name': 'Grade 1',
          'system_name': 'National',
          'curriculum_name': 'TIE',
          'school_name': 'Independent Learner',
          'summary': {
            'learner_id': 'learner-1',
            'total_lessons': 5,
            'completed_lessons': 3,
            'in_progress_lessons': 1,
            'average_quiz_score_percent': 85,
            'mastery_percent': 60,
            'has_active_subscription': true,
          },
          'resume_lesson': {
            'lesson_id': 'les-1',
            'lesson_title': 'Kusoma Herufi',
            'subject_name': 'Kiswahili',
            'reading_progress_percent': 70,
            'is_completed': false,
          },
          'streak_days': 4,
          'daily_target_lessons': 1,
          'today_completed_lessons': 1,
          'daily_target_minutes': 20,
          'academic_calendar': {
            'id': 'cal-1',
            'name': 'Mwaka wa Masomo 2026',
            'terms': [
              {
                'id': 't-1',
                'name': 'Term 1',
                'is_current': true,
              },
            ],
          },
        });
        return;
      }
      if (path == '/rest/v1/rpc/get_curriculum_explorer_tree') {
        _writeJson(request, 200, [
          {
            'subject_id': 'sub-1',
            'subject_name': 'Kiswahili',
            'subject_code': 'KIS',
            'description': 'Kiswahili language curriculum',
            'grade_id': 'grade-1',
            'display_order': 1,
            'topics': [
              {
                'topic_id': 'top-1',
                'title': 'Kusoma',
                'summary': 'Misingi ya kusoma',
                'display_order': 1,
                'lessons': [
                  {
                    'lesson_id': 'les-1',
                    'title': 'Kusoma Herufi',
                    'estimated_minutes': 15,
                    'is_free_preview': true,
                    'display_order': 1,
                  },
                ],
              },
            ],
          },
        ]);
        return;
      }
      _writeJson(request, 404, {'message': 'Not found'});
    });

    final client = await _signedInClient(server);
    final repo = LearningRepository(client);

    final parentOverview = await repo.getParentDashboardOverview();
    expect(parentOverview.length, 1);
    expect(parentOverview.first.fullName, 'Baraka Parent');
    expect(parentOverview.first.streakDays, 4);
    expect(parentOverview.first.subjectsOverview.first.status, 'excelling');
    expect(parentOverview.first.lastLessonAccessed?.lessonTitle, 'Kusoma Herufi');

    final learnerData = await repo.getLearnerDashboardData('learner-1');
    expect(learnerData.fullName, 'Baraka Parent');
    expect(learnerData.todayCompletedLessons, 1);
    expect(learnerData.activeTermName, 'Term 1');
    expect(learnerData.resumeLesson?.subjectName, 'Kiswahili');

    final explorerTree = await repo.getCurriculumExplorerTree(
      countryCode: 'TZ',
      educationSystemId: 'sys-1',
    );
    expect(explorerTree.length, 1);
    expect(explorerTree.first.subjectName, 'Kiswahili');
    expect(explorerTree.first.totalLessons, 1);
    expect(explorerTree.first.topics.first.lessons.first.title, 'Kusoma Herufi');

    await client.dispose();
    await server.close();
  });

  test('LearningRepository invokes Phase 2 interactive content and question bank RPCs correctly', () async {
    final server = await _FakeSupabaseServer.start((request, body) async {
      final path = request.uri.path;
      if (path == '/auth/v1/token') {
        _writeJson(request, 200, _sessionPayload());
        return;
      }
      if (path == '/rest/v1/rpc/get_lesson_interactive_content') {
        expect(body['p_lesson_id'], 'lesson-101');
        _writeJson(request, 200, {
          'id': 'lesson-101',
          'topic_id': 'topic-101',
          'title': 'Sauti za Irabu',
          'summary': 'Misingi ya irabu',
          'estimated_minutes': 12,
          'is_free_preview': true,
          'body_markdown': '# Irabu\n\na, e, i, o, u',
          'content_blocks': [
            {
              'type': 'markdown',
              'body': 'Katika lugha ya Kiswahili tuna irabu tano.',
            },
            {
              'type': 'callout',
              'style': 'tip',
              'title': 'Zingatio',
              'content': 'Kila neno lina irabu.',
            },
            {
              'type': 'definition',
              'term': 'Irabu',
              'pronunciation': '/i.ra.bu/',
              'definition': 'Sauti huru',
              'example': 'a, e, i, o, u',
            },
            {
              'type': 'example',
              'title': 'Mfano',
              'problem': 'Silabi',
              'steps': ['b + a = ba', 'k + i = ki'],
              'takeaway': 'Konsonanti na irabu huunda silabi',
            },
            {
              'type': 'checkpoint',
              'question': 'b + a inatoa nini?',
              'options': ['ba', 'bo'],
              'correct_index': 0,
              'explanation': 'b + a = ba',
            },
          ],
        });
        return;
      }
      if (path == '/rest/v1/rpc/get_topic_assessment_questions') {
        expect(body['p_topic_id'], 'topic-101');
        _writeJson(request, 200, [
          {
            'id': 'q-mc',
            'topic_id': 'topic-101',
            'lesson_id': 'lesson-101',
            'question_type': 'multiple_choice',
            'difficulty_level': 'easy',
            'question_text': 'Ipi ni irabu?',
            'options': ['a', 'b', 'c'],
            'cognitive_tier': 'knowledge',
            'display_order': 1,
          },
          {
            'id': 'q-tf',
            'topic_id': 'topic-101',
            'lesson_id': 'lesson-101',
            'question_type': 'true_false',
            'difficulty_level': 'easy',
            'question_text': 'Kiswahili kina irabu tano.',
            'options': ['Kweli', 'Si Kweli'],
            'cognitive_tier': 'knowledge',
            'display_order': 2,
          },
          {
            'id': 'q-fill',
            'topic_id': 'topic-101',
            'lesson_id': 'lesson-101',
            'question_type': 'fill_in_the_blank',
            'difficulty_level': 'medium',
            'question_text': 'b + a = ___',
            'options': null,
            'cognitive_tier': 'comprehension',
            'display_order': 3,
          },
          {
            'id': 'q-match',
            'topic_id': 'topic-101',
            'lesson_id': 'lesson-101',
            'question_type': 'matching',
            'difficulty_level': 'medium',
            'question_text': 'Oanisha:',
            'options': {
              'premises': [
                {'id': 'p1', 'text': 'm'},
              ],
              'responses': [
                {'id': 'r1', 'text': 'mama'},
              ],
            },
            'cognitive_tier': 'application',
            'display_order': 4,
          },
          {
            'id': 'q-short',
            'topic_id': 'topic-101',
            'lesson_id': 'lesson-101',
            'question_type': 'short_answer',
            'difficulty_level': 'easy',
            'question_text': 'Taja mzazi wa kike:',
            'options': null,
            'cognitive_tier': 'knowledge',
            'display_order': 5,
          },
        ]);
        return;
      }
      if (path == '/rest/v1/rpc/submit_assessment_attempt') {
        expect(body['p_learner_id'], 'learner-101');
        expect(body['p_topic_id'], 'topic-101');
        _writeJson(request, 200, {
          'score_percent': 100,
          'passed': true,
          'total_questions': 5,
          'correct_count': 5,
          'mastery_status': 'proficient',
          'results': [
            {
              'question_id': 'q-mc',
              'question_type': 'multiple_choice',
              'is_correct': true,
              'user_answer': 0,
              'correct_answer': 0,
              'explanation': 'a ni irabu.',
            },
          ],
        });
        return;
      }
      _writeJson(request, 404, {'message': 'Not found'});
    });

    final client = await _signedInClient(server);
    final repo = LearningRepository(client);

    final lesson = await repo.getLessonInteractiveContent('lesson-101');
    expect(lesson.title, 'Sauti za Irabu');
    expect(lesson.summary, 'Misingi ya irabu');
    expect(lesson.estimatedMinutes, 12);
    expect(lesson.contentBlocks.length, 5);
    expect(lesson.contentBlocks[1].type, 'callout');
    expect(lesson.contentBlocks[1].style, 'tip');
    expect(lesson.contentBlocks[2].term, 'Irabu');
    expect(lesson.contentBlocks[3].steps.length, 2);
    expect(lesson.contentBlocks[4].question, 'b + a inatoa nini?');

    final questions = await repo.getTopicAssessmentQuestions(topicId: 'topic-101');
    expect(questions.length, 5);
    expect(questions[0].questionType, 'multiple_choice');
    expect(questions[0].options?.length, 3);
    expect(questions[1].questionType, 'true_false');
    expect(questions[2].questionType, 'fill_in_the_blank');
    expect(questions[3].questionType, 'matching');
    expect(questions[3].matchingPremises.first.text, 'm');
    expect(questions[3].matchingResponses.first.text, 'mama');
    expect(questions[4].questionType, 'short_answer');

    final result = await repo.submitAssessmentAttempt(
      learnerId: 'learner-101',
      topicId: 'topic-101',
      answers: [
        {'question_id': 'q-mc', 'answer': 0},
      ],
    );
    expect(result.passed, isTrue);
    expect(result.scorePercent, 100);
    expect(result.masteryStatus, 'proficient');
    expect(result.results.first.isCorrect, isTrue);
    expect(result.results.first.explanation, 'a ni irabu.');

    await client.dispose();
    await server.close();
  });

  test('LearningRepository invokes recommendations and mastery report RPCs correctly', () async {
    final server = await _FakeSupabaseServer.start((request, body) async {
      final path = request.uri.path;
      if (path == '/auth/v1/token') {
        _writeJson(request, 200, _sessionPayload());
        return;
      }
      if (path == '/rest/v1/rpc/get_learner_recommendations') {
        expect(body['p_learner_id'], 'learner-201');
        _writeJson(request, 200, [
          {
            'id': 'rec-1',
            'subject_id': 'subj-1',
            'subject_name': 'Kiswahili',
            'topic_id': 'topic-1',
            'topic_title': 'Irabu na Silabi',
            'lesson_id': 'lesson-1',
            'lesson_title': 'Sauti za Irabu',
            'recommendation_type': 'remedial',
            'title': 'Zoezi la Uimarishaji: Irabu na Silabi',
            'reason': 'Kiwango cha usahihi kiko chini ya 60%.',
            'priority': 1,
            'created_at': '2026-11-13T00:00:00Z',
          },
        ]);
        return;
      }
      if (path == '/rest/v1/rpc/dismiss_learner_recommendation') {
        expect(body['p_learner_id'], 'learner-201');
        expect(body['p_recommendation_id'], 'rec-1');
        _writeJson(request, 200, true);
        return;
      }
      if (path == '/rest/v1/rpc/get_learner_mastery_report') {
        expect(body['p_learner_id'], 'learner-201');
        _writeJson(request, 200, {
          'learner_id': 'learner-201',
          'total_topics': 10,
          'mastered_topics': 6,
          'proficient_topics': 2,
          'in_progress_topics': 1,
          'not_started_topics': 1,
          'overall_accuracy_rate': 82.5,
          'streak_days': 5,
          'readiness_index': 77,
          'subjects_breakdown': [
            {
              'subject_id': 'subj-1',
              'subject_name': 'Kiswahili',
              'subject_code': 'KISW',
              'total_topics': 5,
              'mastered_topics': 4,
              'proficient_topics': 1,
              'in_progress_topics': 0,
              'not_started_topics': 0,
              'average_accuracy': 88.0,
              'mastery_percent': 80,
            },
          ],
        });
        return;
      }
      _writeJson(request, 404, {'message': 'Not found'});
    });

    final client = await _signedInClient(server);
    final repo = LearningRepository(client);

    final recs = await repo.getLearnerRecommendations('learner-201');
    expect(recs.length, 1);
    expect(recs.first.recommendationType, 'remedial');
    expect(recs.first.subjectName, 'Kiswahili');
    expect(recs.first.title, 'Zoezi la Uimarishaji: Irabu na Silabi');

    final dismissed = await repo.dismissLearnerRecommendation(
      learnerId: 'learner-201',
      recommendationId: 'rec-1',
    );
    expect(dismissed, isTrue);

    final report = await repo.getLearnerMasteryReport('learner-201');
    expect(report.totalTopics, 10);
    expect(report.masteredTopics, 6);
    expect(report.readinessIndex, 77);
    expect(report.streakDays, 5);
    expect(report.subjectsBreakdown.first.subjectName, 'Kiswahili');
    expect(report.subjectsBreakdown.first.masteryPercent, 80);

    await client.dispose();
    await server.close();
  });

  test('LearningRepository invokes Phase 2 revision and resource library RPCs correctly', () async {
    final server = await _FakeSupabaseServer.start((request, body) async {
      final path = request.uri.path;
      if (path == '/auth/v1/token') {
        _writeJson(request, 200, _sessionPayload());
        return;
      }
      if (path == '/rest/v1/rpc/get_learner_revision_overview') {
        expect(body['p_learner_id'], 'learner-301');
        _writeJson(request, 200, {
          'learner_id': 'learner-301',
          'curriculum_id': 'curr-1',
          'readiness_index': 70,
          'total_curriculum_topics': 12,
          'proficient_topics_count': 4,
          'mastered_topics_count': 3,
          'weak_topics': [
            {
              'topic_id': 'top-1',
              'topic_title': 'Irabu na Silabi',
              'subject_id': 'subj-1',
              'subject_name': 'Kiswahili',
              'accuracy_rate': 45.0,
              'quizzes_attempted': 2,
              'mastery_status': 'in_progress',
            },
          ],
          'flashcard_decks_count': 3,
          'learning_resources_count': 5,
        });
        return;
      }
      if (path == '/rest/v1/rpc/get_weak_topic_drill_questions') {
        expect(body['p_learner_id'], 'learner-301');
        _writeJson(request, 200, [
          {
            'id': 'q-drill-1',
            'topic_id': 'top-1',
            'lesson_id': 'les-1',
            'question_type': 'multiple_choice',
            'difficulty_level': 'easy',
            'question_text': 'Silabi inayotokana na B + A ni nini?',
            'options': ['BA', 'BE', 'BO'],
            'cognitive_tier': 'knowledge',
            'display_order': 1,
          },
        ]);
        return;
      }
      if (path == '/rest/v1/rpc/get_flashcard_decks') {
        _writeJson(request, 200, [
          {
            'id': 'deck-1',
            'country_code': 'TZ',
            'curriculum_id': 'curr-1',
            'subject_id': 'subj-1',
            'subject_name': 'Kiswahili',
            'title': 'Kadi za Silabi',
            'description': 'Mazoezi ya haraka ya silabi',
            'card_count': 4,
            'estimated_minutes': 5,
          },
        ]);
        return;
      }
      if (path == '/rest/v1/rpc/get_deck_flashcards') {
        expect(body['p_deck_id'], 'deck-1');
        _writeJson(request, 200, [
          {
            'id': 'card-1',
            'deck_id': 'deck-1',
            'front_prompt': 'Irabu 5 ni zipi?',
            'back_solution': 'A, E, I, O, U',
            'hint': 'Sauti za msingi',
            'explanation': 'Irabu zote tano za Kiswahili',
            'display_order': 1,
          },
        ]);
        return;
      }
      if (path == '/rest/v1/rpc/get_learning_resources') {
        expect(body['p_country_code'], 'TZ');
        expect(body['p_resource_type'], 'textbook');
        _writeJson(request, 200, [
          {
            'id': 'res-1',
            'country_code': 'TZ',
            'curriculum_id': 'curr-1',
            'subject_id': 'subj-1',
            'subject_name': 'Kiswahili',
            'title': 'Kitabu cha Kiswahili Darasa la 1',
            'description': 'Kitabu rasmi cha kiada TIE',
            'resource_type': 'textbook',
            'file_url': 'https://cdn.learntz.org/tz/std1_swahili.pdf',
            'file_format': 'pdf',
            'file_size_bytes': 15000000,
            'author_or_publisher': 'TIE',
            'is_official': true,
            'is_downloadable': true,
            'is_premium': false,
            'metadata': {},
          },
        ]);
        return;
      }
      _writeJson(request, 404, {'message': 'Not found'});
    });

    final client = await _signedInClient(server);
    final repo = LearningRepository(client);

    final overview = await repo.getLearnerRevisionOverview('learner-301');
    expect(overview.readinessIndex, 70);
    expect(overview.weakTopics.length, 1);
    expect(overview.weakTopics.first.topicTitle, 'Irabu na Silabi');
    expect(overview.flashcardDecksCount, 3);
    expect(overview.learningResourcesCount, 5);

    final drillQuestions = await repo.getWeakTopicDrillQuestions('learner-301');
    expect(drillQuestions.length, 1);
    expect(drillQuestions.first.questionText, contains('B + A'));

    final decks = await repo.getFlashcardDecks(learnerId: 'learner-301');
    expect(decks.length, 1);
    expect(decks.first.title, 'Kadi za Silabi');
    expect(decks.first.cardCount, 4);

    final cards = await repo.getDeckFlashcards('deck-1');
    expect(cards.length, 1);
    expect(cards.first.frontPrompt, contains('Irabu 5'));
    expect(cards.first.backSolution, 'A, E, I, O, U');

    final resources = await repo.getLearningResources(
      countryCode: 'TZ',
      resourceType: 'textbook',
    );
    expect(resources.length, 1);
    expect(resources.first.title, contains('Kitabu cha Kiswahili'));
    expect(resources.first.isOfficial, isTrue);

    await client.dispose();
    await server.close();
  });

  test('LearningRepository invokes Phase 2 offline sync and pack download RPCs correctly', () async {
    final server = await _FakeSupabaseServer.start((request, body) async {
      final path = request.uri.path;
      if (path == '/auth/v1/token') {
        _writeJson(request, 200, _sessionPayload());
        return;
      }
      if (path == '/rest/v1/rpc/sync_learner_offline_activity') {
        expect(body['p_learner_id'], 'learner-401');
        final events = body['p_events'] as List<dynamic>;
        expect(events.length, 1);
        expect(events.first['event_type'], 'reading_progress');
        _writeJson(request, 200, {
          'learner_id': 'learner-401',
          'events_received': 1,
          'events_processed': 1,
          'events_duplicate': 0,
          'synced_at': '2026-11-13T07:00:00Z',
        });
        return;
      }
      if (path == '/rest/v1/rpc/get_subject_offline_pack') {
        expect(body['p_learner_id'], 'learner-401');
        expect(body['p_subject_id'], 'subj-101');
        _writeJson(request, 200, {
          'subject_id': 'subj-101',
          'subject_name': 'Kiswahili',
          'subject_code': 'KISW',
          'country_code': 'TZ',
          'curriculum_id': 'curr-101',
          'description': 'Mtaala wa Msingi',
          'topics': [
            {
              'id': 'top-1',
              'title': 'Kusoma na Kuandika',
              'lessons': [],
              'questions': [],
            },
          ],
          'flashcard_decks': [],
          'packed_at': '2026-11-13T07:00:00Z',
        });
        return;
      }
      _writeJson(request, 404, {'message': 'Not found'});
    });

    final client = await _signedInClient(server);
    final repo = LearningRepository(client);

    final syncResult = await repo.syncOfflineActivity(
      learnerId: 'learner-401',
      events: [
        OfflineSyncEvent(
          clientEventId: 'evt-101',
          eventType: 'reading_progress',
          payload: {
            'lesson_id': 'les-1',
            'reading_progress_percent': 85,
          },
          clientRecordedAt: DateTime.utc(2026, 11, 13, 6, 30),
        ),
      ],
    );
    expect(syncResult.eventsReceived, 1);
    expect(syncResult.eventsProcessed, 1);
    expect(syncResult.eventsDuplicate, 0);

    final pack = await repo.getSubjectOfflinePack(
      learnerId: 'learner-401',
      subjectId: 'subj-101',
    );
    expect(pack.subjectName, 'Kiswahili');
    expect(pack.topics.length, 1);

    await client.dispose();
    await server.close();
  });
}
