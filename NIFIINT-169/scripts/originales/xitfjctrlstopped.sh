#!/bin/bash

#-----------------------------------------------------------------------
#	Nombre: xitfjctrlstopped.sh
#	Fecha:29/04/2026                            Autor: Jonathan Del Arco
#	Obtener el número de circuitos en stopped (en el grupo de ITF).
#-----------------------------------------------------------------------
#	Codigo de Retorno:
#		0 -> Ejecucion correcta
#		1 -> Ejecucion incorrecta
#
#   Parámetros:
#       1 -> Host de la aplicacion nifi
#       2 -> ID del grupo a obtener el número de procesos en stopped
#-----------------------------------------------------------------------

# IMPORTS
. /home/itf/.entorno # Cargo las variables de Entorno de la Aplicacion.
. $EROSKI/fuente/scripts/OUTSORUS.sh $GDEAPPL \$0 # Cargo usuario y contraseña para el token

# PARÁMETROS
ID_HOST="$1"  # Host de la aplicacion nifi
ID_GROUP="$2" # ID del grupo a obtener el número de procesos en stopped

# CONSTANTES
MSGID=`date +%Y%m%d`$RANDOM
LOG_EJEC=/home/itf/datos/log/xitfjctrlstopped_$MSGID.log
SH_NAME="xitfjctrlstopped"
DIR_FICHERO_LOG="/home/itf/datos/log"
NOM_FICHERO_LOG=$SH_NAME"_"`date +%Y%m%d`".log"
NOM_FICHERO_LOG_EJEC=$SH_NAME"_"`date +%Y%m%d%H%M%S`".log.ejec"
LOG=$DIR_FICHERO_LOG"/"$NOM_FICHERO_LOG
LOG_EJEC=$DIR_FICHERO_LOG"/"$NOM_FICHERO_LOG_EJEC
FICH="/home/itf/datos/tmp"
ERROR=0

# El entorno esta securizado asique tenemos que crearnos un TOKEN para las consultas a la API
TOKEN=`curl -k -s "${ID_HOST}/nifi-api/access/token" -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' --data "username=${ORAUSER}&password=${ORAPASS}"`

obtener_procesos_stopped() {

    echo >> ${LOG_EJEC}
    echo "#################################################################################################################################">>${LOG_EJEC}
    echo "`date +%d%m%Y%H:%M:%S` : Inicio del Proceso ${SH_NAME}.sh" >> ${LOG_EJEC}
    echo "Llamamos al Grupo de Nifi de ${ID_GROUP}.">>${LOG_EJEC}
    echo "#################################################################################################################################">>${LOG_EJEC}
    echo >> ${LOG_EJEC}

    # Obtenemos los datos del grupo establecido como parámetro y lo guardamos en JSON
    /usr/bin/curl -k -s -H "Authorization: Bearer $TOKEN" ${ID_HOST}/nifi-api/process-groups/${ID_GROUP}/ -o /home/itf/datos/tmp/${ID_GROUP}.json

    # Buscamos en el JSON mediante JSONQuery el total de los procesos parados
    procesos_stopped=`jq .component.stoppedCount /home/itf/datos/tmp/${ID_GROUP}.json`

    # Obtener el nombre de los procesos parados
    /usr/bin/curl -k -s -H "Authorization: Bearer $TOKEN" ${ID_HOST}/nifi-api/flow/process-groups/${ID_GROUP}/status?recursive=true -o /home/itf/datos/tmp/${ID_GROUP}_status.json

    nombres_procesos_stopped=$(jq -r '.. | objects | to_entries[] | select(.value.runStatus? == "Stopped") | "\(.key | sub("StatusSnapshot$"; "")): \(.value.name) [\(.value.id)]"' "/home/itf/datos/tmp/${ID_GROUP}_status.json")
    
    # Borramos ficheros temporales.
    rm $FICH/${ID_GROUP}.json
    rm $FICH/${ID_GROUP}_status.json

    if (( procesos_stopped > 0 )); then
        echo >> ${LOG_EJEC}
        echo "#################################################################################################################################">>${LOG_EJEC}
        echo "`date +%d%m%Y%H:%M:%S` : Resultado del Proceso ${SH_NAME}.sh" >> ${LOG_EJEC}
        echo "Se ha detectado un total de ${procesos_stopped} procesos en STOPPED en el Grupo de Nifi de ${ID_GROUP}.">>${LOG_EJEC}
        echo "${nombres_procesos_stopped}" >> ${LOG_EJEC}
        echo "#################################################################################################################################">>${LOG_EJEC}
        echo >> ${LOG_EJEC}
        ERROR=1
    elif (( procesos_stopped == 0 )); then
        echo >> ${LOG_EJEC}
        echo "#################################################################################################################################">>${LOG_EJEC}
        echo "`date +%d%m%Y%H:%M:%S` : Resultado del Proceso ${SH_NAME}.sh" >> ${LOG_EJEC}
        echo "No se ha detectado ningún proceso en STOPPED en el Grupo de Nifi de ${ID_GROUP}.">>${LOG_EJEC}
        echo "#################################################################################################################################">>${LOG_EJEC}
        echo >> ${LOG_EJEC}
        ERROR=0
    else
        echo >> ${LOG_EJEC}
        echo "#################################################################################################################################">>${LOG_EJEC}
        echo "`date +%d%m%Y%H:%M:%S` : Resultado del Proceso ${SH_NAME}.sh" >> ${LOG_EJEC}
        echo "Ha ocurrido un error al obtener los procesos en STOPPED en el Grupo de Nifi de ${ID_GROUP}.">>${LOG_EJEC}
        echo "#################################################################################################################################">>${LOG_EJEC}
        echo >> ${LOG_EJEC}
        ERROR=1
    fi
}

obtener_procesos_stopped ${ID_HOST} ${ID_GROUP}

# Informo al LOG
echo >> ${LOG_EJEC}
echo "#####################################################################################">>${LOG_EJEC}
echo "`date +%d%m%Y%H:%M:%S` : Fin del Proceso ${SH_NAME}" >> ${LOG_EJEC}
echo "#####################################################################################">>${LOG_EJEC}
echo >> ${LOG_EJEC}

/usr/bin/SUTSPILO APR_ITF:${SH_NAME}.sh:Completed Fin OK en la ejecución del proceso
cat ${LOG_EJEC} >> ${LOG}
##LOGFIN LOG=${LOG_EJEC}
if (( ${ERROR} == 0 )); then
    exit 0
elif (( ${ERROR} == 1 )); then
    exit 1
fi