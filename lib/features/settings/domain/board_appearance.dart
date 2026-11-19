enum BoardViewMode { flat, overhead, table3d, wizard3d }

enum BoardStyle {
  walnut,
  oak,
  marble,
  slate,
  artisanWalnut,
  creamMarble,
  meadow,
  candy,
  ocean,
  lavender,
  blackWhite,
}

enum PieceStyle {
  classic,
  porcelain,
  bronze,
  coralBlue,
  berryMint,
  sunViolet,
  blackWhite,
}

enum BoardCamera { low, balanced, high }

enum PieceShape { classic, carved }

class BoardAppearance {
  const BoardAppearance({
    this.view = BoardViewMode.table3d,
    this.board = BoardStyle.walnut,
    this.pieces = PieceStyle.classic,
    this.camera = BoardCamera.balanced,
    this.shape = PieceShape.classic,
    this.showLegalMoves = false,
  });
  final BoardViewMode view;
  final BoardStyle board;
  final PieceStyle pieces;
  final BoardCamera camera;
  final PieceShape shape;
  final bool showLegalMoves;

  BoardAppearance copyWith({
    BoardViewMode? view,
    BoardStyle? board,
    PieceStyle? pieces,
    BoardCamera? camera,
    PieceShape? shape,
    bool? showLegalMoves,
  }) => BoardAppearance(
    view: view ?? this.view,
    board: board ?? this.board,
    pieces: pieces ?? this.pieces,
    camera: camera ?? this.camera,
    shape: shape ?? this.shape,
    showLegalMoves: showLegalMoves ?? this.showLegalMoves,
  );

  Map<String, dynamic> toJson() => {
    'version': 2,
    'view': view.name,
    'board': board.name,
    'pieces': pieces.name,
    'camera': camera.name,
    'shape': shape.name,
    'showLegalMoves': showLegalMoves,
  };

  factory BoardAppearance.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1 && json['version'] != 2) {
      return const BoardAppearance();
    }
    T parse<T extends Enum>(List<T> values, Object? value, T fallback) =>
        values.firstWhere((item) => item.name == value, orElse: () => fallback);
    return BoardAppearance(
      view: parse(BoardViewMode.values, json['view'], BoardViewMode.table3d),
      board: parse(BoardStyle.values, json['board'], BoardStyle.walnut),
      pieces: parse(PieceStyle.values, json['pieces'], PieceStyle.classic),
      camera: parse(BoardCamera.values, json['camera'], BoardCamera.balanced),
      shape: parse(PieceShape.values, json['shape'], PieceShape.classic),
      showLegalMoves: json['version'] == 2 && json['showLegalMoves'] is bool
          ? json['showLegalMoves'] as bool
          : false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BoardAppearance &&
      view == other.view &&
      board == other.board &&
      pieces == other.pieces &&
      camera == other.camera &&
      shape == other.shape &&
      showLegalMoves == other.showLegalMoves;
  @override
  int get hashCode =>
      Object.hash(view, board, pieces, camera, shape, showLegalMoves);
}

abstract interface class BoardAppearanceRepository {
  Future<BoardAppearance> load();
  Future<void> save(BoardAppearance appearance);
}
