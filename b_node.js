const WebSocket = require('ws');

//const ws = new WebSocket('wss://stream.binance.com:9443/ws/btcusdt@trade');
const ws = new WebSocket('wss://fstream.binance.com/ws/btcusdt@trade');

ws.on('message', function incoming(data) {
    console.log(data);
});
