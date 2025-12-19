// lib/ai/planb_ai.dart
import 'dart:math';
import '../planb_game.dart';

enum Difficulty { easy, normal, hard, expert }

final _rng = Random();

const int _winBase = 100000;
const int _noMovePenalty = 80000;

int _nodesLeft = 0; // global node budget for alpha-beta

class _SearchResult {
  final Move move;
  final int score;
  const _SearchResult(this.move, this.score);
}

int _nodeBudgetForDepth(int depth) {
  if (depth <= 3) return 8000;
  if (depth <= 5) return 22000;
  return 40000; // deeper searches (Expert)
}

/// Main CPU move selector
Move? chooseCpuMove(
  GameState state,
  Player cpuPlayer,
  Difficulty level,
  Move? forbiddenMove,
) {
  // Only think when it's actually the CPU's turn
  if (state.currentPlayer != cpuPlayer) return null;

  var moves = listLegalMoves(state, cpuPlayer);

  // Respect Plan B restriction at root: don't repeat the forbidden move
  if (forbiddenMove != null) {
    moves = moves.where((m) => !_sameMove(m, forbiddenMove)).toList();
  }

  if (moves.isEmpty) return null;

  final opp = _opponentOf(cpuPlayer);

  // ---------- 1) Immediate win if possible ----------
  final winningMoves = moves.where(
    (m) => _isWinningMove(state, cpuPlayer, m),
  ).toList();

  if (winningMoves.isNotEmpty) {
    return _pickRandom(winningMoves);
  }

  // ---------- 2) Filter out moves that allow an immediate opponent win ----------
  final safeMoves = <Move>[];
  for (final m in moves) {
    final next = applyMove(state, m);
    final oppCanWin = _hasImmediateWin(next, opp);
    if (!oppCanWin) {
      safeMoves.add(m);
    }
  }

  if (safeMoves.isNotEmpty) {
    moves = safeMoves;
  }

  // ---------- 3) Difficulty-based strategy ----------
  switch (level) {
    case Difficulty.easy:
      // Dumb but legal
      return _pickRandom(moves);

    case Difficulty.normal:
      // One-ply greedy + eval
      return _chooseGreedy(state, cpuPlayer, moves);

    case Difficulty.hard:
      // Stronger: deeper + time-limited search
      return _chooseWithMinimax(
        state,
        cpuPlayer,
        moves,
        maxDepth: 6,
        maxMillis: 2200, // ~2.2s cap
      );

    case Difficulty.expert:
      // Strongest: deeper search with a ~5s cap
      return _chooseWithMinimax(
        state,
        cpuPlayer,
        moves,
        maxDepth: 7,
        maxMillis: 5000, // hard cap ~5s
      );
  }
}

// ---------- helpers ----------

bool _sameMove(Move a, Move b) {
  if (a.type != b.type) return false;
  if (a.type == MoveType.place) {
    return a.toIndex == b.toIndex;
  } else {
    return a.fromIndex == b.fromIndex && a.toIndex == b.toIndex;
  }
}

Move _pickRandom(List<Move> moves) {
  return moves[_rng.nextInt(moves.length)];
}

Player _opponentOf(Player p) => p == Player.a ? Player.b : Player.a;

// Pick best move by evaluation after one step
Move _pickBestByEval(
  GameState state,
  Player cpu,
  List<Move> moves,
) {
  Move? best;
  var bestScore = -999999999;

  for (final m in moves) {
    final next = applyMove(state, m);
    final score = _evaluate(next, cpu);
    if (best == null || score > bestScore) {
      bestScore = score;
      best = m;
    }
  }

  return best ?? moves.first;
}


// ---------- Normal: greedy heuristic ----------

Move _chooseGreedy(
  GameState state,
  Player cpu,
  List<Move> moves,
) {
  final opp = _opponentOf(cpu);

  final immediateWins = <Move>[];
  final safeMoves = <Move>[];

  for (final m in moves) {
    final next = applyMove(state, m);
    // Did this move win immediately?
    final winner = checkWinner(next, cpu);
    if (winner == cpu) {
      immediateWins.add(m);
      continue;
    }

    // Check if opponent has an immediate winning reply
    final oppMoves = listLegalMoves(next, opp);
    final oppWins = oppMoves.any((om) {
      final afterOpp = applyMove(next, om);
      final w = checkWinner(afterOpp, opp);
      return w == opp;
    });

    if (!oppWins) {
      safeMoves.add(m);
    }
  }

  if (immediateWins.isNotEmpty) {
    // Among winning moves, pick the one leading to the best position
    return _pickBestByEval(state, cpu, immediateWins);
  }

  if (safeMoves.isNotEmpty) {
    // Among “safe” moves, pick the best-evaluated one
    return _pickBestByEval(state, cpu, safeMoves);
  }

  // Nothing is safe: pick the least awful by eval
  return _pickBestByEval(state, cpu, moves);
}

// ---------- Hard/Expert: minimax with alpha–beta ----------

Move _chooseWithMinimax(
  GameState state,
  Player cpu,
  List<Move> moves, {
  required int maxDepth,
  required int maxMillis,
}) {
  assert(moves.isNotEmpty);

  final start = DateTime.now();
  final deadline = start.add(Duration(milliseconds: maxMillis));

  Move? bestMove;

  // Order root moves by shallow evaluation to improve pruning.
  final rootMoves = [...moves];
  rootMoves.sort((a, b) {
    final sa = _evaluate(applyMove(state, a), cpu);
    final sb = _evaluate(applyMove(state, b), cpu);
    return sb.compareTo(sa); // descending (better moves first)
  });

  // Iterative deepening: try depth 2, 3, ..., maxDepth
  for (var depth = 2; depth <= maxDepth; depth++) {
    if (DateTime.now().isAfter(deadline)) break;

    // Reset node budget for this depth
    _nodesLeft = _nodeBudgetForDepth(depth);

    final result = _searchAtDepth(
      state,
      cpu,
      rootMoves,
      depth,
      deadline,
    );

    if (result == null) {
      // Time or nodes ran out during this iteration.
      // Keep whatever bestMove we had from a smaller depth.
      break;
    } else {
      bestMove = result.move;
    }
  }

  return bestMove ?? moves.first;
}

int _alphaBeta(
  GameState state, {
  required int depth,
  required int maxDepth,
  required int alpha,
  required int beta,
  required bool maximizing,
  required Player perspective,
  required DateTime deadline,
}) {
  // Time cap: if we ran out of time, just return a static eval.
  if (DateTime.now().isAfter(deadline)) {
    return _evaluate(state, perspective);
  }

  // Global node budget cutoff: if we run out, just return a static eval.
  if (_nodesLeft-- <= 0) {
    return _evaluate(state, perspective);
  }

  var a = alpha;
  var b = beta;

  final current = state.currentPlayer;
  final lastMover = _opponentOf(current);
  final opp = _opponentOf(perspective);

  // Check for terminal win/loss at this node
  final winner = checkWinner(state, lastMover);
  if (winner != null) {
    if (winner == perspective) {
      // Prefer quicker wins
      return _winBase - (maxDepth - depth);
    } else if (winner == opp) {
      // Prefer delaying losses
      return -_winBase + (maxDepth - depth);
    }
  }

  // Depth limit
  if (depth == 0) {
    return _evaluate(state, perspective);
  }

  final moves = listLegalMoves(state, current);

  if (moves.isEmpty) {
    // No legal moves: very bad for the side to move
    if (current == perspective) {
      return -_noMovePenalty + (maxDepth - depth);
    } else {
      return _noMovePenalty - (maxDepth - depth);
    }
  }

  if (maximizing) {
    var best = -999999999;
    for (final m in moves) {
      final next = applyMove(state, m);
      final score = _alphaBeta(
        next,
        depth: depth - 1,
        maxDepth: maxDepth,
        alpha: a,
        beta: b,
        maximizing: false,
        perspective: perspective,
        deadline: deadline,
      );
      if (score > best) best = score;
      if (score > a) a = score;
      if (b <= a) break; // beta cut-off
    }
    return best;
  } else {
    var best = 999999999;
    for (final m in moves) {
      final next = applyMove(state, m);
      final score = _alphaBeta(
        next,
        depth: depth - 1,
        maxDepth: maxDepth,
        alpha: a,
        beta: b,
        maximizing: true,
        perspective: perspective,
        deadline: deadline,
      );
      if (score < best) best = score;
      if (score < b) b = score;
      if (b <= a) break; // alpha cut-off
    }
    return best;
  }
}

_SearchResult? _searchAtDepth(
  GameState state,
  Player cpu,
  List<Move> rootMoves,
  int depth,
  DateTime deadline,
) {
  Move? bestMove;
  var bestScore = -999999999;

  for (final m in rootMoves) {
    if (DateTime.now().isAfter(deadline)) {
      break;
    }

    final next = applyMove(state, m);
    final winner = checkWinner(next, cpu);
    int score;

    if (winner == cpu) {
      score = _winBase; // immediate win
    } else {
      score = _alphaBeta(
        next,
        depth: depth - 1,
        maxDepth: depth,
        alpha: -_winBase,
        beta: _winBase,
        maximizing: false,
        perspective: cpu,
        deadline: deadline,
      );
    }

    if (bestMove == null || score > bestScore) {
      bestScore = score;
      bestMove = m;
    }
  }

  if (bestMove == null) return null;
  return _SearchResult(bestMove, bestScore);
}

// ---------- Evaluation & threat detection ----------

int _evaluate(GameState state, Player perspective) {
  final opp = _opponentOf(perspective);
  int score = 0;

  // --- 1) Column / stack structure ---
  for (var i = 0; i < boardSize; i++) {
    final col = state.board[i];
    if (col.pieces.isEmpty) continue;

    final top = col.pieces.last;
    final len = col.pieces.length;
    final allMine = col.pieces.every((p) => p == perspective);
    final allOpp = col.pieces.every((p) => p == opp);

    // Top control
    if (top == perspective) {
      score += 8;
    } else if (top == opp) {
      score -= 8;
    }

    // Stack threats – slightly stronger now
    if (len == 2) {
      if (allMine) {
        score += 60;
      } else if (allOpp) {
        score -= 60;
      }
    } else if (len == 3) {
      if (allMine) {
        score += 200;
      } else if (allOpp) {
        score -= 200;
      }
    }
  }

  // --- 2) Four-in-a-row potential around the ring ---
  for (var start = 0; start < boardSize; start++) {
    int myCount = 0;
    int oppCount = 0;

    for (var offset = 0; offset < 4; offset++) {
      final idx = (start + offset) % boardSize;
      final col = state.board[idx];
      if (col.pieces.isEmpty) continue;

      final top = col.pieces.last;
      if (top == perspective) {
        myCount++;
      } else if (top == opp) {
        oppCount++;
      }
    }

    // Only pure windows (all mine or all theirs)
    if (oppCount == 0 && myCount > 0) {
      if (myCount == 1) score += 3;
      if (myCount == 2) score += 14;
      if (myCount == 3) score += 45;
      if (myCount == 4) score += 150;
    }
    if (myCount == 0 && oppCount > 0) {
      if (oppCount == 1) score -= 3;
      if (oppCount == 2) score -= 14;
      if (oppCount == 3) score -= 45;
      if (oppCount == 4) score -= 150;
    }
  }

  // --- 3) Reserve piece advantage (tempo) ---
  final myReserve = state.reserveOf(perspective);
  final oppReserve = state.reserveOf(opp);
  score += (myReserve - oppReserve) * 4;

  // --- 4) One-move-away wins (including 3-stacks) ---
  int myImminentWins = 0;
  int oppImminentWins = 0;

  if (state.currentPlayer == perspective) {
    myImminentWins = _countImmediateWins(state, perspective);
  } else if (state.currentPlayer == opp) {
    oppImminentWins = _countImmediateWins(state, opp);
  }

  score += myImminentWins * 250;
  score -= oppImminentWins * 260;

  return score;
}

/// Count how many legal moves for [player] would immediately win.
int _countImmediateWins(GameState state, Player player) {
  final moves = listLegalMoves(state, player);
  int count = 0;

  for (final m in moves) {
    final next = applyMove(state, m);
    final winner = checkWinner(next, player);
    if (winner == player) {
      count++;
    }
  }

  return count;
}

bool _isWinningMove(GameState state, Player player, Move m) {
  final next = applyMove(state, m);
  return checkWinner(next, player) == player;
}

bool _hasImmediateWin(GameState state, Player player) {
  final moves = listLegalMoves(state, player);
  for (final m in moves) {
    final next = applyMove(state, m);
    if (checkWinner(next, player) == player) {
      return true;
    }
  }
  return false;
}

// ---------- CPU Plan B decision (reuses evaluation) ----------

bool shouldCpuUsePlanB(
  GameState before,
  GameState after,
  Player cpu,
  Difficulty level,
) {
  // Easy never calls Plan B
  if (level == Difficulty.easy) return false;

  // 1) Compare evaluations (how much worse did this get for CPU?)
  final evalBefore = _evaluate(before, cpu);
  final evalAfter = _evaluate(after, cpu);
  final delta = evalAfter - evalBefore; // negative = worse for CPU

  int threshold;
  switch (level) {
    case Difficulty.normal:
      threshold = -60; // only big blunders trigger Plan B
      break;
    case Difficulty.hard:
      threshold = -35; // more willing to use it
      break;
    case Difficulty.expert:
      threshold = -20; // very protective
      break;
    case Difficulty.easy:
      threshold = -1000000; // unreachable
      break;
  }

  if (delta <= threshold) {
    return true;
  }

  // 2) Extra paranoia for Expert:
  if (level == Difficulty.expert) {
    final replies = listLegalMoves(after, cpu);
    if (replies.isNotEmpty) {
      final evalAfterCpu = _evaluate(after, cpu);
      bool allBad = true;
      for (final r in replies) {
        final next = applyMove(after, r);
        final score = _evaluate(next, cpu);
        if (score >= evalAfterCpu - 6) {
          allBad = false;
          break;
        }
      }
      if (allBad) return true;
    }
  }

  return false;
}
