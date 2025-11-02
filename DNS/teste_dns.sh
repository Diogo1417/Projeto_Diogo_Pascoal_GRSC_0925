#!/bin/bash

echo "Bind"
dig @192.168.1.192 empresa.local

echo "NSLOOKUP"
nslookup servidor1.empresa.local 192.168.1.192

echo "Teste Inverso"
dig -x 192.168.1.192

echo "Teste de Encaminhamento"
ping www.google.com