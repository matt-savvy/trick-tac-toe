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
const RESET = 'RESET';

function move(row, col) {
  return {
    type: MAKE_MOVE,
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

  return possibilities.reduce(
    (accumulator, currentValue) => accumulator || check(currentValue), null,
  );
}

const emptyBoard = [
  [null, null, null],
  [null, null, null],
  [null, null, null],
];

const initialState = {
  whoseTurn: 'X',
  board: emptyBoard,
  winner: null,
  moves: [],
};

function gameReducer(state, action) {
  switch (action.type) {
    case MAKE_MOVE: {
      const nextBoard = state.board.map((row) => [...row]);

      nextBoard[action.row][action.col] = state.whoseTurn;
      const nextPlayer = changeTurns(state.whoseTurn);

      const moves = [...state.moves, [action.row, action.col]];
      if (moves.length === 6) {
        const moveToRemove = moves.shift();
        const [removeRow, removeCol] = moveToRemove;
        nextBoard[removeRow][removeCol] = null;
      }

      const winner = hasWinner(nextBoard);

      return {
        ...state,
        board: nextBoard,
        whoseTurn: nextPlayer,
        moves,
        winner,
      };
    }
    case RESET:
      return {
        ...initialState,
        whoseTurn: state.whoseTurn,
      };
    default:
      return state;
  }
}

function App() {
  const [gameState, dispatch] = useReducer(gameReducer, initialState);
  const { whoseTurn, board, winner } = gameState;
  const classes = useStyles();

  const handleCellClick = React.useCallback((row, col) => {
    if (winner) {
      return;
    }

    if (board[row][col]) {
      return;
    }

    dispatch(move(row, col));
  }, [board, winner, dispatch]);

  React.useEffect(() => {
    if (winner) {
      setTimeout(() => {
        const playAgain = window.confirm(`${winner} is winner, play again?!`);
        if (playAgain) {
          dispatch({ type: RESET });
        }
      }, 250);
    }
  }, [winner, dispatch]);

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
