/// A data class describing a bar in a bar graph
class Bar {
  /// The amount represented by the bar. This will be scaled to a height
  /// in the bar graph and plotted.
  double value;

  /// The title of what the bar represents. This will be displayed
  /// in the legends.
  String title;

  /// The unique identifier of the [Bar] object.
  String? id;

  Bar({required this.value, required this.title, this.id});
}
