/// A data class describing scatter points in a scatter graph
class ScatterPoint {
  /// The title of what the bar represents. This will be displayed
  /// on the x axis.
  String title;

  /// The amounts represented by each series at this x ([title]) location.
  /// These will be scaled in the scatter graph and plotted.
  List<double> values = [];

  /// The unique identifier of the [Bar] object.
  String? id;

  ScatterPoint({required List<double> amounts, required this.title, this.id}) {
    this.values.clear();
    this.values.addAll(amounts);
  }
}
