(function(ext) {
  var ip;

  ext._shutdown = function() {};

  ext._getStatus = function() {
      return {status: 2, msg: 'Ready'};
  };

  ext.translate_x = function(value) {
    var ws = new WebSocket('ws://' + ip + ':3000');
    ws.onopen = function(){ ws.send("translate_x:" + value); };
  };

  ext.translate_y = function(value) {
    var ws = new WebSocket('ws://' + ip + ':3000');
    ws.onopen = function(){ ws.send("translate_y:" + value); };
  };

  ext.translate_z = function(value) {
    var ws = new WebSocket('ws://' + ip + ':3000');
    ws.onopen = function(){ ws.send("translate_z:" + value); };
  };

  ext.set_ip = function(str) {
    ip = str;
  };

  var lang = ((navigator.language || navigator.userLanguage) == 'ja') ? 'ja' : 'en';
  var locale = {
    ja: {
      set_ip: '接続先IPを %s に設定する',
      translate_x: 'x座標を %n ずつ変える',
      translate_y: 'y座標を %n ずつ変える',
      translate_z: 'z座標を %n ずつ変える'
    },
    en: {
      set_ip: 'Set IP address to %s',
      translate_x: 'change x by %n',
      translate_y: 'change y by %n',
      translate_z: 'change z by %n',
    },
  }

  var descriptor = {
    blocks: [
      [' ', locale[lang].set_ip, 'set_ip', ip],
      [' ', locale[lang].translate_x, 'translate_x', 0.1],
      [' ', locale[lang].translate_y, 'translate_y', 0.1],
      [' ', locale[lang].translate_z, 'translate_z', 0.1]
    ]
  };

  ScratchExtensions.register('Scratch2ARKit', descriptor, ext);
})({});
