#!/bin/bash

echo "Ver leases.."
sudo cat /var/lib/kea/kea-leases4.csv

echo "Teste de logs.."
sudo tail -f /var/log/kea-dhcp4.log

echo "Verficação de escuta.."
sudo ss -lun | grep 67