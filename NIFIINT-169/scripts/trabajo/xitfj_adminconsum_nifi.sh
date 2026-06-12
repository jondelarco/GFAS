#-----------------------------------------------------------------------
#Nombre: xitfj_adminconsum_nifi.sh
#Fecha: 26/06/2025                                Autor: Yeray San Martin
#-----------------------------------------------------------------------
#Código de Retorno:
#     0 -> Ejecución correcta
#     1 -> Ejecución incorrecta
#
# Parámetros:
#     1 - ID del process group raíz
#     2 - Acción: START o STOP (opcional, por defecto solo lista)
#-----------------------------------------------------------------------

#Cargamos las variables de entorno
. /home/itf/.entorno

#------------------------ Inicialización ------------------------#
SH_NAME="xitfj_adminconsum_nifi"
DIR_FICHERO_LOG="/home/itf/datos/log"
MSGID=$(date +%Y%m%d%H%M%S)$RANDOM
NOM_FICHERO_LOG="${SH_NAME}_$(date +%Y%m%d).log"
NOM_FICHERO_LOG_EJEC="${SH_NAME}_${MSGID}.log.ejec"
LOG="${DIR_FICHERO_LOG}/${NOM_FICHERO_LOG}"
LOG_EJEC="${DIR_FICHERO_LOG}/${NOM_FICHERO_LOG_EJEC}"

PORT="8443"
ID_HOST="https://$(hostname -f):${PORT}"
PGID="$1"
ACCION=$2  # START o STOP
FICH="/home/itf/datos/tmp"
TMPDIR="${FICH}/nifi_inputforbidden_${MSGID}"

##Borramos ficheros temporales de ejecuciones anteriores
#find "${FICH}" -maxdepth 1 -type d -name "nifi_*" -exec rm -r {} +

mkdir -p "$TMPDIR"

#Traducimos la accion que queremos al estado final del procesador
if [[ ${ACCION} -eq 1 ]]; then
  ESTADO="RUNNING"
else
  ESTADO="STOPPED"
fi

#------------------------ Función log fin ------------------------#
finlog() {
    echo >> ${LOG_EJEC}
    echo "#####################################################################################" >> ${LOG_EJEC}
    echo "$(date +%d/%m/%Y\ %H:%M:%S): Fin del Proceso ${SH_NAME}" >> ${LOG_EJEC}
    echo "#####################################################################################" >> ${LOG_EJEC}
    echo >> ${LOG_EJEC}

    cat ${LOG_EJEC} >> ${LOG}

    if [[ $1 -ne 0 ]]; then
        /usr/bin/SUTSPILO ARQ:${SH_NAME}.sh:KO proceso $SH_NAME
         exit 1
    else
        /usr/bin/SUTSPILO ARQ:${SH_NAME}.sh:OK proceso $SH_NAME
    fi
}

# Usuario cdp_srv_itf
. $EROSKI/fuente/scripts/OUTSORUS.sh $GDEAPPL \$0

#------------------------ Obtener token JWT para la API ------------------------#
# En entornos securizados es obligatorio autenticarse vía POST con credenciales
# El token obtenido se usará como cabecera Bearer en las llamadas posteriores
token=$(curl -sk "${ID_HOST}/nifi-api/access/token" \
  -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
  --data "username=${ORAUSER}&password=${ORAPASS}")

# Validamos que el token se haya obtenido correctamente
if [ -z "$token" ]; then
  echo " Error: No se pudo obtener token" >> ${LOG_EJEC}
  finlog 1
  exit 1
fi

#------------------------ Función para refrescar token ------------------------#
obtener_token() {
  token=$(curl -sk "${ID_HOST}/nifi-api/access/token" \
    -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
    --data "username=${ORAUSER}&password=${ORAPASS}")
  if [ -z "$token" ]; then
    echo "Error: no se pudo obtener token" >> ${LOG_EJEC}
    finlog 1
    exit 1
  fi
}

#------------------------ Función recursiva para recorrer subgrupos ------------------------#
recorrer_grupo() {
  local group_id="$1"
  echo "Procesando grupo: $group_id" >> ${LOG_EJEC}

  # Guardamos los procesadores del grupo en fichero local
response=$(curl -sk -w "\n%{http_code}" \
  -H "Authorization: Bearer $token" \
  "$ID_HOST/nifi-api/process-groups/$group_id/processors")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [[ "$http_code" != "200" ]]; then
  echo " Error al obtener procesadores del grupo $group_id (HTTP $http_code)" >> "$LOG_EJEC"
  echo " Respuesta: $body" >> "$LOG_EJEC"
  finlog 1
  exit 1
else
  echo "$body" > "$TMPDIR/${group_id}_procesadores.json"
fi
  # Buscamos recursivamente todos los subgrupos que cuelgan de este grupo
  for g in $(curl -sk -H "Authorization: Bearer $token" \
    "${ID_HOST}/nifi-api/process-groups/$group_id/process-groups" | \
    jq -r '.processGroups[].id'); do
    recorrer_grupo "$g"
  done
}

#------------------------ Inicio de la ejecución ------------------------#
echo >> ${LOG_EJEC}
echo "#####################################################################################" >> ${LOG_EJEC}
echo "$(date +%d%m%Y%H:%M:%S) : Inicio del Proceso ${SH_NAME}.sh" >> ${LOG_EJEC}
echo "Acción solicitada: $ESTADO" >> ${LOG_EJEC}
echo "Recorremos el grupo NiFi: ${PGID}" >> ${LOG_EJEC}
echo "#####################################################################################" >> ${LOG_EJEC}
echo >> ${LOG_EJEC}

# Iniciamos el recorrido del árbol de process groups desde el grupo raíz indicado
recorrer_grupo "$PGID"

#------------------------ Identificación de procesadores raíz ------------------------#
# Extraemos los procesadores con las siguientes condiciones:
#   - inputRequirement = "INPUT_FORBIDDEN" -> No admiten entradas, por tanto, deben estar en el inicio del flujo
#   - No son de tipo "GenerateFlowFile" -> Se excluyen los generadores de prueba
jq -r '
  .processors[]
  | select(.component.inputRequirement == "INPUT_FORBIDDEN")
  | select(.component.type | test("GenerateFlowFile") | not)
  | @base64
' "$TMPDIR/"*"_procesadores.json" | while read -r b64; do
  PROC=$(echo "$b64" | base64 -d)
  ID=$(echo "$PROC" | jq -r '.id')
  NAME=$(echo "$PROC" | jq -r '.component.name')
  TYPE=$(echo "$PROC" | jq -r '.component.type')

  echo "- $NAME (ID: $ID) | Tipo: $TYPE" >> ${LOG_EJEC}

  if [[ "$ACCION" -eq 0 || "$ACCION" -eq 1 ]]; then
    echo " -> Comprobando estado actual del procesador antes de aplicar $ESTADO..." >> ${LOG_EJEC}

    # Obtener la info actual del procesador para extraer versión y estado real
    PROC_INFO=$(curl -sk -H "Authorization: Bearer $token" \
      "$ID_HOST/nifi-api/processors/$ID")

    # Extraemos la versión actual del procesador para evitar error 400 (conflicto de versión)
    CUR_VERSION=$(echo "$PROC_INFO" | jq -r '.revision.version')

    # Extraemos el estado actual del procesador (RUNNING, STOPPED, etc.)
    CUR_STATE=$(echo "$PROC_INFO" | jq -r '.component.state')

    echo "     Estado actual: $CUR_STATE | Versión actual: $CUR_VERSION" >> ${LOG_EJEC}

    if [[ "$CUR_STATE" == "$ESTADO" ]]; then
      echo "     El procesador ya está en estado $ESTADO, no se hace nada." >> ${LOG_EJEC}
    elif [[ "$CUR_STATE" == "DISABLED" ]]; then
      echo "     El procesador está DISABLED, no se puede cambiar su estado." >> ${LOG_EJEC}  
    else
      echo " -> Enviando acción $ESTADO..." >> ${LOG_EJEC}

      # Intentamos cambiar el estado del procesador con la versión actualizada
      STATUS_CODE=$(curl -sk -w "%{http_code}" -o /dev/null -X PUT \
        "$ID_HOST/nifi-api/processors/$ID/run-status" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "{
          \"revision\": {\"version\": $CUR_VERSION},
          \"state\": \"$ESTADO\"
        }")

#      if [ "$STATUS_CODE" == "403" ]; then
#        echo "Token expirado, intentando refrescar..." >> ${LOG_EJEC}
 #      obtener_token
 #      STATUS_CODE=$(curl -sk -w "%{http_code}" -o /dev/null -X PUT \
 #        "$ID_HOST/nifi-api/processors/$ID/run-status" \
 #        -H "Authorization: Bearer $token" \
 #        -H "Content-Type: application/json" \
 #        -d "{
 #          \"revision\": {\"version\": $CUR_VERSION},
 #          \"state\": \"$ESTADO\"
 #        }")
 #    fi

 #    if [ "$STATUS_CODE" == "409" ]; then
 #      echo "Versión desactualizada, obteniendo nueva..." >> ${LOG_EJEC}

 #      # Vuelve a consultar el procesador para obtener la versión actual
 #      PROC_INFO=$(curl -sk -H "Authorization: Bearer $token" \
 #        "$ID_HOST/nifi-api/processors/$ID")
 #      CUR_VERSION=$(echo "$PROC_INFO" | jq -r '.revision.version')

 #      echo "Nueva versión detectada: $CUR_VERSION" >> ${LOG_EJEC}

 #      # Reintentamos el PUT con la versión actualizada
 #      STATUS_CODE=$(curl -sk -w "%{http_code}" -o /dev/null -X PUT \
 #        "$ID_HOST/nifi-api/processors/$ID/run-status" \
 #        -H "Authorization: Bearer $token" \
 #        -H "Content-Type: application/json" \
 #        -d "{
 #          \"revision\": {\"version\": $CUR_VERSION},
 #          \"state\": \"$ESTADO\"
#         }")
#      fi
#    
      if [ "$STATUS_CODE" == "200" ]; then
        echo "     Procesador $ESTADO ejecutado correctamente" >> ${LOG_EJEC}
      else
        echo "     Error al aplicar $ESTADO (HTTP $STATUS_CODE)" >> ${LOG_EJEC}
      fi
    fi
  fi
done

#------------------------ Fin ------------------------#
finlog 0
exit 0

