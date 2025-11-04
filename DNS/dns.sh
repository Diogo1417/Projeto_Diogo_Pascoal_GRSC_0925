#!/bin/bash
echo "--- Configuração do Servidor DNS (BIND) ---"

# --- VARIAVEIS INICIAIS ---
subrede_base="192.168.180" 
sub_rede="${subrede_base}.0/24" 
zona_reversa="180.168.192" 

# --- PASSO 1: OBTENÇÃO E VALIDAÇÃO DAS VARIÁVEIS ---

# 1. VERIFICAÇÃO DE ARGUMENTOS (Execução silenciosa se IP e Interface forem passados)
if [ "$#" -eq 2 ]; then
    # Se houver 2 argumentos (IP e Interface), usa-os.
    ip_servidor="$1"
    lan="$2"
    echo "Usando IP ($ip_servidor) e Interface ($lan) fornecidos via argumento."
    
    # Extração das variáveis
    octeto=$(echo "$ip_servidor" | awk -F'.' '{print $4}')
    ip_www="$subrede_base.195" 

# 2. INTERAÇÃO COM UTILIZADOR (Execução manual se não houver argumentos)
else
    echo "AVISO: Argumentos não encontrados. A pedir IP ao utilizador."
    
    # Pedir a Interface LAN
    nmcli device show
    echo "Insira a interface LAN onde deseja configurar o IP estático (ex: ens192):"
    read lan

    # Pedir e Validar o Sufixo do IP do Servidor
    while true; do
        echo "O IP do servidor será: .$subrede_base.1 ou .$subrede_base.254"
        read ipserver_suffix
        if 	[ "$ipserver_suffix" = "1" ] || [ "$ipserver_suffix" = "254" ]; then
            ip_servidor="$subrede_base.$ipserver_suffix"
            octeto="$ipserver_suffix"
            ip_www="$subrede_base.195" 
            echo "IP do Servidor DNS: $ip_servidor"
            break
        else
            echo "Valor inválido, insira 1 ou 254"
        fi
    done
fi


# --- PASSO 2: INSTALAÇÃO E CONFIGURAÇÃO DE REDE ---
echo "A instalar o dns (bind).."
sudo dnf -y install bind bind-utils

echo "A configurar o IP estático para $ip_servidor na interface $lan..."
sudo nmcli connection modify "$lan" ipv4.addresses "$ip_servidor/24"
sudo nmcli connection modify "$lan" ipv4.method manual
sudo nmcli connection up "$lan" 
echo "Interface $lan configurada com IP estático."

# --- PASSO 3: CONFIGURAÇÃO DOS FICHEIROS DNS (CORREÇÃO DE SINTAXE com Tabs) ---
echo "A configurar os arquivos DNS..."

# 1. Criação do /etc/named.conf 
sudo tee /etc/named.conf > /dev/null << END
acl internal-network {
	$sub_rede;
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
// Zona Reversa (USA VARIÁVEL)
zone "${zona_reversa}.in-addr.arpa" IN {
	type primary;
	file "${zona_reversa}.db";
	allow-update { none; };
};
END

# 2. Criação do /etc/named.loopback 
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

# 3. Criação da Zona Direta (empresa.local.lan)
sudo tee /var/named/empresa.local.lan > /dev/null << END
\$TTL 86400
@	IN	SOA	servidor1.empresa.local. root.empresa.local. (
	1762118665	; Serial
	3600		; Refresh
	1800		; Retry
	604800		; Expire
	86400		; Minimum TTL
)
@		IN	NS		servidor1.empresa.local.
@		IN	A		$ip_servidor
@		IN	MX 10	servidor1.empresa.local.

servidor1	IN	A		$ip_servidor
www		IN	A		$ip_www
END

# 4. Criação da Zona Reversa ($zona_reversa.db)
sudo tee /var/named/${zona_reversa}.db > /dev/null << END
\$TTL 86400
@	IN	SOA	servidor1.empresa.local. root.empresa.local. (
	1762118665	; Serial
	3600		; Refresh
	1800		; Retry
	604800		; Expire
	86400		; Minimum TTL
)
@		IN	NS		servidor1.empresa.local.
$octeto		IN	PTR		servidor1.empresa.local.
195		IN	PTR		www.empresa.local.
END

# 5. Criação dos ficheiros de Loopback em /var/named/
sudo tee /var/named/named.localhost > /dev/null << END
\$TTL 1D
@	IN SOA	@ root ( 1 1H 15M 1W 1D )
	IN NS	localhost.
	IN A	127.0.0.1
END
sudo tee /var/named/named.loopback > /dev/null << END
\$TTL 1D
@	IN SOA	@ root ( 1 1H 15M 1W 1D )
	IN NS	localhost.
1	IN PTR	localhost.
END
sudo tee /var/named/named.ip6.local > /dev/null << END
\$TTL 1D
@	IN SOA	@ root ( 1 1H 15M 1W 1D )
	IN NS	localhost.
	IN PTR	localhost.
END


echo "Definir permissões nos Ficheiros..."
# Permissões
sudo chown root:named /etc/named.conf
sudo chown root:named /etc/named.loopback
sudo chown named:named /var/named/empresa.local.lan
sudo chown named:named /var/named/${zona_reversa}.db
sudo chown named:named /var/named/named.localhost
sudo chown named:named /var/named/named.loopback
sudo chown named:named /var/named/named.ip6.local


# --- PASSO 4: FIREWALL E SERVIÇO ---
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