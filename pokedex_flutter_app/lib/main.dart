import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'database_service.dart';
import 'pokemon.dart';

void main() {
  runApp(const PokedexApp());
}

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokédex Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Segoe UI',
      ),
      home: const PokedexScreen(),
    );
  }
}

class PokedexScreen extends StatefulWidget {
  const PokedexScreen({super.key});

  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  final PageController _statsPageController = PageController();
  
  List<Pokemon> allBasePokemon = [];
  Map<String, List<Pokemon>> regionalForms = {};
  Map<String, Map<String, int>> generationStats = {};
  bool isLoading = true;
  String searchQuery = '';
  int currentStatsPage = 0;
  int pokemonPerRow = 5; // Default value

  @override
  void initState() {
    super.initState();
    _loadPokemon();
    _loadSettings();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _statsPageController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      pokemonPerRow = prefs.getInt('pokemonPerRow') ?? 5;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pokemonPerRow', pokemonPerRow);
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchController.text;
    });
    _loadPokemon();
  }

  Future<void> _loadPokemon() async {
    try {
      final allPokemon = await _databaseService.getAllPokemon();
      final stats = await _databaseService.getStatusCountsByGeneration();
      
      // Separate base forms and regional forms
      final baseForms = <Pokemon>[];
      final regionalFormsMap = <String, List<Pokemon>>{};
      
      for (final pokemon in allPokemon) {
        if (searchQuery.isNotEmpty && !pokemon.matchesSearch(searchQuery)) {
          continue;
        }
        
        if (pokemon.isRegionalForm) {
          final formKey = pokemon.formDisplayName;
          if (!regionalFormsMap.containsKey(formKey)) {
            regionalFormsMap[formKey] = [];
          }
          regionalFormsMap[formKey]!.add(pokemon);
        } else {
          baseForms.add(pokemon);
        }
      }
      
      // Sort base forms by Pokedex number
      baseForms.sort((a, b) => a.number.compareTo(b.number));
      
      // Sort regional forms by Pokedex number within each region
      for (final forms in regionalFormsMap.values) {
        forms.sort((a, b) => a.number.compareTo(b.number));
      }
      
      setState(() {
        allBasePokemon = baseForms;
        regionalForms = regionalFormsMap;
        generationStats = stats;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading Pokemon: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updatePokemonStatus(Pokemon pokemon) async {
    // Cycle through status: 0 -> 1 -> 2 -> 0
    final newStatus = (pokemon.status + 1) % 3;
    
    try {
      await _databaseService.updatePokemonStatus(pokemon.id, newStatus);
      
      setState(() {
        pokemon.status = newStatus;
      });
      
      // Update stats
      final stats = await _databaseService.getStatusCountsByGeneration();
      setState(() {
        generationStats = stats;
      });
    } catch (e) {
      print('Error updating Pokemon status: $e');
    }
  }

  Future<void> _exportCaptureData() async {
    try {
      final allPokemon = await _databaseService.getAllPokemon();
      
      // Create CSV content
      String csvContent = 'ID,Nom_FR,Nom_EN,Numero,Forme,Generation,Status,Status_Text\n';
      
      for (final pokemon in allPokemon) {
        final statusText = pokemon.status == 0 ? 'Non_Capture' : 
                          pokemon.status == 1 ? 'Normal' : 'Shiny';
        csvContent += '${pokemon.id},"${pokemon.nameFr}","${pokemon.nameEn}",${pokemon.number},"${pokemon.form}",${pokemon.generation},"${pokemon.status}","$statusText"\n';
      }
      
      // Request storage permission
      final permission = await Permission.storage.request();
      if (permission.isGranted || await Permission.manageExternalStorage.request().isGranted) {
        // Save to Downloads folder
        final directory = Directory('/storage/emulated/0/Download');
        if (!directory.existsSync()) {
          // Fallback to app documents directory
          final appDir = await getApplicationDocumentsDirectory();
          final file = File('${appDir.path}/pokemon_capture_data.csv');
          await file.writeAsString(csvContent);
        } else {
          final file = File('${directory.path}/pokemon_capture_data_${DateTime.now().millisecondsSinceEpoch}.csv');
          await file.writeAsString(csvContent);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fichier sauvegardé dans le dossier Téléchargements !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Fallback to old sharing method
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/pokemon_capture_data.csv');
        await file.writeAsString(csvContent);
        
        // Share the file
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Données de capture Pokédex - ${DateTime.now().toIso8601String().split('T')[0]}',
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Données exportées avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error exporting data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'export'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importCaptureData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final contents = await file.readAsString();
        
        // Parse CSV
        final lines = contents.split('\n');
        if (lines.isEmpty) return;
        
        // Skip header
        int importedCount = 0;
        for (int i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          
          final parts = line.split(',');
          if (parts.length >= 7) {
            final id = int.tryParse(parts[0]);
            final status = int.tryParse(parts[6]);
            
            if (id != null && status != null) {
              await _databaseService.updatePokemonStatus(id, status);
              importedCount++;
            }
          }
        }
        
        // Reload data
        await _loadPokemon();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Import terminé ! $importedCount Pokémon mis à jour.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error importing data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'import'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.green.withValues(alpha: 0.7); // Caught normal
      case 2:
        return Colors.yellow.withValues(alpha: 0.7); // Caught shiny
      default:
        return Colors.transparent; // Not caught
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return 'Normal';
      case 2:
        return 'Shiny';
      default:
        return 'Non capturé';
    }
  }

  void _showPokemonModal(Pokemon pokemon) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pokemon.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Image.asset(
                  pokemon.localImagePath,
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.catching_pokemon,
                      size: 100,
                      color: Colors.grey.shade400,
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Forme: ${pokemon.formDisplayName}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Génération: ${pokemon.generation}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Statut: ${_getStatusText(pokemon.status)}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Fermer'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _updatePokemonStatus(pokemon);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Changer Statut'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPokemonCard(Pokemon pokemon) {
    return GestureDetector(
      onTap: () => _updatePokemonStatus(pokemon),
      onLongPress: () => _showPokemonModal(pokemon),
      child: Container(
        decoration: BoxDecoration(
          color: _getStatusColor(pokemon.status),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Image.asset(
                  pokemon.localImagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.catching_pokemon,
                      size: 30,
                      color: Colors.grey.shade400,
                    );
                  },
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      pokemon.nameFr,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '#${pokemon.number.toString().padLeft(4, '0')}',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (pokemon.status > 0)
                      Text(
                        _getStatusText(pokemon.status),
                        style: const TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPokemonGrid(List<Pokemon> pokemon, String title, {bool isRegional = false}) {
    if (pokemon.isEmpty) return const SizedBox.shrink();
    
    // Group Pokemon by batches of 30
    final batches = <List<Pokemon>>[];
    for (int i = 0; i < pokemon.length; i += 30) {
      final end = (i + 30 < pokemon.length) ? i + 30 : pokemon.length;
      batches.add(pokemon.sublist(i, end));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '$title (${pokemon.length} Pokémon)',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...batches.asMap().entries.map((entry) {
          final batchIndex = entry.key;
          final batch = entry.value;
          
          String batchTitle;
          if (isRegional) {
            batchTitle = 'Lot ${batchIndex + 1} (${batch.length} Pokémon)';
          } else {
            final startNum = batch.first.number;
            final endNum = batch.last.number;
            batchTitle = '${startNum.toString().padLeft(4, '0')}-${endNum.toString().padLeft(4, '0')}';
          }
          
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    batchTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: pokemonPerRow,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: batch.length,
                  itemBuilder: (context, index) {
                    return _buildPokemonCard(batch[index]);
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildGlobalStatsCard() {
    int totalPokemon = 0;
    int totalCaught = 0;
    int totalNormal = 0;
    int totalShiny = 0;

    for (final stats in generationStats.values) {
      totalPokemon += stats['total'] ?? 0;
      totalNormal += stats['caught_normal'] ?? 0;
      totalShiny += stats['caught_shiny'] ?? 0;
    }
    totalCaught = totalNormal + totalShiny;
    final captureProgress = totalPokemon > 0 ? (totalCaught / totalPokemon * 100) : 0.0;
    // FIXED: Calculate shiny percentage based on total available Pokemon, not just caught ones
    final shinyProgress = totalPokemon > 0 ? (totalShiny / totalPokemon * 100) : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          const Text(
            'Statistiques Globales',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', totalPokemon.toString(), Colors.blue),
              _buildStatItem('Capturés', totalCaught.toString(), Colors.green),
              _buildStatItem('Normal', totalNormal.toString(), Colors.green.shade600),
              _buildStatItem('Shiny', totalShiny.toString(), Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          // Capture progress
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: captureProgress / 100,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Capturés: ${captureProgress.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: shinyProgress / 100,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Shiny: ${shinyProgress.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenerationStatsCard(String genName, Map<String, int> stats) {
    final total = stats['total'] ?? 0;
    final caught = (stats['caught_normal'] ?? 0) + (stats['caught_shiny'] ?? 0);
    final normalCaught = stats['caught_normal'] ?? 0;
    final shinyCaught = stats['caught_shiny'] ?? 0;
    final captureProgress = total > 0 ? (caught / total * 100) : 0.0;
    // FIXED: Calculate shiny percentage based on total available Pokemon, not just caught ones
    final shinyProgress = total > 0 ? (shinyCaught / total * 100) : 0.0;

    // Generate different colors for each generation
    final colors = [
      [Colors.red.shade50, Colors.red.shade100, Colors.red.shade200],
      [Colors.blue.shade50, Colors.blue.shade100, Colors.blue.shade200],
      [Colors.green.shade50, Colors.green.shade100, Colors.green.shade200],
      [Colors.purple.shade50, Colors.purple.shade100, Colors.purple.shade200],
      [Colors.orange.shade50, Colors.orange.shade100, Colors.orange.shade200],
      [Colors.pink.shade50, Colors.pink.shade100, Colors.pink.shade200],
      [Colors.teal.shade50, Colors.teal.shade100, Colors.teal.shade200],
      [Colors.indigo.shade50, Colors.indigo.shade100, Colors.indigo.shade200],
      [Colors.cyan.shade50, Colors.cyan.shade100, Colors.cyan.shade200],
    ];
    
    final genNumber = int.tryParse(genName.split(' ')[1]) ?? 1;
    final colorSet = colors[(genNumber - 1) % colors.length];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorSet[0], colorSet[1]],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorSet[2]),
      ),
      child: Column(
        children: [
          Text(
            genName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorSet[2],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', total.toString(), Colors.blue),
              _buildStatItem('Capturés', caught.toString(), Colors.green),
              _buildStatItem('Normal', normalCaught.toString(), Colors.green.shade600),
              _buildStatItem('Shiny', shinyCaught.toString(), Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bars
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: captureProgress / 100,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Capturés: ${captureProgress.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: shinyProgress / 100,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Shiny: ${shinyProgress.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwipableStatsCard() {
    final sortedGenerations = generationStats.entries.toList()
      ..sort((a, b) {
        final genA = int.parse(a.key.split(' ')[1]);
        final genB = int.parse(b.key.split(' ')[1]);
        return genA.compareTo(genB);
      });

    final totalPages = 1 + sortedGenerations.length; // Global + all generations

    return Column(
      children: [
        SizedBox(
          height: 220, // Increased height to fix overflow
          child: PageView.builder(
            controller: _statsPageController,
            onPageChanged: (index) {
              setState(() {
                currentStatsPage = index;
              });
            },
            itemCount: totalPages,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildGlobalStatsCard();
              } else {
                final genEntry = sortedGenerations[index - 1];
                return _buildGenerationStatsCard(genEntry.key, genEntry.value);
              }
            },
          ),
        ),
        // Page indicators
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left arrow
              IconButton(
                onPressed: currentStatsPage > 0
                    ? () {
                        _statsPageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
                icon: const Icon(Icons.arrow_back_ios),
              ),
              // Dots
              ...List.generate(totalPages, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentStatsPage == index
                        ? Colors.blue
                        : Colors.grey.shade300,
                  ),
                );
              }),
              // Right arrow
              IconButton(
                onPressed: currentStatsPage < totalPages - 1
                    ? () {
                        _statsPageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
                icon: const Icon(Icons.arrow_forward_ios),
              ),
            ],
          ),
        ),
        // Page label
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            currentStatsPage == 0
                ? 'Global (${currentStatsPage + 1}/${totalPages})'
                : '${sortedGenerations[currentStatsPage - 1].key} (${currentStatsPage + 1}/${totalPages})',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20, // Reduced font size
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10, // Reduced font size
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Rechercher un Pokémon...',
          prefixIcon: Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Paramètres'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Nombre de Pokémon par ligne :'),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [3, 4, 5, 6, 7].map((count) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        pokemonPerRow = count;
                      });
                      _saveSettings();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: pokemonPerRow == count ? Colors.blue : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          color: pokemonPerRow == count ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Pokédex Tracker 🌟',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            onPressed: _importCaptureData,
            icon: const Icon(Icons.upload),
            tooltip: 'Importer les données',
          ),
          IconButton(
            onPressed: _exportCaptureData,
            icon: const Icon(Icons.download),
            tooltip: 'Exporter les données',
          ),
          IconButton(
            onPressed: _showSettingsDialog,
            icon: const Icon(Icons.settings),
            tooltip: 'Paramètres',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildSwipableStatsCard(),
            _buildPokemonGrid(allBasePokemon, 'Pokédex National'),
            ...regionalForms.entries.map((entry) {
              final formName = entry.key;
              final pokemon = entry.value;
              return _buildPokemonGrid(pokemon, 'Formes $formName', isRegional: true);
            }).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
