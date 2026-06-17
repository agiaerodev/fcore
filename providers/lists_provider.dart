import 'package:flutter/material.dart';
import '../models/lists_model.dart';
import '../services/base_api_service.dart';

class ListsProvider extends ChangeNotifier {
  final BaseApiService _apiService = BaseApiService();

  List<Station> _stations = [];
  List<GreetStatus> _greetStatuses = [];
  List<FlightType> _flightTypes = [];
  List<Airport> _airports = [];

  bool _isLoading = false;

  List<Station> get stations => _stations;
  List<GreetStatus> get greetStatuses => _greetStatuses;
  List<FlightType> get flightTypes => _flightTypes;
  List<Airport> get airports => _airports;
  bool get isLoading => _isLoading;

  /// Inicializa las listas globales si no están cargadas.
  Future<void> init() async {
    // Si ya está cargando, no re-inicializar
    if (_isLoading) return;

    // Solo cargar lo que falte
    final tasks = <Future>[];
    if (_stations.isEmpty) tasks.add(_fetchStationsInternal());
    if (_greetStatuses.isEmpty) tasks.add(_fetchGreetStatusesInternal());
    if (_flightTypes.isEmpty) tasks.add(_fetchFlightTypesInternal());
    if (_airports.isEmpty) tasks.add(_fetchAirportsInternal());

    if (tasks.isEmpty) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait(tasks);
    } catch (e) {
      debugPrint('Error initializing lists: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchStationsInternal() async {
    try {
      final response = await _apiService.index('/ecommerce/v1/stations');
      if (response != null && response['data'] != null) {
        _stations = (response['data'] as List)
            .map((item) => Station.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching stations: $e');
    }
  }

  Future<void> _fetchAirportsInternal() async {
    try {
      final response = await _apiService.index('/flight/v1/airports');
      if (response != null && response['data'] != null) {
        _airports = (response['data'] as List)
            .map((item) => Airport.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching airports: $e');
    }
  }

  Future<void> _fetchGreetStatusesInternal() async {
    try {
      final response = await _apiService.index('/reservations/v1/greet-statuses');
      if (response != null && response['data'] != null) {
        _greetStatuses = (response['data'] as List)
            .map((item) => GreetStatus.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching greet statuses: $e');
    }
  }

  Future<void> _fetchFlightTypesInternal() async {
    try {
      final response = await _apiService.index('/reservations/v1/flight-types');
      if (response != null && response['data'] != null) {
        _flightTypes = (response['data'] as List)
            .map((item) => FlightType.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching flight types: $e');
    }
  }

  /// Refresco manual de estaciones
  Future<void> fetchStations() async {
    _isLoading = true;
    notifyListeners();
    await _fetchStationsInternal();
    _isLoading = false;
    notifyListeners();
  }

  /// Refresco manual de estados
  Future<void> fetchGreetStatuses() async {
    _isLoading = true;
    notifyListeners();
    await _fetchGreetStatusesInternal();
    _isLoading = false;
    notifyListeners();
  }

  /// Refresco manual de tipos de vuelo
  Future<void> fetchFlightTypes() async {
    _isLoading = true;
    notifyListeners();
    await _fetchFlightTypesInternal();
    _isLoading = false;
    notifyListeners();
  }

  /// Refresco manual de aeropuertos
  Future<void> fetchAirports() async {
    _isLoading = true;
    notifyListeners();
    await _fetchAirportsInternal();
    _isLoading = false;
    notifyListeners();
  }

  /// Limpia las listas (útil al cerrar sesión)
  void clear() {
    _stations = [];
    _greetStatuses = [];
    _flightTypes = [];
    notifyListeners();
  }
}
