#!/bin/sh
docker build --pull -t ucloudant/php:8.1 .
docker push ucloudant/php:8.1
