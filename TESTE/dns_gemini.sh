#!/bin/bash
echo "A instalar o dns (bind).."
sudo dnf -y install bind bind-utils

# Variáveis do ambiente, confirmadas para 192.168.180.1
ip_servidor="192.168.180.1" 
octeto="1" # Último octeto do seu IP
ip_www="192.168.180.195" # Exemplo de um IP para o www na sua rede
zona_reversa="180.168.192" # Correto para 192.168.180.x

echo "IP do Servidor: $ip_servidor"
echo "Último Octeto: $octeto"
echo "A configurar os arquivos..."

# 1. Criação do /etc/named.conf (Configuração Principal)
# Remove named.rfc1912.zones para evitar conflitos e usa includes específicos
sudo tee /etc/named.conf > /dev/null << END
acl internal-network {
    192.168.180.0/24;
};

options {
    listen-on port 53 { any; };
    listen-on-v6 { any; };
    directory       "/var/named";
    dump-file       "/var/named/data/cache_dump.db";
    statistics-file "/var/named/data/named_stats.txt";
    memstatistics-file "/var/named/data/named_mem_stats.txt";
    secroots-file   "/var/named/data/named.secroots";
    recursing-file  "/var/named/data/named.recursing";
    allow-query     { localhost; internal-network; };
    allow-transfer  { localhost; };
    recursion yes;
    forward only;
    forwarders { 8.8.8.8; 8.8.4.4; };
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

include "/etc/named.root.key";
include "/etc/named.loopback";

// Zona Direta
zone "empresa.local" IN {
    type primary;
    file "empresa.local.lan";
    allow-update { none; };
};
// Zona Reversa - CORRETA para 192.168.180.x
zone "${zona_reversa}.in-addr.arpa" IN {
    type primary;
    file "${zona_reversa}.db";
    allow-update { none; };
};
END

# 2. Criação do /etc/named.loopback (Necessário para a linha de include acima)
sudo tee /etc/named.loopback > /dev/null << END
zone "localhost" IN {
    type master;
    file "named.localhost";
    allow-update { none; };
};
zone "0.0.127.in-addr.arpa" IN {
    type master;
    file "named.loopback";
    allow-update { none; };
};
zone "0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa" IN {
    type master;
    file "named.ip6.local";
    allow-update { none; };
};
END

# 3. Criação da Zona Direta (empresa.local.lan) - Sintaxe limpa
sudo tee /var/named/empresa.local.lan > /dev/null << END
\$TTL 86400
@   IN  SOA     servidor1.empresa.local. root.empresa.local. (
    1762118665  ; Serial
    3600        ; Refresh
    1800        ; Retry
    604800      ; Expire
    86400       ; Minimum TTL
)
@               IN  NS       servidor1.empresa.local.
@               IN  A        $ip_servidor
@               IN  MX 10    servidor1.empresa.local.

servidor1       IN  A        $ip_servidor
www             IN  A        $ip_www
END

# 4. Criação da Zona Reversa (180.168.192.db) - Sintaxe limpa
sudo tee /var/named/${zona_reversa}.db > /dev/null << END
\$TTL 86400
@   IN  SOA     servidor1.empresa.local. root.empresa.local. (
    1762118665  ; Serial
    3600        ; Refresh
    1800        ; Retry
    604800      ; Expire
    86400       ; Minimum TTL
)
@               IN  NS       servidor1.empresa.local.
$octeto         IN  PTR      servidor1.empresa.local.
195             IN  PTR      www.empresa.local.
END

# 5. Criação dos ficheiros de Loopback que estavam a faltar em /var/named/
# CORRIGE O ERRO "file not found"
sudo tee /var/named/named.localhost > /dev/null << END
\$TTL 1D
@       IN SOA  @ root ( 1 1H 15M 1W 1D )
        IN NS   localhost.
        IN A    127.0.0.1
END
sudo tee /var/named/named.loopback > /dev/null << END
\$TTL 1D
@       IN SOA  @ root ( 1 1H 15M 1W 1D )
        IN NS   localhost.
1       IN PTR  localhost.
END
sudo tee /var/named/named.ip6.local > /dev/null << END
\$TTL 1D
@       IN SOA  @ root ( 1 1H 15M 1W 1D )
        IN NS   localhost.
        IN PTR  localhost.
END


echo "Definir permissões nos Ficheiros..."
# Permissões do sistema
sudo chown root:named /etc/named.conf
sudo chown root:named /etc/named.loopback

# Permissões das zonas
sudo chown named:named /var/named/empresa.local.lan
sudo chown named:named /var/named/${zona_reversa}.db

# Permissões dos ficheiros de loopback
sudo chown named:named /var/named/named.localhost
sudo chown named:named /var/named/named.loopback
sudo chown named:named /var/named/named.ip6.local


echo "Definir permissões na FireWall..."
sudo firewall-cmd --add-service=dns --permanent
sudo firewall-cmd --reload

echo "Iniciar o serviço DNS..."

# Verificações de sintaxe antes de tentar iniciar
echo "Verificando sintaxe da zona direta..."
sudo named-checkzone empresa.local /var/named/empresa.local.lan
echo "Verificando sintaxe da zona reversa..."
sudo named-checkzone ${zona_reversa}.in-addr.arpa /var/named/${zona_reversa}.db

sudo systemctl enable --now named
sudo systemctl status named