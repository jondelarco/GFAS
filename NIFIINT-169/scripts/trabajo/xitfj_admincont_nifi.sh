#!/bin/bash
#-----------------------------------------------------------------------
#Nombre: xitfj_admincont_nifi.sh
#Fecha: 07/10/2025                               Autor: Yeray San Martin
#-----------------------------------------------------------------------
#Código de Retorno:
#     0 -> Ejecución correcta
#     1 -> Ejecución incorrecta
#
# Parámetros:
#     1 - ID del process group raíz
#     2 - Nombre del Controller Service
#-----------------------------------------------------------------------

. ../../.entorno

#------------------------ Función fin log ------------------------#
finlog() {
  echo >> ${LOG_EJEC}
  echo "#####################################################################################" >> ${LOG_EJEC}
  echo "$(date +%d/%m/%Y\ %H:%M:%S): Fin del Proceso ${SH_NAME}" >> ${LOG_EJEC}
  echo "#####################################################################################" >> ${LOG_EJEC}
  echo >> ${LOG_EJEC}
  cat ${LOG_EJEC} >> ${LOG}

  if [[ $1 -ne 0 ]]; then
    /usr/bin/SUTSPILO ARQ:${SH_NAME}.sh:KO proceso $SH_NAME
  else
    /usr/bin/SUTSPILO ARQ:${SH_NAME}.sh:OK proceso $SH_NAME
  fi
}


#------------------------ Inicialización ------------------------#
SH_NAME="xitfj_admincont_nifi"
DIR_FICHERO_LOG="/home/itf/datos/log"
MSGID=$(date +%Y%m%d%H%M%S)$RANDOM
NOM_FICHERO_LOG="${SH_NAME}_$(date +%Y%m%d).log"
NOM_FICHERO_LOG_EJEC="${SH_NAME}_${MSGID}.log.ejec"
LOG="${DIR_FICHERO_LOG}/${NOM_FICHERO_LOG}"
LOG_EJEC="${DIR_FICHERO_LOG}/${NOM_FICHERO_LOG_EJEC}"

PORT="8443"
ID_HOST="https://$(hostname -f):${PORT}"
PGID="$1"
CTRL_NAME="$2"
ACCION=$3

#Traducimos la accion que queremos al estado final del procesador
if [[ ${ACCION} -eq 1 ]]; then
  ESTADO="RUNNING"
else
  ESTADO="STOPPED"
fi

FICH="/home/itf/datos/tmp"
TMPDIR="${FICH}/nifi_adminproduc_${MSGID}"

##Borramos ficheros temporales de ejecuciones anteriores
find "${FICH}" -maxdepth 1 -type d -name "nifi_*" -exec rm -r {} +

#Creacion del directorio temporal
mkdir -p "$TMPDIR"


#------------------------ Inicio de la ejecución ------------------------#
echo >> ${LOG_EJEC}
echo "#####################################################################################" >> ${LOG_EJEC}
echo "$(date +%d%m%Y%H:%M:%S) : Inicio del Proceso ${SH_NAME}.sh" >> ${LOG_EJEC}
echo "Acción solicitada: $ESTADO" >> ${LOG_EJEC}
echo "Recorremos el grupo NiFi: ${PGID}" >> ${LOG_EJEC}
echo "#####################################################################################" >> ${LOG_EJEC}
echo >> ${LOG_EJEC}

# Usuario cdp_srv_itf
. $EROSKI/fuente/scripts/OUTSORUS.sh $GDEAPPL \$0

#------------------------ Autenticación ------------------------#
token=$(curl -sk "${ID_HOST}/nifi-api/access/token" \
  -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
  --data "username=${ORAUSER}&password=${ORAPASS}")

if [ -z "$token" ]; then
  echo " Error: No se pudo obtener token" >> ${LOG_EJEC}
  finlog 1
  exit 1
fi

#------------------------ Buscar Controller por nombre ------------------------#
echo "Buscando controller '${CTRL_NAME}' en grupo ${PGID}..." >> ${LOG_EJEC}

response=$(curl -sk -w "\n%{http_code}" -H "Authorization: Bearer $token" \
  "$ID_HOST/nifi-api/flow/process-groups/$PGID/controller-services")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [[ "$http_code" != "200" ]]; then
  echo " Error al obtener controller services del grupo $PGID (HTTP $http_code)" >> "$LOG_EJEC"
  echo " Respuesta: $body" >> "$LOG_EJEC"
  finlog 1
  exit 1
fi

echo "$body" > "$TMPDIR/controller_services.json"

controller_id=$(jq -r --arg name "$CTRL_NAME" '.controllerServices[] | select(.component.name == $name) | .id' "$TMPDIR/controller_services.json")

if [[ -z "$controller_id" ]]; then
  echo " Error: No se encontró el controller con nombre '$CTRL_NAME' en el grupo $PGID" >> "$LOG_EJEC"
  finlog 1
  exit 1
fi

echo "Controller encontrado: $controller_id" >> ${LOG_EJEC}

#------------------------ Obtener procesadores que lo usan ------------------------#
echo "Obteniendo procesadores que usan controller $controller_id..." >> ${LOG_EJEC}

references=$(curl -sk -H "Authorization: Bearer $token" \
  "$ID_HOST/nifi-api/controller-services/$controller_id/references")

echo "$references" > "$TMPDIR/references.json"

#------------------------ Procesar referencias ------------------------#
jq -r '.controllerServiceReferencingComponents[].id' "$TMPDIR/references.json" | while read -r proc_id; do
  [[ -z "$proc_id" ]] && continue

  PROC_INFO=$(curl -sk -H "Authorization: Bearer $token" \
    "$ID_HOST/nifi-api/processors/$proc_id")

  CUR_VERSION=$(echo "$PROC_INFO" | jq -r '.revision.version')
  CUR_STATE=$(echo "$PROC_INFO" | jq -r '.component.state')
  NAME=$(echo "$PROC_INFO" | jq -r '.component.name')

  echo "- Procesador: $NAME ($proc_id) Estado actual: $CUR_STATE" >> ${LOG_EJEC}

## Validamos si ya está en el estado deseado
  if [[ "$CUR_STATE" == "$ESTADO" ]]; then
    echo "  -> Ya está "$ESTADO", no se hace nada." >> ${LOG_EJEC}
    continue
  elif [[ "$CUR_STATE" == "DISABLED" ]]; then
    echo "  -> Está DISABLED, se omite." >> ${LOG_EJEC}
    continue
  fi

# Intentamos cambiar el estado del procesador
  STATUS_CODE=$(curl -sk -w "%{http_code}" -o /dev/null -X PUT \
    "$ID_HOST/nifi-api/processors/$proc_id/run-status" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -d "{
      \"revision\": {\"version\": $CUR_VERSION},
      \"state\": \"$ESTADO\"
    }")

# Validamos el resultado
  if [[ "$STATUS_CODE" == "200" ]]; then
    echo "  -> Procesador detenido correctamente." >> ${LOG_EJEC}
  else
    echo "  -> Error al detener procesador (HTTP $STATUS_CODE)" >> ${LOG_EJEC}
  fi
done

finlog 0
exit 0
