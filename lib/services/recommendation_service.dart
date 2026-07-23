class ThreadSize {
  final String label;
  final String mm;
  final String desc;
  final int maxLines;
  final int recommendedNails;

  const ThreadSize({
    required this.label,
    required this.mm,
    required this.desc,
    required this.maxLines,
    required this.recommendedNails,
  });
}

class BoardSize {
  final String label;
  final int cm;
  final int minNails;
  final int maxNails;
  final String nailSpacing;

  const BoardSize({
    required this.label,
    required this.cm,
    required this.minNails,
    required this.maxNails,
    required this.nailSpacing,
  });
}

class RecommendedSetup {
  final int nailCount;
  final String density;
  final ThreadSize threadSize;
  final BoardSize boardSize;
  final int estimatedLines;
  final String reason;

  const RecommendedSetup({
    required this.nailCount,
    required this.density,
    required this.threadSize,
    required this.boardSize,
    required this.estimatedLines,
    required this.reason,
  });
}

class RecommendationService {
  // ── 4 Thread Sizes ──
  static const List<ThreadSize> threadSizes = [
    ThreadSize(
      label: 'Hair Thin',
      mm: '0.11 mm',
      desc: 'Ultra detail, delicate',
      maxLines: 3000,
      recommendedNails: 350,
    ),
    ThreadSize(
      label: 'Medium Thin',
      mm: '0.16 mm',
      desc: 'High detail, popular',
      maxLines: 2000,
      recommendedNails: 250,
    ),
    ThreadSize(
      label: 'Normal',
      mm: '0.19 mm',
      desc: 'Balanced, beginner friendly',
      maxLines: 1500,
      recommendedNails: 200,
    ),
    ThreadSize(
      label: 'Thick',
      mm: '0.25 mm',
      desc: 'Bold look, faster',
      maxLines: 800,
      recommendedNails: 150,
    ),
  ];

  // ── Board Sizes ──
  static const List<BoardSize> boardSizes = [
    BoardSize(
      label: 'Small',
      cm: 30,
      minNails: 80,
      maxNails: 150,
      nailSpacing: '6 mm',
    ),
    BoardSize(
      label: 'Medium',
      cm: 50,
      minNails: 150,
      maxNails: 200,
      nailSpacing: '8 mm',
    ),
    BoardSize(
      label: 'Large',
      cm: 75,
      minNails: 200,
      maxNails: 300,
      nailSpacing: '10 mm',
    ),
    BoardSize(
      label: 'XL',
      cm: 100,
      minNails: 280,
      maxNails: 360,
      nailSpacing: '11 mm',
    ),
    BoardSize(
      label: 'XXL',
      cm: 120,
      minNails: 350,
      maxNails: 400,
      nailSpacing: '12 mm',
    ),
  ];

  // ── Smart Recommendation based on preset ──
  static RecommendedSetup getRecommendation(
      String preset) {
    switch (preset) {
      case 'Beginner':
        return const RecommendedSetup(
          nailCount: 100,
          density: 'Low',
          threadSize: ThreadSize(
            label: 'Thick',
            mm: '0.25 mm',
            desc: 'Bold look, faster',
            maxLines: 800,
            recommendedNails: 150,
          ),
          boardSize: BoardSize(
            label: 'Small',
            cm: 30,
            minNails: 80,
            maxNails: 150,
            nailSpacing: '6 mm',
          ),
          estimatedLines: 500,
          reason: 'Perfect for first-timers. '
              'Easy to follow, quick to complete.',
        );

      case 'Balanced':
        return const RecommendedSetup(
          nailCount: 200,
          density: 'Medium',
          threadSize: ThreadSize(
            label: 'Normal',
            mm: '0.19 mm',
            desc: 'Balanced, beginner friendly',
            maxLines: 1500,
            recommendedNails: 200,
          ),
          boardSize: BoardSize(
            label: 'Medium',
            cm: 50,
            minNails: 150,
            maxNails: 200,
            nailSpacing: '8 mm',
          ),
          estimatedLines: 1200,
          reason: 'Great balance of detail and '
              'effort. Most popular choice.',
        );

      case 'Detailed':
        return const RecommendedSetup(
          nailCount: 300,
          density: 'High',
          threadSize: ThreadSize(
            label: 'Medium Thin',
            mm: '0.16 mm',
            desc: 'High detail, popular',
            maxLines: 2000,
            recommendedNails: 250,
          ),
          boardSize: BoardSize(
            label: 'Large',
            cm: 75,
            minNails: 200,
            maxNails: 300,
            nailSpacing: '10 mm',
          ),
          estimatedLines: 2000,
          reason: 'Sharp portrait detail. '
              'Great for faces and hair.',
        );

      case 'Ultra':
      default:
        return const RecommendedSetup(
          nailCount: 400,
          density: 'High',
          threadSize: ThreadSize(
            label: 'Hair Thin',
            mm: '0.11 mm',
            desc: 'Ultra detail, delicate',
            maxLines: 3000,
            recommendedNails: 350,
          ),
          boardSize: BoardSize(
            label: 'XL',
            cm: 100,
            minNails: 280,
            maxNails: 360,
            nailSpacing: '11 mm',
          ),
          estimatedLines: 3000,
          reason: 'Maximum realism. '
              'For experienced artists.',
        );
    }
  }

  // ── Get thread count for algorithm ──
  // Thread size affects how many lines are drawn
  static int getThreadCount(
      ThreadSize size, String density) {
    final base = size.maxLines;
    switch (density) {
      case 'Low':
        return (base * 0.4).round();
      case 'High':
        return base;
      default:
        return (base * 0.65).round();
    }
  }
}