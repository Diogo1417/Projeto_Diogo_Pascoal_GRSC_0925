#!/bin/bash
#variaveis
serial=§ (data +%s)
acl internal-network {
        192.168.20.0/24;
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
	zone "180.168.192.in-addr.arpa" IN {
			type primary;
			file "180.168.192.db";
			allow-update { none; };
	};
	sudo cat /var/named/empresa.local << END
	$TTL 86400
@   IN  SOA     dlp.srv.world. root.srv.world. (
        ;; any numerical values are OK for serial number but
        ;; recommendation is [YYYYMMDDnn] (update date + number)
        1761831619  ;Serial
        3600        ;Refresh
        1800        ;Retry
        604800      ;Expire
        86400       ;Minimum TTL
)
        ;; define Name Server
        IN  NS      servidor1.empresa.local.
        ;; define Name Server's IP address
        IN  A       192.168.180.230
        ;; define Mail Exchanger Server
        IN  MX 10   servidor1.empresa.local.

;; define each IP address of a hostname
servidor1    IN  A       192.168.180.230
www     IN  A       10.0.0.31

END
