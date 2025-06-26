import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

// ==========================================================================
// Firebase Options - REPLACE WITH YOUR ACTUAL CONFIGURATION
// You can get this from your Firebase project settings.
// ==========================================================================
const FirebaseOptions firebaseOptions = FirebaseOptions(
    apiKey: "AIzaSyDfw829zgNH7WiSn5_9AJWigNYRA_4pT0k",
    authDomain: "tachtechrnr.firebaseapp.com",
    projectId: "tachtechrnr",
    storageBucket: "tachtechrnr.firebasestorage.app",
    messagingSenderId: "493072699110",
    appId: "1:493072699110:web:d6da732a0a3b06b92fb527",
    measurementId: "G-G4MFR66DE6"
);

// ==========================================================================
// Custom Color Swatch for TachTech Orange
// ==========================================================================
const MaterialColor tachtechOrange = MaterialColor(
  0xFFF05B2D,
  <int, Color>{
    50: Color(0xFFFDECEA),
    100: Color(0xFFFACFBE),
    200: Color(0xFFF7B090),
    300: Color(0xFFF49162),
    400: Color(0xFFF27941),
    500: Color(0xFFF05B2D),
    600: Color(0xFFEE5428),
    700: Color(0xFFEC4B22),
    800: Color(0xFFEA421C),
    900: Color(0xFFE63211),
  },
);

// ==========================================================================
// Main Application Entry Point
// ==========================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // IMPORTANT: Initialize Firebase with the options provided above.
  await Firebase.initializeApp(options: firebaseOptions);
  runApp(const MitreApp());
}

// ==========================================================================
// Root Application Widget - UPDATED with Dark Theme
// ==========================================================================
class MitreApp extends StatelessWidget {
  const MitreApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RiskRemediationState(),
      child: MaterialApp(
        title: 'MITRE ATT&CK Risk Remediation',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF212121),
          cardColor: const Color(0xFF303030),
          primaryColor: tachtechOrange,
          appBarTheme: const AppBarTheme(
              backgroundColor: tachtechOrange,
              foregroundColor: Colors.white
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: tachtechOrange,
                foregroundColor: Colors.white,
              )
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: tachtechOrange),
          ),
          expansionTileTheme: const ExpansionTileThemeData(
            iconColor: tachtechOrange,
            textColor: tachtechOrange,
          ),
          textTheme: const TextTheme(
            titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            bodyMedium: TextStyle(color: Colors.white70),
          ),
          dividerColor: Colors.grey[800],
          colorScheme: ColorScheme.fromSwatch(primarySwatch: tachtechOrange, brightness: Brightness.dark).copyWith(background: const Color(0xFF212121)),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// ==========================================================================
// Data Models
// ==========================================================================

/// Represents a top-level Tactic.
class Tactic {
  final String id;
  final String name;
  final String? description;
  final String? link;
  final List<Technique> techniques;
  Tactic({required this.id, required this.name, this.description, this.link, this.techniques = const []});
}

/// Represents a Technique nested under a Tactic.
class Technique {
  final String id;
  final String name;
  final String parentTacticId;
  final String? description;
  final String? link;
  List<SubTechnique> subTechniques;

  Technique({required this.id, required this.name, required this.parentTacticId, this.description, this.link, this.subTechniques = const []});
}

/// Represents a Sub-Technique.
class SubTechnique {
  final String id;
  final String name;
  final String parentTechniqueId;
  final String parentTacticId;
  final String? description;
  final String? link;

  SubTechnique({
    required this.id,
    required this.name,
    required this.parentTechniqueId,
    required this.parentTacticId,
    this.description,
    this.link
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SubTechnique && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Represents a remediation Product.
class Product {
  final String id;
  final String name;
  Product({required this.id, required this.name});
}

// ==========================================================================
// Firestore Service
// ==========================================================================
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Tactic>> getHierarchicalData() async {
    List<Tactic> finalTactics = [];
    try {
      final tacticsSnapshot = await _db.collection('MITRE ATT&CK Framework').get();

      for (final tacticDoc in tacticsSnapshot.docs) {
        final tacticData = tacticDoc.data();
        final techniquesSnapshot = await tacticDoc.reference.collection('techniques').get();

        List<Technique> parentTechniques = [];
        List<SubTechnique> subTechniques = [];

        for (var doc in techniquesSnapshot.docs) {
          final data = doc.data();
          final id = doc.id;

          if (id.contains('.')) {
            subTechniques.add(SubTechnique(
              id: id,
              name: data['name'] ?? 'Unnamed Sub-Technique',
              description: data['description'] as String?,
              link: data['link'] as String?,
              parentTacticId: tacticDoc.id,
              parentTechniqueId: id.split('.').first,
            ));
          } else {
            parentTechniques.add(Technique(
              id: id,
              name: data['name'] ?? 'Unnamed Technique',
              description: data['description'] as String?,
              link: data['link'] as String?,
              parentTacticId: tacticDoc.id,
            ));
          }
        }

        for (var parent in parentTechniques) {
          parent.subTechniques = subTechniques
              .where((sub) => sub.parentTechniqueId == parent.id)
              .toList();
        }

        finalTactics.add(Tactic(
          id: tacticDoc.id,
          name: tacticData['name'] ?? 'Unnamed Tactic',
          description: tacticData['description'] as String?,
          link: tacticData['link'] as String?,
          techniques: parentTechniques,
        ));
      }
      return finalTactics;
    } catch (e) {
      print("Error fetching hierarchical data: $e");
      return [];
    }
  }

  Future<List<Product>> getAllProducts() async {
    try {
      QuerySnapshot snapshot = await _db.collection('products').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product(id: doc.id, name: data['product_name'] ?? 'Unnamed Product');
      }).toList();
    } catch (e) {
      print("Error fetching all products: $e");
      return [];
    }
  }

  Future<List<SubTechnique>> getCoveredSubTechniques(String productId) async {
    try {
      QuerySnapshot mappingSnapshot = await _db
          .collection('product_subtechnique_mappings')
          .where('product_id', isEqualTo: productId)
          .get();

      if (mappingSnapshot.docs.isEmpty) return [];

      return mappingSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SubTechnique(
            id: data['sub_technique_id'] ?? 'Unknown ID',
            name: data['sub_technique_name'] ?? 'Unnamed Sub-Technique',
            parentTacticId: '',
            parentTechniqueId: ''
        );
      }).toList();

    } catch (e) {
      print("Error getting covered sub-techniques for product $productId: $e");
      return [];
    }
  }

  Future<List<String>> getRemediatingProductIds(List<String> subTechniqueIds) async {
    if (subTechniqueIds.isEmpty) return [];

    try {
      QuerySnapshot snapshot = await _db
          .collection('product_subtechnique_mappings')
          .where('sub_technique_id', whereIn: subTechniqueIds)
          .get();

      final productIds = snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['product_id'] as String)
          .toSet()
          .toList();

      return productIds;
    } catch (e) {
      print("Error fetching remediating product IDs: $e");
      return [];
    }
  }

  Future<List<Product>> getProductsByIds(List<String> productIds) async {
    if (productIds.isEmpty) return [];
    try {
      final snapshot = await _db.collection('products').where(FieldPath.documentId, whereIn: productIds).get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product(id: doc.id, name: data['product_name'] ?? 'Unnamed Product');
      }).toList();
    } catch (e) {
      print("Error fetching products by IDs: $e");
      return [];
    }
  }
}

// ==========================================================================
// Application State Management (Provider)
// ==========================================================================
class RiskRemediationState with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<SubTechnique> _selectedSubTechniques = [];
  List<Product> _allProducts = [];
  List<Product> _remediatingProducts = [];
  List<Tactic> _allTacticsData = [];
  String _searchQuery = "";

  bool _isLoadingProducts = false;
  bool _isLoadingTactics = false;

  List<SubTechnique> get selectedSubTechniques => _selectedSubTechniques;
  List<Product> get allProducts => _allProducts;
  List<Product> get remediatingProducts => _remediatingProducts;
  List<Tactic> get allTacticsData => _allTacticsData;
  String get searchQuery => _searchQuery;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isLoadingTactics => _isLoadingTactics;

  RiskRemediationState() {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _isLoadingTactics = true;
    _isLoadingProducts = true;
    notifyListeners();

    final results = await Future.wait([
      _firestoreService.getHierarchicalData(),
      _firestoreService.getAllProducts(),
    ]);

    _allTacticsData = results[0] as List<Tactic>;
    _allProducts = results[1] as List<Product>;

    _isLoadingTactics = false;
    _isLoadingProducts = false;
    notifyListeners();
  }

  void toggleSubTechnique(SubTechnique subTechnique) {
    if (_selectedSubTechniques.contains(subTechnique)) {
      _selectedSubTechniques.remove(subTechnique);
    } else {
      _selectedSubTechniques.add(subTechnique);
    }
    _updateRemediatingProducts();
    notifyListeners();
  }

  void clearSelection() {
    _selectedSubTechniques.clear();
    _updateRemediatingProducts();
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> _updateRemediatingProducts() async {
    _isLoadingProducts = true;
    notifyListeners();

    if (_selectedSubTechniques.isEmpty) {
      _remediatingProducts = [];
      _isLoadingProducts = false;
      notifyListeners();
      return;
    }

    final selectedIds = _selectedSubTechniques.map((st) => st.id).toList();
    final productIds = await _firestoreService.getRemediatingProductIds(selectedIds);
    _remediatingProducts = await _firestoreService.getProductsByIds(productIds);

    _isLoadingProducts = false;
    notifyListeners();
  }
}

// ==========================================================================
// Main Screen Widget - UPDATED for Mobile View
// ==========================================================================

enum MobileView { risk, remediation }

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MobileView _currentView = MobileView.risk;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MITRE ATT&CK Risk and Remediation Mapping'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // --- Desktop View ---
          if (constraints.maxWidth > 850) {
            return const Row(
              children: [
                Expanded(flex: 1, child: RiskPanel()),
                VerticalDivider(width: 1),
                Expanded(flex: 1, child: RemediationPanel()),
              ],
            );
          }

          // --- Mobile View ---
          else {
            return Column(
              children: [
                Expanded(
                  child: IndexedStack(
                    index: _currentView.index,
                    children: const [
                      RiskPanel(),
                      RemediationPanel(),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: Offset(0, -2),
                        )
                      ]
                  ),
                  child: ToggleButtons(
                    isSelected: [
                      _currentView == MobileView.risk,
                      _currentView == MobileView.remediation,
                    ],
                    onPressed: (int index) {
                      setState(() {
                        _currentView = MobileView.values[index];
                      });
                    },
                    borderRadius: BorderRadius.circular(8.0),
                    fillColor: tachtechOrange.withOpacity(0.2),
                    selectedColor: tachtechOrange,
                    constraints: BoxConstraints(
                      minWidth: (constraints.maxWidth - 40) / 2, // Ensure buttons fill space
                      minHeight: 40,
                    ),
                    children: const [
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shield_outlined), SizedBox(width: 8), Text('Risk')]),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.construction_outlined), SizedBox(width: 8), Text('Remediation')]),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}


// ==========================================================================
// Left Panel: Risk
// ==========================================================================
class RiskPanel extends StatefulWidget {
  const RiskPanel({Key? key}) : super(key: key);

  @override
  State<RiskPanel> createState() => _RiskPanelState();
}

class _RiskPanelState extends State<RiskPanel> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RiskRemediationState>(
      builder: (context, state, child) {

        List<Tactic> filteredTactics = [];
        if (state.searchQuery.isEmpty) {
          filteredTactics = state.allTacticsData;
        } else {
          final query = state.searchQuery.toLowerCase();
          for (final tactic in state.allTacticsData) {
            final List<Technique> filteredTechniques = [];
            for (final technique in tactic.techniques) {
              final List<SubTechnique> filteredSubTechniques = technique.subTechniques.where((sub) {
                return sub.name.toLowerCase().contains(query) || sub.id.toLowerCase().contains(query);
              }).toList();

              if (filteredSubTechniques.isNotEmpty || technique.name.toLowerCase().contains(query) || technique.id.toLowerCase().contains(query)) {
                filteredTechniques.add(Technique(
                    id: technique.id,
                    name: technique.name,
                    parentTacticId: technique.parentTacticId,
                    description: technique.description,
                    link: technique.link,
                    subTechniques: technique.name.toLowerCase().contains(query) ? technique.subTechniques : filteredSubTechniques
                ));
              }
            }

            if (filteredTechniques.isNotEmpty || tactic.name.toLowerCase().contains(query) || tactic.id.toLowerCase().contains(query)) {
              filteredTactics.add(Tactic(
                  id: tactic.id,
                  name: tactic.name,
                  description: tactic.description,
                  link: tactic.link,
                  techniques: tactic.name.toLowerCase().contains(query) ? tactic.techniques : filteredTechniques
              ));
            }
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Risk', style: Theme.of(context).textTheme.titleLarge),
                  if (state.selectedSubTechniques.isNotEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.clear_all, size: 20),
                      label: const Text('Clear'),
                      onPressed: state.clearSelection,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or ID...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey)
                  ),
                  isDense: true,
                  suffixIcon: state.searchQuery.isNotEmpty ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      state.updateSearchQuery('');
                    },
                  ) : null,
                ),
                onChanged: state.updateSearchQuery,
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: state.isLoadingTactics
                  ? const Center(child: CircularProgressIndicator())
                  : filteredTactics.isEmpty
                  ? const Center(child: Text('No matching techniques found.'))
                  : ListView.builder(
                itemCount: filteredTactics.length,
                itemBuilder: (context, index) {
                  final tactic = filteredTactics[index];
                  return TacticExpansionTile(tactic: tactic, searchQuery: state.searchQuery);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class TacticExpansionTile extends StatelessWidget {
  final Tactic tactic;
  final String searchQuery;
  const TacticExpansionTile({Key? key, required this.tactic, required this.searchQuery}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      key: PageStorageKey(tactic.id),
      leading: IconButton(
        icon: Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
        tooltip: 'View Description for ${tactic.id}',
        onPressed: () => _showInfoDialog(
          context: context,
          name: tactic.name,
          id: tactic.id,
          description: tactic.description,
          link: tactic.link,
        ),
      ),
      title: Text(tactic.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tactic.id, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(width: 8),
          const Icon(Icons.expand_more),
        ],
      ),
      initiallyExpanded: searchQuery.isNotEmpty,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Column(
            children: tactic.techniques.map((technique) =>
                TechniqueExpansionTile(technique: technique, searchQuery: searchQuery)
            ).toList(),
          ),
        ),
      ],
    );
  }
}

class TechniqueExpansionTile extends StatelessWidget {
  final Technique technique;
  final String searchQuery;
  const TechniqueExpansionTile({Key? key, required this.technique, required this.searchQuery}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (technique.subTechniques.isEmpty) {
      return ListTile(
        contentPadding: const EdgeInsets.only(left: 16.0, right: 16.0),
        leading: IconButton(
          icon: Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
          tooltip: 'View Description for ${technique.id}',
          onPressed: () => _showInfoDialog(
            context: context,
            name: technique.name,
            id: technique.id,
            description: technique.description,
            link: technique.link,
          ),
        ),
        title: Text(technique.name),
        trailing: Text(technique.id, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      );
    }

    return ExpansionTile(
        key: PageStorageKey(technique.id),
        leading: IconButton(
          icon: Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
          tooltip: 'View Description for ${technique.id}',
          onPressed: () => _showInfoDialog(
            context: context,
            name: technique.name,
            id: technique.id,
            description: technique.description,
            link: technique.link,
          ),
        ),
        title: Text(technique.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(technique.id, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(width: 8),
            const Icon(Icons.expand_more),
          ],
        ),
        initiallyExpanded: searchQuery.isNotEmpty,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: Column(
              children: technique.subTechniques.map((subTechnique) {
                final riskState = context.watch<RiskRemediationState>();
                final isSelected = riskState.selectedSubTechniques.contains(subTechnique);
                return ListTile(
                  leading: IconButton(
                    icon: Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                    tooltip: 'View Description for ${subTechnique.id}',
                    onPressed: () => _showInfoDialog(
                      context: context,
                      name: subTechnique.name,
                      id: subTechnique.id,
                      description: subTechnique.description,
                      link: subTechnique.link,
                    ),
                  ),
                  title: Text(subTechnique.name),
                  trailing: Text(subTechnique.id, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  dense: true,
                  tileColor: isSelected ? tachtechOrange.withOpacity(0.15) : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onTap: () {
                    context.read<RiskRemediationState>().toggleSubTechnique(subTechnique);
                  },
                );
              }).toList(),
            ),
          ),
        ]
    );
  }
}

void _showInfoDialog({
  required BuildContext context,
  required String name,
  required String id,
  required String? description,
  required String? link,
}) {
  if (description == null || description.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No description available for $id'),
          duration: const Duration(seconds: 2),
        )
    );
    return;
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        titlePadding: const EdgeInsets.all(0),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (link != null && link.isNotEmpty)
                ElevatedButton.icon(
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text('MITRE Documentation'),
                  onPressed: () async {
                    final uri = Uri.tryParse(link);
                    if (uri != null) {
                      try {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } catch (e) {
                        print("Could not launch URL: $e");
                      }
                    }
                  },
                )
              else
                const SizedBox(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
            maxWidth: MediaQuery.of(context).size.width * 0.5,
          ),
          child: SingleChildScrollView(
            child: Text(description),
          ),
        ),
      );
    },
  );
}


// ==========================================================================
// Right Panel: Remediation
// ==========================================================================
class RemediationPanel extends StatelessWidget {
  const RemediationPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<RiskRemediationState>(
      builder: (context, state, child) {
        List<Product> productsToShow;
        String message;

        if (state.selectedSubTechniques.isEmpty) {
          productsToShow = state.allProducts;
          message = 'All available products are shown below. Select a risk on the left to see specific remediations.';
        } else {
          productsToShow = state.remediatingProducts;
          if (!state.isLoadingProducts && productsToShow.isEmpty) {
            message = 'No products found that remediate the selected risks.';
          } else {
            message = 'Showing products that remediate the selected risks.';
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Remediation', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            ),
            if (state.isLoadingProducts)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: productsToShow.length,
                  itemBuilder: (context, index) {
                    final product = productsToShow[index];
                    return ProductExpansionTile(
                      product: product,
                      selectedSubTechniques: state.selectedSubTechniques,
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class ProductExpansionTile extends StatelessWidget {
  final Product product;
  final List<SubTechnique> selectedSubTechniques;

  const ProductExpansionTile({
    Key? key,
    required this.product,
    required this.selectedSubTechniques
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    return ExpansionTile(
      title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      children: [
        FutureBuilder<List<SubTechnique>>(
          future: firestoreService.getCoveredSubTechniques(product.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
              );
            }
            if (snapshot.hasError) {
              return ListTile(title: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.only(left: 32, right: 16),
                  title: Text('No covered sub-techniques found for this product.', style: TextStyle(fontStyle: FontStyle.italic))
              );
            }

            final allCoveredSubTechniques = snapshot.data!;
            List<SubTechnique> subTechniquesToShow;

            if (selectedSubTechniques.isEmpty) {
              subTechniquesToShow = allCoveredSubTechniques;
            } else {
              final selectedIds = selectedSubTechniques.map((s) => s.id).toSet();
              subTechniquesToShow = allCoveredSubTechniques
                  .where((covered) => selectedIds.contains(covered.id))
                  .toList();
            }

            subTechniquesToShow.sort((a, b) => a.name.compareTo(b.name));

            return Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                children: subTechniquesToShow.map((st) => ListTile(
                  title: Text(st.name),
                  subtitle: Text(st.id),
                  dense: true,
                )).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}
