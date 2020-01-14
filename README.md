# binance_bot

Binance tradener robot made from scrach with Ruby.

## 1. Requisites

### 1.1 Binance

```shell
$ gem install binance
```

### 1.2 Binance (Future-API)

Until Craysiii approve my pull request you need use my branch of binance for support future-api:

#### Checkout my branch:
https://github.com/lucribas/binance/tree/support_fufures_api

#### Replace the files of binance gem in your ruby instalation path:
ruby2651\lib\ruby\gems\2.6.0\gems\binance-1.2.0 


### 1.3 Telegram

I use telegram to send messages to my mobile.

```shell
$ gem install telegram-bot-ruby
```


### 1.4 NTP

I use ntp to check if time of my computer is synchronized and to measure the network latency between my computer and Binance server.

```shell
$ gem install ntp
```

### 1.5 Event Machine

[how install EM](docs/)


## 2. Install

Checkout this repository.

## 2.1 Get your API KEYS

Copy secret_keys_template.rb to secret_keys.rb:
```shell
$ cd source
$ cp secret_keys_template.rb secret_keys.rb
```

Open file source/secret_keys.rb and fill the API-KEYs of Binance and your Telegram Bot

### 2.1.1 Binance

go to https://www.binance.com/pt/usercenter/settings/api-management

### 2.1.2 Telegram

go to your Telegram, talk with @BotFather, send cmd: /start, send cmd: /newbot



## 3. run

See [readme of source](source/)


## 3. status
### 3.1 record trades

ready and working since 20/12/2019.

## 3.2 backlog test

ready and working since 20/12/2019.

## 3.3 production execution

working yet.




## study:

[SVM - Support Vector Machine Introduction](https://towardsdatascience.com/support-vector-machine-introduction-to-machine-learning-algorithms-934a444fca47)
