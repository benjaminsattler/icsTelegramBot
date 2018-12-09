#!/bin/bash

openssl aes-256-cbc -K $encrypted_31ee9ec10cd4_key -iv $encrypted_31ee9ec10cd4_iv -in production.env.enc -out docker/production.env -d && \
wget -O hyper.tar.gz https://hyper-install.s3.amazonaws.com/hyper-linux-x86_64.tar.gz && \
tar xvvf hyper.tar.gz && \
sudo mv hyper /usr/local/bin && \
hyper --version
