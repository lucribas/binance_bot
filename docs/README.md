
======================================================================
# 1. HOW install EM

* need improve step by step text

https://github.com/eventmachine/eventmachine/issues/689
```shell
gem uninstall eventmachine
gem install --platform ruby eventmachine
```


Install the MSYS2 DevKit:

```shell
ridk install
```
Then run all the 3 options


Install the openssl library from the MSYS2 repositories:
```shell
ridk exec pacman -S mingw-w64-x86_64-openssl
```

Install eventmachine with the following command:
(change the path for the --with-ssl-dir install flag to match your MSYS2 DevKit directory)
```shell
gem install eventmachine --platform ruby -- --use-system-libraries --with-ssl-dir=c:/ruby/msys64/mingw64
```



```shell
.\ridk.cmd install
.\ridk.cmd exec pacman -S mingw-w64-x86_64-openssl

gem install eventmachine --platform ruby -- --use-system-libraries --with-ssl-dir=F:\tools\ruby2651\msys64\mingw64
```



------
in my windows machine

Install the MSYS2 DevKit:

```shell
ridk install
```
Then run all the 3 options

Install the openssl library from the MSYS2 repositories:
```shell
ridk exec pacman -S mingw-w64-x86_64-openssl

gem install eventmachine --platform ruby -- --use-system-libraries --with-ssl-dir=I:\sw_apps\Ruby26-x64\msys64\mingw64


gem install bundler
bundle install
```