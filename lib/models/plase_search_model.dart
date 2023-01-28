import 'package:google_place/google_place.dart';

class PlaceSearchModel {
  List<AutocompletePrediction>? predictions;
  bool isReset;
  PlaceSearchModel({this.predictions, this.isReset = false});
}
