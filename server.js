const express = require('express');
const path = require('path');

const app = express();
const http = require('http').Server(app);
const io = require('socket.io')(http);

const port = process.env.PORT || 8080;
const socketPort = 3030;

app.use(express.static(__dirname));
app.use(express.static(path.join(__dirname, 'build')));

app.get('/ping', (req, res) => res.send('pong'));

app.get('/*', (req, res) => {
  res.sendFile(path.join(__dirname, 'build', 'index.html'));
});

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

app.listen(port);
http.listen(socketPort, () => {
  console.log(`listening on *:${socketPort}`);
});
