(function(ext) {
  $.getScript('https://cdnjs.cloudflare.com/ajax/libs/socket.io/2.1.1/socket.io.js')
    .done(function() {
      var socket;
      var hostname = "s2ar-helper.glitch.me";
      var roomId;

      ext._shutdown = function() {};

      ext._getStatus = function() {
        return {status: 2, msg: 'Ready'};
      };

      ext.set_hostname = function(str) {
        hostname = str;
      };

      ext.connect = function(str1, str2) {
        roomId = str1 + "-" + str2;
        socket = io.connect('http://' + hostname);
        socket.on("connect", function() {
          socket.emit("from_client", JSON.stringify({roomId: roomId, command: "connect"}));
        });
      }

      ext.set_cube = function(x, y, z) {
        let command = "set_cube:" + x + ":" + y + ":" + z;
        socket.emit("from_client", JSON.stringify({roomId: roomId, command: command}));
      }

      ext.set_box = function(x, y, z, w, d, h) {
        let command = "set_box:" + x + ":" + y + ":" + z + ":" + w + ":" + d + ":" + h;
        socket.emit("from_client", JSON.stringify({roomId: roomId, command: command}));
      }

      ext.set_cylinder = function(x, y, z, r, h, a) {
        let command = "set_cylinder:" + x + ":" + y + ":" + z + ":" + r + ":" + h + ":" + a;
        socket.emit("from_client", JSON.stringify({roomId: roomId, command: command}));
      }

      ext.set_hexagon = function(x, y, z, r, h, a) {
        let command = "set_hexagon:" + x + ":" + y + ":" + z + ":" + r + ":" + h + ":" + a;
        socket.emit("from_client", JSON.stringify({roomId: roomId, command: command}));
      }

      ext.set_sphere = function(x, y, z, r) {
        let command = "set_sphere:" + x + ":" + y + ":" + z + ":" + r;
        socket.emit("from_client", JSON.stringify({roomId: roomId, command: command}));
      }

      ext.set_char = function(x, y, z, c, a) {
        let command = "set_char:" + x + ":" + y + ":" + z + ":" + c + ":" + a;
        socket.emit("from_client", JSON.stringify({roomId: roomId, command: command}));
      }

      ext.set_line = function(x1, y1, z1, x2, y2, z2) {
        let command = "set_line:" + x1 + ":" + y1 + ":" + z1 + ":" + x2 + ":" + y2 + ":" + z2;
        socket.emit("from_client", JSON.stringify({roomId: roomId, command: command}));
      }

      ext.set_roof = function(x, y, z, w, d, h, a) {
        let command = "set_roof:" + x + ":" + y + ":" + z + ":" + w + ":" + d + ":" + h + ":" + a;
        socket.emit("from_client", JSON.stringify({roomId: roomId, command: command}));
      }

      ext.set_color = function(r, g, b) {
        let command = "set_color:" + r + ":" + g + ":" + b;
        socket.emit("from_client", JSON.stringify({roomId: roomId, command: command}));
      }

      ext.remove_cube = function(x, y, z) {
        let command = "remove_cube:" + x + ":" + y + ":" + z;
        socket.emit("from_client", JSON.stringify({roomId: roomId, command: command}));
      }

      ext.reset = function() {
        let command = "reset:";
        socket.emit("from_client", JSON.stringify({roomId: roomId, command: command}));
      }

      var lang = ((navigator.language || navigator.userLanguage) == 'ja') ? 'ja' : 'en';
      var locale = {
        ja: {
          set_hostname: '接続先を %s に設定する',
          connect: 'ID: %s - %s で接続する',
          set_cube: 'x座標 %n 、y座標 %n 、z座標 %n にブロックを置く',
          set_box: '直方体を置く。x座標 %n 、y座標 %n 、z座標 %n 、幅を %n 、奥行を %n 、高さを %n',
          set_cylinder: '円柱を置く。x座標 %n 、y座標 %n 、z座標 %n 、半径を %n 、高さを %n 、 %s 軸',
          set_hexagon: '六角柱を置く。x座標 %n 、y座標 %n 、z座標 %n 、半径を %n 、高さを %n 、 %s 軸',
          set_sphere: '球を置く。x座標 %n 、y座標 %n 、z座標 %n 、半径を %n',
          set_char: '文字を書く。x座標 %n 、y座標 %n 、z座標 %n 、文字 %s 、 %s 軸',
          set_line: '２点間に線を引く。x1 を %n 、y1 を %n 、z1 を %n 、x2 を %n 、y2 を %n 、z2を %n',
          set_roof: '屋根を作る。x座標 %n 、y座標 %n 、z座標 %n 、幅を %n 、奥行を %n 、高さを %n 、 %s 軸に',
          set_color: 'ブロックの色を r: %n g: %n b: %n に変える',
          remove_cube: 'x座標 %n 、y座標 %n 、z座標 %n のブロックを消す',
          reset: 'リセット'
        },
        en: {
          set_hostname: 'Set hostname to %s',
          connect: 'Connect with ID: %s -  %s',
          set_cube: 'set cube at x: %n y: %n z: %n',
          set_box: 'set box at x: %n y: %n z: %n wide: %n depth: %n height: %n',
          set_cylinder: 'set cylinder at x: %n y: %n z: %n radius: %n height: %n axis: %s',
          set_hexagon: 'set hexagon at x: %n y: %n z: %n radius: %n height: %n axis: %s',
          set_sphere: 'set sphere at x: %n y: %n z: %n radius: %n',
          set_char: 'set char at x: %n y: %n z: %n letter: %s axis: %s',
          set_line: 'set line between x1: %n y1: %n z1: %n and x2: %n y2: %n z2: %n',
          set_roof: 'set roof at x: %n y: %n z: %n wide: %n depth: %n height: %n axis: %s',
          set_color: 'set color to r: %n g: %n b: %n',
          remove_cube: 'remove cube at x: %n y: %n z: %n',
          reset: 'reset'
        },
      }

      var descriptor = {
        blocks: [
          [' ', locale[lang].set_hostname, 'set_hostname', hostname],
          [' ', locale[lang].connect, 'connect', '', ''],
          [' ', locale[lang].set_cube, 'set_cube', 1, 0, 1],
          [' ', locale[lang].set_box, 'set_box', 2, 0, 2, 2, 2, 2],
          [' ', locale[lang].set_cylinder, 'set_cylinder', 3, 0, 3, 4, 4, 'y'],
          [' ', locale[lang].set_hexagon, 'set_hexagon', 4, 10, 10, 6, 4, 'y'],
          [' ', locale[lang].set_sphere, 'set_sphere', 4, 4, 4, 4],
          [' ', locale[lang].set_char, 'set_char', 0, 0, 10, 'A', 'y'],
          [' ', locale[lang].set_line, 'set_line', 0, 0, 0, 10, 10, 10],
          [' ', locale[lang].set_roof, 'set_roof', 0, 3, 0, 14, 10, 7, 'z'],
          [' ', locale[lang].set_color, 'set_color', 255, 255, 255],
          [' ', locale[lang].remove_cube, 'remove_cube', 1, 0, 1],
          [' ', locale[lang].reset, 'reset']
        ]
      };

      ScratchExtensions.register('S2AR(Scratch2ARKit)', descriptor, ext);
  });
})({});
