#!bin/bash

echo "A Instalar o dhcp..."
sudo dnf install -y kea

#Colocar o ip estatico
echo "A colocar o ip do server como estatico..."
sudo nmcli connection modify ens192 ipv4.addresses 192.168.1.184/24
sudo nmcli connection modify ens192 ipv4.method manual #buscar nmcli

#Pedir de ips para utilizar
echo "Introduz uma gama de ips que  pertençam a mesma subnet do servidor dhcp 192.168.1.0/24:"
echo "Atenção!!!! Não utilizar uma gama de IPS onde o ip do servidor ( 192.168.1.184/24 ) nem o ips do gateway (192.168.1.254) estejam presentes!!"
read -p " Ip de inicío :" ip_inicio
read -p " ip final:" ip_fim

#verificar o intervalo da gama de ips
subnet="^192\.168\.1\."
mask="255.255.255.0"
subrede="192.168.1.0/24"
ip_servidor="192.168.1.184"

if [[ $ip_inicio =~ $subnet ]] && [[ $ip_fim =~ $subnet ]] && [[ $ip_inicio != $ip_servidor ]] &&  [[ $ip_fim != $ip_servidor ]]; then
echo " IPs válidos na subnet do servidor! :)"
else
echo " ERRO 232: Os IPs estão na subnet errado ou algum IP está com o mesmo ip do servidor. A fechar o programa..."
exit 1
fi

# Ip default gateway
echo " Introduz o IP do default-gateway"
read -p "gateway:" ip_gateway

#verificar gateway
if [[ $ip_gateway =~ $subnet ]];then
echo " O default-gateway válido na subrede! :)"
else
echo "ERRO 232: O default-gateway não está na mesma subrede. A Fechar o programa..."
exit 1
fi

#receber o dns
echo " Introduza o ip do DNS"
read -p " DNS:" dns
echo "$ip_inicio"

#backup
echo "Criação de um arquivo .org de modo a deixar mais fluida a leitura do ficheiro de configuração..."
sudo mv /etc/kea/kea-dhcp4.conf /etc/kea/kea-dhcp4.conf.org

#Variavel do arquivo de DHCP
dhcp_config="/etc/kea/kea-dhcp4.conf"
echo "A aplicar as configurações..."

dns= $dns
subrede= $subrede
ip_inicio= $ip_inicio
ip_fim= $ip_fim
ip_gateway= $ip_gateway

echo "A aplicar as configurações..."
sudo tee /etc/kea/kea-dhcp4.conf > /dev/null << END
{
  "Dhcp4": {
    "interfaces-config": {
      "interfaces": [ "ens192" ]
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
            "data": "$ip_gateway"
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


#Inicio DHCP
echo " A iniciar todas as configurações..."
sudo systemctl enable --now kea-dhcp4

#ativar serviços firewall
echo " Configurar a firewall..."
sudo firewall-cmd --add-service=dhcp
sudo firewall-cmd --runtime-to-permanent
sudo firewall-cmd --reload

#veriicar os status
echo " A verificar o status do DHCP..."
sudo systemctl status kea-dhcp4

echo "Instalação concluida e configuração feita com sucesso! :)"