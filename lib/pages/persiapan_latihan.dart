import 'package:flutter/material.dart';

import '../models/exercise/exercise.dart';
import '../models/exercise/exercise_guide.dart';
import '../models/exercise/workout_plan.dart';

class PersiapanLatihan extends StatefulWidget {
  final WorkoutPlan workoutPlan;
  const PersiapanLatihan({super.key, required this.workoutPlan});

  @override
  State<PersiapanLatihan> createState() => _PersiapanLatihanState();
}

class _PersiapanLatihanState extends State<PersiapanLatihan>
{
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState()
  {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose()
  {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int pageIndex)
  {
    if (pageIndex >= 0 && pageIndex < widget.workoutPlan.exercises.length)
    {
      _pageController.animateToPage(pageIndex,
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
      bottomNavigationBar: _buildBottomMenu(context),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.workoutPlan.exercises.length,
            onPageChanged: (index) => setState(() { _currentIndex = index; }),
            itemBuilder: (context, index)
            {
              final latihan = widget.workoutPlan.exercises[index];
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 216),
                child: Column(
                  children: [
                    Text(latihan.name,
                      style: Theme.of(context).textTheme
                        .headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    Text(latihan.description,
                      style: Theme.of(context).textTheme
                        .bodyLarge?.copyWith(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 24),
                    Divider(color: Colors.grey[300]),
                    const SizedBox(height: 24),

                    // Populate exercise guides details
                    if (latihan.guides != null && latihan.guides!.isNotEmpty)
                      ...latihan.guides!.map((guide) => _buildGuideItem(guide))

                    else // Show a placeholder if no guides are available
                      const Center(child: Text("Tidak ada panduan untuk gerakan ini."))
                  ],
                ),
              );
            },
          ),
          SafeArea(child: _buildTopOverlay(context)),
          _buildFloatingControlCard(context, currentExercise),
        ],
      ),
    );
  }

  Widget _buildGuideItem(ExerciseGuide guide)
  {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          Text(guide.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              guide.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              loadingBuilder: (context, child, loadingProgress)
              {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace)
              => Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[300],
                child: Icon(
                  Icons.error_outline,
                  color: Colors.grey[500],
                  size: 48),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Floating Back Button
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(25),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),

          // 2. Progress Bar
          Expanded(
            child: Row(
              children: List.generate(totalExercises, (index)
              => Expanded(
                child: Container(
                  height: 4.0,
                  margin: const EdgeInsets.symmetric(horizontal: 2.0),
                  decoration: BoxDecoration(
                    color: index == _currentIndex
                        ? theme.colorScheme.secondary
                        : (index < _currentIndex ? Colors.grey[600] : Colors.grey[300]),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              )),
            ),
          ),
          const SizedBox(width: 8),

          // 3. Floating Home Button
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(25),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.home, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFloatingControlCard(BuildContext context, Exercise currentExercise)
  {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1.0)
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(currentExercise.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),

                Text(currentExercise.detailsString,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700], fontSize: 16)),
                const SizedBox(height: 12),

                Text(
                  'Gerakan ${_currentIndex + 1} dari ${widget.workoutPlan.exercises.length}',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Expanded(flex: 2,
                        child: Align(alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.skip_previous),
                            iconSize: 32,
                            color: _currentIndex > 0 ? theme.colorScheme.secondary : Colors.grey,
                            onPressed: _currentIndex > 0 ? () => _goToPage(_currentIndex - 1) : null,
                          ))),

                      Expanded(flex: 4,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {},
                          child: const Text('Mulai'),
                        )),

                      Expanded(flex: 2,
                        child: Align(alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.skip_next),
                            iconSize: 32,
                            color: _currentIndex < widget.workoutPlan.exercises.length - 1
                                ? theme.colorScheme.secondary
                                : Colors.grey,
                            onPressed: _currentIndex < widget.workoutPlan.exercises.length - 1
                                ? () => _goToPage(_currentIndex + 1)
                                : null,
                          ))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomMenu(BuildContext context)
  {
    final theme = Theme.of(context);
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.hub_outlined), label: 'Perangkat'),
        BottomNavigationBarItem(icon: Icon(Icons.volume_up_outlined), label: 'Feedback Suara'),
      ],
      currentIndex: 0,
      backgroundColor: theme.primaryColor,
      selectedItemColor: theme.colorScheme.secondary,
      unselectedItemColor: theme.colorScheme.secondary.withOpacity(0.7),
      type: BottomNavigationBarType.fixed,
      onTap: (index) {},
    );
  }
}