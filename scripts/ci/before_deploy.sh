#!/bin/bash

wget -O hypercli.tar.gz https://github.com/hyperhq/hypercli/archive/v1.10.16.tar.gz && tar xvvf hypercli.tar.gz && cd hypercli-1.10.16 && chmod +x ./build.sh && ./build.sh && cd ..
