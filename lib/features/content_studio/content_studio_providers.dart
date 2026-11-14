import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'content_studio_models.dart';
import 'content_studio_repository.dart';

final contentStudioRepositoryProvider = Provider<ContentStudioRepository>((ref) {
  try {
    return ContentStudioRepository(Supabase.instance.client);
  } catch (_) {
    return ContentStudioRepository();
  }
});

class ContentStudioCountryFilterNotifier extends Notifier<String> {
  @override
  String build() => 'ALL';

  void setCountry(String country) => state = country;
}

final contentStudioCountryFilterProvider =
    NotifierProvider<ContentStudioCountryFilterNotifier, String>(
  ContentStudioCountryFilterNotifier.new,
);

class ContentStudioSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final contentStudioSearchQueryProvider =
    NotifierProvider<ContentStudioSearchQueryNotifier, String>(
  ContentStudioSearchQueryNotifier.new,
);

final contentStudioMetricsProvider =
    FutureProvider<ContentStudioMetrics>((ref) async {
  final repo = ref.watch(contentStudioRepositoryProvider);
  final country = ref.watch(contentStudioCountryFilterProvider);
  return repo.getContentStudioMetrics(countryCode: country);
});

final contentStudioCatalogProvider =
    FutureProvider<List<StudioSubjectItem>>((ref) async {
  final repo = ref.watch(contentStudioRepositoryProvider);
  final country = ref.watch(contentStudioCountryFilterProvider);
  final query = ref.watch(contentStudioSearchQueryProvider);
  return repo.getContentStudioCatalog(countryCode: country, search: query);
});

final contentMediaAssetsProvider =
    FutureProvider<List<MediaAssetItem>>((ref) async {
  final repo = ref.watch(contentStudioRepositoryProvider);
  final country = ref.watch(contentStudioCountryFilterProvider);
  return repo.listContentMediaAssets(countryCode: country);
});

@immutable
class FlatTopicOption {
  const FlatTopicOption({
    required this.topicId,
    required this.topicTitle,
    required this.subjectName,
    required this.countryCode,
  });

  final String topicId;
  final String topicTitle;
  final String subjectName;
  final String countryCode;

  String get label => '[$countryCode - $subjectName] $topicTitle';
}

final studioFlatTopicsProvider =
    FutureProvider<List<FlatTopicOption>>((ref) async {
  final catalog = await ref.watch(contentStudioCatalogProvider.future);
  final list = <FlatTopicOption>[];
  for (final subject in catalog) {
    for (final topic in subject.topics) {
      list.add(FlatTopicOption(
        topicId: topic.topicId,
        topicTitle: topic.topicTitle,
        subjectName: subject.subjectName,
        countryCode: subject.countryCode,
      ));
    }
  }
  return list;
});
