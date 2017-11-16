(function(ext) {
  var ip = "";
  var connected = false;

  ext._shutdown = function() {};

  ext._getStatus = function() {
      return {status: 2, msg: 'Ready'};
  };

  ext.set_cube = function(x, y, z) {
    if (!connected) {
      ws = new WebSocket('ws://' + ip + ':3000');
    } else {
      ws.send("set_cube:" + x + ":" + y + ":" + z);
    }
    ws.onopen = function(){ connected = true; ws.send("set_cube:" + x + ":" + y + ":" + z); };
    ws.onclose = function(){ connected = false; };
  }

  ext.set_color = function(r, g, b) {
    if (!connected) {
      ws = new WebSocket('ws://' + ip + ':3000');
    } else {
      ws.send("set_color:" + r + ":" + g + ":" + b);
    }
    ws.onopen = function(){ connected = true; ws.send("set_color:" + r + ":" + g + ":" + b); };
    ws.onclose = function(){ connected = false; };
  }

  ext.reset = function() {
    if (!connected) {
      ws = new WebSocket('ws://' + ip + ':3000');
    } else {
      ws.send("reset");
    }
    ws.onopen = function(){ connected = true; ws.send("reset"); };
    ws.onclose = function(){ connected = false; };
  }

  ext.set_ip = function(str) {
    ip = str;
  };

  var lang = ((navigator.language || navigator.userLanguage) == 'ja') ? 'ja' : 'en';
  var locale = {
    ja: {
      set_ip: '接続先IPを %s に設定する',
      set_cube: 'x座標を %n 、y座標を %n 、z座標を %n にブロックを置く',
      set_color: 'ブロックの色を r: %n g: %n b: %n に変える',
      reset: 'リセット'
    },
    en: {
      set_ip: 'Set IP address to %s',
      set_cube: 'set cube at x: %n y: %n z: %n',
      set_color: 'set color to r: %n g: %n b: %n',
      reset: 'reset'
    },
  }

  var descriptor = {
    blocks: [
      [' ', locale[lang].set_ip, 'set_ip', ip],
      [' ', locale[lang].set_cube, 'set_cube', 0.01, 0.01, 0.01],
      [' ', locale[lang].set_color, 'set_color', 255, 255, 255],
      [' ', locale[lang].reset, 'reset']
    ]
  };

  ScratchExtensions.register('Scratch2ARKit', descriptor, ext);
})({});
