const express = require('express');
const path = require('path');

const app = express();
const http = require('http').createServer(app);
const io = require('socket.io')(http);

const port = process.env.PORT || 3000;

app.use(express.static(path.join(__dirname, 'build')));

app.get('/ping', (req, res) => res.send('pong'));

app.get('/', (req, res) => {
  console.log(path.join(__dirname, 'build', 'index.html'));
  res.sendFile(path.join(__dirname, 'build', 'index.html'));
});

/*
eslint
no-console: 0
*/


const players = ['X', 'O'];
let counter = 0;

io.on('connection', (socket) => {
  console.log('a user connected');
    const player = players[counter % 2];
    if (player) {
      socket.emit('update', { type: 'SET_PLAYER', player });
      counter += 1;
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
  console.log(`listening on ${port}`)
})
