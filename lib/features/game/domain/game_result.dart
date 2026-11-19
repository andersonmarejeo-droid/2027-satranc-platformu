enum GameResult {
  unfinished('*', 'Kaydedilmiş pratik'),
  whiteWins('1-0', 'Beyaz kazandı'),
  blackWins('0-1', 'Siyah kazandı'),
  draw('1/2-1/2', 'Berabere');

  const GameResult(this.pgn, this.label);
  final String pgn;
  final String label;
}
