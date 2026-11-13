import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import 'learning_models.dart';
import 'learning_providers.dart';

class FlashcardStudyScreen extends ConsumerStatefulWidget {
  const FlashcardStudyScreen({
    super.key,
    required this.deckId,
  });

  final String deckId;

  @override
  ConsumerState<FlashcardStudyScreen> createState() =>
      _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends ConsumerState<FlashcardStudyScreen> {
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _showHint = false;
  bool _isCompleted = false;
  List<FlashcardItem> _cards = [];
  bool _isInitialized = false;

  void _nextCard() {
    if (_currentIndex < _cards.length - 1) {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
        _showHint = false;
      });
    } else {
      setState(() {
        _isCompleted = true;
      });
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isFlipped = false;
        _showHint = false;
      });
    }
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _isFlipped = false;
      _showHint = false;
      _isCompleted = false;
    });
  }

  void _shuffle() {
    setState(() {
      _cards.shuffle();
      _currentIndex = 0;
      _isFlipped = false;
      _showHint = false;
      _isCompleted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cardsAsync = ref.watch(deckFlashcardsProvider(widget.deckId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.flashcardsStudyTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go(AppRoutes.revisionCentre),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: l10n.shuffleCardsTooltip,
            onPressed: _cards.length > 1 ? _shuffle : null,
          ),
        ],
      ),
      body: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.requestFailed}: $e')),
        data: (loadedCards) {
          if (!_isInitialized) {
            _cards = List.from(loadedCards);
            _isInitialized = true;
          }

          if (_cards.isEmpty) {
            return Center(
              child: AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.noFlashcardsInDeck),
                ),
              ),
            );
          }

          if (_isCompleted) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.celebration_outlined,
                          size: 64,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.flashcardDeckCompletedTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.flashcardDeckCompletedSubtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _restart,
                              icon: const Icon(Icons.replay),
                              label: Text(l10n.restartDeckAction),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: () => context.go(AppRoutes.revisionCentre),
                              icon: const Icon(Icons.check),
                              label: Text(l10n.finishAction),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          final currentCard = _cards[_currentIndex];

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Progress bar & Card count
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (_currentIndex + 1) / _cards.length,
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_currentIndex + 1} / ${_cards.length}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Flip card container
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isFlipped = !_isFlipped;
                          });
                        },
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          child: AppCard(
                            key: ValueKey('${currentCard.id}_$_isFlipped'),
                            child: Container(
                              width: double.infinity,
                              height: double.infinity,
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Chip(
                                        label: Text(
                                          _isFlipped
                                              ? l10n.solutionBadge
                                              : l10n.promptBadge,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      Text(
                                        l10n.tapToFlipHint,
                                        style: Theme.of(context).textTheme.labelSmall,
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  if (!_isFlipped) ...[
                                    Text(
                                      currentCard.frontPrompt,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(fontWeight: FontWeight.w600),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (currentCard.hint != null &&
                                        currentCard.hint!.isNotEmpty) ...[
                                      const SizedBox(height: 20),
                                      if (_showHint)
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.amber.withValues(alpha: 0.4),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.lightbulb_outline,
                                                color: Colors.amber,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  currentCard.hint!,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        TextButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _showHint = true;
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.lightbulb_outline,
                                            size: 16,
                                          ),
                                          label: Text(l10n.showHintAction),
                                        ),
                                    ],
                                  ] else ...[
                                    Text(
                                      currentCard.backSolution,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (currentCard.explanation != null &&
                                        currentCard.explanation!.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      Text(
                                        currentCard.explanation!,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ],
                                  const Spacer(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Navigation controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _currentIndex > 0 ? _previousCard : null,
                          icon: const Icon(Icons.arrow_back),
                          label: Text(l10n.previousAction),
                        ),
                        FilledButton.tonal(
                          onPressed: () {
                            setState(() {
                              _isFlipped = !_isFlipped;
                            });
                          },
                          child: Text(l10n.flipCardAction),
                        ),
                        FilledButton.icon(
                          onPressed: _nextCard,
                          icon: Icon(
                            _currentIndex < _cards.length - 1
                                ? Icons.arrow_forward
                                : Icons.check,
                          ),
                          label: Text(
                            _currentIndex < _cards.length - 1
                                ? l10n.nextAction
                                : l10n.finishAction,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
