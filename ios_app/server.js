var server = require("http").createServer(function(req, res) {
    res.write("Hello World!!");
    res.end();
});
var io = require('socket.io')(server);

io.on('connection', function(socket) {
    console.log("client connected")

    socket.on('disconnect', function() {
        console.log("client disconnected")
    });

    socket.on("from_client", function(msg){
        console.log("receive:" + msg);
        socket.broadcast.emit("from_server", msg);
    });
});

server.listen(3000);
