# MyRocks Benchmark on Vector Data

[MyRocks](https://myrocks.io/) is a RocksDB storage engine for MySQL database developed by facebook.

This repo benchmarks the performance of MyRocks with vector data, especially considering multi-vector queries.

## MyRocks

MyRocks can be built manually following the official [Getting Started](https://myrocks.io/docs/getting-started/).

Alternatively, a docker container has been provided. To build the docker container:

``` bash
# build MyRocks docker container
docker build -t myrocks:latest -f ./Dockerfile .
# run MyRocks docker container with port-forwarding
docker run -d -p 3306:3306 myrocks:latest
# connect database with mysql client (password can be configured in Dockerfile argument)
mysql -u root -h 127.0.0.1 -P 3306 -p
```
