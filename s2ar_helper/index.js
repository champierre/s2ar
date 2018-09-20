var server = require('http').createServer(function(req, res) {
    res.write("S2AR");
    res.end();
});
var io = require('socket.io')(server);
var port = process.env.PORT;

server.listen(port, function () {
  console.log('Server listening at port %d', port);
});

io.on('connection', function(socket) {
  console.log("client connected");

  socket.on('disconnect', function() {
    console.log("client disconnected");
  });

  socket.on("from_client", function(msg){
    var json
    try {
      json = JSON.parse(msg);
    } catch(e) {
      console.log("Error:", e);
    }

    if (!json) {
      return;
    }

    var roomId = json.roomId;
    var command = json.command;
    console.log("receive:" + msg);
    console.log("roomId:" + roomId);

    if (command == "join") {
      console.log("enter:" + roomId);
      socket.join(roomId);
    } else {
      io.to(roomId).emit("from_server", command);
    }
  });
});
