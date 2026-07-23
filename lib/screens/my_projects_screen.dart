import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';
import '../widgets/gradient_button.dart';
import 'preview_screen.dart';
import 'new_project_screen.dart';
import 'rgb_preview_screen.dart';
class MyProjectsScreen extends StatelessWidget {
  const MyProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projectService = context.watch<ProjectService>();
    final projects = projectService.projects;

    return Scaffold(
      backgroundColor: AppColors.background,

      // ── TOP BAR ──
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 16),
          ),
        ),
        title: Text(
          'My Projects',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Project count badge
          if (projects.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${projects.length}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),

      body: projects.isEmpty
          ? _buildEmptyState(context)
          : _buildProjectList(context, projects, projectService),

      // ── FLOATING NEW PROJECT BUTTON ──
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const NewProjectScreen()),
        ),
        backgroundColor: AppColors.purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'New Project',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ── EMPTY STATE ──
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.card,
              border: Border.all(
                  color: Colors.white.withOpacity(0.08)),
            ),
            child: Icon(
              Icons.folder_open_rounded,
              color: AppColors.purple.withOpacity(0.6),
              size: 46,
            ),
          )
              .animate()
              .scale(
            begin: const Offset(0.5, 0.5),
            duration: 600.ms,
            curve: Curves.elasticOut,
          ),

          const SizedBox(height: 24),

          Text(
            'No Projects Yet',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 8),

          Text(
            'Create your first thread art project\nand it will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.6,
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: GradientButton(
              text: '+ Create First Project',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NewProjectScreen()),
              ),
            ).animate().fadeIn(delay: 400.ms),
          ),
        ],
      ),
    );
  }

  // ── PROJECT LIST ──
  Widget _buildProjectList(
      BuildContext context,
      List<ProjectModel> projects,
      ProjectService service,
      ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        return _ProjectCard(
          project: projects[index],
          service: service,
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: index * 80))
            .slideY(begin: 0.2);
      },
    );
  }
}

// ── PROJECT CARD WIDGET ──
class _ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final ProjectService service;

  const _ProjectCard({
    required this.project,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final imageExists = File(project.imagePath).existsSync();

    return GestureDetector(
      onTap: () => _openProject(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: project.isCompleted
                ? AppColors.purple.withOpacity(0.3)
                : Colors.white.withOpacity(0.06),
          ),
          boxShadow: project.isCompleted
              ? [
            BoxShadow(
              color: AppColors.purpleGlow,
              blurRadius: 15,
            )
          ]
              : [],
        ),
        child: Column(
          children: [
            // ── IMAGE + OVERLAY ──
            _buildImageSection(imageExists),

            // ── INFO SECTION ──
            _buildInfoSection(context),
          ],
        ),
      ),
    );
  }

  // ── IMAGE SECTION ──
  Widget _buildImageSection(bool imageExists) {
    return ClipRRect(
      borderRadius:
      const BorderRadius.vertical(top: Radius.circular(20)),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image or placeholder
            imageExists
                ? Image.file(
              File(project.imagePath),
              fit: BoxFit.cover,
            )
                : Container(
              color: AppColors.surface,
              child: const Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.textMuted,
                size: 40,
              ),
            ),

            // Dark gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
// RGB badge
            if (project.isRGB)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.red, Colors.blue,
                        Colors.green],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('🌈 RGB',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            // Completed badge
            if (project.isCompleted)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Complete',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Shape + nail count badge
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  '${project.shape} · ${project.nailCount} nails',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),

            // Progress bar at bottom of image
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: project.progress,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(
                  project.isCompleted
                      ? AppColors.purple
                      : AppColors.pink,
                ),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── INFO SECTION ──
  Widget _buildInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome,
                color: Colors.white, size: 20),
          ),

          const SizedBox(width: 12),

          // Name + stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${project.currentStep} / ${project.nailPath.length} steps  ·  '
                      '${(project.progress * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Three dot menu
          GestureDetector(
            onTap: () => _showOptionsMenu(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.more_vert,
                  color: AppColors.textSecondary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── OPEN PROJECT ──
  void _openProject(BuildContext context) {
    if (!File(project.imagePath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.card,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          content: Text(
            'Image file not found. Please create a new project.',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ),
      );
      return;
    }

    if (project.isRGB) {
      // Open RGB Preview Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RGBPreviewScreen(
            imageFile: File(project.imagePath),
            bluePath: project.nailPath,
            redPath: project.redPath,
            greenPath: project.greenPath,
            nailCount: project.nailCount,
            shape: project.shape,
            density: project.density,
            projectId: project.id,
            startPhase: project.currentPhase,
            startStep: project.currentStep,
          ),
        ),
      );
    } else {
      // Open classic Preview Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewScreen(
            imageFile: File(project.imagePath),
            nailPath: project.nailPath,
            nailCount: project.nailCount,
            shape: project.shape,
            density: project.density,
            projectId: project.id,
            startStep: project.currentStep,
          ),
        ),
      );
    }
  }

  // ── THREE DOT OPTIONS MENU ──
  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              project.name,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            // Resume
            _menuOption(
              context,
              icon: Icons.play_arrow_rounded,
              iconColor: AppColors.purple,
              label: 'Resume Project',
              onTap: () {
                Navigator.pop(context);
                _openProject(context);
              },
            ),

            // Rename
            _menuOption(
              context,
              icon: Icons.edit_outlined,
              iconColor: AppColors.cyan,
              label: 'Rename',
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context);
              },
            ),

            // Delete
            _menuOption(
              context,
              icon: Icons.delete_outline_rounded,
              iconColor: Colors.red.shade400,
              label: 'Delete Project',
              labelColor: Colors.red.shade400,
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuOption(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required String label,
        required VoidCallback onTap,
        Color? labelColor,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
              Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: labelColor ?? Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── RENAME DIALOG ──
  void _showRenameDialog(BuildContext context) {
    final controller =
    TextEditingController(text: project.name);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Rename Project',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.poppins(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter project name',
            hintStyle: GoogleFonts.poppins(
                color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppColors.purple),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await service.renameProject(
                    project.id, newName);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text('Save',
                style: GoogleFonts.poppins(
                    color: AppColors.purple,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── DELETE DIALOG ──
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Project?',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will permanently delete "${project.name}". This cannot be undone.',
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              await service.deleteProject(project.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text('Delete',
                style: GoogleFonts.poppins(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}