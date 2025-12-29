// planb_game.dart
// Core rules for the game "Plan B" (reworked Second Best).
// Board: 8 positions in a ring, stacks up to 3 pieces.

const int boardSize = 8;
const int maxStackHeight = 3;

enum PlanBMode { casual, noMercy }

enum Player { a, b }

enum MoveType { place, move }

class Move {
  final MoveType type;
  final int toIndex;
  final int? fromIndex; // only used for MoveType.move

  const Move.place(this.toIndex)
      : type = MoveType.place,
        fromIndex = null;

  const Move.move({required this.fromIndex, required this.toIndex})
      : type = MoveType.move;

  @override
  String toString() {
    switch (type) {
      case MoveType.place:
        return 'Place at $toIndex';
      case MoveType.move:
        return 'Move from $fromIndex to $toIndex';
    }
  }
}

bool _isRedoTurnFor(GameState s, Player p) {
  if (s.currentPlayer != p) return false;
  return p == Player.a ? s.pendingAcceptForA : s.pendingAcceptForB;
}

// Equality for moves so we can compare/forbid repeats
bool _moveEquals(Move? a, Move? b) {
  if (a == null || b == null) return false;
  return a.type == b.type && a.toIndex == b.toIndex && (a.fromIndex ?? -1) == (b.fromIndex ?? -1);
}

class StackColumn {
  final List<Player> pieces;

  StackColumn(List<Player> pieces) : pieces = List.unmodifiable(pieces);

  bool get isEmpty => pieces.isEmpty;
  int get height => pieces.length;
  Player? get top => isEmpty ? null : pieces.last;

  StackColumn addTop(Player p) {
    if (height >= maxStackHeight) {
      throw StateError('Stack already at max height');
    }
    final next = List<Player>.from(pieces)..add(p);
    return StackColumn(next);
  }

  StackColumn removeTop() {
    if (isEmpty) {
      throw StateError('No pieces to remove');
    }
    final next = List<Player>.from(pieces)..removeLast();
    return StackColumn(next);
  }
}

class GameState {
  final List<StackColumn> board; // length = 8
  final int reserveA;
  final int reserveB;
  final Player currentPlayer;
  final GameState? lastState; // for Plan B rewind
  final bool planBUsedByA; // "has A used Plan B this opponent turn?"
  final bool planBUsedByB;
  final Move? forbiddenMoveForA; // move A is forbidden to play (used to block repeats after Plan B)
  final Move? forbiddenMoveForB;
  // If a Plan B was just used, record the fingerprint of the position that
  // was undone (the "origin"). The opponent's next move must be accepted
  // (cannot be Plan B'd) unless that move results in exactly this origin
  // position — in that special case the opponent may still use Plan B.
  final String? planBOriginFingerprint;
  final bool pendingAcceptForA;
  final bool pendingAcceptForB;
  final Player? lastPlanBUsedBy;

  GameState({
    required this.board,
    required this.reserveA,
    required this.reserveB,
    required this.currentPlayer,
    required this.lastState,
    required this.planBUsedByA,
    required this.planBUsedByB,
    this.forbiddenMoveForA,
    this.forbiddenMoveForB,
    this.planBOriginFingerprint,
    this.pendingAcceptForA = false,
    this.pendingAcceptForB = false,
    this.lastPlanBUsedBy,
  }) : assert(board.length == boardSize);

  factory GameState.initial() {
    return GameState(
      board: List<StackColumn>.generate(
        boardSize,
        (_) => StackColumn(const []),
      ),
      reserveA: 8,
      reserveB: 8,
      currentPlayer: Player.a,
      lastState: null,
      planBUsedByA: false,
      planBUsedByB: false,
        forbiddenMoveForA: null,
        forbiddenMoveForB: null,
        planBOriginFingerprint: null,
        pendingAcceptForA: false,
        pendingAcceptForB: false,
        lastPlanBUsedBy: null,
    );
  }

  GameState copyWith({
    List<StackColumn>? board,
    int? reserveA,
    int? reserveB,
    Player? currentPlayer,
    GameState? lastState,
    bool? planBUsedByA,
    bool? planBUsedByB,
    Move? forbiddenMoveForA,
    Move? forbiddenMoveForB,
    bool? pendingAcceptForA,
    bool? pendingAcceptForB,
    Player? lastPlanBUsedBy,
  }) {
    return GameState(
      board: board ?? this.board,
      reserveA: reserveA ?? this.reserveA,
      reserveB: reserveB ?? this.reserveB,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      lastState: lastState ?? this.lastState,
      planBUsedByA: planBUsedByA ?? this.planBUsedByA,
      planBUsedByB: planBUsedByB ?? this.planBUsedByB,
      forbiddenMoveForA: forbiddenMoveForA ?? this.forbiddenMoveForA,
      forbiddenMoveForB: forbiddenMoveForB ?? this.forbiddenMoveForB,
      pendingAcceptForA: pendingAcceptForA ?? this.pendingAcceptForA,
      pendingAcceptForB: pendingAcceptForB ?? this.pendingAcceptForB,
      lastPlanBUsedBy: lastPlanBUsedBy ?? this.lastPlanBUsedBy,
    );
  }

  int reserveOf(Player p) => p == Player.a ? reserveA : reserveB;

  GameState setReserve(Player p, int value) {
    return (p == Player.a)
        ? copyWith(reserveA: value)
        : copyWith(reserveB: value);
  }
}

// ---------- helpers ----------

int oppositeIndex(int i) => (i + 4) % boardSize;

List<int> adjacentIndices(int i) {
  final left = (i - 1 + boardSize) % boardSize;
  final right = (i + 1) % boardSize;
  return [left, right, oppositeIndex(i)];
}

// ---------- legal move generation ----------

List<Move> listLegalMoves(GameState state, Player player) {
  final moves = <Move>[];
  final reserve = state.reserveOf(player);

  if (reserve > 0) {
    // Place on any stack with space
    for (var i = 0; i < boardSize; i++) {
      if (state.board[i].height < maxStackHeight) {
        moves.add(Move.place(i));
      }
    }
  } else {
    // Move top piece of this player to adjacent/opposite stacks with space
    for (var i = 0; i < boardSize; i++) {
      final stack = state.board[i];
      if (stack.top != player) continue;

      for (final j in adjacentIndices(i)) {
        if (state.board[j].height < maxStackHeight) {
          moves.add(Move.move(fromIndex: i, toIndex: j));
        }
      }
    }
  }

    // Filter out any forbidden destination for this player (prevents replaying the undone spot after Plan B)
    final forbidden =
      player == Player.a ? state.forbiddenMoveForA : state.forbiddenMoveForB;

  if (forbidden != null && _isRedoTurnFor(state, player)) {
    final forbiddenTo = forbidden.toIndex;
    moves.removeWhere((m) => m.toIndex == forbiddenTo);
  }

  return moves;
}

// ---------- applying a move ----------

GameState applyMove(GameState state, Move move) {
  final player = state.currentPlayer;

  final wasRedoTurn = player == Player.a
      ? state.pendingAcceptForA
      : state.pendingAcceptForB;

  // Deep copy board
  final newBoard = state.board
      .map((c) => StackColumn(List<Player>.from(c.pieces)))
      .toList();

  var nextState = state.copyWith(board: newBoard, lastState: state);

  if (move.type == MoveType.place) {
    final reserve = nextState.reserveOf(player);
    if (reserve <= 0) {
      throw StateError('No reserve pieces left');
    }
    final col = nextState.board[move.toIndex];
    nextState.board[move.toIndex] = col.addTop(player);
    nextState = nextState.setReserve(player, reserve - 1);
  } else {
    final from = move.fromIndex!;
    final fromCol = nextState.board[from];
    if (fromCol.top != player) {
      throw StateError('No movable piece for $player at $from');
    }
    final toCol = nextState.board[move.toIndex];
    if (toCol.height >= maxStackHeight) {
      throw StateError('Destination stack full');
    }

    nextState.board[from] = fromCol.removeTop();
    nextState.board[move.toIndex] = toCol.addTop(player);
  }

  final nextPlayer = player == Player.a ? Player.b : Player.a;

  final switchingBackToPlanBUser =
      state.lastPlanBUsedBy != null && state.lastPlanBUsedBy == nextPlayer;

  // Keep lastPlanBUsedBy until the Plan B user makes their own next move.
  // That prevents "double Plan B" on the forced redo move.
  final updatedLastPlanBUsedBy =
      (state.lastPlanBUsedBy != null && state.lastPlanBUsedBy == player)
          ? null
          : state.lastPlanBUsedBy;

  // Reset planBUsedBy flags in two cases:
  // 1. When the current player accepts opponent's Plan B (wasRedoTurn)
  // 2. When the opponent completes their redo turn and it's switching back
  final resetPlanBForA = wasRedoTurn && player == Player.b;
  final resetPlanBForB = wasRedoTurn && player == Player.a;
  
  // Also reset when switching away from a player who just completed their redo
  // (their pendingAccept was true, now switching away from them)
  final playerAJustCompletedRedo = !wasRedoTurn && player == Player.a && state.pendingAcceptForA;
  final playerBJustCompletedRedo = !wasRedoTurn && player == Player.b && state.pendingAcceptForB;

  final switched = nextState.copyWith(
    currentPlayer: nextPlayer,
    planBUsedByA: resetPlanBForA || playerAJustCompletedRedo
        ? false
        : (nextPlayer == Player.a
            ? (switchingBackToPlanBUser ? nextState.planBUsedByA : false)
            : nextState.planBUsedByA),
    planBUsedByB: resetPlanBForB || playerBJustCompletedRedo
        ? false
        : (nextPlayer == Player.b
            ? (switchingBackToPlanBUser ? nextState.planBUsedByB : false)
            : nextState.planBUsedByB),
    forbiddenMoveForA: null,
    forbiddenMoveForB: null,
    lastPlanBUsedBy: updatedLastPlanBUsedBy,
  );

  nextState = switched;

  if (wasRedoTurn) {
    nextState = nextState.copyWith(
      pendingAcceptForA: false,
      pendingAcceptForB: false,
    );
  }

  return nextState;
}

// ---------- Plan B! mechanic ----------

bool canUsePlanB(GameState state, Player player, [PlanBMode mode = PlanBMode.casual]) {
  if (state.currentPlayer != player) return false;

  final base = player == Player.a ? !state.planBUsedByA : !state.planBUsedByB;
  if (!base) return false;

  if (state.lastPlanBUsedBy != null && state.lastPlanBUsedBy == player) return false;

  // ✅ no Plan B during redo move
  if (_isRedoTurnFor(state, player)) return false;

  if (mode == PlanBMode.noMercy && state.lastState != null) {
    final lastMover = state.lastState!.currentPlayer;
    final winner = checkWinner(state, lastMover);
    if (winner == lastMover) return false;
  }

  return true;
}


GameState usePlanB(GameState state, Player player, [PlanBMode mode = PlanBMode.casual]) {
  if (!canUsePlanB(state, player, mode)) {
    throw StateError('Plan B already used this opponent turn');
  }
  if (state.lastState == null) {
    throw StateError('No previous state to rewind to');
  }

  final prev = state.lastState!; // state before the last move
  // Infer the move that transformed `prev` -> `state` so we can forbid it for the next player
  Move? undone;
  // Helper: find height changes
  int? increasedIndex;
  int? decreasedIndex;
  for (var i = 0; i < boardSize; i++) {
    final hPrev = prev.board[i].height;
    final hNext = state.board[i].height;
    if (hNext > hPrev) {
      if (increasedIndex == null) increasedIndex = i; else increasedIndex = -1; // multiple
    }
    if (hNext < hPrev) {
      if (decreasedIndex == null) decreasedIndex = i; else decreasedIndex = -1;
    }
  }

  // Check reserves for a place move
  if (state.reserveA < prev.reserveA) {
    // Player A placed somewhere
    if (increasedIndex != null && increasedIndex >= 0) {
      undone = Move.place(increasedIndex);
    }
  } else if (state.reserveB < prev.reserveB) {
    if (increasedIndex != null && increasedIndex >= 0) {
      undone = Move.place(increasedIndex);
    }
  } else {
    // Otherwise it's a move from decreasedIndex -> increasedIndex
    if (decreasedIndex != null && increasedIndex != null && decreasedIndex >= 0 && increasedIndex >= 0) {
      undone = Move.move(fromIndex: decreasedIndex, toIndex: increasedIndex);
    }
  }
  // Record fingerprint of the position we are undoing so that the special
  // accept rule can inspect the opponent's next move.
  final originFp = _fingerprint(state);
    var reverted = prev;

  if (player == Player.a) {
  reverted = reverted.copyWith(
    planBUsedByA: true,
    forbiddenMoveForB: undone,
    forbiddenMoveForA: null,
    pendingAcceptForB: true,
    pendingAcceptForA: false,
    lastPlanBUsedBy: Player.a,
  );
} else {
  reverted = reverted.copyWith(
    planBUsedByB: true,
    forbiddenMoveForA: undone,
    forbiddenMoveForB: null,
    pendingAcceptForA: true,
    pendingAcceptForB: false,
    lastPlanBUsedBy: Player.b,
  );
}

  // Debug: announce Plan B usage and resulting flags
  // ignore: avoid_print
  print('[PlanB] usePlanB: player=$player undone=$undone originFp=$originFp -> planBUsedByA=${reverted.planBUsedByA} planBUsedByB=${reverted.planBUsedByB} pendingA=${reverted.pendingAcceptForA} pendingB=${reverted.pendingAcceptForB} forbiddenA=${reverted.forbiddenMoveForA} forbiddenB=${reverted.forbiddenMoveForB}');

  return reverted;
}

// ---------- win checking ----------

bool _hasFourInRow(GameState state, Player player) {
  // Look at top pieces only
  final tops = List<Player?>.generate(
    boardSize,
    (i) => state.board[i].top,
  );

  for (var start = 0; start < boardSize; start++) {
    var ok = true;
    for (var offset = 0; offset < 4; offset++) {
      final idx = (start + offset) % boardSize;
      if (tops[idx] != player) {
        ok = false;
        break;
      }
    }
    if (ok) return true;
  }
  return false;
}

bool _hasTripleStack(GameState state, Player player) {
  for (final col in state.board) {
    if (col.height == 3 &&
        col.pieces.every((p) => p == player)) {
      return true;
    }
  }
  return false;
}

// Simple fingerprint for a game state: include reserves and compact board layout.
String _fingerprint(GameState s) {
  final b = StringBuffer();
  b.write('A${s.reserveA}B${s.reserveB}|');
  for (final col in s.board) {
    if (col.isEmpty) {
      b.write('0');
    } else {
      b.write(col.pieces.map((p) => p == Player.a ? 'a' : 'b').join());
    }
    b.write(',');
  }
  return b.toString();
}

/// Returns the winner if any, given the [lastMover].
/// Call this *after* applying a move and after any Plan B! chance is over.
Player? checkWinner(GameState state, Player lastMover) {
  if (_hasFourInRow(state, lastMover) ||
      _hasTripleStack(state, lastMover)) {
    return lastMover;
  }
  return null;
}

bool hasAnyMove(GameState state, Player player) {
  return listLegalMoves(state, player).isNotEmpty;
}