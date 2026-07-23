class ProjectModel {
  final String id;
  final String name;
  final String imagePath;
  final int nailCount;
  final String shape;
  final String density;

  // Classic mode: main path
  // RGB mode: Blue path (stored here for compatibility)
  final List<int> nailPath;
  final int currentStep;
  final DateTime createdAt;

  // ── RGB fields ──
  final bool isRGB;
  final List<int> redPath;
  final List<int> greenPath;
  final int currentPhase; // 0=Blue, 1=Red, 2=Green

  ProjectModel({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.nailCount,
    required this.shape,
    required this.density,
    required this.nailPath,
    required this.currentStep,
    required this.createdAt,
    this.isRGB = false,
    this.redPath = const [],
    this.greenPath = const [],
    this.currentPhase = 0,
  });

  // ── Save to map ──
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'nailCount': nailCount,
      'shape': shape,
      'density': density,
      'nailPath': nailPath.join(','),
      'currentStep': currentStep,
      'createdAt': createdAt.millisecondsSinceEpoch,
      // RGB fields
      'isRGB': isRGB,
      'redPath': redPath.join(','),
      'greenPath': greenPath.join(','),
      'currentPhase': currentPhase,
    };
  }

  // ── Load from map ──
  factory ProjectModel.fromMap(
      Map<dynamic, dynamic> map) {
    return ProjectModel(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Untitled',
      imagePath: map['imagePath'] ?? '',
      nailCount: map['nailCount'] ?? 200,
      shape: map['shape'] ?? 'Circle',
      density: map['density'] ?? 'Medium',
      nailPath: _parsePath(
          map['nailPath']?.toString() ?? ''),
      currentStep: map['currentStep'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['createdAt'] ?? 0),
      isRGB: map['isRGB'] ?? false,
      redPath: _parsePath(
          map['redPath']?.toString() ?? ''),
      greenPath: _parsePath(
          map['greenPath']?.toString() ?? ''),
      currentPhase: map['currentPhase'] ?? 0,
    );
  }

  static List<int> _parsePath(String raw) {
    if (raw.isEmpty) return [];
    try {
      return raw
          .split(',')
          .map((e) => int.tryParse(e.trim()) ?? 0)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Copy with updated values ──
  ProjectModel copyWith({
    int? currentStep,
    String? name,
    int? currentPhase,
  }) {
    return ProjectModel(
      id: id,
      name: name ?? this.name,
      imagePath: imagePath,
      nailCount: nailCount,
      shape: shape,
      density: density,
      nailPath: nailPath,
      currentStep: currentStep ?? this.currentStep,
      createdAt: createdAt,
      isRGB: isRGB,
      redPath: redPath,
      greenPath: greenPath,
      currentPhase: currentPhase ?? this.currentPhase,
    );
  }

  // ── Progress calculation ──
  double get progress {
    if (isRGB) {
      final total = nailPath.length +
          redPath.length +
          greenPath.length;
      if (total == 0) return 0;
      int done = 0;
      if (currentPhase > 0) done += nailPath.length;
      if (currentPhase > 1) done += redPath.length;
      done += currentStep;
      return (done / total).clamp(0.0, 1.0);
    }
    if (nailPath.isEmpty || nailPath.length <= 1) {
      return 0.0;
    }
    return (currentStep / (nailPath.length - 1))
        .clamp(0.0, 1.0);
  }

  // ── Is finished ──
  bool get isCompleted {
    if (isRGB) {
      return currentPhase >= 2 &&
          currentStep >= greenPath.length - 2 &&
          greenPath.isNotEmpty;
    }
    return currentStep >= nailPath.length - 2 &&
        nailPath.isNotEmpty;
  }
}