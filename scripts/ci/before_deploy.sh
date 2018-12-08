#!/bin/sh

wget -O hypercli.tar.gz https://github.com/hyperhq/hypercli/archive/v1.10.16.tar.gz && tar xvvf hypercli.tar.gz && pushd hypercli-1.10.16 && chmod +x ./build.sh && ./build.sh
