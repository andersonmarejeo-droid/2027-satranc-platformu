enum ComputerDifficulty {
  easy('Kolay', 'Yeni başlayanlar için', 1, 400, 250, 0),
  medium('Orta', 'Karşı hamleni hesaba katar', 2, 2500, 700, 0),
  hard('Zor', 'Daha fazla hamleyi değerlendirir', 3, 12000, 1400, 2),
  master('Usta', 'En kapsamlı yerel hamle hesabı', 4, 35000, 2400, 3);

  const ComputerDifficulty(
    this.label,
    this.description,
    this.searchDepth,
    this.nodeBudget,
    this.milliseconds,
    this.captureDepth,
  );
  final String label, description;
  final int searchDepth, nodeBudget, milliseconds, captureDepth;

  static ComputerDifficulty fromQuery(String? name) =>
      values.where((level) => level.name == name).firstOrNull ??
      ComputerDifficulty.medium;
}
