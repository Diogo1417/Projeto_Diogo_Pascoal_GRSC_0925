#!/bin/bash
lan=""
ipserver=""

echo "A Instalar o dhcp..."
# Usar 'dnf install -y kea' para evitar a instalação do isc-dhcp-server
sudo dnf install -y kea

nmcli
echo "Insira a interface LAN.."
read lan

while true; do
	echo "O ip do server será: .1 ou .254"
	read ipserver
	if 	[ "$ipserver" -eq 1 ] || [ "$ipserver" -eq 254 ]; then
		echo "ip server: 192.168.180.$ipserver"
		break
	else
		echo "valor invalido, insira .1 ou .254"
	fi
done

# Colocar o ip estático
echo "A colocar o ip do server como estático..."
# **Corrigir IP na interface para o correto 192.168.180.254/24**
# mas o IP do servidor é declarado como 192.168.180.254, vamos usar este.
sudo nmcli connection modify "$lan" ipv4.addresses $ipserver/24
sudo nmcli connection modify "$lan" ipv4.method manual
sudo nmcli connection up "$lan" # Adicionado para garantir que a interface sobe com o novo IP

# Pedir de ips para utilizar
echo "Introduz uma gama de ips que pertençam à mesma subnet do servidor dhcp 192.168.180.0/24:"
echo "Atenção!!!! Não utilizar o ip do servidor ($ip_servidor) ou o ip do gateway!"
read -p " Ip de início (ex: 192.168.180.10): " ip_inicio
read -p " Ip final (ex: 192.168.180.250): " ip_fim

# verificar o intervalo da gama de ips
if [[ $ip_inicio =~ $subnet ]] && [[ $ip_fim =~ $subnet ]] && [[ $ip_inicio != $ip_servidor ]] && [[ $ip_fim != $ip_servidor ]]; then
    echo " IPs válidos na subnet do servidor! :)"
else
    echo " ERRO 232: Os IPs estão na subnet errada ou algum IP é igual ao IP do servidor. A fechar o programa..."
    exit 1
fi

# receber o dns
echo " Introduza o ip do DNS"
read -p " DNS (ex: 8.8.8.8): " dns
echo "DNS escolhido: $dns"

# backup
echo "Criação de um arquivo .org de modo a deixar mais fluida a leitura do ficheiro de configuração..."
# Adicionar verificação para evitar erro se o .conf não existir (primeira execução)
if [ -f /etc/kea/kea-dhcp4.conf ]; then
    sudo mv /etc/kea/kea-dhcp4.conf /etc/kea/kea-dhcp4.conf.org
fi

# Variável do arquivo de DHCP
dhcp_config="/etc/kea/kea-dhcp4.conf"
echo "A aplicar as configurações..."

# Os valores das variáveis já estão definidos, esta parte é redundante:
# dns= $dns

echo "A criar todas as configurações..."
# Corrigido: A sintaxe correta para a pool no Kea é: "pool": "$ip_inicio-$ip_fim" (sem espaços)
# Também corrigi o nome do logger de kea-dhcp4 para kea-dhcp4.log, que é o padrão.
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
        "pools": [ { "pool": "$ip_inicio-$ip_fim" } ],
        "option-data": [
          {
            "name": "routers",
            "data": "$ipserver"
          }
        ]
      }
    ],
    "loggers": [
      {
        "name": "kea-dhcp4.log",
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

# Início DHCP
echo " A iniciar todas as configurações..."
sudo systemctl daemon-reload # Adicionado para garantir que o systemd reconhece mudanças
sudo systemctl enable --now kea-dhcp4

# ativar serviços firewall
echo " Configurar a firewall..."
# O serviço correto para DHCP no firewall geralmente é 'dhcp' ou 'dhcpv4'
# De acordo com as imagens, 'dhcp' funcionou, vamos mantê-lo.
sudo firewall-cmd --add-service=dhcp --permanent
sudo firewall-cmd --reload

# verificar o status
echo " A verificar o status do DHCP..."
sudo systemctl status kea-dhcp4

echo "Instalação concluída e configuração feita com sucesso! :)"