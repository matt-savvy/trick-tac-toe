import React, { useReducer } from 'react';
import { makeStyles } from '@material-ui/core/styles';
import Container from '@material-ui/core/Container';
import Grid from '@material-ui/core/Grid';
import Typography from '@material-ui/core/Typography';
import io from 'socket.io-client';

/*
eslint
no-alert: 0
*/

let socket;
console.log('sanity');
const useStyles = makeStyles({
  container: {
    margin: 50,
  },
  cell: {
    fontSize: 90,
    border: '1px solid blue',
    height: 250,
    width: 250,
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
  },
});

const MAKE_MOVE = 'MAKE_MOVE';
const RESET = 'RESET';
const SET_PLAYER = 'SET_PLAYER';

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
  player: null,
  whoseTurn: 'X',
  board: emptyBoard,
  moves: [],
};

function gameReducer(state, action) {
  switch (action.type) {
    case SET_PLAYER: {
      return { ...state, player: action.player };
    }
    case MAKE_MOVE: {
      if (action.player !== state.whoseTurn) {
        // prevent multiple events being hit
        return state;
      }

      const nextBoard = state.board.map((row) => [...row]);

      nextBoard[action.row][action.col] = state.whoseTurn;
      const nextPlayer = changeTurns(state.whoseTurn);

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
    case RESET:
      return {
        ...initialState,
        whoseTurn: state.whoseTurn,
        player: state.player,
      };
    default:
      return state;
  }
}

function App() {
  const [gameState, dispatch] = useReducer(gameReducer, initialState);
  const {
    whoseTurn, player, board,
  } = gameState;

  const winner = hasWinner(board);
  const classes = useStyles();

  const handleCellClick = React.useCallback((row, col) => {
    if (player !== whoseTurn) {
      return;
    }
    if (winner) {
      return;
    }

    if (board[row][col]) {
      return;
    }

    const action = move(player, row, col);

    socket.emit('update', action);
    dispatch(action);
  }, [board, winner, whoseTurn, dispatch, player]);

  React.useEffect(() => {
    function gameOverAlert() {
      if (winner === player) {
        window.alert(`${winner} is winner! Great work`);
      } else {
        const playAgain = window.confirm(`${winner} is winner, play again?!`);
        if (playAgain) {
          const action = { type: RESET };
          socket.emit('update', action);
          dispatch(action);
        }
      }
    }

    if (winner) {
      setTimeout(gameOverAlert, 250);
    }
  }, [winner, player, dispatch]);

  if (!socket) {
    socket = io();
  }

  socket.on('update', (data) => {
    dispatch(data);
  });
  const whoseTurnString = player && (whoseTurn === player) ? "It's your turn" : `It is ${whoseTurn}'s turn`;

  return (
    <Container className={classes.container}>
      <Typography>
        {whoseTurnString}
      </Typography>
      <Grid
        className={classes.grid}
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
