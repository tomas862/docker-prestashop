# Docker for PrestaShop

This repository contains a working docker configuration, prepared to work with PrestaShop.

`docker-compose.yml` is configured for production, to launch it simply run:
```
docker-compose up
``` 

Development version can be launched using `docker-compose.local.yml` file,
which enables xdebug and phpmyadmin:
```
docker-compose -f docker-compose.yml -f docker-compose.local.yml up
```
