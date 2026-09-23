class VisionBoardItem {
  final String id;
  final String goalTitle;
  final DateTime? createdAt;
  final String formattedDate;
  final String visionStatement;
  final int actionStepsCount;
  final Map<String, dynamic> rawData;

  const VisionBoardItem({
    required this.id,
    required this.goalTitle,
    required this.createdAt,
    required this.formattedDate,
    required this.visionStatement,
    required this.actionStepsCount,
    required this.rawData,
  });

  factory VisionBoardItem.fromRaw(dynamic raw) {
    if (raw is! Map) {
      return VisionBoardItem(
        id: '',
        goalTitle: 'Sacred Manifestation',
        createdAt: null,
        formattedDate: '',
        visionStatement: '',
        actionStepsCount: 0,
        rawData: const {},
      );
    }

    final rawMap = Map<String, dynamic>.from(raw);
    final id = (rawMap['id'] ?? '').toString();
    final title = (rawMap['goal_title'] ?? 'Sacred Manifestation')
        .toString()
        .trim();

    // Safely parse date once
    DateTime? dt;
    String formatted = '';
    final rawDate = rawMap['created_at'];
    if (rawDate != null) {
      try {
        dt = DateTime.parse(rawDate.toString()).toLocal();
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        formatted = '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
      } catch (_) {
        formatted = '';
      }
    }

    // Safely parse first manifestation plan
    String vision = '';
    int taskCount = 0;
    final plans = rawMap['manifestation_plans'];
    if (plans is List && plans.isNotEmpty && plans.first is Map) {
      final planMap = Map<String, dynamic>.from(plans.first as Map);
      vision = (planMap['vision_statement'] ?? '').toString().trim();
      final tasks = planMap['daily_tasks'];
      if (tasks is List) {
        taskCount = tasks.length;
      }
    }

    return VisionBoardItem(
      id: id,
      goalTitle: title.isEmpty ? 'Sacred Manifestation' : title,
      createdAt: dt,
      formattedDate: formatted,
      visionStatement: vision,
      actionStepsCount: taskCount,
      rawData: rawMap,
    );
  }
}
