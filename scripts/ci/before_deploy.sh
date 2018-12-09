#!/bin/bash

wget -O hyper.tar.gz https://hyper-install.s3.amazonaws.com/hyper-linux-x86_64.tar.gz && \
tar xvvf hyper.tar.gz && \
sudo mv hyper /usr/local/bin && \
hyper --version
