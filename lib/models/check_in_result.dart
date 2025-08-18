class CheckInResult {
  final bool alreadyCheckedIn;
  final int eventPoints;
  final int newPoints;
  final int newEventsAttended;
  final int newRank;

  CheckInResult({
    required this.alreadyCheckedIn,
    required this.eventPoints,
    required this.newPoints,
    required this.newEventsAttended,
    required this.newRank,
  });

  factory CheckInResult.fromMap(Map<String, dynamic> m) {
    return CheckInResult(
      alreadyCheckedIn: (m['already_checked_in'] as bool?) ?? false,
      eventPoints: (m['event_points'] as int?) ?? 0,
      newPoints: (m['new_points'] as int?) ?? 0,
      newEventsAttended: (m['new_events_attended'] as int?) ?? 0,
      newRank: (m['new_rank'] as int?) ?? 0,
    );
  }
}
