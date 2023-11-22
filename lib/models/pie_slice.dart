/// A data class describing a slice in a pie graph
class PieSlice {
  /// The amount represented by the slice. This will be scaled to a sweep angle
  /// in the pie graph and plotted.
  double value;

  /// The title of what the slice represents. This will be displayed
  /// in the legends.
  String title;

  /// The relative value i.e. [value] / sum of all slices' [value]s. This will
  /// be set in the graph
  double relativeValue = 0;

  /// The unique identifier of the [PieSlice] object.
  String? id;

  PieSlice({required this.value, required this.title, this.id});
}
