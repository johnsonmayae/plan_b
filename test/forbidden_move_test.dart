import 'package:flutter_test/flutter_test.dart';
import 'package:plan_b_2nd_best/planb_game.dart';

void main() {
  test('CPU cannot repeat undone move after Plan B', () {
    // prev: Player.b has a piece at index 0
    final prevBoard = List<StackColumn>.generate(
      boardSize,
      (i) => StackColumn(const []),
    );
    prevBoard[0] = StackColumn([Player.b]);

    final prev = GameState(
      board: prevBoard,
      reserveA: 8,
      reserveB: 8,
      currentPlayer: Player.b,
      lastState: null,
      planBUsedByA: false,
      planBUsedByB: false,
      forbiddenMoveForA: null,
      forbiddenMoveForB: null,
    );

    // state: after Player.b moved from 0 -> 1
    final nextBoard = prevBoard.map((c) => StackColumn(List<Player>.from(c.pieces))).toList();
    nextBoard[0] = nextBoard[0].removeTop();
    nextBoard[1] = nextBoard[1].addTop(Player.b);

    final state = GameState(
      board: nextBoard,
      reserveA: 8,
      reserveB: 8,
      currentPlayer: Player.a, // switched after move
      lastState: prev,
      planBUsedByA: false,
      planBUsedByB: false,
      forbiddenMoveForA: null,
      forbiddenMoveForB: null,
    );

    // Player A uses Plan B to revert the CPU's move
    final reverted = usePlanB(state, Player.a);

    // Now, CPU (Player.b) should have the undone move forbidden
    final legalForCpu = listLegalMoves(reverted, Player.b);
    final undoneMove = Move.move(fromIndex: 0, toIndex: 1);

    expect(legalForCpu.any((m) => m.type == undoneMove.type && m.toIndex == undoneMove.toIndex && (m.fromIndex ?? -1) == (undoneMove.fromIndex ?? -1)), isFalse,
      reason: 'CPU should not be able to repeat the undone move immediately after Plan B');
  });
}
