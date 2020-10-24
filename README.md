# binance_bot

Binance tradener robot made from scrach with Ruby.

## 1. Requisites

### 1.1 Binance

```shell
$ gem install binance
```

### 1.2 Binance (Future-API)

Until Craysiii approve my [pull request](https://github.com/craysiii/binance/pull/37) you need use my branch for support future-api:

#### Checkout my branch:
https://github.com/lucribas/binance/tree/support_fufures_api

#### Replace the files of binance gem in your ruby instalation path:
ruby2651\lib\ruby\gems\2.6.0\gems\binance-1.2.0 


### 1.3 Telegram

Use telegram bot to send messages to your telegram.

```shell
$ gem install telegram-bot-ruby
```


### 1.4 NTP

Use ntp to check if time of you computer is synchronized.
Then it allow measure the network latency between your computer and Binance server.

```shell
$ gem install ntp
```

### 1.5 Event Machine

[how install EM](docs/)

### 1.6 Other gems

```shell
$ cd source
$ bundle install
```

## 2. Install

Checkout this repository.
https://github.com/lucribas/binance_bot.git

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
save your API-KEYs

## 3. Run

See [readme](source/) of source code


## 4. Project status
### 4.1 record trades

ready and working since 20/12/2019.

### 4.2 backlog test

ready and working since 20/12/2019.

### 4.3 production execution

ready to test.




## 5. To be done

Use machine learning algorithms:
[SVM - Support Vector Machine Introduction](https://towardsdatascience.com/support-vector-machine-introduction-to-machine-learning-algorithms-934a444fca47)
