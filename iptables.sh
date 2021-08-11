#!/bin/bash
set -e

iptables_func (){
  IPTABLES=$(which iptables)
  echo $IPTABLES
  if [[ -z "$IPTABLES" ]]; then
	  apt install iptables iptables-persistent -y
  else 
	 echo "iptables is already installed"
	 apt install iptables-persistent -y
  fi

  PORTS=(
	  "tcp:22"
	  "tcp:80"
	  "tcp:443"
	  "tcp:53"
	  "udp:53"
	  "tcp:10000"
	  
  )
  
  # Open ports
  for p in "${PORTS[@]}" 
  do
	  KEY=${p%%:*}
	  VALUE=${p#*:}
	  echo "Running: iptables -A INPUT -p $KEY --dport $VALUE -j ACCEPT" 
	  iptables -A INPUT -p $KEY --dport $VALUE -j ACCEPT
	  echo "Running: iptables -A OUTPUT -p $KEY --dport $VALUE -j ACCEPT"
	  iptables -A OUTPUT -p $KEY --dport $VALUE -j ACCEPT
  done

  # Allow loopback
  iptables -A INPUT -i lo -j ACCEPT
  iptables -A OUTPUT -o lo -j ACCEPT
  # Allow established connections
  iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
  iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
  # Allow 5044/9200 from peer to elk 
  iptables -A OUTPUT -p tcp --dport 5044 -j ACCEPT
  iptables -A OUTPUT -p tcp --dport 9200 -j ACCEPT
  # Default policies
  iptables -P INPUT DROP
  iptables -P FORWARD DROP
  iptables -P OUTPUT ACCEPT 

  echo "Saving iptables rules"
  iptables-save > /etc/iptables/rules.v4
}

iptables_func
