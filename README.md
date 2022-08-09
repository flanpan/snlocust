# snlocust
## Description
A high performence load test tool, implement with [skynet](https://github.com/cloudwu/skynet) and [locust](https://github.com/locustio/locust).

## Design
```mermaid
flowchart TD;
browser[browser 1..n]<--http get data-->web
agent[agent 1..n]-->stats[stats 1..n]-->web
agent-->counter[counter 1..n]-->web
logger-->web--websocket push log-->browser
```

## Install
pull submodule
```
git submodule update --init
```
build linux
```
make linux
```
or macosx
```
make macosx
```

## run
```
./start.sh
```
open the browser with default url http://127.0.0.1:8001 