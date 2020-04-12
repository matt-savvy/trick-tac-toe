import React, { useReducer } from 'react';
// import Paper from '@material-ui/core/Paper';
import Grid from '@material-ui/core/Grid';
import Container from '@material-ui/core/Container';
import { makeStyles } from '@material-ui/core/styles';

const useStyles = makeStyles((theme) => ({
  container: {
    margin: 50,
  },
  cell: {
    fontSize: 90,
    border: '1px solid black',
    height: theme.spacing(30),
    width: theme.spacing(30),
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
  },
  grid: {

  },
}));

const MAKE_MOVE = 'MAKE_MOVE';

function move(player, row, col) {
  return {
    type: MAKE_MOVE,
    player,
    row,
    col,
  };
}

function changeTurns(player) {
  if (player === 'X') {
    return 'O';
  }

  if (player === 'O') {
    return 'X';
  }
}

function gameReducer(state, action) {
  switch (action.type) {
    case MAKE_MOVE: {
      const nextBoard = [...state.board];
      nextBoard[action.row][action.col] = action.player;
      const nextPlayer = changeTurns(action.player);

      const moves = [...state.moves, [action.row, action.col]];
      if (moves.length === 6) {
        const moveToRemove = moves.shift();
        const [removeRow, removeCol] = moveToRemove;
        nextBoard[removeRow][removeCol] = null;
      }

      return {
        ...state,
        board: nextBoard,
        whoseTurn: nextPlayer,
        moves,
      };
    }

    default:
      return state;
  }

  // remove a move
  return state;
}

function check(list) {
  const set = new Set();
  list.forEach((cell) => set.add(cell));

  if (set.size !== 1) {
    return null;
  }

  if (set.has(null)) {
    return null;
  }

  return Array.from(set)[0];
}

function hasWinner(board) {
  const rows = board.map((row) => row);
  const colIndexes = [0, 1, 2];
  const cols = colIndexes.map((col) => board.map((row) => row[col]));

  const diagonalA = [
    board[0][0], board[1][1], board[2][2],
  ];
  const diagonalB = [
    board[0][2], board[1][1], board[2][0],
  ];

  const possibilities = [...rows, ...cols, diagonalA, diagonalB];

  return possibilities.reduce((accumulator, currentValue) => accumulator || check(currentValue), null);
}

const emptyBoard = [
  [null, null, null],
  [null, null, null],
  [null, null, null],
];

const initialState = {
  whoseTurn: 'X',
  board: emptyBoard,
  moves: [],
};

function App() {
  // whose turn is it?
  const [gameState, dispatch] = useReducer(gameReducer, initialState);
  const { whoseTurn, board } = gameState;
  const classes = useStyles();

  const handleCellClick = (row, col) => {
    if (!board[row][col]) {
      dispatch(move(whoseTurn, row, col));
    }
  };

  const winner = hasWinner(board);
  if (winner) {
    console.log(winner);
  }

  return (
    <Container className={classes.container}>
      <Grid
        justify="center"
        alignItems="center"
        container
      >
        {board.map((gridRow, row) => (
          <Grid
            key={row}
            container
            item
          >
            {gridRow.map((cell, col) => (
              <Grid
                item
                xs
                className={classes.cell}
                onClick={() => handleCellClick(row, col)}
                key={col}
              >
                {cell}
              </Grid>
            ))}
          </Grid>
        ))}
      </Grid>
    </Container>
  );
}

export default App;
