class LearningProgress {
  const LearningProgress({
    required this.learnerId,
    required this.lessonId,
    required this.completionPercent,
    required this.lastBlockIndex,
    required this.updatedAt,
    this.completedAt,
  });

  final String learnerId;
  final String lessonId;
  final int completionPercent;
  final int lastBlockIndex;
  final DateTime updatedAt;
  final DateTime? completedAt;

  bool get isComplete => completionPercent >= 100;

  LearningProgress copyWith({
    int? completionPercent,
    int? lastBlockIndex,
    DateTime? completedAt,
  }) {
    return LearningProgress(
      learnerId: learnerId,
      lessonId: lessonId,
      completionPercent: completionPercent ?? this.completionPercent,
      lastBlockIndex: lastBlockIndex ?? this.lastBlockIndex,
      updatedAt: DateTime.now(),
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
