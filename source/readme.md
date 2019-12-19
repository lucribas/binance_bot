

======================================================================
# 1. TRADE RECORD

## 1.1 Linux

```
export TRADE_DISABLE=1
export TRADE_REALTIME_DISABLE=1
export RECORD_ONLY=1

nohup ruby tradener.rb &
```
## 1.2 Windows
```
$env:TRADE_DISABLE=1
$env:TRADE_REALTIME_DISABLE=1
$env:RECORD_ONLY=1
$env:TELEGRAM_DISABLE=1

ruby tradener.rb
```

======================================================================
# 2. TRADE PLAY
## 2.1 Linux
Como rodar o player para fazer backtest com o que foi gravado:

```
export TRADE_REALTIME_DISABLE=1
ruby .\play_trade.rb -r rec\TRADE_20191204_001437.dmp  -p

```
## 2.2 Windows
```
$env:TRADE_REALTIME_DISABLE=1
ruby .\play_trade.rb -r rec\TRADE_20191204_001437.dmp  -p
```

======================================================================
# 3. Desabilitar o Telegram

## 3.1 Linux
```
export TELEGRAM_DISABLE=1
```

## 3.2 Windows
```
$env:TELEGRAM_DISABLE=1
```
