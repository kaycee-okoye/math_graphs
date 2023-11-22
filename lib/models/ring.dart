/// A data class describing a ring in a rings graph
class Ring {
  /// The total amount represented by the ring.
  double value;

  /// The title of what the slice represents. This will be displayed
  /// in the legends.
  String title;

  /// The percentage progress of [value] that will be plotted in the graph
  double ratio = 0;

  /// The unique identifier of the [Ring] object.
  String? id;

  Ring({required this.value, required this.title, this.ratio = 0, this.id});
}
