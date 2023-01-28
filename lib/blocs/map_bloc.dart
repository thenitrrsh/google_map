import 'package:google_place/google_place.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rxdart/subjects.dart';

import '../models/coordinates_model.dart';
import '../models/plase_search_model.dart';

class MapBloc {
  final BehaviorSubject<PlaceSearchModel> _predictions =
      BehaviorSubject<PlaceSearchModel>();

  final BehaviorSubject<List<Coordinate>> _latLongData =
      BehaviorSubject<List<Coordinate>>();

  getPlacesData(List<AutocompletePrediction> result) async {
    PlaceSearchModel p = PlaceSearchModel();
    p.predictions = result;
    _predictions.sink.add(p);
  }

  clearPlacesData() async {
    PlaceSearchModel p = PlaceSearchModel();
    p.predictions = [];
    p.isReset = true;
    _predictions.sink.add(p);
  }

  getLatLongData(List<Coordinate> data) async {
    _latLongData.sink.add(data);
    if (_latLongData.hasValue) {}
  }

  String biggerDate(List<String> date) {
    String minDate = "";
    if (date.isNotEmpty) {
      minDate = date.first;
      for (var element in date) {
        if (int.parse(minDate) < int.parse(element)) {
          minDate = element;
        }
      }
    }
    return minDate;
  }

  dispose() {
    _latLongData.close();
    _predictions.close();
  }

  BehaviorSubject<List<Coordinate>> get latLongData => _latLongData;

  BehaviorSubject<PlaceSearchModel> get predictions => _predictions;
}

MapBloc mapBloc = MapBloc();
