#!/bin/bash

echo "Ver leases.."
sudo cat /var/lib/kea/kea-leases4.csv

echo "Verficação de escuta.."
sudo ss -lun | grep 67
