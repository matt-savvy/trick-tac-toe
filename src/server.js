const app = require('express')();
const http = require('http').Server(app);
const io = require('socket.io')(http);

const port = 3030;

/*
app.get('/', (req, res) => {
  res.sendFile(`${__dirname}/index.html`);
});
*/
const players = ['X', 'O'];
let counter = 0;

io.on('connection', (socket) => {
  console.log('a user connected');
  if (counter < 2) {
    const player = players[counter];
    if (player) {
      socket.emit('update', { type: 'SET_PLAYER', player });
      counter += 1;
    }
  }

  socket.on('update', (action) => {
    socket.broadcast.emit('update', action);
  });


  socket.on('disconnect', () => {
    console.log('user disconnected');
    counter -= 1;
  });
});

http.listen(port, () => {
  console.log(`listening on *:${port}`);
});
