#!/bin/bash
echo "A instalar o dns (bind).."
sudo dnf -y install bind bind-utils

# Variáveis do ambiente
ip_servidor="192.168.180.1" 
octeto="1" # Último octeto do seu IP
ip_www="192.168.180.195" # Exemplo de um IP para o www na sua rede
zona_reversa="180.168.192" # Correto para 192.168.180.x

echo "IP do Servidor: $ip_servidor"
echo "Último Octeto: $octeto"
echo "A configurar os arquivos..."

# 1. Criação do /etc/named.conf (Configuração Principal)
# Removida a inclusão de named.rfc1912.zones para evitar conflitos de zona
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
include "/etc/named.loopback"; # Adicionar o loopback para boa prática

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

# Criação de um named.loopback simples (boa prática)
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

# 2. Criação da Zona Direta (empresa.local.lan) - Sintaxe limpa
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

# 3. Criação da Zona Reversa (180.168.192.db) - Sintaxe limpa
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

echo "Definir permissões nos Ficheiros..."
# Mantenha sempre o named como proprietário.
sudo chown named:named /var/named/empresa.local.lan
sudo chown named:named /var/named/${zona_reversa}.db
sudo chown named:named /etc/named.loopback
sudo chown root:named /etc/named.conf # Mudar o dono do named.conf para root, como é padrão

echo "Definir permissões na FireWall..."
sudo firewall-cmd --add-service=dns --permanent
sudo firewall-cmd --reload

echo "Iniciar o serviço DNS..."
# Adicionar verificação de sintaxe para debug
echo "Verificando sintaxe da zona direta..."
sudo named-checkzone empresa.local /var/named/empresa.local.lan
echo "Verificando sintaxe da zona reversa..."
sudo named-checkzone ${zona_reversa}.in-addr.arpa /var/named/${zona_reversa}.db

sudo systemctl enable --now named
sudo systemctl status named