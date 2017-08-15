FROM ubuntu:latest

RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends simulavr make avr-libc gdb-avr;

COPY code /code
