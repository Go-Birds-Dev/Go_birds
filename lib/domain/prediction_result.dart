/// One class with score from the classifier.
class ScoredLabel {
  const ScoredLabel({
    required this.scientificName,
    required this.commonName,
    required this.probability,
    required this.rank,
  });

  final String scientificName;
  final String commonName;
  final double probability;
  final int rank;
}

/// Top-k prediction output plus optional debug preview path.
class PredictionResult {
  const PredictionResult({
    required this.topLabels,
    required this.formattedSummary,
    this.topScientificName,
  });

  final List<ScoredLabel> topLabels;

  /// Human-readable block (legacy UI).
  final String formattedSummary;

  /// Scientific name of top-1 (for reference asset lookup).
  final String? topScientificName;
}
