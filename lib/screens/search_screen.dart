import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
// Importamos el nuevo servicio y modelo
import 'package:rapiruta_app/api/google_search_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _searchService = GoogleSearchService(); // Usamos el nuevo servicio

  List<PlacePrediction> _results = []; // Ahora la lista es de predicciones
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (_searchController.text.length > 2) {
        _performSearch();
      } else {
        setState(() => _results = []);
      }
    });
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);
    final results = await _searchService.getAutocomplete(
      _searchController.text,
    );
    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
      });
    }
  }

  // --- NUEVA FUNCIÓN PARA SELECCIONAR UN LUGAR ---
  Future<void> _onPlaceSelected(String placeId) async {
    // Cerramos el teclado
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    // Obtenemos las coordenadas del lugar usando su placeId
    final coordinates = await _searchService.getPlaceDetails(placeId);

    if (mounted) {
      // Devolvemos las coordenadas a HomeScreen
      Navigator.of(context).pop(coordinates);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Busca una dirección o lugar...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[400]),
          ),
          style: const TextStyle(fontSize: 18),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_results.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? 'Empieza a escribir para buscar'
              : 'No se encontraron resultados',
        ),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final prediction = _results[index];
        return ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: Text(prediction.description),
          onTap: () {
            // Al tocar, llamamos a la nueva función
            _onPlaceSelected(prediction.placeId);
          },
        );
      },
    );
  }
}
