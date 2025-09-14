import 'package:flutter/material.dart';

import '../../models/exercise/exercise.dart';
import '../../models/exercise/exercise_guide.dart';
import '../../models/exercise/workout_plan.dart';

class PersiapanLatihan extends StatefulWidget {
  final WorkoutPlan workoutPlan;
  const PersiapanLatihan({super.key, required this.workoutPlan});

  @override
  State<PersiapanLatihan> createState() => _PersiapanLatihanState();
}

class _PersiapanLatihanState extends State<PersiapanLatihan> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int pageIndex) {
    if (pageIndex >= 0 && pageIndex < widget.workoutPlan.exercises.length) {
      _pageController.animateToPage(
        pageIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context)
  {
    final theme = Theme.of(context);
    final currentExercise = widget.workoutPlan.exercises[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 1,
        title: Text(
          "Guide Latihan",
          style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24), // tinggi progress bar
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _buildTopOverlay(context), // langsung taruh progress bar di sini
          ),
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.workoutPlan.exercises.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              final latihan = widget.workoutPlan.exercises[index];
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 240),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      latihan.name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      latihan.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      "Tutorial",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (latihan.guides != null && latihan.guides!.isNotEmpty)
                      ...latihan.guides!.map(_buildGuideItem)
                    else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            "Tidak ada panduan untuk gerakan ini.",
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),

          /// Overlay atas (back + progress + home)
          // SafeArea(child: _buildTopOverlay(context)),

          /// Kontrol bawah
          _buildFloatingControlCard(context, currentExercise),
        ],
      ),
    );
  }

  Widget _buildGuideItem(ExerciseGuide guide)
  {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            guide.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                guide.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress)
                {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: Icon(Icons.error_outline,
                      color: Colors.grey[500], size: 40),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopOverlay(BuildContext context)
  {
    final theme = Theme.of(context);
    final totalExercises = widget.workoutPlan.exercises.length;

    return Row(
      children: List.generate(totalExercises, (index) {
        return Expanded(
          child: Container(
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            decoration: BoxDecoration(
              color: index == _currentIndex
                  ? theme.colorScheme.primary
                  : index < _currentIndex
                  ? theme.colorScheme.secondary.withOpacity(0.7)
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }


  Widget _buildFloatingControlCard(BuildContext context, Exercise currentExercise)
  {
    final theme = Theme.of(context);
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == widget.workoutPlan.exercises.length - 1;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade100],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Judul latihan
                Text(
                  currentExercise.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

                // Detail latihan
                Text(
                  currentExercise.detailsString,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Progress info
                Text(
                  'Gerakan ${_currentIndex + 1} dari ${widget.workoutPlan.exercises.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),

                // Control buttons
                Row(
                  children: [
                    // Previous
                    IconButton.filledTonal(
                      onPressed: isFirst ? null : () => _goToPage(_currentIndex - 1),
                      icon: const Icon(Icons.skip_previous_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: isFirst
                            ? Colors.grey.shade200
                            : theme.colorScheme.secondary.withOpacity(0.1),
                        foregroundColor: isFirst
                            ? Colors.grey
                            : theme.colorScheme.secondary,
                        padding: const EdgeInsets.all(12),
                        shape: const CircleBorder(),
                      ),
                    ),

                    // Tombol utama "Mulai"
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text(
                            'Mulai',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),

                    // Next
                    IconButton.filledTonal(
                      onPressed: isLast ? null : () => _goToPage(_currentIndex + 1),
                      icon: const Icon(Icons.skip_next_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: isLast
                            ? Colors.grey.shade200
                            : theme.colorScheme.secondary.withOpacity(0.1),
                        foregroundColor: isLast
                            ? Colors.grey
                            : theme.colorScheme.secondary,
                        padding: const EdgeInsets.all(12),
                        shape: const CircleBorder(),
                      ),
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

}
