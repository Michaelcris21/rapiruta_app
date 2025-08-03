// Archivo: lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:rapiruta_app/providers/auth_provider.dart';
import 'package:rapiruta_app/providers/theme_provider.dart';
import 'package:rapiruta_app/api/route_service.dart';
import 'package:rapiruta_app/models/route_model.dart';

enum SelectionMode { none, origin, destination }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final RouteService _routeService = RouteService();

  late AnimationController _fabAnimationController;
  late AnimationController _headerAnimationController;
  late AnimationController _routeInfoAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _routeInfoAnimation;

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

    _headerSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _headerAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _routeInfoAnimation = CurvedAnimation(
      parent: _routeInfoAnimationController,
      curve: Curves.easeInOut,
    );

    _headerAnimationController.forward();
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _headerAnimationController.dispose();
    _routeInfoAnimationController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        _showCustomSnackBar('No se pudo abrir el enlace', isError: true);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    HapticFeedback.lightImpact();
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      _showCustomSnackBar(
        'Los servicios de ubicación están desactivados.',
        isError: true,
      );
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied && mounted) {
        _showCustomSnackBar(
          'Los permisos de ubicación fueron denegados.',
          isError: true,
        );
        return;
      }
    }
    if (permission == LocationPermission.deniedForever && mounted) {
      _showCustomSnackBar(
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
                _showCustomSnackBar(
                  'No se encontró una ruta. Intenta con otros puntos.',
                  isError: true,
                );
              } else {
                _showCustomSnackBar('¡Ruta encontrada!', isError: false);
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
          _showCustomSnackBar('Error al buscar la ruta: $e', isError: true);
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

  void _showCustomSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFE53E3E)
            : const Color(0xFF38A169),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }

  bool _hasTransfer() {
    if (_foundSolution == null) return false;
    int busSteps = _foundSolution!.steps
        .where((step) => step.type == StepType.bus)
        .length;
    return busSteps > 1;
  }

  Widget _buildTransferIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Icon(Icons.swap_horiz, size: 14, color: Colors.orange.shade700),
    );
  }

  Widget _buildBusInfo(RouteStep step, int stepIndex) {
    if (step.busColor == null) return const SizedBox.shrink();

    final textColor = step.busColor!.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;

    final bool isTransferStep =
        stepIndex > 0 &&
        _foundSolution!.steps[stepIndex - 1].type == StepType.walk &&
        _foundSolution!.steps
                .take(stepIndex)
                .where((s) => s.type == StepType.bus)
                .length >
            0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: step.busColor!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: step.busColor!.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: step.busColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: step.busColor!.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      step.vehicleIdentifier ?? '',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (isTransferStep)
                  Positioned(top: -6, right: -6, child: _buildTransferIcon()),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          step.companyName ?? 'Empresa Desconocida',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isTransferStep)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Transbordo',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.instructions,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalkInfo(RouteStep step) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_walk,
              size: 18,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              step.instructions,
              style: const TextStyle(fontSize: 14, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context);

    IconData themeIcon;
    switch (themeProvider.themeStyle) {
      case ThemeStyle.light:
        themeIcon = Icons.nightlight_round;
        break;
      case ThemeStyle.dark:
        themeIcon = Icons.satellite_alt_outlined;
        break;
      case ThemeStyle.satellite:
        themeIcon = Icons.wb_sunny_outlined;
        break;
    }

    String urlTemplate;
    Widget attributionWidget;
    List<String> subdomains = [];

    switch (themeProvider.themeStyle) {
      case ThemeStyle.light:
        urlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
        attributionWidget = RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              '© OpenStreetMap',
              onTap: () =>
                  _launchUrl('https://www.openstreetmap.org/copyright'),
            ),
          ],
        );
        break;
      case ThemeStyle.dark:
        urlTemplate =
            'https://{s}.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}{r}.png';
        subdomains = ['a', 'b', 'c'];
        attributionWidget = RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              '© CartoDB',
              onTap: () => _launchUrl('https://carto.com/attributions'),
            ),
            TextSourceAttribution(
              '© OpenStreetMap',
              onTap: () =>
                  _launchUrl('https://www.openstreetmap.org/copyright'),
            ),
          ],
        );
        break;
      case ThemeStyle.satellite:
        urlTemplate =
            'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
        attributionWidget = RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community',
            ),
          ],
        );
        break;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 14.0,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _currentCenter = position.center!;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: urlTemplate,
                subdomains: subdomains,
                userAgentPackageName: 'com.example.rapiruta_app',
                retinaMode: themeProvider.themeStyle == ThemeStyle.dark,
              ),
              attributionWidget,
              if (_foundSolution != null)
                PolylineLayer(
                  polylines: _foundSolution!.steps.map((step) {
                    return Polyline(
                      points: step.path,
                      color: step.type == StepType.walk
                          ? Colors.orange.withOpacity(0.9)
                          : step.busColor ?? Colors.blue,
                      strokeWidth: step.type == StepType.walk ? 4.0 : 6.0,
                    );
                  }).toList(),
                ),
              MarkerLayer(
                markers: [
                  if (_originPoint != null)
                    Marker(
                      point: _originPoint!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  if (_destinationPoint != null)
                    Marker(
                      point: _destinationPoint!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.place,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          SlideTransition(
            position: _headerSlideAnimation,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'RapiRuta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (_originPoint != null || _destinationPoint != null)
                    _buildGlassButton(
                      icon: Icons.refresh,
                      onPressed: _resetSelection,
                      tooltip: 'Reiniciar',
                    ),
                  const SizedBox(width: 8),
                  _buildGlassButton(
                    icon: themeIcon,
                    onPressed: () => themeProvider.cycleTheme(),
                    tooltip: 'Cambiar Estilo de Mapa',
                  ),
                  const SizedBox(width: 8),
                  _buildGlassButton(
                    icon: Icons.logout,
                    onPressed: () => authProvider.logout(),
                    tooltip: 'Cerrar Sesión',
                  ),
                ],
              ),
            ),
          ),
          if (_selectionMode != SelectionMode.none)
            IgnorePointer(
              child: Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color:
                        (_selectionMode == SelectionMode.origin
                                ? Colors.green
                                : Colors.red)
                            .withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectionMode == SelectionMode.origin
                          ? Colors.green
                          : Colors.red,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.add,
                    color: _selectionMode == SelectionMode.origin
                        ? Colors.green
                        : Colors.red,
                    size: 20,
                  ),
                ),
              ),
            ),

          if (_showRouteInfo && _foundSolution != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: ScaleTransition(
                scale: _routeInfoAnimation,
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  constraints: BoxConstraints(
                    maxHeight: _routeInfoMinimized
                        ? 80
                        : MediaQuery.of(context).size.height * 0.45,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  // --- CAMBIO CLAVE: AnimatedSwitcher para la transición ---
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SizeTransition(
                          sizeFactor: animation,
                          axis: Axis.vertical,
                          child: child,
                        ),
                      );
                    },
                    child: _routeInfoMinimized
                        ? _buildMinimizedPanel() // Panel minimizado
                        : _buildExpandedPanel(), // Panel expandido
                  ),
                ),
              ),
            ),

          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _routeInfoAnimation,
                  _fabAnimation,
                ]),
                builder: (context, child) {
                  // Lógica para el espacio que empuja los botones hacia arriba
                  double bottomPadding = 0;
                  if (_showRouteInfo) {
                    bottomPadding = _routeInfoMinimized
                        ? 100
                        : (MediaQuery.of(context).size.height * 0.45 + 20);
                  }

                  return Transform.scale(
                    scale: _fabAnimation.value,
                    child: AnimatedPadding(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.only(bottom: bottomPadding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: FloatingActionButton(
                              heroTag: "btn_location",
                              onPressed: _getCurrentLocation,
                              tooltip: 'Mi Ubicación',
                              backgroundColor: Theme.of(context).cardColor,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onSurface,
                              child: const Icon(Icons.my_location),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_selectionMode == SelectionMode.origin)
                            _buildActionButton(
                              heroTag: "btn_set_origin",
                              onPressed: () {
                                if (mounted) {
                                  setState(() {
                                    _originPoint = _currentCenter;
                                    _selectionMode = SelectionMode.destination;
                                  });
                                }
                              },
                              label: 'Fijar Origen',
                              icon: Icons.check,
                              color: Colors.green,
                            ),
                          if (_selectionMode == SelectionMode.destination)
                            _buildActionButton(
                              heroTag: "btn_set_destination",
                              onPressed: () {
                                if (mounted) {
                                  setState(() {
                                    _destinationPoint = _currentCenter;
                                    _selectionMode = SelectionMode.none;
                                  });
                                }
                              },
                              label: 'Fijar Destino',
                              icon: Icons.check,
                              color: Colors.red,
                            ),
                          if (_originPoint != null &&
                              _destinationPoint != null &&
                              _selectionMode == SelectionMode.none &&
                              !_showRouteInfo)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: _buildActionButton(
                                heroTag: "btn_search",
                                onPressed: _isSearching ? null : _findRoute,
                                label: _isSearching
                                    ? 'Buscando...'
                                    : 'Buscar Ruta',
                                icon: _isSearching ? null : Icons.search,
                                color: Colors.blue,
                                isLoading: _isSearching,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS DE PANEL SEPARADOS PARA MAYOR CLARIDAD ---

  Widget _buildMinimizedPanel() {
    return GestureDetector(
      key: const ValueKey('minimized'), // Key para AnimatedSwitcher
      onTap: _toggleRouteInfo,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.route,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        '${(_foundSolution!.totalWalkingDistance / 1000).toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_hasTransfer()) ...[
                        const SizedBox(width: 8),
                        _buildTransferIcon(),
                      ],
                    ],
                  ),
                  Text(
                    '${_foundSolution!.steps.length} pasos',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_up, color: Colors.grey[400], size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedPanel() {
    return Column(
      key: const ValueKey('expanded'), // Key para AnimatedSwitcher
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.route,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Tu Ruta',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (_hasTransfer()) ...[
                          const SizedBox(width: 12),
                          _buildTransferIcon(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.directions_walk,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${(_foundSolution!.totalWalkingDistance / 1000).toStringAsFixed(1)} km caminando',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down),
                onPressed: _toggleRouteInfo,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 1,
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          margin: const EdgeInsets.symmetric(horizontal: 24),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _foundSolution!.steps.length,
              itemBuilder: (context, index) {
                final step = _foundSolution!.steps[index];
                if (step.type == StepType.bus) {
                  return _buildBusInfo(step, index);
                } else {
                  return _buildWalkInfo(step);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildActionButton({
    required String heroTag,
    required VoidCallback? onPressed,
    required String label,
    IconData? icon,
    required Color color,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        heroTag: heroTag,
        onPressed: onPressed,
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : (icon != null ? Icon(icon) : null),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
    );
  }
}
