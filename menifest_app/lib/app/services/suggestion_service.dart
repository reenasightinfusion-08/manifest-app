import '../models/suggestion_model.dart';

class SuggestionService {
  SuggestionService._();
  static final SuggestionService instance = SuggestionService._();

  // Simulates fetching AI-generated suggestions based on user dream input
  Future<List<Suggestion>> getSuggestions(String dream) async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    return [
      Suggestion(
        id: '1',
        text: 'Break your goal into 3 smaller, actionable steps and tackle one each week.',
        category: 'Planning',
      ),
      Suggestion(
        id: '2',
        text: 'Dedicate 15 minutes every morning to visualizing your dream reality.',
        category: 'Mindset',
      ),
      Suggestion(
        id: '3',
        text: 'Find a community or mentor who has already achieved a similar goal.',
        category: 'Network',
      ),
      Suggestion(
        id: '4',
        text: "Write down 'I am...' affirmation statements related to your dream every day.",
        category: 'Affirmations',
      ),
    ];
  }
}
