#!/bin/bash

indatafile=$1
inpubkeyfile=$2
outsymkeyfile=$3
outencdatafile=$4

error=0
tmpfile=`mktemp`

if [ "$#" != "4" ]; then
    echo Invalid number of arguments. Call this script like this:
    echo 
    echo "./`basename $BASH_SOURCE` <inpath to source file> <inpath to public key file> <outpath to encrypted symmetric key> <outpath to encrypted file>"
    exit 1
fi

if [ "$OPENSSL_BINARY" == "" ]; then
    OPENSSL_BINARY=openssl
fi

openssl_version=`$OPENSSL_BINARY version 2>&1`
if [ "$?" == "0" ]; then
    echo Found openssl executable $OPENSSL_BINARY
else
    echo Did not find openssl at $OPENSSL_BINARY. Please install to continue!
    exit 1
fi

# Generate random symmetric key
echo Generating random key
key=`$OPENSSL_BINARY rand -base64 128 2>$tmpfile`

if [ ! -s $tmpfile ]; then
    # Encrypt data file with symmetric key
    echo Encrypting data file with symmetric key
    echo $key | $OPENSSL_BINARY enc -aes-256-cbc -salt -in $indatafile -out $outencdatafile -pass stdin 2>$tmpfile
    if [ ! -s $tmpfile ]; then
        # Encrypt symmetric key with public key
        echo Encrypting symmetric key with public key
        echo $key | $OPENSSL_BINARY rsautl -encrypt -inkey $inpubkeyfile -pubin -out $outsymkeyfile 2>$tmpfile
        if [ ! -s $tmpfile ]; then
            echo Successsfully encrypted symmetric key
        else
            error=1
        fi
    else
        error=1
    fi
else
    error=1
fi

if [ "$error" == "1" ]; then
    echo Failed to encrypt file.
fi
exit $error
