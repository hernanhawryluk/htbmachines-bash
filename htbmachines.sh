#!/bin/bash

# Dependencias:
# js-beautify
# sponge

# Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

function ctrl_c() {
  echo -e "\n\n${redColour}[!] Saliendo...\n${endColour}"
  tput cnorm && exit 1
}

# Ctrl + C
trap ctrl_c INT

# Varibales globales
main_url="https://htbmachines.github.io/bundle.js"

function helpPanel() {
  echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Uso:${endColour}"
  echo -e "\t${purpleColour}u)${endColour} ${grayColour}Descargar o actualizar archivos necesarios.${endColour}"
  echo -e "\t${purpleColour}m)${endColour} ${grayColour}Buscar por un nombre de máquina.${endColour}"
  echo -e "\t${purpleColour}i)${endColour} ${grayColour}Buscar por dirección IP.${endColour}"
  echo -e "\t${purpleColour}i)${endColour} ${grayColour}Obtener link de la resolucón de la máquina en YouTube.${endColour}"
  echo -e "\t${purpleColour}h)${endColour} ${grayColour}Mostrar este panel de ayuda.${endColour}\n"
}

function updateFiles() {
  tput civis

  if [ ! -f bundle.js ]; then
    echo -e "${yellowColour}[+]${endColour} ${grayColour}Descargando archivos necesarios...${endColour}"
    curl -s $main_url > bundle.js
    js-beautify bundle.js | sponge bundle.js
    echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Todos los archivos han sido descargados.${endColour}"
  else
    echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Comprobando si hay actualizaciones pendientes...${grayColour}\n"
    sleep 2
    curl -s $main_url > bundle_temp.js
    js-beautify bundle_temp.js | sponge bundle_temp.js
    md5_temp_value=$(md5sum bundle_temp.js | awk '{print $1}')
    md5_original_value=$(md5sum bundle.js | awk '{print $1}')
    
    if [ "$md5_temp_value" == "$md5_original_value" ]; then
      echo -e "${yellowColour}[+]${endColour} ${grayColour}No se han detectado actualizaciones disponibles, esta todo al día.${endColour}"
      rm bundle_temp.js
    else 
      echo -e "${yellowColour}[+]${endColour} ${grayColour}Se han encontrado actualizaciones disponibles.${endColour}\n"
      sleep 2
      rm bundle.js && mv bundle_temp.js bundle.js  
      echo -e "${yellowColour}[+]${endColour} ${grayColour}Los archivos han sido actualizados.${endColour}"
    fi
  fi
  tput cnorm
}

function searchMachine() {
  machineName="$1"

  machineName_checker="$(cat bundle.js | awk "/name: \"${machineName}\"/,/resuelta:/" | grep -vE "id:|sku|resuelta" | tr -d '""' | tr -d "," | sed 's/^ *//')"

  if [ "${machineName_checker}" ]; then
  echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Listando las propiedades de la máquina${endColour} ${blueColour}${machineName}${endColour}${grayColour}:${endColour}\n"
  cat bundle.js | awk "/name: \"${machineName}\"/,/resuelta:/" | grep -vE "id:|sku|resuelta" | tr -d '""' | tr -d "," | sed 's/^ *//'
  else
    echo -e "\n${redColour}[!]${endColour} ${grayColour}La máquina proporcionada no existe.${endColour}\n"
  fi
}

function searchIP() {
  ipAddress="$1"
  
  machineName="$(cat bundle.js | grep "ip: \"${ipAddress}\"" -B 3 | grep "name: " | awk 'NF{print $NF}' | tr -d '"' | tr -d ',')"
  
  if [ "${machineName}" ]; then
  echo -e "\n${yellowColour}[+]${endColour} ${grayColour}La máquina correspondiente para la IP${endColour} ${blueColour}${ipAddress}${endColour} es ${blueColour}${machineName}${endColour}${grayColour}:${endColour}"
  searchMachine $machineName
  else
    echo -e "\n${redColour}[!]${endColour} ${grayColour}La dirección IP proporcionada no existe.${endColour}\n"
  fi
}

function getYouTubeLink() {
  machineName="$1"

  youtubeLink="$(cat bundle.js | awk "/name: \"${machineName}\"/,/resuelta:/" | grep -vE "id:|sku|resuelta" | tr -d '""' | tr -d "," | sed 's/^ *//' | grep youtube | awk 'NF{print $NF}')"
  
  if [ "${youtubeLink}" ]; then
    echo -e "\n${yellowColour}[+]${endColour} ${grayColour}El tutorial para la máquina${endColour} ${blueColour}${machineName}${endColour} esta en el siguiente enlace: ${blueColour}${youtubeLink}${endColour}"
  else 
    echo -e "\n${redColour}[!]${endColour} ${grayColour}La máquina proporcionada no existe.${endColour}\n"
  fi
}

# Indicadores
declare -i parameter_counter=0

while getopts "m:ui:y:h" arg; do
  case $arg in
    m) machineName="$OPTARG"; let parameter_counter+=1;;
    u) let parameter_counter+=2;;
    i) ipAddress="$OPTARG"; let parameter_counter+=3;;
    y) machineName="$OPTARG"; let parameter_counter+=4;;
    h) ;;
  esac
done

if [ $parameter_counter -eq 1 ]; then
  searchMachine $machineName
elif [ $parameter_counter -eq 2 ]; then
  updateFiles
elif [ $parameter_counter -eq 3 ]; then
  searchIP $ipAddress
elif [ $parameter_counter -eq 4 ]; then
  getYouTubeLink $machineName
else
  helpPanel
fi
