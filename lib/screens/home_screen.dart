// lib/screens/home_screen.dart (versión simplificada)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'package:rapiruta_app/api/route_service.dart';
import 'package:rapiruta_app/models/route_model.dart';
import 'package:rapiruta_app/models/selection_mode.dart';
// import 'package:rapiruta_app/widgets/home/header_widget.dart';
import 'package:rapiruta_app/widgets/home/selection_crosshair.dart';
import 'package:rapiruta_app/widgets/home/route_info_panel.dart'; // Ensure this file exists and exports RouteInfoPanel
import 'package:rapiruta_app/widgets/home/floating_action_buttons.dart';
import 'package:rapiruta_app/widgets/home/map_widget.dart'; // Ensure this import exists and the file contains MapWidget
import 'package:rapiruta_app/utils/snackbar_helper.dart';
import 'package:rapiruta_app/widgets/home/search_bar_widget.dart';
import 'package:rapiruta_app/screens/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final RouteService _routeService = RouteService();

  // Animations
  late AnimationController _fabAnimationController;
  late AnimationController _headerAnimationController;
  late AnimationController _routeInfoAnimationController;
  late Animation<double> _fabAnimation;
  // late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _routeInfoAnimation;

  // State
  LatLng _currentCenter = const LatLng(-8.11599, -79.02998);
  RouteSolution? _foundSolution;
  bool _isSearching = false;
  bool _showRouteInfo = false;
  bool _routeInfoMinimized = false;
  SelectionMode _selectionMode = SelectionMode.origin;
  LatLng? _originPoint;
  LatLng? _destinationPoint;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _routeInfoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );

    // _headerSlideAnimation =
    //     Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
    //       CurvedAnimation(
    //         parent: _headerAnimationController,
    //         curve: Curves.easeOutCubic,
    //       ),
    //     );

    _routeInfoAnimation = CurvedAnimation(
      parent: _routeInfoAnimationController,
      curve: Curves.easeInOut,
    );

    _headerAnimationController.forward();
    _fabAnimationController.forward();
  }

  void _openSearchScreen() async {
    // Navega a la pantalla de búsqueda y ESPERA un resultado (await)
    final result = await Navigator.push<LatLng?>(
      context,
      MaterialPageRoute(builder: (context) => const SearchScreen()),
    );

    // Si el usuario seleccionó un lugar (result no es null)
    if (result != null && mounted) {
      // Mueve el mapa a la ubicación seleccionada
      _mapController.move(result, 15.0);

      // Opcional: Si quieres que el punto se fije automáticamente como destino
      // puedes añadir la lógica aquí:
      // setState(() {
      //   _destinationPoint = result;
      //   _selectionMode = SelectionMode.none;
      // });
    }
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _headerAnimationController.dispose();
    _routeInfoAnimationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    HapticFeedback.lightImpact();
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      // CAMBIO: Ahora usas SnackBarHelper en lugar del método local
      SnackBarHelper.showCustomSnackBar(
        context,
        'Los servicios de ubicación están desactivados.',
        isError: true,
      );
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied && mounted) {
        SnackBarHelper.showCustomSnackBar(
          context,
          'Los permisos de ubicación fueron denegados.',
          isError: true,
        );
        return;
      }
    }
    if (permission == LocationPermission.deniedForever && mounted) {
      SnackBarHelper.showCustomSnackBar(
        context,
        'Los permisos de ubicación están permanentemente denegados.',
        isError: true,
      );
      return;
    }
    final position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentCenter = LatLng(position.latitude, position.longitude);
        _mapController.move(_currentCenter, 15.0);
      });
    }
  }

  Future<void> _findRoute() async {
    if (_originPoint == null || _destinationPoint == null) return;
    HapticFeedback.mediumImpact();

    if (!mounted) return;
    setState(() {
      _isSearching = true;
      _foundSolution = null;
      _showRouteInfo = false;
      _routeInfoMinimized = false;
    });
    _routeInfoAnimationController.reset();

    try {
      final solution = await _routeService.findRoute(
        _originPoint!,
        _destinationPoint!,
      );

      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _foundSolution = solution;
            _isSearching = false;
            _showRouteInfo = solution != null;
            _routeInfoMinimized = false;
          });

          if (solution != null) {
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) {
                _routeInfoAnimationController.forward(from: 0.0);
              }
            });
          }

          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              if (solution == null) {
                // CAMBIO: Usar SnackBarHelper
                SnackBarHelper.showCustomSnackBar(
                  context,
                  'No se encontró una ruta. Intenta con otros puntos.',
                  isError: true,
                );
              } else {
                SnackBarHelper.showCustomSnackBar(
                  context,
                  '¡Ruta encontrada!',
                  isError: false,
                );
              }
            }
          });
        }
      });
    } catch (e) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isSearching = false;
          });
          // CAMBIO: Usar SnackBarHelper
          SnackBarHelper.showCustomSnackBar(
            context,
            'Error al buscar la ruta: $e',
            isError: true,
          );
        }
      });
    }
  }

  void _resetSelection() {
    HapticFeedback.lightImpact();
    setState(() {
      _originPoint = null;
      _destinationPoint = null;
      _foundSolution = null;
      _selectionMode = SelectionMode.origin;
      _showRouteInfo = false;
      _routeInfoMinimized = false;
    });
    _routeInfoAnimationController.reset();
  }

  void _toggleRouteInfo() {
    setState(() {
      _routeInfoMinimized = !_routeInfoMinimized;
    });
  }

  // Métodos principales (getCurrentLocation, findRoute, resetSelection, etc.)
  // ... (mantienes la lógica principal pero usando SnackBarHelper)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MapWidget(
            mapController: _mapController,
            currentCenter: _currentCenter,
            foundSolution: _foundSolution,
            originPoint: _originPoint,
            destinationPoint: _destinationPoint,
            onPositionChanged: (position, hasGesture) {
              if (hasGesture) {
                setState(() {
                  _currentCenter = position.center!;
                });
              }
            },
          ),
          // HeaderWidget(
          //   slideAnimation: _headerSlideAnimation,
          //   onResetSelection: _resetSelection,
          //   hasSelection: _originPoint != null || _destinationPoint != null,
          // ),
          SelectionCrosshair(selectionMode: _selectionMode),
          if (_showRouteInfo && _foundSolution != null)
            RouteInfoPanel(
              foundSolution: _foundSolution!,
              routeInfoAnimation: _routeInfoAnimation,
              routeInfoMinimized: _routeInfoMinimized,
              onToggle: _toggleRouteInfo,
            ),
          FloatingActionButtons(
            fabAnimation: _fabAnimation,
            routeInfoAnimation: _routeInfoAnimation,
            showRouteInfo: _showRouteInfo,
            routeInfoMinimized: _routeInfoMinimized,
            selectionMode: _selectionMode,
            originPoint: _originPoint,
            destinationPoint: _destinationPoint,
            isSearching: _isSearching,
            onGetCurrentLocation: _getCurrentLocation,
            onSetOrigin: () {
              if (mounted) {
                setState(() {
                  _originPoint = _currentCenter;
                  _selectionMode = SelectionMode.destination;
                });
              }
            },
            onSetDestination: () {
              if (mounted) {
                setState(() {
                  _destinationPoint = _currentCenter;
                  _selectionMode = SelectionMode.none;
                });
              }
            },
            onFindRoute: _findRoute,
            onResetSelection: _resetSelection,
          ),
          SearchBarWidget(onSearchBarTapped: _openSearchScreen),
        ],
      ),
    );
  }
}
