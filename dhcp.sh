#!/bin/bash
#
# Automação de DHCP
#
# Andrei Henrique Santos
# CVS $Header$

interface_default="/etc/default/isc-dhcp-server"
dir_dhcp="/etc/dhcp"
conf="dhcpd.conf"

# Título
echo "Inicando Servidor DHCP..."

# Validando permissão de super usuário
if [[ "EUID" -ne 0 ]]; then
	echo "Necessário estar em modo super usuário!"
	sleep 3
	exit 1
fi

# Atualizando pacotes
apt-get update -y && apt-get upgrade -y
sleep 4

# Verificando se o serviço dhcp já existe
if [ ! -e "$interface_default" ]; then
	echo "O servidor DHCP não está instalado"
	echo "Instalando servidor..."
	sleep 3
	apt-get install isc-dhcp-server -y
	sleep 4
else
	echo "O servidor DHCP já está instalado!!!"
	cd "$dir_dhcp/"
	sleep 3
	exit 1
fi

# Limpando configuração default
rm "$dir_dhcp/$conf"

# Configurando
echo "---------------------------------------------------"
echo "Hora de configurar o Servidor!!"
echo "É necessário que algumas informações sejam passadas"
echo "---------------------------------------------------"
echo "* - Obrigatório informar algo"
echo "Se preferir não informar coloque - 0"
echo "---------------------------------------------------"
echo "O IP que este servidor DHCP terá:*"
read ip_fixo
echo "A sua máscara de rede:*"
read mask_fixo
echo "o seu gateway:"
read gateway
echo "Interface em que o DHCP estará instalado:* (coloque entre aspas)"
read interface
echo "Domínio:* (coloque entre aspas)"
read dominio
echo "DNS: (IP)"
read dns
echo "Lease time:* (Segundos)"
read lease_time
echo "Rede que deseja compartilhar:*"
read subnet
echo "Máscara da rede a compartilhar:*"
read netmask
echo "Range de IPs:* (Separe IPs com espaço)"
read range
echo "Máscara do range:*"
read subnet_mask
echo "Gateway: (Ip1, Ip2...)"
read routers

# Configurando em que interface o DHCP vai entregar IPs
{
sed -i '17 s/""//' $interface_default
sed -i "s|INTERFACESv4=|INTERFACESv4=$interface|g" $interface_default
} >>"$interface_default"

# Configurando IP estático
interface=${interface:1:6}
{
if [[ "$gateway" == "0" ]]; then
	sed -i "s|iface $interface inet dhcp|iface $interface inet static \naddress $ip_fixo \nnetmask $mask_fixo|" "/etc/network/interfaces"
else
	sed -i "s|iface $interface inet dhcp|iface $interface inet static \naddress $ip_fixo \nnetmask $mask_fixo \ngateway $gateway|" "/etc/network/interfaces"
fi
} >>"/etc/network/interfaces"


# Configuração do dhcp.conf
{

echo "option domain-name $dominio;"
echo " "

if [[ ! "$dns" == "0" ]]; then
	echo "option domain-name-servers $dns;"
	echo " "
fi

echo "default-lease-time $lease_time;"
echo " "
echo "authoritative;"
echo " "
echo "subnet $subnet netmask $netmask {"
echo "     range $range;"
echo "     option subnet-mask $subnet_mask;"

if [[ ! "$routers" == "0" ]]; then
	echo "      option routers $routers;"
fi

echo "}"
} >>"$dir_dhcp/$conf"

echo "----------------------------------------------------------------------"
echo "Configuração realizada com sucesso!!!"
echo "Desligaremos a máquina para que possa colocar em rede interna..."
sleep 3

init 0
