#!/bin/sh

set -e

python -c 'import socket; socket.socket(socket.AF_INET, socket.SOCK_STREAM).connect(("localhost", 8081))'
python -c 'import socket; socket.socket(socket.AF_INET, socket.SOCK_STREAM).connect(("localhost", 8082))'
python -c 'import socket; socket.socket(socket.AF_INET, socket.SOCK_STREAM).connect(("localhost", 8083))'
