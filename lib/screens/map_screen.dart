import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map/blocs/map_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/constants_values.dart';
import '../constants/custom_colors.dart';
import '../models/plase_search_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late Position _currentPosition;
  CameraPosition _initialLocation = CameraPosition(target: LatLng(0.0, 0.0));
  GoogleMapController? mapController;
  Geolocator? geoLocator;
  late Position position;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _markerIdCounter = 1;
  TextEditingController nametext = TextEditingController();
  TextEditingController _searchController = TextEditingController();
  late GooglePlace googlePlace;
  List<AutocompletePrediction> predictions = [];
  Set<Polygon> _polygons = HashSet<Polygon>();
  FocusNode _focusNode = FocusNode();
  ScrollController _scrollController = ScrollController();
  Map<PolylineId, Polyline> polylines = {};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getCurrentLocation();
    mapBloc.clearPlacesData();
    googlePlace = GooglePlace(ConstantsValues.googleMapKey);
  }

  Future<bool> locationPermission() async {
    await [Permission.location].request();
    if (await Permission.location.status.isGranted != true) {
      Fluttertoast.showToast(msg: "Please provide location permission");
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Container(
        height: height,
        width: width,
        child: Scaffold(
          key: _scaffoldKey,
          resizeToAvoidBottomInset: false,
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 40,
                  width: 35,
                  child: FloatingActionButton(
                    heroTag: "2",
                    backgroundColor: CustomColors.colorWhite,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                    child: Icon(
                      Icons.add_rounded,
                      color: CustomColors.colorBlack,
                      size: 25,
                    ),
                    onPressed: () {
                      mapController?.animateCamera(
                        CameraUpdate.zoomIn(),
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                SizedBox(
                  height: 40,
                  width: 35,
                  child: FloatingActionButton(
                    heroTag: "1",
                    backgroundColor: CustomColors.colorWhite,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                    child: Icon(
                      Icons.remove,
                      color: CustomColors.colorBlack,
                      size: 25,
                    ),
                    onPressed: () {
                      mapController?.animateCamera(
                        CameraUpdate.zoomOut(),
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                SizedBox(
                  height: 40,
                  width: 35,
                  child: FloatingActionButton(
                    heroTag: "0",
                    backgroundColor: CustomColors.colorWhite,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                    child: SvgPicture.asset("assets/current_location_icon.svg"),
                    onPressed: () {
                      _getCurrentLocation();
                    },
                  ),
                ),
              ],
            ),
          ),
          body: Stack(
            children: <Widget>[
              GoogleMap(
                polygons: _polygons,
                polylines: Set<Polyline>.of(polylines.values),
                onTap: (v) {},
                initialCameraPosition: _initialLocation,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                mapType: MapType.normal,
                zoomGesturesEnabled: true,
                buildingsEnabled: true,
                zoomControlsEnabled: false,
                onMapCreated: (GoogleMapController controller) {
                  mapController = controller;
                },
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(left: 10, top: 5, right: 10),
                      height: 70,
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.all(15.0),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: CustomColors.colorBlack, width: 1),
                          color: CustomColors.colorWhite),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StreamBuilder<PlaceSearchModel>(
                              stream: mapBloc.predictions.stream,
                              builder: (context, snapshot) {
                                return Visibility(
                                  visible: _searchController.text.length > 0,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: Icon(Icons.keyboard_arrow_left),
                                    onPressed: () {
                                      _searchController.clear();
                                      _focusNode.unfocus();
                                      mapBloc.clearPlacesData();
                                    },
                                  ),
                                  replacement: Icon(Icons.search),
                                );
                              }),
                          SizedBox(
                            width: 5,
                          ),
                          Expanded(
                            child: TextFormField(
                              // maxLength: 50,
                              maxLines: 1,
                              style: TextStyle(overflow: TextOverflow.ellipsis),
                              controller: _searchController,
                              focusNode: _focusNode,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.only(bottom: 10),
                                hintText: "Search",
                              ),
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  autoCompleteSearch(value);
                                } else {
                                  mapBloc.clearPlacesData();
                                }
                              },
                            ),
                          ),
                          StreamBuilder<PlaceSearchModel>(
                              stream: mapBloc.predictions.stream,
                              builder: (context, snapshot) {
                                return Visibility(
                                    visible: _searchController.text
                                        .trim()
                                        .isNotEmpty,
                                    child: IconButton(
                                        padding: EdgeInsets.zero,
                                        onPressed: () {
                                          mapBloc.clearPlacesData();
                                          _searchController.clear();
                                        },
                                        icon: Icon(Icons.close)));
                              }),
                        ],
                      ),
                    ),
                    StreamBuilder<PlaceSearchModel>(
                        stream: mapBloc.predictions.stream,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            if (snapshot.data!.isReset) {
                              return Container();
                            }
                            if (snapshot.data!.predictions!.isEmpty ||
                                snapshot.data!.predictions == [] &&
                                    snapshot.data!.isReset == false) {
                              return Container(
                                margin: EdgeInsets.symmetric(horizontal: 10),
                                height: 40,
                                padding: EdgeInsets.all(10),
                                color: CustomColors.colorWhite,
                                child: Center(
                                  child: Text("No result found"),
                                ),
                              );
                            }
                            return Flexible(
                              child: Container(
                                constraints: BoxConstraints(
                                    maxHeight:
                                        (MediaQuery.of(context).size.height /
                                                2) -
                                            100),
                                margin: EdgeInsets.symmetric(horizontal: 10),
                                // height: 200,
                                color: CustomColors.colorWhite,
                                child: Scrollbar(
                                  controller: _scrollController,
                                  isAlwaysShown: true,
                                  thickness: 4,
                                  hoverThickness: 5,
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    shrinkWrap: true,
                                    itemCount:
                                        snapshot.data!.predictions!.length,
                                    itemBuilder: (context, index) {
                                      AutocompletePrediction data =
                                          snapshot.data!.predictions![index];
                                      return ListTile(
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        leading: CircleAvatar(
                                          child: Icon(
                                            Icons.pin_drop,
                                            color: Colors.white,
                                          ),
                                        ),
                                        title: Text(
                                          data.description!,
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        onTap: () {
                                          _searchController.text =
                                              data.description ?? "";
                                          getPlaceDetails(data.placeId ?? "");
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          }
                          return Container();
                        }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _getCurrentLocation() async {
    await locationPermission();
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
      setState(() {
        _currentPosition = position;
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 18.0,
            ),
          ),
        );
      });
      //await _getAddress();
    }).catchError((e) {
      print(e);
    });
  }

  void getPlaceDetails(String placeId) async {
    double lat = 0.00;
    double long = 0.00;
    var result = await this.googlePlace.details.get(placeId);
    if (result != null && result.result != null && mounted) {
      lat = result.result!.geometry!.location!.lat ?? 0.00;
      long = result.result!.geometry!.location!.lng ?? 0.00;
      _focusNode.unfocus();
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(lat, long),
            zoom: 18.0,
          ),
        ),
      );
      mapBloc.clearPlacesData();
    }
  }

  void autoCompleteSearch(String value) async {
    try {
      var result = await googlePlace.autocomplete.get(value);
      if (result != null && result.predictions != null && mounted) {
        if (_searchController.text.trim().isNotEmpty) {
          mapBloc.getPlacesData(result.predictions ?? []);
        } else {
          mapBloc.clearPlacesData();
        }
      } else {
        mapBloc.getPlacesData([]);
      }
    } catch (e) {
      print(e);
    }
  }
}
