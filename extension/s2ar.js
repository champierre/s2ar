(function(ext) {
  $.getScript('https://cdnjs.cloudflare.com/ajax/libs/socket.io/2.1.1/socket.io.js')
    .done(function() {
      var socket;
      var hostname = "s2ar-helper.glitch.me";
      var roomId;
      var connected = false;

      ext._shutdown = function() {};

      ext._getStatus = function() {
        if (connected) {
          return {status: 2, msg: 'Connected to the Server'};
        } else {
          return {status: 1, msg: 'Not connected to the Server'};
        }
      };

      ext.set_hostname = function(str) {
        hostname = str;
      };

      ext.connect = function(str) {
        roomId = str;
        socket = io.connect('http://' + hostname);
        socket.on("connect", function() {
          connected = true;
          socket.emit("from_client", JSON.stringify({roomId: roomId, command: "connect"}));
        });
      }

      ext.change_cube_size = function(maginification) {
        let command = "change_cube_size:" + maginification;
        socket.emit("from_client", JSON.stringify({roomId: roomId, command: command}));
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

      ext.polygon_file_format = function(x, y, z, s) {
        let command = "polygon_file_format:" + x + ":" + y + ":" + z + ":" + s;
        socket.emit("from_client", JSON.stringify({roomId: roomId, command: command}));
      }

      ext.animation = function(x, y, z, diffX, diffY, diffZ, time, times, files) {
        let command = "animation:" + x + ":" + y + ":" + z + ":" + diffX + ":" + diffY + ":" + diffZ + ":" + time + ":" + times + ":" + files;
        socket.emit("from_client", JSON.stringify({roomId: roomId, command: command}));
      }

      ext.map = function(csv_name, width, height, magnification, r1, g1, b1, r2, g2, b2, upward) {
        let command = "map:" + csv_name + ":" + width + ":" + height + ":" + magnification + ":" + r1 + ":" + g1 + ":" + b1 + ":" + r2 + ":" + g2 + ":" + b2 + ":" + upward;
        socket.emit("from_client", JSON.stringify({roomId: roomId, command: command}));
      }

      ext.pin = function(csv_name, width, height, magnification, up_left_latitude, up_left_longitude, down_right_latitude, down_right_longitude, step) {
        let command = "pin:" + csv_name + ":" + width + ":" + height + ":" + magnification + ":" + up_left_latitude + ":" + up_left_longitude + ":" + down_right_latitude + ":" + down_right_longitude + ":" + step;
        socket.emit("from_client", JSON.stringify({roomId: roomId, command: command}));
      }

      ext.molecular_structure = function(x, y, z, magnification, s) {
        let command = "molecular_structure:" + x + ":" + y + ":" + z + ":" + magnification + ":" + s;
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

      ext.set_char = function(x, y, z, c, a) {
        let command = "set_char:" + x + ":" + y + ":" + z + ":" + c + ":" + a;
        socket.emit("from_client", JSON.stringify({roomId: roomId, command: command}));
      }

      ext.ar_game = function(x, y, z, sprite, costume, color, direction) {
        let command = "ar_game:" + x + ":" + y + ":" + z + ":" + sprite  + ":" + costume + ":" + color + ":" + direction;
        socket.emit("from_client", JSON.stringify({roomId: roomId, command: command}));
      }

      ext.set_color = function(r, g, b) {
        let command = "set_color:" + r + ":" + g + ":" + b;
        socket.emit("from_client", JSON.stringify({roomId: roomId, command: command}));
      }

      ext.set_color_hexadecimal = function(hexa) {
        let command = "set_color_hexadecimal:" + hexa;
        socket.emit("from_client", JSON.stringify({roomId: roomId, command: command}));
      }

      ext.set_alpha = function(a) {
        let command = "set_alpha:" + a;
        socket.emit("from_client", JSON.stringify({roomId: roomId, command: command}));
      }

      ext.change_layer = function(l) {
        let command = "change_layer:" + l;
        socket.emit("from_client", JSON.stringify({roomId: roomId, command: command}));
      }

      ext.change_shape = function(shape) {
        let command = "change_shape:" + shape;
        socket.emit("from_client", JSON.stringify({roomId: roomId, command: command}));
      }

      ext.rotate_shape = function(rotationX, rotationY, rotationZ) {
        let command = "rotate_shape:" + rotationX + ":" + rotationY + ":" + rotationZ;
        socket.emit("from_client", JSON.stringify({roomId: roomId, command: command}));
      }

      ext.change_material = function(material) {
        let command = "change_material:" + material;
        socket.emit("from_client", JSON.stringify({roomId: roomId, command: command}));
      }

      ext.change_light = function(x, y, z, intensity) {
        let command = "change_light:" + x + ":" + y + ":" + z + ":" + intensity;
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
          connect: 'ID: %s で接続する',
          change_cube_size: 'ブロックサイズの変更。拡大倍率を %n',
          set_cube: 'ブロックを置く。x座標を %n 、y座標を %n 、z座標を %n',
          set_box: '直方体を置く。x座標を %n 、y座標を %n 、z座標を %n 、幅を %n 、奥行を %n 、高さを %n',
          set_cylinder: '円柱を置く。x座標を %n 、y座標を %n 、z座標を %n 、半径を %n 、高さを %n 、 %m.axes 軸',
          set_hexagon: '六角柱を置く。x座標を %n 、y座標を %n 、z座標を %n 、半径を %n 、高さを %n 、 %m.axes 軸',
          set_sphere: '球を置く。x座標を %n 、y座標を %n 、z座標を %n 、半径を %n',
          set_char: '文字を書く。x座標を %n 、y座標を %n 、z座標を %n 、文字 %s 、 %m.axes 軸',
          set_line: '２点間に線を引く。x1 を %n 、y1 を %n 、z1 を %n 、x2 を %n 、y2 を %n 、z2を %n',
          set_roof: '屋根を作る。x座標を %n 、y座標を %n 、z座標を %n 、幅を %n 、奥行を %n 、高さを %n 、 %m.axes 軸',
          polygon_file_format: '3Dモデルを作成。x座標を %n 、y座標を %n 、z座標を %n 、PLYファイル %s',
          animation: 'アニメーション。x座標を %n 、y座標を %n 、z座標を %n 、差分Xを %n 、 差分Yを %n 、 差分Zを %n 、 時間を %n 、回数を %n 、モデルデータを %s',
          map: '地図を作成。地図データを %s 、幅を %n 、高さを %n 、拡大倍率を %n 、（低地の色を r1: %n g1: %n b1: %n ）、（高地の色を r2: %n g2: %n b2: %n ）、上方向へ %n',
          pin: 'ピンを立てる。位置データを %s 、幅を %n 、高さを %n 、拡大倍率を %n 、左上緯度を %n 、左上経度を %n 、右下緯度を %n 、右下経度を %n 横に %n ずらす',
          molecular_structure: '分子構造モデルを作成。x座標を %n 、y座標を %n 、z座標を %n 、拡大倍率を %n 、MLDファイル %s',
          ar_game: 'スプライトを作成。X座標: %n Y座標: %n Z座標: %n スプライト: %m.sprite コスチューム： %m.costume 色: %m.color 向き: %m.direction',
          set_color: 'ブロックの色を変える。r: %n g: %n b: %n',
          set_color_hexadecimal: 'ブロックの色を変える。# %s （16進数）',
          set_alpha: 'ブロックの透明度を変える。alpha: %n',
          change_layer: 'ARのレイヤを変える。レイヤ: %m.layer',
          change_shape: '基本形状を変える。 %m.shape',
          rotate_shape: '基本形状を回転する。rotationX: %n rotationY: %n rotationZ: %n',
          change_material: 'テクスチャを変える。 %m.material',
          change_light: 'ライティングの変更。x: %n y: %n z: %n intensity: %n',
          remove_cube: 'ブロックを消す。x座標を %n 、y座標を %n 、z座標を %n',
          reset: 'リセット'
        },
        en: {
          set_hostname: 'Set hostname to %s',
          connect: 'Connect with ID: %s',
          change_cube_size: 'change cube size maginification: %n',
          set_cube: 'set cube at x: %n y: %n z: %n',
          set_box: 'set box at x: %n y: %n z: %n wide: %n depth: %n height: %n',
          set_cylinder: 'set cylinder at x: %n y: %n z: %n radius: %n height: %n axis: %m.axes',
          set_hexagon: 'set hexagon at x: %n y: %n z: %n radius: %n height: %n axis: %m.axes',
          set_sphere: 'set sphere at x: %n y: %n z: %n radius: %n',
          set_char: 'set char at x: %n y: %n z: %n letter: %s axis: %m.axes',
          set_line: 'set line between x1: %n y1: %n z1: %n and x2: %n y2: %n z2: %n',
          set_roof: 'set roof at x: %n y: %n z: %n wide: %n depth: %n height: %n axis: %m.axes',
          polygon_file_format: 'create 3d model at x: %n y: %n z: %n ply file: %s',
          animation: 'animation at x: %n y: %n z: %n diffX: %n diffY: %n diffZ: %n time: %n times: %n models: %s',
          map: 'draw map from csv: %s width: %n height: %n magnification: %n (lowland r1: %n g1: %n b1: %n ) (highland r2: %n g2: %n b2: %n ) upward: %n',
          pin: 'stand pins at position: %s width: %n height: %n magnification: %n up-left (latitude: %n longitude: %n ) down-right (latitude: %n longitude: %n ) shift %n',
          molecular_structure: 'molecular structure at x: %n y: %n z: %n magnification: %n mld file: %s',
          ar_game: 'spawn sprite at x: %n y: %n z: %n sprite: %m.sprite costume: %m.costume color: %m.color direction: %m.direction',
          set_color: 'set color to r: %n g: %n b: %n',
          set_color_hexadecimal: 'set color to # %s using hexadecimal numbers',
          set_alpha: 'set transparency to alpha: %n',
          change_layer: 'change AR layer: %m.layer',
          change_shape: 'change basic shape: %m.shape',
          rotate_shape: 'rotate basic shape: rotationX: %n rotationY: %n rotationZ: %n',
          change_material: 'change material: %m.material',
          change_light: 'change lighting at x: %n y: %n z: %n intensity: %n',
          remove_cube: 'remove cube at x: %n y: %n z: %n',
          reset: 'reset'
        },
      }

      var descriptor = {
        blocks: [
          [' ', locale[lang].set_hostname, 'set_hostname', hostname],
          [' ', locale[lang].connect, 'connect', '', ''],
          [' ', locale[lang].change_cube_size, 'change_cube_size', 1],
          [' ', locale[lang].set_cube, 'set_cube', 1, 0, 1],
          [' ', locale[lang].set_box, 'set_box', 2, 0, 2, 2, 2, 2],
          [' ', locale[lang].set_cylinder, 'set_cylinder', 3, 0, 3, 4, 4, 'y'],
          [' ', locale[lang].set_hexagon, 'set_hexagon', 4, 10, 10, 6, 4, 'y'],
          [' ', locale[lang].set_sphere, 'set_sphere', 4, 4, 4, 4],
          [' ', locale[lang].set_char, 'set_char', 0, 0, 10, 'A', 'y'],
          [' ', locale[lang].set_line, 'set_line', 0, 0, 0, 10, 10, 10],
          [' ', locale[lang].set_roof, 'set_roof', 0, 3, 0, 14, 10, 7, 'z'],
          [' ', locale[lang].polygon_file_format, 'polygon_file_format', 0, 0, 0, 'model.ply'],
          [' ', locale[lang].animation, 'animation', 0, 0, 0, 1, 0, 0, 2.0, 100, 'model1.ply,model2.ply,model3.ply'],
          [' ', locale[lang].map, 'map', 'map_data.csv', 257, 257, 100, 0, 255, 0, 124, 96, 53, 0],
          [' ', locale[lang].pin, 'pin', 'potision_data.csv', 257, 257, 2, 46.852, 126.738, 29.148, 149.238, 0],
          [' ', locale[lang].molecular_structure, 'molecular_structure', 0, 10, 0, 10, 'methane.mld'],
          [' ', locale[lang].ar_game, 'ar_game', 0, 0, 0, 'spaceship', 'a', 'red', '+y'],
          [' ', locale[lang].set_color, 'set_color', 255, 255, 255],
          [' ', locale[lang].set_color_hexadecimal, 'set_color_hexadecimal', 'ff0000'],
          [' ', locale[lang].set_alpha, 'set_alpha', 1.0],
          [' ', locale[lang].change_layer, 'change_layer', '1'],
          [' ', locale[lang].change_shape, 'change_shape', 'cube'],
          [' ', locale[lang].rotate_shape, 'rotate_shape', 0, 0 ,0],
          [' ', locale[lang].change_material, 'change_material', 'none'],
          [' ', locale[lang].change_light, 'change_light', 10, 10, 10, 1000],
          [' ', locale[lang].remove_cube, 'remove_cube', 1, 0, 1],
          [' ', locale[lang].reset, 'reset']
        ],
        menus: {
          axes: ['x', 'y', 'z'],
          layer: ['1', '2', '3'],
          shape: ['cube', 'sphere', 'cylinder', 'cone', 'pyramid'],
          material: ['none', 'aluminum', 'asphalt', 'brass', 'brick', 'cedar', 'craft', 'grass', 'maple', 'marble01', 'marble02', 'punching metal', 'stainless steel', 'stone01', 'stone02', 'terra cotta', 'earth'],
          sprite: ['spaceship', 'invader', 'human', 'cat', 'dinosaur', 'frog', 'tree', 'car', 'airplane', 'sword', 'fire', 'explosion', '1x1x1', '2x2x2', '4x4x4', '8x8x8'],
          costume: ['a', 'b'],
          color: ['red', 'green', 'blue', 'yellow', 'cyan', 'magenta', 'white', 'black'],
          direction: ['+y', '+x', '+z', '-y', '-x', '-z'],
        }
      };

      ScratchExtensions.register('S2AR(Scratch2ARKit)', descriptor, ext);
  });
})({});
