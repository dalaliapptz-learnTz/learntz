class CountryConfiguration {
  const CountryConfiguration({
    required this.code,
    required this.productName,
    required this.defaultLanguageCode,
    required this.currencyCode,
    required this.timezone,
    required this.curricula,
  });

  final String code;
  final String productName;
  final String defaultLanguageCode;
  final String currencyCode;
  final String timezone;
  final List<CurriculumConfiguration> curricula;
}

class CurriculumConfiguration {
  const CurriculumConfiguration({
    required this.code,
    required this.name,
    required this.educationSystems,
  });

  final String code;
  final String name;
  final List<EducationSystemConfiguration> educationSystems;
}

class EducationSystemConfiguration {
  const EducationSystemConfiguration({
    required this.code,
    required this.name,
    required this.levels,
  });

  final String code;
  final String name;
  final List<EducationLevelConfiguration> levels;
}

class EducationLevelConfiguration {
  const EducationLevelConfiguration({
    required this.code,
    required this.name,
    required this.grades,
  });

  final String code;
  final String name;
  final List<GradeConfiguration> grades;
}

class GradeConfiguration {
  const GradeConfiguration({required this.code, required this.name});

  final String code;
  final String name;
}

class SubjectConfiguration {
  const SubjectConfiguration({required this.code, required this.name});

  final String code;
  final String name;
}

class PlatformCatalog {
  const PlatformCatalog._();

  static const countries = <CountryConfiguration>[
    CountryConfiguration(
      code: 'TZ',
      productName: 'LearnTZ',
      defaultLanguageCode: 'sw',
      currencyCode: 'TZS',
      timezone: 'Africa/Dar_es_Salaam',
      curricula: [
        CurriculumConfiguration(
          code: 'TIE',
          name: 'Tanzania Institute of Education',
          educationSystems: [
            EducationSystemConfiguration(
              code: 'PRIMARY',
              name: 'Primary',
              levels: [
                EducationLevelConfiguration(
                  code: 'PRIMARY',
                  name: 'Primary school',
                  grades: [
                    GradeConfiguration(code: 'STD_1', name: 'Standard 1'),
                    GradeConfiguration(code: 'STD_2', name: 'Standard 2'),
                    GradeConfiguration(code: 'STD_3', name: 'Standard 3'),
                    GradeConfiguration(code: 'STD_4', name: 'Standard 4'),
                    GradeConfiguration(code: 'STD_5', name: 'Standard 5'),
                    GradeConfiguration(code: 'STD_6', name: 'Standard 6'),
                    GradeConfiguration(code: 'STD_7', name: 'Standard 7'),
                  ],
                ),
              ],
            ),
            EducationSystemConfiguration(
              code: 'SECONDARY',
              name: 'Secondary',
              levels: [
                EducationLevelConfiguration(
                  code: 'ORDINARY_SECONDARY',
                  name: 'Ordinary secondary',
                  grades: [
                    GradeConfiguration(code: 'FORM_1', name: 'Form 1'),
                    GradeConfiguration(code: 'FORM_2', name: 'Form 2'),
                    GradeConfiguration(code: 'FORM_3', name: 'Form 3'),
                    GradeConfiguration(code: 'FORM_4', name: 'Form 4'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CountryConfiguration(
      code: 'KE',
      productName: 'LearnKE',
      defaultLanguageCode: 'en',
      currencyCode: 'KES',
      timezone: 'Africa/Nairobi',
      curricula: [
        CurriculumConfiguration(
          code: 'CBC',
          name: 'Competency Based Curriculum',
          educationSystems: [
            EducationSystemConfiguration(
              code: 'PRIMARY',
              name: 'Primary',
              levels: [
                EducationLevelConfiguration(
                  code: 'PRIMARY',
                  name: 'Primary school',
                  grades: [
                    GradeConfiguration(code: 'GRADE_1', name: 'Grade 1'),
                    GradeConfiguration(code: 'GRADE_5', name: 'Grade 5'),
                    GradeConfiguration(code: 'GRADE_6', name: 'Grade 6'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CountryConfiguration(
      code: 'UG',
      productName: 'LearnUG',
      defaultLanguageCode: 'en',
      currencyCode: 'UGX',
      timezone: 'Africa/Kampala',
      curricula: [
        CurriculumConfiguration(
          code: 'UNEB',
          name: 'Uganda national curriculum',
          educationSystems: [
            EducationSystemConfiguration(
              code: 'PRIMARY',
              name: 'Primary',
              levels: [
                EducationLevelConfiguration(
                  code: 'PRIMARY',
                  name: 'Primary school',
                  grades: [GradeConfiguration(code: 'P5', name: 'Primary 5')],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CountryConfiguration(
      code: 'RW',
      productName: 'LearnRW',
      defaultLanguageCode: 'en',
      currencyCode: 'RWF',
      timezone: 'Africa/Kigali',
      curricula: [
        CurriculumConfiguration(
          code: 'NATIONAL',
          name: 'Rwanda national curriculum',
          educationSystems: [
            EducationSystemConfiguration(
              code: 'PRIMARY',
              name: 'Primary',
              levels: [
                EducationLevelConfiguration(
                  code: 'PRIMARY',
                  name: 'Primary school',
                  grades: [GradeConfiguration(code: 'P5', name: 'Primary 5')],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CountryConfiguration(
      code: 'BI',
      productName: 'LearnBI',
      defaultLanguageCode: 'fr',
      currencyCode: 'BIF',
      timezone: 'Africa/Bujumbura',
      curricula: [
        CurriculumConfiguration(
          code: 'NATIONAL',
          name: 'Burundi national curriculum',
          educationSystems: [
            EducationSystemConfiguration(
              code: 'PRIMARY',
              name: 'Primary',
              levels: [
                EducationLevelConfiguration(
                  code: 'PRIMARY',
                  name: 'Primary school',
                  grades: [GradeConfiguration(code: 'YEAR_5', name: 'Year 5')],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CountryConfiguration(
      code: 'SS',
      productName: 'LearnSS',
      defaultLanguageCode: 'en',
      currencyCode: 'SSP',
      timezone: 'Africa/Juba',
      curricula: [
        CurriculumConfiguration(
          code: 'NATIONAL',
          name: 'South Sudan national curriculum',
          educationSystems: [
            EducationSystemConfiguration(
              code: 'PRIMARY',
              name: 'Primary',
              levels: [
                EducationLevelConfiguration(
                  code: 'PRIMARY',
                  name: 'Primary school',
                  grades: [GradeConfiguration(code: 'P5', name: 'Primary 5')],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ];

  static CountryConfiguration country(String code) => countries.firstWhere(
        (country) => country.code == code,
        orElse: () => countries.first,
      );
}
