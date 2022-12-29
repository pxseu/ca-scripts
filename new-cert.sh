#!/bin/bash

set -e

source ./commons.sh

if [ ! -d "$ROOT_DIR" ];
then
	echo "Root directory not found. Run ./new-root.sh first"
	exit 1
fi



echo "Provide the domain name you would like to create the cert for:"
read DOMAIN_NAME


if [ -d "$CERTS_DIR/$DOMAIN_NAME" ];
then
	read -p "Certificate for this domain was already issued, would you like to override it? (yes/no) " yn
	
	case $yn in
		yes|y)echo "Continuing...";
			rm -r $CERTS_DIR/$DOMAIN_NAME;;
		no|n)	echo "Operation cancelled by user";
			exit;;
		* )	echo "Invalid option, aborting";
			exit 1;;
	esac
fi

echo "Provide the Orginisation Name for the certificate:"
read CERT_ORG

echo "Creating certficate for $DOMAIN_NAME with $ALG private key"

mkdir -p $CERTS_DIR/$DOMAIN_NAME

case $ALG in
	# for ec anything above 256 is ok
	ec)	TMP=`mktemp "/tmp/ec-param.XXXXXXX"`
		openssl ecparam -name secp384r1 > $TMP
		NEW_KEY_VALUE="ec:$TMP";;
	# for rsa anything above 2048 is ok
	rsa)	NEW_KEY_VALUE=rsa:4096;;
esac

openssl req \
	-new \
	-nodes \
	-out $CERTS_DIR/$DOMAIN_NAME/csr \
	-newkey $NEW_KEY_VALUE \
	-keyout $CERTS_DIR/$DOMAIN_NAME/key \
	-subj "/CN=$DOMAIN_NAME/C=$C/O=$CERT_ORG/emailAddress=$E/OU=$OU"

set +e
rm $TMP &> /dev/null
set -e

cat > $CERTS_DIR/$DOMAIN_NAME/ext << EOF
authorityKeyIdentifier=keyid,issuer
subjectKeyIdentifier=hash
subjectAltName = @alt_names
extendedKeyUsage = serverAuth, clientAuth
basicConstraints=critical, CA:FALSE
keyUsage = critical, digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment


[alt_names]
DNS.1=$DOMAIN_NAME
EOF

openssl x509 \
	-req \
	-in $CERTS_DIR/$DOMAIN_NAME/csr \
	-CA $ROOT_DIR/ca.crt \
	-CAkey $ROOT_DIR/ca.key \
	-CAserial $ROOT_DIR/srl \
	-CAcreateserial \
	-out $CERTS_DIR/$DOMAIN_NAME/crt \
	-days 730 \
	-sha256 \
	-extfile $CERTS_DIR/$DOMAIN_NAME/ext

echo "Done, outputed to $CERTS_DIR/$DOMAIN_NAME"

# https://arminreiter.com/2022/01/create-your-own-certificate-authority-ca-using-openssl/
# https://deliciousbrains.com/ssl-certificate-authority-for-local-https-development/
# get all prime bit sizes for ec
# openssl ecparam -list_curves | grep -o "secp[[:digit:]]*r1" | sed -e "s/secp//" | sed -e "s/r1//"
