// lib/widgets/home/floating_action_buttons.dart

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:rapiruta_app/models/selection_mode.dart';

class FloatingActionButtons extends StatelessWidget {
  final Animation<double> fabAnimation;
  final Animation<double> routeInfoAnimation;
  final bool showRouteInfo;
  final bool routeInfoMinimized;
  final SelectionMode selectionMode;
  final LatLng? originPoint;
  final LatLng? destinationPoint;
  final bool isSearching;
  final VoidCallback onGetCurrentLocation;
  final VoidCallback onSetOrigin;
  final VoidCallback onSetDestination;
  final VoidCallback onFindRoute;
  final VoidCallback onResetSelection; // <-- NUEVO: El callback para limpiar

  const FloatingActionButtons({
    super.key,
    required this.fabAnimation,
    required this.routeInfoAnimation,
    required this.showRouteInfo,
    required this.routeInfoMinimized,
    required this.selectionMode,
    required this.originPoint,
    required this.destinationPoint,
    required this.isSearching,
    required this.onGetCurrentLocation,
    required this.onSetOrigin,
    required this.onSetDestination,
    required this.onFindRoute,
    required this.onResetSelection, // <-- NUEVO: Añadido al constructor
  });

  // Este widget interno no necesita cambios, está perfecto.
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

  @override
  Widget build(BuildContext context) {
    // --- NUEVO: Lógica para saber si mostrar el botón de reset ---
    final bool hasSelection = originPoint != null || destinationPoint != null;

    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedBuilder(
          animation: Listenable.merge([routeInfoAnimation, fabAnimation]),
          builder: (context, child) {
            double bottomPadding = 0;
            if (showRouteInfo) {
              bottomPadding = routeInfoMinimized
                  ? 100
                  : (MediaQuery.of(context).size.height * 0.45 + 20);
            }

            return Transform.scale(
              scale: fabAnimation.value,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // --- MODIFICADO: Agrupamos los botones de herramientas del mapa ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // --- NUEVO: Botón de Reset condicional ---
                        if (hasSelection)
                          Container(
                            margin: const EdgeInsets.only(right: 12),
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
                              heroTag: "btn_reset",
                              onPressed: onResetSelection,
                              tooltip: 'Limpiar Selección',
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                              child: const Icon(Icons.close_rounded),
                            ),
                          ),

                        // Botón de Mi Ubicación (sin cambios)
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
                            onPressed: onGetCurrentLocation,
                            tooltip: 'Mi Ubicación',
                            backgroundColor: Theme.of(context).cardColor,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onSurface,
                            child: const Icon(Icons.my_location),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // El resto de la lógica de botones se mantiene igual
                    if (selectionMode == SelectionMode.origin)
                      _buildActionButton(
                        heroTag: "btn_set_origin",
                        onPressed: onSetOrigin,
                        label: 'Fijar Origen',
                        icon: Icons.check,
                        color: Colors.green,
                      ),
                    if (selectionMode == SelectionMode.destination)
                      _buildActionButton(
                        heroTag: "btn_set_destination",
                        onPressed: onSetDestination,
                        label: 'Fijar Destino',
                        icon: Icons.check,
                        color: Colors.red,
                      ),
                    if (originPoint != null &&
                        destinationPoint != null &&
                        selectionMode == SelectionMode.none &&
                        !showRouteInfo)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: _buildActionButton(
                          heroTag: "btn_search",
                          onPressed: isSearching ? null : onFindRoute,
                          label: isSearching ? 'Buscando...' : 'Buscar Ruta',
                          icon: isSearching ? null : Icons.search,
                          color: Colors.blue,
                          isLoading: isSearching,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
