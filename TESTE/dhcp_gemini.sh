#!/bin/bash

# Variáveis globais para configuração (Sub-rede definida explicitamente)
lan=""
ipserver_suffix=""
ip_inicio=""
ip_fim=""
dns=""
ip_servidor=""
# Sub-rede baseada no seu script: 192.168.180.x
subrede="192.168.180.0/24" 

echo "--- Instalação do KEA DHCP ---"
echo "A Instalar o dhcp..."
# Usar 'dnf install -y kea' para evitar a instalação do isc-dhcp-server
sudo dnf install -y kea

# 1. Pedir e Validar a Interface LAN
nmcli device show # Mostrar interfaces para o usuário
echo "Insira a interface LAN (ex: ens160):"
read lan

# 2. Pedir e Validar o Sufixo do IP do Servidor
while true; do
	echo "O ip do server será: .1 ou .254"
	read ipserver_suffix
	if 	[ "$ipserver_suffix" = "1" ] || [ "$ipserver_suffix" = "254" ]; then
        ip_servidor="192.168.180.$ipserver_suffix"
		echo "IP do Servidor: $ip_servidor"
		break
	else
		echo "Valor inválido, insira 1 ou 254"
	fi
done

# 3. Configurar IP Estático
echo "A colocar o ip do server ($ip_servidor) como estático..."
sudo nmcli connection modify "$lan" ipv4.addresses "$ip_servidor/24"
sudo nmcli connection modify "$lan" ipv4.method manual
sudo nmcli connection up "$lan" 
echo "Interface $lan configurada com IP estático."

# 4. Pedir a Gama de IPs para a Pool DHCP
echo "Introduza uma gama de ips que pertençam à subnet $subrede:"
echo "ATENÇÃO! Não utilizar o ip do servidor ($ip_servidor) ou o ip do gateway!"
read -p " Ip de início (ex: 192.168.180.10): " ip_inicio
read -p " Ip final (ex: 192.168.180.250): " ip_fim

# VALIDAÇÃO SIMPLES (Apenas verificar se os IPs estão na sub-rede 192.168.180.x e se não são o IP do servidor)
if [[ $ip_inicio == 192.168.180.* ]] && [[ $ip_fim == 192.168.180.* ]] && [[ $ip_inicio != "$ip_servidor" ]] && [[ $ip_fim != "$ip_servidor" ]]; then
    echo "Gama de IPs válida: $ip_inicio até $ip_fim."
else
    echo "ERRO: A gama de IPs não é válida para a sub-rede $subrede ou um dos IPs é igual ao IP do servidor. A fechar o programa..."
    exit 1
fi

# 5. Receber o DNS
echo " Introduza o ip do DNS"
read -p " DNS (ex: 8.8.8.8): " dns
echo "DNS escolhido: $dns"

# 6. Backup e Configuração do KEA
echo "Criação de um arquivo .org de modo a deixar mais fluida a leitura do ficheiro de configuração..."
dhcp_config="/etc/kea/kea-dhcp4.conf"

if [ -f "$dhcp_config" ]; then
    sudo mv "$dhcp_config" "$dhcp_config.org"
fi

echo "A criar todas as configurações em $dhcp_config..."

# Geração do Arquivo de Configuração KEA (JSON)
# NOTA: O 'id' está presente e a pool usa a formatação correta "IP_INICIO - IP_FIM"
sudo tee "$dhcp_config" > /dev/null << END
{
  "Dhcp4": {
    "interfaces-config": {
      "interfaces": [ "$lan" ]
    },
    "expired-leases-processing": {
      "reclaim-timer-wait-time": 10,
      "flush-reclaimed-timer-wait-time": 25,
      "hold-reclaimed-time": 3600,
      "max-reclaim-leases": 100,
      "max-reclaim-time": 250,
      "unwarned-reclaim-cycles": 5
    },
    "renew-timer": 900,
    "rebind-timer": 1800,
    "valid-lifetime": 3600,
    "option-data": [
      {
        "name": "domain-name-servers",
        "data": "$dns"
      },
      {
        "name": "domain-name",
        "data": "empresa.local"
      },
      {
        "name": "domain-search",
        "data": "empresa.local"
      }
    ],
    "subnet4": [
      {
        "id": 1,
        "subnet": "$subrede",
        "pools": [ { "pool": "$ip_inicio - $ip_fim" } ],
        "option-data": [
          {
            "name": "routers",
            "data": "$ip_servidor"
          }
        ]
      }
    ],
    "loggers": [
      {
        "name": "kea-dhcp4",
        "output-options": [
          {
            "output": "/var/log/kea/kea-dhcp4.log"
          }
        ],
        "severity": "INFO",
        "debuglevel": 0
      }
    ]
  }
}
END

# 7. Início do Serviço DHCP (Adicionando o teste de configuração antes de iniciar!)
echo "--- Teste de Configuração do KEA ---"
sudo kea-dhcp4 -t "$dhcp_config"

echo "--- Início do Serviço KEA ---"
sudo systemctl daemon-reload
sudo systemctl enable --now kea-dhcp4

# 8. Configuração do Firewall
echo "Configurar a firewall..."
sudo firewall-cmd --add-service=dhcp --permanent
sudo firewall-cmd --reload

# 9. Verificação Final
echo "A verificar o status do DHCP..."
sudo systemctl status kea-dhcp4 --no-pager

echo "--- FIM ---"
echo "Instalação e configuração do KEA DHCPv4 concluídas."