#!/bin/bash

indatafile=$1
inprivkeyfile=$2
insymkeyfile=$3
outdecdatafile=$4

error=0
tmpfile=`mktemp`

if [ "$#" != "4" ]; then
    echo Invalid number of arguments. Call this script like this:
    echo 
    echo "./`basename $BASH_SOURCE` <inpath to encrypted file> <inpath to private key file> <inpath to encrypted symmetric key> <outpath to decrypted file>"
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

# Decrypting symmetric key
echo Decrypting symmetric key
key=`$OPENSSL_BINARY rsautl -decrypt -inkey $inprivkeyfile -in $insymkeyfile 2>$tmpfile`

if [ ! -s $tmpfile ]; then
    # Decrypt data file with symmetric key
    echo Decrypting data file with symmetric key
    echo $key | $OPENSSL_BINARY enc -d -aes-256-cbc -in $indatafile -out $outdecdatafile -pass stdin 2>$tmpfile
    if [ ! -s $tmpfile ]; then
        echo Successfully decrypted file
    else
        $error=1
    fi
else
    $error=1
fi

if [ "$error" == "1" ]; then
    echo Failed to encrypt data file
    exit -1
fi
