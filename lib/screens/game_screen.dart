import 'dart:async';

import 'package:flutter/material.dart';

import '../planb_game.dart';
import '../audio/planb_sounds.dart';
import '../widgets/board_ring.dart';
import '../ai/planb_ai.dart';

class GameScreen extends StatefulWidget {
  final bool vsCpu;
  final Difficulty cpuDifficulty;
  final PlanBMode planBMode;

  const GameScreen({
    super.key,
    required this.vsCpu,
    required this.cpuDifficulty,
    required this.planBMode,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  GameState _state = GameState.initial();

  // Board interaction: which column the human is currently moving from
  int? _selectedFromIndex;

  // Game over tracking
  Player? _winner;
  bool _isDraw = false;

  // CPU move highlight
  int? _cpuFromIndex;
  int? _cpuToIndex;
  bool _cpuHighlightActive = false;

  final Player _humanPlayer = Player.a;
  final Player _cpuPlayer = Player.b;

  Player get _currentPlayer => _state.currentPlayer;

  bool get _isGameOver => _winner != null || _isDraw;

  bool get _isCpuTurn =>
      widget.vsCpu && !_isGameOver && _state.currentPlayer == _cpuPlayer;

  @override
  void initState() {
    super.initState();

    // If the CPU should start, kick off its turn after first frame.
    if (_isCpuTurn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _takeCpuTurn();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // -----------------------------
  // Board interaction (human)
  // -----------------------------

  void _handleSlotTap(int index) {
    if (_isGameOver) return;

    // Ignore taps while it's CPU's turn.
    if (_isCpuTurn) return;

    final current = _currentPlayer;
    PlanBSounds.instance.tap();

    final reserve = _state.reserveOf(current);

    if (_selectedFromIndex == null) {
      // No selection yet: either place from reserve or select a stack to move.
      if (reserve > 0) {
        // Interpret this tap as "place from reserve onto this column".
        _tryApplyHumanMove(Move.place(index));
        return;
      }

      final column = _state.board[index];
      if (column.pieces.isNotEmpty && column.top == current) {
        // Select this column as source.
        setState(() {
          _selectedFromIndex = index;
        });
      } else {
        // Illegal selection.
        PlanBSounds.instance.error();
      }
    } else {
      // We already have a "from" column selected.
      if (index == _selectedFromIndex) {
        // Tap again to cancel selection.
        setState(() {
          _selectedFromIndex = null;
        });
        return;
      }

      // Attempt to move from the selected column to this index.
      final move = Move.move(
        fromIndex: _selectedFromIndex!,
        toIndex: index,
      );
      _tryApplyHumanMove(move);
    }

  }

  void _tryApplyHumanMove(Move move) {
    if (_isGameOver) return;

    final legal = listLegalMoves(_state, _currentPlayer);

    final isLegal = legal.any(
      (m) =>
          m.type == move.type &&
          m.toIndex == move.toIndex &&
          (m.fromIndex ?? -1) == (move.fromIndex ?? -1),
    );

    if (!isLegal) {
      PlanBSounds.instance.error();
      return;
    }

    setState(() {
      _state = applyMove(_state, move);
      _selectedFromIndex = null;
    });

    PlanBSounds.instance.movePiece();

    _afterHumanMove();
  }

  void _afterHumanMove() {
    final ended = _checkGameEnd(lastMover: _humanPlayer);
    if (ended) return;

    if (_isCpuTurn) {
      _takeCpuTurn();
    }
  }

  // -----------------------------
  // Game end logic
  // -----------------------------

  bool _checkGameEnd({required Player lastMover}) {
    final winner = checkWinner(_state, lastMover);
    if (winner != null) {
      setState(() {
        _winner = winner;
        _isDraw = false;
      });
      PlanBSounds.instance.win();
      _showGameOverDialog();
      return true;
    }

    // Optional draw: no legal moves for current player.
    if (!hasAnyMove(_state, _state.currentPlayer)) {
      setState(() {
        _winner = null;
        _isDraw = true;
      });
      _showGameOverDialog();
      return true;
    }

    return false;
  }

  void _onResetPressed() {
    setState(() {
      _state = GameState.initial();
      _selectedFromIndex = null;
      _winner = null;
      _isDraw = false;
      _cpuFromIndex = null;
      _cpuToIndex = null;
      _cpuHighlightActive = false;
    });
  }

  // -----------------------------
  // CPU logic + highlight
  // -----------------------------

  Future<void> _takeCpuTurn() async {
    if (!_isCpuTurn || _isGameOver || !widget.vsCpu) return;

    // Brief delay so the move isn't instant.
    await Future.delayed(const Duration(milliseconds: 500));
    if (!_isCpuTurn || _isGameOver) return;

    final move = chooseCpuMove(
      _state,
      _cpuPlayer,
      widget.cpuDifficulty,
      null, // we are not enforcing "forbidden" move here
    );

    if (move == null) {
      // CPU has no legal moves — human wins.
      setState(() {
        _winner = _humanPlayer;
        _isDraw = false;
      });
      PlanBSounds.instance.win();
      _showGameOverDialog();
      return;
    }

    setState(() {
      _cpuFromIndex = move.type == MoveType.move ? move.fromIndex : null;
      _cpuToIndex = move.toIndex;
      _cpuHighlightActive = true;
      _state = applyMove(_state, move);
    });

    PlanBSounds.instance.movePiece();

    // Turn off highlight after a short pulse.
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _cpuHighlightActive = false;
      });
    });

    _checkGameEnd(lastMover: _cpuPlayer);
  }

  // -----------------------------
  // Plan B button
  // -----------------------------

  bool get _planBEnabled {
    // For now, Plan B is only exposed to the human in vs-CPU mode.
    if (!widget.vsCpu) return false;
    if (_isGameOver) return false;
    if (_state.lastState == null) return false;
    return canUsePlanB(_state, _humanPlayer);
  }

  void _onPlanBPressed() {
    if (!_planBEnabled) return;

    setState(() {
      _state = usePlanB(_state, _humanPlayer);
      _selectedFromIndex = null;
    });

    PlanBSounds.instance.planB();

    // After Plan B, we’ve reverted to the previous state.
    // If that puts the CPU back on move, trigger it again.
    if (_isCpuTurn) {
      _takeCpuTurn();
    }
  }

  // -----------------------------
  // UI helpers
  // -----------------------------

  void _showGameOverDialog() {
    final String title;
    final String message;

    if (_isDraw) {
      title = 'Draw';
      message = 'No more legal moves. The game is a draw.';
    } else if (_winner == Player.a) {
      title = 'Player A Wins';
      message = widget.vsCpu ? 'You won this round!' : 'Player A takes it.';
    } else if (_winner == Player.b) {
      title = 'Player B Wins';
      message = widget.vsCpu ? 'The CPU won this round.' : 'Player B takes it.';
    } else {
      title = 'Game Over';
      message = 'The game has ended.';
    }

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _onResetPressed();
              },
              child: const Text('Play Again'),
            ),
          ],
        );
      },
    );
  }

  List<SlotData> _buildSlots() {
    final last = _state.lastState;
    final legal = listLegalMoves(_state, _currentPlayer);

    return List<SlotData>.generate(boardSize, (index) {
      final column = _state.board[index];

      final isSelected = _selectedFromIndex == index;
      final isCpuFrom = _cpuHighlightActive && _cpuFromIndex == index;
      final isCpuTo = _cpuHighlightActive && _cpuToIndex == index;

      final isHighlighted = isCpuFrom || isCpuTo || (_selectedFromIndex != null && legal.any((m) => m.type == MoveType.move && m.fromIndex == _selectedFromIndex && m.toIndex == index));

      final isLastFrom = last != null && last.board[index].height > _state.board[index].height;
      final isLastTo = last != null && last.board[index].height < _state.board[index].height;

      return SlotData(
        index: index,
        stackPieces: column.pieces,
        isHighlighted: isHighlighted,
        isSelected: isSelected,
        isLastFrom: isLastFrom,
        isLastTo: isLastTo,
      );
    });
  }

  Color _slotColorForIndex(int index) {
    final column = _state.board[index];

    final isSelected = _selectedFromIndex == index;
    final isCpuFrom = _cpuHighlightActive && _cpuFromIndex == index;
    final isCpuTo = _cpuHighlightActive && _cpuToIndex == index;

    Color base;
    if (column.pieces.isEmpty) {
      base = Colors.grey.shade300;
    } else {
      base = column.top == Player.a ? Colors.blue : Colors.red;
    }

    if (isSelected || isCpuFrom || isCpuTo) {
      return base.withOpacity(0.9);
    }
    return base.withOpacity(0.7);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan B'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _PlayerHeaderRow(
              currentPlayer: _currentPlayer,
              state: _state,
              vsCpu: widget.vsCpu,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: BoardRing(
                  slots: _buildSlots(),
                  onSlotTap: _handleSlotTap,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: 140,
                    child: ElevatedButton(
                      onPressed: _planBEnabled ? _onPlanBPressed : null,
                      child: Text(_planBEnabled ? 'PLAN B' : 'PLAN B USED'),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: ElevatedButton(
                      onPressed: _onResetPressed,
                      child: const Text('Reset'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _statusText,
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String get _statusText {
    if (_isGameOver) {
      if (_isDraw) {
        return 'Draw game.';
      }
      if (_winner == Player.a) {
        return widget.vsCpu ? 'You win!' : 'Player A wins.';
      }
      if (_winner == Player.b) {
        return widget.vsCpu ? 'CPU wins.' : 'Player B wins.';
      }
      return 'Game over.';
    }

    if (_isCpuTurn) {
      return 'CPU is thinking...';
    }

    if (_currentPlayer == Player.a) {
      return widget.vsCpu ? 'Your turn.' : 'Player A to move.';
    }

    return 'Player B to move.';
  }
}

class _PlayerHeaderRow extends StatelessWidget {
  final Player currentPlayer;
  final GameState state;
  final bool vsCpu;

  const _PlayerHeaderRow({
    required this.currentPlayer,
    required this.state,
    required this.vsCpu,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final reserveA = state.reserveOf(Player.a);
    final reserveB = state.reserveOf(Player.b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _PlayerHeader(
            label: 'Player A',
            isCpu: false,
            isActive: currentPlayer == Player.a,
            reserve: reserveA,
            textTheme: textTheme,
          ),
          _PlayerHeader(
            label: vsCpu ? 'CPU' : 'Player B',
            isCpu: vsCpu,
            isActive: currentPlayer == Player.b,
            reserve: reserveB,
            textTheme: textTheme,
          ),
        ],
      ),
    );
  }
}

class _PlayerHeader extends StatelessWidget {
  final String label;
  final bool isCpu;
  final bool isActive;
  final int reserve;
  final TextTheme textTheme;

  const _PlayerHeader({
    required this.label,
    required this.isCpu,
    required this.isActive,
    required this.reserve,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color dotColor = label == 'Player A' ? Colors.blue : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            Text(
              label,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isActive ? colorScheme.primary : null,
              ),
            ),
            if (isCpu)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  '(CPU)',
                  style: textTheme.bodySmall,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Reserve: $reserve',
          style: textTheme.bodySmall,
        ),
        if (isActive)
          Text(
            'Your move',
            style:
                textTheme.bodySmall?.copyWith(color: colorScheme.primary),
          ),
      ],
    );
  }
}
