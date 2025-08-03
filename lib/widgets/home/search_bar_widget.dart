// lib/widgets/home/search_bar_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rapiruta_app/providers/auth_provider.dart';
import 'package:rapiruta_app/providers/theme_provider.dart';

class SearchBarWidget extends StatelessWidget {
  final VoidCallback onSearchBarTapped;

  const SearchBarWidget({super.key, required this.onSearchBarTapped});

  // Widget interno para los botones de acción para no repetir código
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.8),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
        onPressed: onPressed,
        tooltip: tooltip,
        iconSize: 22,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usamos Consumer para reconstruir solo este widget cuando cambie el tema
    return Consumer2<ThemeProvider, AuthProvider>(
      builder: (context, themeProvider, authProvider, child) {
        // Lógica para determinar el ícono del tema (la movimos aquí)
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

        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 15,
          right: 15,
          child: GestureDetector(
            onTap: onSearchBarTapped,
            child: Container(
              padding: const EdgeInsets.only(left: 20, right: 8),
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.blueGrey),
                  const SizedBox(width: 15),
                  // Usamos Expanded para que el texto ocupe el espacio disponible
                  const Expanded(
                    child: Text(
                      '¿A dónde vas?',
                      style: TextStyle(color: Colors.blueGrey, fontSize: 18),
                    ),
                  ),

                  // --- AQUÍ ESTÁN LOS BOTONES FUSIONADOS ---
                  _buildActionButton(
                    context,
                    icon: themeIcon,
                    onPressed: () => themeProvider.cycleTheme(),
                    tooltip: 'Cambiar Estilo de Mapa',
                  ),
                  _buildActionButton(
                    context,
                    icon: Icons.logout,
                    onPressed: () => authProvider.logout(),
                    tooltip: 'Cerrar Sesión',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
