import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/project_model.dart';

class ProjectService extends ChangeNotifier {
  static const String _boxName = 'threadcraft_db';
  static const String _projectsKey = 'saved_projects';

  List<ProjectModel> _projects = [];

  List<ProjectModel> get projects => _projects;
  int get totalProjects => _projects.length;

  ProjectService() {
    _loadProjects();
  }

  // ── LOAD all projects from storage ──
  void _loadProjects() {
    try {
      final box = Hive.box(_boxName);
      final raw = box.get(_projectsKey);

      if (raw == null) {
        _projects = [];
        return;
      }

      final list = raw as List;
      _projects = list
          .map((item) => ProjectModel.fromMap(
          item as Map<dynamic, dynamic>))
          .toList();

      // Sort by newest first
      _projects.sort(
              (a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _projects = [];
    }
    notifyListeners();
  }

  // ── SAVE a new project ──
  Future<void> saveProject(ProjectModel project) async {
    try {
      // Remove old version if exists
      _projects.removeWhere((p) => p.id == project.id);

      // Add new version at front
      _projects.insert(0, project);

      await _persist();
      notifyListeners();
    } catch (e) {
      debugPrint('Save error: $e');
    }
  }

  // ── UPDATE progress of existing project ──
  Future<void> updateProgress(
      String projectId, int currentStep) async {
    final index =
    _projects.indexWhere((p) => p.id == projectId);
    if (index == -1) return;

    _projects[index] =
        _projects[index].copyWith(currentStep: currentStep);

    await _persist();
    notifyListeners();
  }
  // ── Update RGB progress (phase + step) ──
  Future<void> updateRGBProgress(
      String projectId, int phase, int step) async {
    final index =
    _projects.indexWhere((p) => p.id == projectId);
    if (index == -1) return;

    _projects[index] = _projects[index].copyWith(
      currentStep: step,
      currentPhase: phase,
    );

    await _persist();
    notifyListeners();
  }

  // ── DELETE a project ──
  Future<void> deleteProject(String projectId) async {
    _projects.removeWhere((p) => p.id == projectId);
    await _persist();
    notifyListeners();
  }

  // ── RENAME a project ──
  Future<void> renameProject(
      String projectId, String newName) async {
    final index =
    _projects.indexWhere((p) => p.id == projectId);
    if (index == -1) return;

    _projects[index] =
        _projects[index].copyWith(name: newName);

    await _persist();
    notifyListeners();
  }

  // ── Write to Hive ──
  Future<void> _persist() async {
    final box = Hive.box(_boxName);
    await box.put(
      _projectsKey,
      _projects.map((p) => p.toMap()).toList(),
    );
  }

  // ── Clear all projects ──
  Future<void> clearAll() async {
    _projects = [];
    final box = Hive.box(_boxName);
    await box.delete(_projectsKey);
    notifyListeners();
  }
}