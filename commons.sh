#!/bin/bash

# default algorith, possible: ec | rsa
ALG="ec"

# allow the alg to be override by the shell argument
ALG="${1:-$ALG}"

case $ALG in
	rsa )	;;
	ec )	;;
	* )	echo "Invalid algorith, can be rsa or ec";
		exit 1;;
esac

# dirs
ROOT_DIR=./root
CERTS_DIR=./certs
