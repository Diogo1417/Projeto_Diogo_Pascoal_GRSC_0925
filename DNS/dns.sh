#!/bin/bash
#variaveis
echo "A instalar o dns.."
sudo dnf -y install bind bind-utils

echo "A configurar os arquivos.."
sudo tee /etc/named.conf > /dev/null << END
acl internal-network {
        192.168.1.0/24;
};

options {
        // change ( listen all )
        listen-on port 53 { any; };
        // change if need ( if not listen IPv6, set [none] )
        listen-on-v6 { any; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        secroots-file   "/var/named/data/named.secroots";
        recursing-file  "/var/named/data/named.recursing";
        // add local network set on [acl] section above
        // network range you allow to receive queries from hosts
        allow-query     { localhost; internal-network; };
        // network range you allow to transfer zone files to clients
        // add secondary DNS servers if it exist
        allow-transfer  { localhost; };

        .....
        .....

        recursion yes;
		
		forward only;
		forwarders { 8.8.8.8; 8.8.4.4 };
	};

	logging {
			channel default_debug {
					file "data/named.run";
					severity dynamic;
			};
	};

	zone "." IN {
			type hint;
			file "named.ca";
	};

	include "/etc/named.rfc1912.zones";
	include "/etc/named.root.key";

	// add zones for your network and domain name
	zone "empresa.local" IN {
			type primary;
			file "empresa.local.lan";
			allow-update { none; };
	};
	zone "1.168.192.in-addr.arpa" IN {
			type primary;
			file "1.168.192.db";
			allow-update { none; };
	};
END
	sudo tee /var/named/empresa.local.lan > /dev/null << END 
	$TTL 86400
@   IN  SOA     servidor1.empresa.local. root.empresa.local. (
        ;; any numerical values are OK for serial number but
        ;; recommendation is [YYYYMMDDnn] (update date + number)
        1762118665  ;Serial
        3600        ;Refresh
        1800        ;Retry
        604800      ;Expire
        86400       ;Minimum TTL
)
        ;; define Name Server
        IN  NS      servidor1.empresa.local.
        ;; define Name Server's IP address
        IN  A       192.168.1.192
        ;; define Mail Exchanger Server
        IN  MX 10   servidor1.empresa.local.

;; define each IP address of a hostname
servidor1    IN  A       192.168.1.192
www     	 IN  A       192.168.1.195
END
	sudo tee /var/named/empresa.local.lan > /dev/null << END
\$TTL 86400
@   IN  SOA     servidor1.empresa.local. root.empresa.local. (
        1762118665  ; Serial
        3600        ; Refresh
        1800        ; Retry
        604800      ; Expire
        86400       ; Minimum TTL
)
@               IN  NS      servidor1.empresa.local.
192        		IN  PTR     servidor1.empresa.local.
195             IN  PTR     www.empresa.local.
 
END

echo "Definir permissões nos Ficheiros.."
sudo chown named:named /var/named/empresa.local.lan
sudo chown named:named /var/named/1.168.192.db

echo "Definir permissões na FireWall.."
sudo firewall-cmd --add-service=dns --permanent
sudo firewall-cmd --reload

echo "Iniciar o serviço DNS.."
sudo systemctl enable --now named
sudo systemctl start named
sudo systemctl status named

