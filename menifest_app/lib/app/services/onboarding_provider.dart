import 'package:flutter/material.dart';

class OnboardingProvider with ChangeNotifier {
  int _currentPage = 0;
  int get currentPage => _currentPage;

  final List<OnboardData> pages = const [
    OnboardData(
      imagePath: 'assets/images/onboard1.png',
      title: 'Write Your\nDreams',
      highlight: 'Dreams',
      description:
          'Tell us everything you want in life — your goals, your desires, your vision. No dream is too big.',
    ),
    OnboardData(
      imagePath: 'assets/images/onboard2.png',
      title: 'Get Your\nAction Plan',
      highlight: 'Action Plan',
      description:
          'We turn your dreams into clear, daily steps so you always know exactly what to do next.',
    ),
    OnboardData(
      imagePath: 'assets/images/onboard3.png',
      title: 'Manifest Your\nReality',
      highlight: 'Reality',
      description:
          'Track your progress, stay consistent, and watch your life transform — one manifestation at a time.',
    ),
  ];

  bool get isLastPage => _currentPage == pages.length - 1;

  void updatePage(int index) {
    _currentPage = index;
    notifyListeners();
  }
}

class OnboardData {
  final String imagePath;
  final String title;
  final String highlight;
  final String description;

  const OnboardData({
    required this.imagePath,
    required this.title,
    required this.highlight,
    required this.description,
  });
}
