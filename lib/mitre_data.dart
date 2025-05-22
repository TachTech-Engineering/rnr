// lib/mitre_data.dart

//##############################################################################
//# DATA MODELS FOR MITRE ATT&CK FRAMEWORK ELEMENTS
//##############################################################################

/// Represents a sub-technique within the MITRE ATT&CK framework.
class SubTechnique {
  final String id; // e.g., "T1595.001"
  final String name;

  SubTechnique({
    required this.id,
    required this.name,
  });
}

/// Represents a technique within the MITRE ATT&CK framework.
class Technique {
  final String id; // e.g., "T1595"
  final String name;
  final List<SubTechnique> subTechniques;
  bool isExpanded; // Manages the expansion state in the UI

  Technique({
    required this.id,
    required this.name,
    this.subTechniques = const [],
    this.isExpanded = false,
  });
}

/// Represents a tactic within the MITRE ATT&CK framework.
class Tactic {
  final String name; // e.g., "Reconnaissance"
  final List<Technique> techniques;
  bool isExpanded; // Manages the expansion state in the UI

  Tactic({
    required this.name,
    this.techniques = const [],
    this.isExpanded = false,
  });
}

//##############################################################################
//# SAMPLE DATA (FOCUSING ON RECONNAISSANCE TACTIC)
//##############################################################################

final Tactic reconnaissanceTactic = Tactic(
  name: 'Reconnaissance',
  techniques: [
    Technique(
      id: 'T1595',
      name: 'Active Scanning',
      subTechniques: [
        SubTechnique(id: 'T1595.001', name: 'Scanning IP Blocks'),
        SubTechnique(id: 'T1595.002', name: 'Vulnerability Scanning'),
        SubTechnique(id: 'T1595.003', name: 'Wordlist Scanning'),
      ],
    ),
    Technique(
      id: 'T1592',
      name: 'Gather Victim Host Information',
      subTechniques: [
        SubTechnique(id: 'T1592.001', name: 'Hardware'),
        SubTechnique(id: 'T1592.002', name: 'Software'),
        SubTechnique(id: 'T1592.003', name: 'Firmware'),
        SubTechnique(id: 'T1592.004', name: 'Client Configurations'),
      ],
    ),
    Technique(
      id: 'T1590',
      name: 'Gather Victim Network Information',
      subTechniques: [
        SubTechnique(id: 'T1590.001', name: 'Domain Properties'),
        SubTechnique(id: 'T1590.002', name: 'DNS'),
        SubTechnique(id: 'T1590.003', name: 'Network Trust Dependencies'),
        SubTechnique(id: 'T1590.004', name: 'Network Topology'),
        SubTechnique(id: 'T1590.005', name: 'IP Addresses'),
        SubTechnique(id: 'T1590.006', name: 'Network Security Appliances'),
      ],
    ),
    Technique(
        id: 'T1589',
        name: 'Gather Victim Identity Information',
        subTechniques: [
          SubTechnique(id: 'T1589.001', name: 'Email Addresses'),
          SubTechnique(id: 'T1589.002', name: 'Credentials'),
          SubTechnique(id: 'T1589.003', name: 'Employee Names'),
        ]
    ),
    Technique(
      id: 'T1598',
      name: 'Phishing for Information',
    ),
  ],
);