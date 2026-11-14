import 'package:flutter_test/flutter_test.dart';
import 'package:learntz/features/exams/exam_models.dart';

void main() {
  group('Exam Models Tests', () {
    test('ExaminationAuthority serializes and deserializes correctly', () {
      final json = {
        'id': 'NECTA',
        'country_code': 'TZ',
        'name': 'National Examinations Council of Tanzania',
        'description': 'Mainland national examinations body',
        'website_url': 'https://www.necta.go.tz',
        'logo_url': null,
        'is_accredited': true,
      };

      final authority = ExaminationAuthority.fromJson(json);
      expect(authority.id, 'NECTA');
      expect(authority.countryCode, 'TZ');
      expect(authority.isAcccredited, isTrue);

      final output = authority.toJson();
      expect(output['id'], 'NECTA');
      expect(output['website_url'], 'https://www.necta.go.tz');
    });

    test('NationalExamination serializes and deserializes correctly', () {
      final json = {
        'id': 'TZ-CSEE',
        'authority_id': 'NECTA',
        'country_code': 'TZ',
        'code': 'CSEE',
        'title': 'Certificate of Secondary Education Examination',
        'education_level': 'O-Level',
        'grading_system': 'division',
        'is_active': true,
      };

      final exam = NationalExamination.fromJson(json);
      expect(exam.id, 'TZ-CSEE');
      expect(exam.code, 'CSEE');
      expect(exam.gradingSystem, 'division');

      final output = exam.toJson();
      expect(output['code'], 'CSEE');
      expect(output['authority_id'], 'NECTA');
    });

    test('ExaminationPaper parses sections and tiers correctly', () {
      final json = {
        'id': '40000000-0000-0000-0000-000000000001',
        'country_code': 'TZ',
        'national_examination_id': 'TZ-CSEE',
        'authority_id': 'NECTA',
        'subject_id': '30000000-0000-0000-0000-000000000102',
        'subject_name': 'Basic Mathematics',
        'paper_number': 1,
        'paper_title': 'NECTA CSEE 2024 Basic Mathematics Paper 1',
        'year': 2024,
        'paper_type': 'official_national',
        'tier': 'national',
        'region': null,
        'district': null,
        'school_name': null,
        'term': null,
        'duration_minutes': 180,
        'total_marks': 100.0,
        'instructions': 'Answer all questions in Section A',
        'sections_config': [
          {
            'code': 'A',
            'name': 'Section A',
            'total_questions': 10,
            'required_questions': 10,
            'marks_per_question': 6,
            'total_marks': 60,
          },
          {
            'code': 'B',
            'name': 'Section B',
            'total_questions': 4,
            'required_questions': 4,
            'marks_per_question': 10,
            'total_marks': 40,
          }
        ],
        'pdf_storage_path': null,
        'marking_scheme_storage_path': null,
        'created_at': '2026-11-13T10:00:00Z',
      };

      final paper = ExaminationPaper.fromJson(json);
      expect(paper.id, '40000000-0000-0000-0000-000000000001');
      expect(paper.subjectName, 'Basic Mathematics');
      expect(paper.tier, 'national');
      expect(paper.sectionsConfig.length, 2);
      expect(paper.sectionsConfig.first.code, 'A');
      expect(paper.sectionsConfig.first.totalMarks, 60);

      final output = paper.toJson();
      expect(output['subject_name'], 'Basic Mathematics');
      expect((output['sections_config'] as List).length, 2);
    });

    test('ExaminationCentreCatalog parses nested authorities and papers', () {
      final json = {
        'authorities': [
          {
            'id': 'NECTA',
            'country_code': 'TZ',
            'name': 'National Examinations Council of Tanzania',
            'description': '',
            'is_accredited': true,
          }
        ],
        'examinations': [
          {
            'id': 'TZ-CSEE',
            'authority_id': 'NECTA',
            'country_code': 'TZ',
            'code': 'CSEE',
            'title': 'CSEE',
            'education_level': 'O-Level',
          }
        ],
        'recent_papers': [
          {
            'id': '40000000-0000-0000-0000-000000000001',
            'country_code': 'TZ',
            'authority_id': 'NECTA',
            'subject_name': 'Basic Mathematics',
            'paper_title': 'NECTA CSEE 2024 Math',
            'year': 2024,
            'paper_type': 'official_national',
            'tier': 'national',
            'duration_minutes': 180,
            'total_marks': 100,
            'created_at': '2026-11-13T10:00:00Z',
          }
        ],
        'tier_counts': {
          'national': 4,
          'regional': 3,
          'district': 1,
          'school': 0,
        },
      };

      final catalog = ExaminationCentreCatalog.fromJson(json);
      expect(catalog.authorities.length, 1);
      expect(catalog.authorities.first.id, 'NECTA');
      expect(catalog.examinations.length, 1);
      expect(catalog.recentPapers.length, 1);
      expect(catalog.tierCounts['national'], 4);
      expect(catalog.tierCounts['regional'], 3);
    });

    test('PaperUploadRequest converts to RPC parameters map', () {
      const request = PaperUploadRequest(
        countryCode: 'TZ',
        authorityId: 'NECTA',
        title: 'Mwanza Regional Mock 2024 Chemistry',
        year: 2024,
        tier: 'regional',
        region: 'Mwanza',
        district: 'Nyamagana',
        schoolName: 'Mwanza High',
        fileUrl: 'https://storage.test/paper.pdf',
        fileSizeBytes: 1048576,
        notes: 'Regional joint mock',
      );

      final rpcParams = request.toRpcParams();
      expect(rpcParams['p_country_code'], 'TZ');
      expect(rpcParams['p_authority_id'], 'NECTA');
      expect(rpcParams['p_title'], 'Mwanza Regional Mock 2024 Chemistry');
      expect(rpcParams['p_tier'], 'regional');
      expect(rpcParams['p_region'], 'Mwanza');
      expect(rpcParams['p_file_size_bytes'], 1048576);
    });
  });
}
