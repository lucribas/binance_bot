# Running

There are two modes of running:

(1) Record Trades and Backlog Tester
- Use to develop and tunning your trade strategy
- All trades are recorded into a file
- Anytime you can execute the backlog tester and check how your bot will perform

(2) Production 
- Use the production to run your bot in live (be caution!)

======================================================================
# 1. TRADE RECORD

## 1.1 Linux

```shell
export TRADE_DISABLE=1
export TRADE_REALTIME_DISABLE=1
export RECORD_ONLY=1

nohup ruby tradener.rb &
```

## 1.2 Windows

```shell
$env:TRADE_DISABLE=1
$env:TRADE_REALTIME_DISABLE=1
$env:RECORD_ONLY=1
$env:TELEGRAM_DISABLE=1

ruby tradener.rb
```

======================================================================
# 2. TRADE PLAY - Backlog tester
## 2.1 Linux
How execure the backlog tester using a dump of recorded trades:

```shell
export TRADE_REALTIME_DISABLE=1
ruby .\play_trade.rb -r rec\TRADE_20191204_001437.dmp  -p

```
## 2.2 Windows

```shell
$env:TRADE_REALTIME_DISABLE=1
ruby .\play_trade.rb -r rec\TRADE_20191204_001437.dmp  -p
```

======================================================================
# 3. Telegram disable
How disable telegram to send messages

## 3.1 Linux

```shell
export TELEGRAM_DISABLE=1
```

## 3.2 Windows

```shell
$env:TELEGRAM_DISABLE=1
```


