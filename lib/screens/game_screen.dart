import 'dart:async';

import 'package:flutter/material.dart';

import '../planb_game.dart';
import '../audio/planb_sounds.dart';
import '../widgets/board_ring.dart';
import '../ai/planb_ai.dart';
import '../theme/game_colors.dart';

// Local helper for comparing moves (mirror of planb_game._moveEquals).
bool _moveEqualsLocal(Move? a, Move? b) {
  if (a == null || b == null) return false;
  return a.type == b.type && a.toIndex == b.toIndex && (a.fromIndex ?? -1) == (b.fromIndex ?? -1);
}

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

  // If a move creates an immediate win, Casual mode should still allow the
  // losing player to invoke Plan B to undo that winning move.
  Player? _pendingWinner;
  Timer? _pendingWinTimer;
  bool _winPendingPlanB = false;
  bool _pendingWinDialogShowing = false;

  // Pending move that will be animated before being applied to the game state.
  Move? _pendingMove;
  bool get _isAnimatingMove => _pendingMove != null;
  bool _pendingMoveWasCpu = false;

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
    // Start background music for gameplay if available and not muted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PlanBSounds.instance.ensureMusicPlaying('audio/music/background.wav');
    });
  }

  @override
  void dispose() {
    // Stop gameplay music when leaving the screen.
    PlanBSounds.instance.stopMusic();
    super.dispose();
  }

  // -----------------------------
  // Board interaction (human)
  // -----------------------------

  void _handleSlotTap(int index) {
    if (_isGameOver) return;
    // If the last move would have ended the game in Casual mode, the only
    // legal response is to use Plan B (if available) or accept the loss.
    if (_winPendingPlanB && _pendingWinner != null) {
      _finalizePendingWin();
      return;
    }
    // Ignore taps while it's CPU's turn or while an animation is playing.
    if (_isCpuTurn) return;
    if (_isAnimatingMove) return;

    final current = _currentPlayer;
    PlanBSounds.instance.tap();

    final reserve = _state.reserveOf(current);

    if (_selectedFromIndex == null) {
      // No selection yet: prefer selecting a stack if the tapped column's
      // top piece belongs to the current player. Otherwise, if the player
      // has reserve pieces, interpret as placing from reserve onto this
      // column.
      final column = _state.board[index];

      // If the player still has reserve pieces, prefer placing from reserve
      // by default. Only fall back to selecting a source stack if placing
      // at this index is not legal.
      if (reserve > 0) {
        final legal = listLegalMoves(_state, current);
        final placeLegal = legal.any((m) => m.type == MoveType.place && m.toIndex == index);
        if (placeLegal) {
          _tryApplyHumanMove(Move.place(index));
          return;
        }

        // If placing isn't legal here but the tapped column contains a piece
        // owned by the player, allow selection so they can move an existing
        // stack instead.
        if (column.pieces.isNotEmpty && column.top == current) {
          setState(() {
            _selectedFromIndex = index;
          });
          return;
        }

        // Otherwise show a helpful message and debug output.
        final forbidden = current == Player.a ? _state.forbiddenMoveForA : _state.forbiddenMoveForB;
        final placeMove = Move.place(index);
        debugPrint('[GameScreen] Rejecting reserve-place: player=$current reserve=${_state.reserveOf(current)} index=$index top=${column.top} height=${column.height}');
        debugPrint('[GameScreen] State curPlayer=${_state.currentPlayer} isCpuTurn=$_isCpuTurn planBUsedByA=${_state.planBUsedByA} planBUsedByB=${_state.planBUsedByB} pendingA=${_state.pendingAcceptForA} pendingB=${_state.pendingAcceptForB} forbiddenA=${_state.forbiddenMoveForA} forbiddenB=${_state.forbiddenMoveForB}');
        debugPrint('[GameScreen] Legal moves for player $current: ${listLegalMoves(_state, current).join('|')}');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot place from reserve there.'),
            duration: Duration(seconds: 2),
          ),
        );
        PlanBSounds.instance.error();
        return;
      }

      // No reserve left (or reserve placing wasn't chosen): if the tapped
      // column contains the player's top piece, select it as source.
      if (column.pieces.isNotEmpty && column.top == current) {
        setState(() {
          _selectedFromIndex = index;
        });
        return;
      }

      // Debug: log why this selection was illegal.
      debugPrint('[GameScreen] Illegal selection: player=$current reserve=${_state.reserveOf(current)} index=$index top=${column.top} height=${column.height}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose a stack to move from.'),
          duration: Duration(seconds: 2),
        ),
      );
      PlanBSounds.instance.error();
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
      debugPrint('[GameScreen] Attempted illegal move by $_currentPlayer: $move');
      debugPrint('[GameScreen] Current reserve=${_state.reserveOf(_currentPlayer)} legalMoves=${legal.join('|')}');
    }

    if (!isLegal) {
      PlanBSounds.instance.error();
      return;
    }

    // If this is a stack-to-stack move, animate the moving piece first,
    // then apply it to the game state so the destination doesn't simply pop
    // into existence. Also animate place-from-reserve moves from a reserve
    // anchor so they don't just appear.
    if (move.type == MoveType.move && move.fromIndex != null) {
      setState(() {
        _pendingMove = move;
        _pendingMoveWasCpu = false;
        _selectedFromIndex = null;
        // also set quick highlights so the UI knows origin/destination
        _cpuFromIndex = move.fromIndex;
        _cpuToIndex = move.toIndex;
        _cpuHighlightActive = true;
      });

      PlanBSounds.instance.movePiece();
      return;
    }

    if (move.type == MoveType.place) {
      // Animate placing from reserve into the chosen slot.
      setState(() {
        _pendingMove = move;
        _pendingMoveWasCpu = false;
        _selectedFromIndex = null;
        // highlight destination while animating
        _cpuFromIndex = null;
        _cpuToIndex = move.toIndex;
        _cpuHighlightActive = true;
      });

      PlanBSounds.instance.movePiece();
      return;
    }

    // Fallback: apply immediately.
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
      // In Casual mode, allow the losing player to call Plan B even if the
      // opponent just made a winning move. That means we do NOT immediately
      // finalize the win if Plan B is still available.
      if (widget.planBMode == PlanBMode.casual) {
        final loser = (winner == Player.a) ? Player.b : Player.a;

        // Don't spam if we're already in the pending-win state.
        if (!_winPendingPlanB && canUsePlanB(_state, loser, widget.planBMode)) {
          setState(() {
            _pendingWinner = winner;
            _winPendingPlanB = true;
          });

          // If the loser is a human (PvP or human-vs-CPU), show a prompt.
          // If the loser is the CPU, we'll handle it in _takeCpuTurn().
          if (!widget.vsCpu || loser == _humanPlayer) {
            _showPendingWinDialog(winner: winner, loser: loser);
          }

          return false;
        }
      }

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
      _pendingWinner = null;
      _winPendingPlanB = false;
      _pendingWinDialogShowing = false;
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

    // If we are in a "winning move" window, the CPU (if it's the losing
    // side) must either use Plan B or concede—no normal moves are allowed.
    if (_winPendingPlanB && _pendingWinner != null && widget.planBMode == PlanBMode.casual) {
      final loser = _pendingWinner == Player.a ? Player.b : Player.a;
      if (loser == _cpuPlayer) {
        final canPlanB = canUsePlanB(_state, _cpuPlayer, widget.planBMode);

        if (canPlanB) {
          try {
            final before = _state.lastState!;
            final after = _state;
            final should = shouldCpuUsePlanB(
              before,
              after,
              _cpuPlayer,
              widget.cpuDifficulty,
              widget.planBMode,
            );

            if (should) {
              debugPrint('[GameScreen] CPU is losing; using Plan B on a winning move');
              setState(() {
                _state = usePlanB(_state, _cpuPlayer, widget.planBMode);
                _cpuHighlightActive = false;
                _pendingWinner = null;
                _winPendingPlanB = false;
              });
              PlanBSounds.instance.planB();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('CPU invoked Plan B — winning move reverted.'),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
          } catch (e) {
            debugPrint('[GameScreen] CPU Plan B (pending-win) check failed: $e');
          }
        }

        debugPrint('[GameScreen] CPU chose not to use Plan B; conceding');
        _finalizePendingWin();
        return;
      }
    }

    // Opportunity: CPU may decide to invoke Plan B to revert the last human move.
    // Check whether CPU should use Plan B based on the last state -> current state.
    if (_state.lastState != null) {
      try {
        final before = _state.lastState!;
        final after = _state;
        if (shouldCpuUsePlanB(
              before,
              after,
              _cpuPlayer,
              widget.cpuDifficulty,
              widget.planBMode,
            ) &&
            canUsePlanB(_state, _cpuPlayer, widget.planBMode)) {
            debugPrint('[GameScreen] CPU will use Plan B now');
            setState(() {
              _state = usePlanB(_state, _cpuPlayer, widget.planBMode);
              _cpuHighlightActive = false;
            });

            // Play Plan B sound and show a brief message.
            PlanBSounds.instance.planB();
            debugPrint('[GameScreen] CPU used Plan B; state.planBUsedByB=${_state.planBUsedByB} pendingAcceptForA=${_state.pendingAcceptForA}');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('CPU invoked Plan B — last move reverted.'),
                duration: Duration(seconds: 2),
              ),
            );

            // After CPU uses Plan B the turn flow may change; return and allow
            // normal flow to continue (CPU will think again on its next scheduled turn).
            return;
        }
      } catch (_) {
        // Ignore AI errors and continue choosing a move.
      }
    }

    final forbidden =
        _cpuPlayer == Player.a ? _state.forbiddenMoveForA : _state.forbiddenMoveForB;

    final move = chooseCpuMove(
      _state,
      _cpuPlayer,
      widget.cpuDifficulty,
      forbidden,
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

    // If the CPU move is a stack-to-stack move, animate it first, then apply.
    if (move.type == MoveType.move && move.fromIndex != null) {
      setState(() {
        _cpuFromIndex = move.fromIndex;
        _cpuToIndex = move.toIndex;
        _cpuHighlightActive = true;
        _pendingMove = move;
        _pendingMoveWasCpu = true;
      });

      PlanBSounds.instance.movePiece();
      return;
    }

    // If CPU places from reserve, animate reserve->slot as well.
    if (move.type == MoveType.place) {
      setState(() {
        _cpuFromIndex = null;
        _cpuToIndex = move.toIndex;
        _cpuHighlightActive = true;
        _pendingMove = move;
        _pendingMoveWasCpu = true;
      });

      PlanBSounds.instance.movePiece();
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
    if (_isAnimatingMove) return false;
    if (_isGameOver) return false;
    if (_state.lastState == null) return false;

    // If a win is pending (Casual mode), the LOSER may use Plan B even if it's
    // not their normal turn.
    Player actor = _currentPlayer;

    if (widget.planBMode == PlanBMode.casual && _winPendingPlanB && _pendingWinner != null) {
      actor = (_pendingWinner == Player.a) ? Player.b : Player.a;
    } else if (widget.vsCpu) {
      // Normal vs-CPU rule: only human can use Plan B on their turn.
      if (_currentPlayer != _humanPlayer) return false;
      actor = _humanPlayer;
    }

    return canUsePlanB(_state, actor, widget.planBMode);
  }

  void _onPlanBPressed({Player? forcedPlayer}) {
  final actor = forcedPlayer ?? _state.currentPlayer;

  if (!canUsePlanB(_state, actor, widget.planBMode)) {
    PlanBSounds.instance.error();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plan B is not available right now.')),
    );
    return;
  }

  setState(() {
    _state = usePlanB(_state, actor, widget.planBMode);

    // If we were in "pending win", Plan B resolves it.
    _pendingWinner = null;
    _winPendingPlanB = false;
    _pendingWinDialogShowing = false;
  });

  PlanBSounds.instance.planB();

  // If CPU should act next, don't stall the game.
  if (widget.vsCpu) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _takeCpuTurn());
  }
}

  // -----------------------------
  // UI helpers
  // -----------------------------
  void _beginPendingWin(Player winner) {
    _pendingWinTimer?.cancel();

    setState(() {
      _pendingWinner = winner;
      _winPendingPlanB = true;

      // IMPORTANT: make it the LOSING player's turn so they can press Plan B.
      final loser = (winner == Player.a) ? Player.b : Player.a;

    });

    // Give them a brief window. Pick what feels right (2–5 seconds).
    _pendingWinTimer = Timer(const Duration(seconds: 3), _finalizePendingWin);
  }


  void _finalizePendingWin() {
  if (_pendingWinner == null) return;

  _pendingWinTimer?.cancel();
  _pendingWinTimer = null;

  setState(() {
    _winner = _pendingWinner;
    _isDraw = false;
    _pendingWinner = null;
    _winPendingPlanB = false;
  });

  PlanBSounds.instance.win();
  _showGameOverDialog();
}

  void _showPendingWinDialog({required Player winner, required Player loser}) {
    // Avoid stacking dialogs if multiple frames call this.
    if (_pendingWinDialogShowing) return;
    _pendingWinDialogShowing = true;

    final String title = widget.vsCpu
        ? (winner == _humanPlayer ? 'You would win' : 'CPU would win')
        : (winner == Player.a ? 'Player A would win' : 'Player B would win');

    final String message = widget.vsCpu
        ? (loser == _humanPlayer
            ? 'In Casual mode you can still use Plan B to undo the winning move.\n\nUse Plan B now?'
            : 'CPU is considering Plan B…')
        : 'In Casual mode, the losing player can still use Plan B to undo the winning move.\n\nUse Plan B now?';

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _pendingWinDialogShowing = false;
                _finalizePendingWin();
              },
              child: const Text('Accept'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _pendingWinDialogShowing = false;
                _onPlanBPressed(forcedPlayer: loser);
              },
              child: const Text('Use Plan B'),
            ),
          ],
        );
      },
    ).then((_) {
      // In case the user backs out via system gestures.
      _pendingWinDialogShowing = false;
    });
  }

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
  final current = _state.currentPlayer;

  final legal = listLegalMoves(_state, current);

  return List<SlotData>.generate(boardSize, (index) {
    final column = _state.board[index];

    final isSelected = _selectedFromIndex == index;
    final isCpuFrom = _cpuHighlightActive && _cpuFromIndex == index;
    final isCpuTo = _cpuHighlightActive && _cpuToIndex == index;

    final isHighlighted =
        isCpuFrom ||
        isCpuTo ||
        (_selectedFromIndex != null &&
            legal.any((m) =>
                m.type == MoveType.move &&
                m.fromIndex == _selectedFromIndex &&
                m.toIndex == index));

    final isLastFrom = last != null && last.board[index].height > _state.board[index].height;
    final isLastTo = last != null && last.board[index].height < _state.board[index].height;

    return SlotData(
      index: index,
      stackPieces: column.pieces,
      isHighlighted: isHighlighted,
      isSelected: isSelected,
      isLastFrom: isLastFrom,
      isLastTo: isLastTo,
      isForbidden: (() {
        final forbidden = current == Player.a
            ? _state.forbiddenMoveForA
            : _state.forbiddenMoveForB;
        if (forbidden == null) return false;

        final pendingForCurrent =
            current == Player.a ? _state.pendingAcceptForA : _state.pendingAcceptForB;
        if (!pendingForCurrent) return false;

        if (_state.planBOriginFingerprint == null) return false;

        return _moveEqualsLocal(forbidden, Move.place(index));
      })(),
    );
  });
}

  // Slot color calculation moved into `_buildSlots()`; old helper removed.

  
  Widget _buildModeDifficultyChips() {
    String difficultyLabel(Difficulty d) => switch (d) {
          Difficulty.easy => 'Easy',
          Difficulty.normal => 'Normal',
          Difficulty.hard => 'Hard',
          Difficulty.expert => 'Expert',
        };

    String modeLabel(PlanBMode m) => switch (m) {
          PlanBMode.casual => 'Casual',
          PlanBMode.noMercy => 'No Mercy',
        };

    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          if (widget.vsCpu)
            Chip(
              label: Text('CPU: ${difficultyLabel(widget.cpuDifficulty)}'),
              backgroundColor: cs.surfaceContainerHighest,
              labelStyle: TextStyle(color: cs.onSurfaceVariant),
              side: BorderSide(color: cs.outlineVariant),
            ),
          Chip(
            label: Text('Mode: ${modeLabel(widget.planBMode)}'),
            backgroundColor: cs.surfaceContainerHighest,
            labelStyle: TextStyle(color: cs.onSurfaceVariant),
            side: BorderSide(color: cs.outlineVariant),
          ),
        ],
      ),
    );
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
            _buildModeDifficultyChips(),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: BoardRing(
                  slots: _buildSlots(),
                  onSlotTap: _handleSlotTap,
                  movingPiece: (_pendingMove != null)
                      ? MovingPiece(
                          fromIndex: _pendingMove!.fromIndex ?? -1,
                          toIndex: _pendingMove!.toIndex,
                          player: _state.currentPlayer,
                          fromReserve: _pendingMove!.type == MoveType.place,
                        )
                      : null,
                  onMoveAnimationComplete: () {
                    // Apply pending move once the visual animation completes.
                    if (!mounted) return;
                    final m = _pendingMove;
                    if (m == null) return;

                    setState(() {
                      _state = applyMove(_state, m);
                      _pendingMove = null;
                    });

                    // Clear cpu highlight after a short delay to allow the
                    // destination to show its state change.
                    Future.delayed(const Duration(milliseconds: 350), () {
                      if (!mounted) return;
                      setState(() {
                        _cpuHighlightActive = false;
                      });
                    });

                    // Continue game flow depending on who initiated the move.
                    if (_pendingMoveWasCpu) {
                      // CPU just moved; check for end of game.
                      _checkGameEnd(lastMover: _cpuPlayer);
                    } else {
                      // Human moved; continue normal post-human flow.
                      _afterHumanMove();
                    }

                    _pendingMoveWasCpu = false;
                  },
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
                      onPressed: _planBEnabled
                        ? () {
                            // In Casual mode, if a win is pending, the LOSER can invoke Plan B
                            // even if it isn't their normal turn.
                            final actor = (widget.planBMode == PlanBMode.casual &&
                                    _winPendingPlanB &&
                                    _pendingWinner != null)
                                ? ((_pendingWinner == Player.a) ? Player.b : Player.a)
                                : _currentPlayer;

                            _onPlanBPressed(forcedPlayer: actor);
                          }
                        : null,
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
    if (_winPendingPlanB && _pendingWinner != null) {
      final winner = _pendingWinner!;
      final loser = winner == Player.a ? Player.b : Player.a;

      if (widget.vsCpu) {
        if (loser == _humanPlayer) {
          return 'CPU has a winning move. Use Plan B to undo it, or accept the loss.';
        }
        return 'You have a winning move. CPU may respond with Plan B.';
      }

      return 'Player ${winner == Player.a ? 'A' : 'B'} has a winning move. ${loser == Player.a ? 'Player A' : 'Player B'} may use Plan B.';
    }

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
    final gc = GameColors.of(context);
    final Color dotColor = isCpu ? gc.cpu : (label == 'Player A' ? gc.playerA : gc.playerB);

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
                textTheme.bodySmall?.copyWith(color: gc.highlightRing),
          ),
      ],
    );
  }
}