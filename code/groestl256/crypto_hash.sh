#!/bin/sh

rm -rf crypto_hash
mkdir -p crypto_hash/groestl256/avr8asm/

tests=$(ls -d */ | tr -d / | egrep -v 'crypto_hash')
for file in $tests ; do
    mkdir -p crypto_hash/groestl256/avr8asm/$file
    cp $file/hash.S crypto_hash/groestl256/avr8asm/$file/hash.S
    cp $file/api.h crypto_hash/groestl256/avr8asm/$file/api.h
    echo "avr" >> crypto_hash/groestl256/avr8asm/$file/architectures
    echo "Johannes Feichtner" >> crypto_hash/groestl256/avr8asm/$file/implementors

    sed 's/crypto_hash_groestl256_8bit_asm/crypto_hash_groestl256_avr8asm_'$file'/g' crypto_hash/groestl256/avr8asm/$file/hash.S >> crypto_hash/groestl256/avr8asm/$file/hash_new.S
    mv crypto_hash/groestl256/avr8asm/$file/hash_new.S crypto_hash/groestl256/avr8asm/$file/hash.S

    tar -czf groestl-avr8asm-1.0.tar.gz crypto_hash
done

