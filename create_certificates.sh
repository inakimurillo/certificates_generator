#!/bin/bash

## Iñaki Murillo 2016
## email: inakimurillo@gmail.com
## https://kb.wisc.edu/middleware/page.php?id=4543
## https://www.openssl.org/docs/manmaster/apps/verify.html
## https://www.madboa.com/geek/openssl/#cert-self
## https://datacenteroverlords.com/2012/03/01/creating-your-own-ssl-certificate-authority/
## https://jamielinux.com/docs/openssl-certificate-authority/

#Variables
CAFOLDER="CA" ### Must be the same as in the openssl.conf file!!
PRIVATEFOLDER="private"
CERTFOLDER="certs"
NEWCERTFOLDER="newcerts"
CRLFOLDER="crl"
CSRFOLDER="csr"
CAKEY="ca.key.pem"
CACERT="ca.cert.pem"
INTERMEDIATEKEY="intermediate.key.pem"
INTERMEDIATECERT="intermediate.cert.pem"
INTERMEDIATECSR="intermediate.csr.pem"
INTERMEDIATECAFOLDER="intermediate"
INTERMEDIATECHAINCERT="ca-chain.cert.pem"

DEPLOYFOLDER="deploy"

DEVICEFOLDER="device_"
DEVICEKEY="device.key"
DEVICECSR="device.csr"
DEVICECRT="device.crt"


echo "***************************************************"
echo "This script is intended to be an example of how"
echo "to create a private CA and how to sign device "
echo "certificates."
echo ""
echo "Iñaki Murillo"
echo "***************************************************"
echo ""

function menu {
  echo "Choose:"
  echo "    1- Theory"
  echo "    2- Create root CA (key and self signed certificate)"
  echo "    3- Create CA intermediate (key and certificate signed by root CA)"
  echo "    4- [DO NOT USE!] Create device (key and signed certificate with rootCA)"
  echo "    5- Create server certificate (key and signed certificate with intermediate CA)"
  echo "    6- Create client certificate (key and signed certificate with intermediate CA)"
  echo "    7- Check every device"
  echo "    8- Clear everything"
  echo "    0- Exit"

  read -s -n 1 C

  case "$C" in
    1)
     print_theory
     menu
     ;;
    2)
     create_rootCA
     menu
     ;;
    3)
      create_intermediate_CA
      menu
      ;;
    4)
     create_device_rootCA
     menu
     ;;
    5)
     create_server_certificate_intermediate_CA
     menu
     ;;
    6)
     create_client_certificate_intermediate_CA
     menu
     ;;
    7)
     check_certificates
     menu
     ;;
    8)
     clear_everything
     initialize
     menu
     ;;
    0)
     echo "Exit"
     exit
     ;;
    *)
     #echo "This is the default case"
     menu
  esac
}

function print_theory {
  echo ""
  echo "THEORY"
  echo ""
  echo "First of all, is neccesary to create a private key, which will"
  echo "be used to sign device certificates. After that is neccesary to"
  echo "create a self-signed certificate, which will be used to sign "
  echo "device certificates and to check its value. Those file will be"
  echo "stored in a folder called \"$CAFOLDER\"."
  echo ""
  echo "Now that we have the CA private key and certificate generated, "
  echo "is time to create each devices private key, signing request and"
  echo "the device certificate. The fist two is straigt foward, while "
  echo "the device's certificate needs the CA's private key and rootCA.pem"
  echo "Everything will be created inside a folder called \"$DEVICEFOLDER\""
  echo "plus a number."
  echo ""
  echo "Finaly, there be a way to check whether the created device's "
  echo "certificate is valid or not. So it will be neccesary to have the "
  echo "CA's certificate."
  echo ""
  echo "End of theory"
  echo ""
}

function initialize {
  if [ ! -d "$CAFOLDER" ]; then
    echo ""
    echo "Creating $CAFOLDER folder"
    mkdir $CAFOLDER
    echo ""
  fi

  if [ ! -d "$CAFOLDER/$PRIVATEFOLDER" ]; then
    echo ""
    echo "Creating $CAFOLDER/$PRIVATEFOLDER folder"
    mkdir $CAFOLDER/$PRIVATEFOLDER
    echo ""
  fi

  if [ ! -d "$CAFOLDER/$CERTFOLDER" ]; then
    echo ""
    echo "Creating $CAFOLDER/$CERTFOLDER folder"
    mkdir $CAFOLDER/$CERTFOLDER
    echo ""
  fi

  if [ ! -d "$CAFOLDER/$NEWCERTFOLDER" ]; then
    echo ""
    echo "Creating $CAFOLDER/$NEWCERTFOLDER folder"
    mkdir $CAFOLDER/$NEWCERTFOLDER
    echo ""
  fi

  if [ ! -d "$CAFOLDER/$CRLFOLDER" ]; then
    echo ""
    echo "Creating $CAFOLDER/$CRLFOLDER folder"
    mkdir $CAFOLDER/$CRLFOLDER
    echo ""
  fi

  if [ ! -f "./$CAFOLDER/index.txt" ]; then
    echo ""
    echo "Creating index.txt"
    touch "./$CAFOLDER/index.txt"
    echo ""
  fi

  if [ ! -f "./$CAFOLDER/serial" ]; then
    echo ""
    echo "Creating serial"
    echo 1000 > ./$CAFOLDER/serial
    echo ""
  fi

  if [ ! -d "$INTERMEDIATECAFOLDER" ]; then
    echo ""
    echo "Creating $INTERMEDIATECAFOLDER folder"
    mkdir $INTERMEDIATECAFOLDER
    echo ""
  fi

  if [ ! -d "$INTERMEDIATECAFOLDER/$PRIVATEFOLDER" ]; then
    echo ""
    echo "Creating $INTERMEDIATECAFOLDER/$PRIVATEFOLDER folder"
    mkdir $INTERMEDIATECAFOLDER/$PRIVATEFOLDER
    echo ""
  fi

  if [ ! -d "$INTERMEDIATECAFOLDER/$CERTFOLDER" ]; then
    echo ""
    echo "Creating $INTERMEDIATECAFOLDER/$CERTFOLDER folder"
    mkdir $INTERMEDIATECAFOLDER/$CERTFOLDER
    echo ""
  fi

  if [ ! -d "$INTERMEDIATECAFOLDER/$NEWCERTFOLDER" ]; then
    echo ""
    echo "Creating $INTERMEDIATECAFOLDER/$NEWCERTFOLDER folder"
    mkdir $INTERMEDIATECAFOLDER/$NEWCERTFOLDER
    echo ""
  fi

  if [ ! -d "$INTERMEDIATECAFOLDER/$CRLFOLDER" ]; then
    echo ""
    echo "Creating $INTERMEDIATECAFOLDER/$CRLFOLDER folder"
    mkdir $INTERMEDIATECAFOLDER/$CRLFOLDER
    echo ""
  fi

  if [ ! -d "$INTERMEDIATECAFOLDER/$CSRFOLDER" ]; then
    echo ""
    echo "Creating $INTERMEDIATECAFOLDER/$CSRFOLDER folder"
    mkdir $INTERMEDIATECAFOLDER/$CSRFOLDER
    echo ""
  fi

  if [ ! -f "./$INTERMEDIATECAFOLDER/index.txt" ]; then
    echo ""
    echo "Creating index.txt"
    touch "./$INTERMEDIATECAFOLDER/index.txt"
    echo ""
  fi

  if [ ! -f "./$INTERMEDIATECAFOLDER/serial" ]; then
    echo ""
    echo "Creating serial"
    echo 1000 > ./$INTERMEDIATECAFOLDER/serial
    echo ""
  fi

  if [ ! -d "$DEPLOYFOLDER" ]; then
    echo ""
    echo "Creating $DEPLOYFOLDER folder"
    mkdir $DEPLOYFOLDER
    echo ""
  fi

}

function create_rootCA {
  if [ ! -f "$CAFOLDER/$PRIVATEFOLDER/$CAKEY" ]; then
    #touch $CAFOLDER/$CAKEY
    echo ""
    echo "Creating CA key"
    openssl genrsa -aes256 -out "$CAFOLDER/$PRIVATEFOLDER/$CAKEY" 4096
    echo "Done"
    echo ""
  else
    echo "CA key already created"
  fi

  if [ ! -f "./$CAFOLDER/$CERTFOLDER/$CACERT" ]; then
    #touch $CAFOLDER/$CAKEY
    echo ""
    echo "Creating CA certificate"
    openssl req -config openssl.conf -x509 -new -nodes -key ./$CAFOLDER/$PRIVATEFOLDER/$CAKEY -sha256 -days 7300 -extensions v3_ca -out ./$CAFOLDER/$CERTFOLDER/$CACERT
    echo "Done"
    echo ""
    echo ""
    echo "Verify certificate:"
    openssl x509 -noout -text -in ./$CAFOLDER/$CERTFOLDER/$CACERT
  else
    echo "CA certificate already created"
  fi
}

function create_intermediate_CA {
  if [ ! -f "$INTERMEDIATECAFOLDER/$PRIVATEFOLDER/$INTERMEDIATEKEY" ]; then
    #touch $CAFOLDER/$CAKEY
    echo ""
    echo "Creating CA key"
    openssl genrsa -aes256 -out "./$INTERMEDIATECAFOLDER/$PRIVATEFOLDER/$INTERMEDIATEKEY" 4096
    echo "Done"
    echo ""
  else
    echo "CA key already created"
  fi

  if [ ! -f "./$INTERMEDIATECAFOLDER/$CSRFOLDER/$INTERMEDIATECSR" ]; then
    #touch $CAFOLDER/$CAKEY
    echo ""
    echo "Creating CA certificate request"
    openssl req -config openssl_intermediate.conf -new -sha256 \
      -key ./$INTERMEDIATECAFOLDER/$PRIVATEFOLDER/$INTERMEDIATEKEY \
      -out ./$INTERMEDIATECAFOLDER/$CSRFOLDER/$INTERMEDIATECSR
    echo "Done"
    echo ""
    echo "Creating intermediate CA certificate"
    openssl ca -config openssl.conf -extensions v3_intermediate_ca \
      -days 3650 -notext -md sha256 \
      -in ./$INTERMEDIATECAFOLDER/$CSRFOLDER/$INTERMEDIATECSR \
      -out ./$INTERMEDIATECAFOLDER/$CERTFOLDER/$INTERMEDIATECERT
    echo ""

    cat ./$INTERMEDIATECAFOLDER/$CERTFOLDER/$INTERMEDIATECERT ./$CAFOLDER/$CERTFOLDER/$CACERT > ./$INTERMEDIATECAFOLDER/$CERTFOLDER/$INTERMEDIATECHAINCERT
  else
    echo "CA certificate already created"
  fi
}

function create_device_rootCA {
  if [ ! -f "$CAFOLDER/$CAKEY" ] || [ ! -f "$CAFOLDER/$CACERT" ]; then
    echo ""
    echo "You must create CA kay and certificate before this!"
    echo ""
    return
  fi

  current_folder=$DEVICEFOLDER
  current_folder+="001"
  if [ ! -d "$current_folder" ]; then
    mkdir "$current_folder"
  else
    targets=( $DEVICEFOLDER* )              # all dirs in an array
    lastdir=${targets[@]: (-1):1}           # select filename from last array element
    lastdir=${lastdir##*/}                  # remove path
    lastnumber=${lastdir/$DEVICEFOLDER/}    # remove '$DEVICEFOLDER'
    lastnumber=00$(( 10#$lastnumber + 1 ))  # increment number (base 10), add leading zeros
    current_folder=$DEVICEFOLDER
    current_folder+=${lastnumber: -3}
    mkdir $current_folder      # make dir; last 3 chars from lastnumber
  fi

  # Create key
  openssl genrsa -out $current_folder/$DEVICEKEY 2048

  # Generate the certificate signing request.
  openssl req -new -key $current_folder/$DEVICEKEY -out $current_folder/$DEVICECSR

  # This creates a signed certificate called device.crt
  openssl x509 -req -in $current_folder/$DEVICECSR -CA $CAFOLDER/$CACERT -CAkey $CAFOLDER/$CAKEY -CAcreateserial -out $current_folder/$DEVICECRT -days 500 -sha256

}

function create_server_certificate_intermediate_CA {
  echo ""
  echo "Creating a server certificate"
  echo "Insert Name: (www.example.com)"
  read NAME

  echo ""
  echo "Creating private key"
  openssl genrsa -aes256 \
      -out $INTERMEDIATECAFOLDER/$PRIVATEFOLDER/"$NAME"".key.pem" 2048

  echo ""
  echo "Creating Certificate Sign request"
  openssl req -config openssl_intermediate.conf \
          -key $INTERMEDIATECAFOLDER/$PRIVATEFOLDER/"$NAME"".key.pem" \
          -new -sha256 -out $INTERMEDIATECAFOLDER/$CSRFOLDER/"$NAME"".csr.pem"

  echo ""
  echo "Signning certificate"
  openssl ca -config openssl_intermediate.conf \
      -extensions server_cert -days 375 -notext -md sha256 \
      -in $INTERMEDIATECAFOLDER/$CSRFOLDER/"$NAME"".csr.pem" \
      -out $INTERMEDIATECAFOLDER/$CERTFOLDER/"$NAME"".cert.pem"

  echo ""
  echo "Moving to deploy"
  cp $INTERMEDIATECAFOLDER/$CERTFOLDER/"$NAME"".cert.pem" $DEPLOYFOLDER
  cp $INTERMEDIATECAFOLDER/$PRIVATEFOLDER/"$NAME"".key.pem" $DEPLOYFOLDER
  cp $INTERMEDIATECAFOLDER/$CERTFOLDER/$INTERMEDIATECHAINCERT $DEPLOYFOLDER
}

function create_client_certificate_intermediate_CA {
  echo ""
  echo "Creating a client certificate"
  echo "Insert Name: (www.example.com)"
  read NAME

  echo ""
  echo "Creating private key"
  openssl genrsa -aes256 \
      -out $INTERMEDIATECAFOLDER/$PRIVATEFOLDER/"$NAME"".key.pem" 2048

  echo ""
  echo "Creating Certificate Sign request"
  openssl req -config openssl_intermediate.conf \
          -key $INTERMEDIATECAFOLDER/$PRIVATEFOLDER/"$NAME"".key.pem" \
          -new -sha256 -out $INTERMEDIATECAFOLDER/$CSRFOLDER/"$NAME"".csr.pem"

  echo ""
  echo "Signning certificate"
  openssl ca -config openssl_intermediate.conf \
      -extensions usr_cert -days 375 -notext -md sha256 \
      -in $INTERMEDIATECAFOLDER/$CSRFOLDER/"$NAME"".csr.pem" \
      -out $INTERMEDIATECAFOLDER/$CERTFOLDER/"$NAME"".cert.pem"

  echo ""
  echo "Moving to deploy"
  cp $INTERMEDIATECAFOLDER/$CERTFOLDER/"$NAME"".cert.pem" $DEPLOYFOLDER
  cp $INTERMEDIATECAFOLDER/$PRIVATEFOLDER/"$NAME"".key.pem" $DEPLOYFOLDER
  cp $INTERMEDIATECAFOLDER/$CERTFOLDER/$INTERMEDIATECHAINCERT $DEPLOYFOLDER
}

function check_certificates {
  echo ""
  echo "Execute:"
  echo "    openssl verify -verbose -CAfile rootCA.pem  device.crt"
}

function clear_everything {
   rm -r $CAFOLDER/*
   rm -r $INTERMEDIATECAFOLDER/*
   rm -r $DEPLOYFOLDER/*
}

initialize
menu
