// lib/main.dart
import 'package:flutter/material.dart';
import 'mitre_data.dart'; // Import our data model

//##############################################################################
//# MAIN APPLICATION SETUP
//##############################################################################
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define your primary color once
    const Color myPrimaryColor = Color(0xFF003366);
    const Color mySecondaryColor = Color(0xFF4A90E2);

    return MaterialApp(
      title: 'Sales Tool Prototype',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey, // Still useful for M2 components if any linger
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: myPrimaryColor, // Use the defined color
          brightness: Brightness.light,
          primary: myPrimaryColor,    // Use the defined color
          secondary: mySecondaryColor, // Use the defined color
        ),
        cardTheme: CardThemeData(
          elevation: 1.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            // Use the defined color directly
            borderSide: BorderSide(color: myPrimaryColor, width: 2.0),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        ),
      ),
      home: const SalesDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}
//##############################################################################
//# MAIN DASHBOARD WIDGET (STATEFUL)
//##############################################################################
class SalesDashboard extends StatefulWidget {
  const SalesDashboard({super.key});

  @override
  State<SalesDashboard> createState() => _SalesDashboardState();
}

class _SalesDashboardState extends State<SalesDashboard> {
  late Tactic _reconnaissanceData;
  final TextEditingController _riskSearchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Deep copy of the sample data
    _reconnaissanceData = Tactic(
      name: reconnaissanceTactic.name,
      isExpanded: reconnaissanceTactic.isExpanded,
      techniques: reconnaissanceTactic.techniques.map((tech) {
        return Technique(
          id: tech.id,
          name: tech.name,
          isExpanded: tech.isExpanded,
          subTechniques: tech.subTechniques.map((sub) => SubTechnique(id: sub.id, name: sub.name)).toList(),
        );
      }).toList(),
    );

    _riskSearchController.addListener(() {
      setState(() {
        _searchQuery = _riskSearchController.text;
      });
    });
  }

  @override
  void dispose() {
    _riskSearchController.dispose();
    super.dispose();
  }

  void _toggleTacticExpansion() {
    setState(() {
      _reconnaissanceData.isExpanded = !_reconnaissanceData.isExpanded;
    });
  }

  void _toggleTechniqueExpansion(int techniqueIndex) {
    // Ensure the techniqueIndex is valid for the current _reconnaissanceData.techniques list
    if (techniqueIndex >= 0 && techniqueIndex < _reconnaissanceData.techniques.length) {
      setState(() {
        _reconnaissanceData.techniques[techniqueIndex].isExpanded =
        !_reconnaissanceData.techniques[techniqueIndex].isExpanded;
      });
    } else {
      // This case might occur if the displayed list of techniques is filtered
      // and the index passed doesn't align with the original list.
      // We need to find the technique by ID from the original list if the displayed list is a filtered subset.
      // However, the current _getFilteredTechniques logic passes the original index, so this path might be less likely.
      // For now, this defensive check is good.
      // print("Warning: Attempted to toggle technique with an out-of-bounds index: $techniqueIndex");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cybersecurity Sales Navigator'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: RisksPanel(
              tactic: _reconnaissanceData, // Pass the original, mutable data
              searchController: _riskSearchController,
              searchQuery: _searchQuery,
              onTacticToggle: _toggleTacticExpansion,
              onTechniqueToggle: _toggleTechniqueExpansion,
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          const Expanded(
            flex: 3,
            child: RemediationPanel(),
          ),
        ],
      ),
    );
  }
}

//##############################################################################
//# RISKS PANEL WIDGET (LEFT SIDE)
//##############################################################################
class RisksPanel extends StatelessWidget {
  final Tactic tactic; // This is the original, stateful tactic data
  final TextEditingController searchController;
  final String searchQuery;
  final VoidCallback onTacticToggle;
  final Function(int) onTechniqueToggle; // Expects original index

  const RisksPanel({
    super.key,
    required this.tactic,
    required this.searchController,
    required this.searchQuery,
    required this.onTacticToggle,
    required this.onTechniqueToggle,
  });

  /// Filters techniques and their sub-techniques based on the search query.
  /// Returns a list of Technique objects that match the criteria.
  /// If a technique itself matches, all its original sub-techniques are included.
  /// If a technique doesn't match but some sub-techniques do, a new technique
  /// object is created with only those matching sub-techniques.
  List<Technique> _getFilteredTechniques() {
    if (searchQuery.isEmpty) {
      // If no search query, return all techniques from the original data
      return tactic.techniques;
    }

    final String lowerCaseQuery = searchQuery.toLowerCase();
    List<Technique> filteredTechniques = [];

    for (var originalTechnique in tactic.techniques) {
      bool techniqueItselfMatches =
          originalTechnique.name.toLowerCase().contains(lowerCaseQuery) ||
              originalTechnique.id.toLowerCase().contains(lowerCaseQuery);

      List<SubTechnique> matchingSubTechniques = originalTechnique.subTechniques
          .where((sub) {
        return sub.name.toLowerCase().contains(lowerCaseQuery) ||
            sub.id.toLowerCase().contains(lowerCaseQuery);
      }).toList();

      if (techniqueItselfMatches) {
        // If the technique itself matches, include it with ALL its original sub-techniques.
        // The display of these sub-techniques will be further filtered by _buildTechniqueItem if needed.
        filteredTechniques.add(Technique(
          id: originalTechnique.id,
          name: originalTechnique.name,
          subTechniques: originalTechnique.subTechniques,
          // Use all original sub-techniques
          isExpanded: originalTechnique.isExpanded, // Preserve expansion state
        ));
      } else if (matchingSubTechniques.isNotEmpty) {
        // If the technique itself does NOT match, but some of its sub-techniques DO,
        // include the technique but with ONLY the matching sub-techniques.
        filteredTechniques.add(Technique(
          id: originalTechnique.id,
          name: originalTechnique.name,
          subTechniques: matchingSubTechniques, // Only matching sub-techniques
          isExpanded: true, // Automatically expand if sub-techniques matched
        ));
      }
    }
    return filteredTechniques;
  }


  @override
  Widget build(BuildContext context) {
    // Get the list of techniques to display based on current search query
    final List<Technique> techniquesToDisplay = _getFilteredTechniques();

    // Determine if the tactic header itself should be shown.
    // Show if search is empty, or if there are techniques to display after filtering.
    bool showTacticHeader = searchQuery.isEmpty ||
        techniquesToDisplay.isNotEmpty;


    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Risks',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12.0),
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search by Name or MITRE ID...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () => searchController.clear(),
              )
                  : null,
            ),
          ),
          const SizedBox(height: 16.0),
          if (showTacticHeader) // Only show tactic if relevant
            Expanded(
              child: ListView(
                children: [
                  _buildTacticItem(context, tactic, techniquesToDisplay),
                ],
              ),
            )
          else // Show a message if search yields no results for this tactic
            const Expanded(
                child: Center(child: Text('No matching risks found.'))
            ),
        ],
      ),
    );
  }

  Widget _buildTacticItem(BuildContext context, Tactic originalTacticData,
      List<Technique> techniquesToRender) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(originalTacticData.name, style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18)),
            trailing: (originalTacticData.techniques.isEmpty)
                ? null
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Display count of techniques being rendered vs original total
                Text(searchQuery.isEmpty
                    ? '(${originalTacticData.techniques.length})'
                    : '(${techniquesToRender.length}/${originalTacticData
                    .techniques.length})'),
                Icon(originalTacticData.isExpanded ? Icons.expand_less : Icons
                    .expand_more),
              ],
            ),
            onTap: (originalTacticData.techniques.isEmpty)
                ? null
                : onTacticToggle,
            tileColor: Colors.blueGrey[50],
          ),
          if (originalTacticData.isExpanded && techniquesToRender.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                  left: 16.0, bottom: 8.0, right: 8.0),
              child: Column(
                children: techniquesToRender.map((techniqueToRender) {
                  // Find the original index of this technique in the main tactic data
                  // This is crucial for the onTechniqueToggle callback to modify the correct item's state
                  final originalIndex = originalTacticData.techniques
                      .indexWhere((origTech) =>
                  origTech.id == techniqueToRender.id);
                  if (originalIndex != -1) {
                    // Pass the technique *from the original data* to ensure its expansion state is correctly read and modified
                    return _buildTechniqueItem(
                        context, originalTacticData.techniques[originalIndex],
                        techniqueToRender.subTechniques, originalIndex);
                  }
                  return const SizedBox
                      .shrink(); // Should not happen if logic is correct
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTechniqueItem(BuildContext context,
      Technique originalTechniqueData,
      List<SubTechnique> subTechniquesToPotentiallyRender,
      int originalTechniqueIndex) {
    // If a search query is active, subTechniquesToPotentiallyRender ALREADY CONTAINS
    // the correct list of sub-techniques determined by _getFilteredTechniques.
    // - If originalTechniqueData itself matched the searchQuery, subTechniquesToPotentiallyRender will be ALL of its original sub-techniques.
    // - If originalTechniqueData did NOT match, but some of its sub-techniques did,
    //   subTechniquesToPotentiallyRender will be ONLY those matching sub-techniques.

    // Therefore, when searchQuery is not empty, subTechniquesToDisplay should directly be subTechniquesToPotentiallyRender.
    // The previous .where() clause here was re-filtering this already-correct list with the original searchQuery,
    // which caused issues when the searchQuery matched the parent technique's name but not the sub-techniques' names/IDs.

    final List<SubTechnique> subTechniquesToDisplay = searchQuery.isEmpty
        ? originalTechniqueData
        .subTechniques // If no search, show all original sub-techniques of this technique
        : subTechniquesToPotentiallyRender; // If search is active, display the sub-techniques already determined by _getFilteredTechniques

    return Tooltip(
      message: 'ID: ${originalTechniqueData.id}',
      waitDuration: const Duration(milliseconds: 500),
      child: Card(
        margin: const EdgeInsets.only(top: 8.0, left: 8.0),
        elevation: 1.0,
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(originalTechniqueData.name),
              trailing: (originalTechniqueData.subTechniques.isEmpty)
                  ? null
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(searchQuery.isEmpty || !originalTechniqueData.isExpanded
                      ? '(${originalTechniqueData.subTechniques.length})'
                      : '(${subTechniquesToDisplay
                      .length}/${originalTechniqueData.subTechniques.length})'),
                  Icon(originalTechniqueData.isExpanded
                      ? Icons.expand_less
                      : Icons.expand_more),
                ],
              ),
              onTap: (originalTechniqueData.subTechniques.isEmpty)
                  ? null
                  : () => onTechniqueToggle(originalTechniqueIndex),
              visualDensity: VisualDensity.compact,
            ),
            if (originalTechniqueData.isExpanded &&
                subTechniquesToDisplay.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                    left: 24.0, bottom: 8.0, right: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: subTechniquesToDisplay.map((subTechnique) {
                    return Tooltip(
                      message: 'ID: ${subTechnique.id}',
                      waitDuration: const Duration(milliseconds: 500),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(subTechnique.name,
                            style: TextStyle(color: Colors.grey[700])),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
//##############################################################################
//# REMEDIATION PANEL WIDGET (RIGHT SIDE)
//##############################################################################
class RemediationPanel extends StatelessWidget {
  const RemediationPanel({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Remediation', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12.0),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search Remediation Solutions...',
              prefixIcon: const Icon(Icons.search, size: 20),
            ),
          ),
          const SizedBox(height: 20.0),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security_rounded, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Select a risk to see remediation details.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}