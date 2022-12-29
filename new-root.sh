#!/bin/bash

set -e
source ./commons.sh

if [ -d "$ROOT_DIR" ];
then
	echo "Warning: Root Directory already exists! Continuing will result in all its contents being overriden."
	read -p "Would you like to override it? (yes/no) " yn
	
	case $yn in
		yes|y)echo "Continuing...";
			set +e;
			rm $ROOT_DIR -r &> /dev/null;
			rm $CERTS_DIR -r &> /dev/null;;
		no|n)	echo "Operation cancelled by user";
			exit;;
		*)	echo "Invalid option, aborting";
			exit 1;;
	esac
fi


echo "Generating new root certificate authority private $ALG key"
read -esp "Passphrase for the private key: " PASS
echo
read -esp "Confirm passphrase: " CONFIRM_PASS

if [ "$PASS" != "$CONFIRM_PASS" ]; then
	echo "Could not confirm passphrase, exiting..."
	exit 1
fi

read -p "For how long should your CA certificate be valid for in years: (default 10) " CA_YEARS
CA_YEARS=${CA_YEARS:-10}
echo "Generating new root certificare valid for $CA_YEARS years"

mkdir $ROOT_DIR

case $ALG in
	# for root ec anything above 384 is ok
	ec)	PRIVATE_KEY_OPT=ec_paramgen_curve:secp384r1;;

	# for root rsa anything above 4096 is ok
	rsa)	PRIVATE_KEY_OPT=bits:4096;;
esac

# fine to use aes 256 cbc since its virtually impenetrable using brute-force
openssl genpkey \
	-algorithm $ALG \
	-pkeyopt $PRIVATE_KEY_OPT \
	-aes-256-cbc \
	-pass "pass:$PASS" \
	-out $ROOT_DIR/ca.key

# can go for sha384 too
openssl req \
	-x509 \
	-new \
	-nodes \
	-key $ROOT_DIR/ca.key \
	-passin "pass:$PASS" \
	-sha256 \
	-days $(expr $CA_YEARS \* 365) \
	-subj "/C=$C/O=$O/OU=$ROOT_OU/CN=$ROOT_CN/emailAddress=$E" \
	-out $ROOT_DIR/ca.crt

touch $ROOT_DIR/index.txt
echo "01" >> $ROOT_DIR/srl

echo "Done, certificates can be found in $ROOT_DIR/"
