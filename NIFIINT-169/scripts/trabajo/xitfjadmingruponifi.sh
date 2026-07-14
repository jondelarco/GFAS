#-----------------------------------------------------------------------
#Nombre: xitfjadmingruponifi.sh
#Fecha:28/05/2020                               Autor:Zigor Uriarte
# script para parar y arrancar un grupo nifi, y si se informa pone DT en nagios
#-----------------------------------------------------------------------
#Codigo de Retorno :
#                       0 -> Ejecucion correcta
#                       1 -> Ejecucion incorrecta
#
#-----------------------------------------------------------------------
# Cargo las variables de Entorno de la Aplicacion.
# $HOME,$FUENTE,$EXEC,$DATOS, $EROSKI.
#. $vPATHSC/../../.entorno >/dev/null
. /home/itf/.entorno

# Referenciamos otras máquinas (Cargo la variable nodo iniciador)
#. $EROSKI/fuente/scripts/exj-name

ACCION=$1
#se genera un aleatorio de 5 digitos
LONG=0

while [ $LONG -ne 5 ]
do
        ALEATORIO=$RANDOM
        LONG=${#ALEATORIO}
done

MSGID=`date +%Y%m%d`$RANDOM
LOG_EJEC=/home/itf/datos/log/xitfjadmingruponifi_$MSGID.log
SH_NAME="xitfjadmingruponifi"
DIR_FICHERO_LOG="/home/itf/datos/log"
NOM_FICHERO_LOG=$SH_NAME"_"`date +%Y%m%d`".log"
NOM_FICHERO_LOG_EJEC=$SH_NAME"_"`date +%Y%m%d%H%M%S`".log.ejec"
LOG=$DIR_FICHERO_LOG"/"$NOM_FICHERO_LOG
LOG_EJEC=$DIR_FICHERO_LOG"/"$NOM_FICHERO_LOG_EJEC

#Parametros para identificar el grupo NIFI
PORT="8443"
ID_HOST="https://$(hostname -f):${PORT}"
ID_GROUP="$2" #Identificador unico del grupo NIFI

#Parametro identificador de la alerta/control en NAGIOS
ID_SERVICE_NAGIOS=$3

# Parametro opcional: Numero de procesadores que se permite no parar
# Se agrega esto porque en Cloudera, al parar desde la aPI, 
# los procesadores ExecuteGroovyScript e InvokeScriptedProcessor no paran
# y aborta por haber procesos que no han parado
# Usaremos esto como umbral de procesos  que permitimos no parar en la parada
UMBRAL_PROCESS_NOTSTOP=$4

# Si no viene informado el parametro 'UMBRAL_PROCESS_NOTSTOP' lo inicializamos a 0 por defecto
if [ -z "${UMBRAL_PROCESS_NOTSTOP}" ]; then
    UMBRAL_PROCESS_NOTSTOP=0  # Valor por defecto
fi


#Constantes
#Identificador unico de parada en NAGIOS
ID_JOB_NAGIOS_STOP=c970bfab-ca01-401d-95bb-b45d3d35128f
#Identificador unico de arranque en NAGIOS
ID_JOB_NAGIOS_START=d7b02cb3-95b1-485f-a4e4-422bdc6c0f1e
#Nodo 1 de NIFI en NAGIOS
ID_HOST_NAGIOS_1=SLX00011042_PSES_UNX_PRO_NIFI
#Nodo 2 de NIFI en NAGIOS
ID_HOST_NAGIOS_2=SLX00011043_PSES_UNX_PRO_NIFI
#Identificador unico de servicio de control de NIFI en NAGIOS
ID_CTRL_STOPPED=SRV_ALL_ALL_PRO_CHECK-NIFI-COMPONENTS
ID_HOST_CTRL_STOPPED=SRVHOST_PSES_ALL_PRO_WAPPL-W-CLOUDERA-MANAGER

# Usuario cdp_srv_itf
. $EROSKI/fuente/scripts/OUTSORUS.sh $GDEAPPL \$0
#ORAUSER=I2344
#ORAPASS=Eroskiitfadm10.


echo >> ${LOG_EJEC}
echo "#################################################################################################################################">>${LOG_EJEC}
echo "`date +%d%m%Y%H:%M:%S` : Inicio del Proceso ${SH_NAME}.sh para la accion ${ACCION}" >> ${LOG_EJEC}
echo "Llamamos al Grupo de Nifi de ${ID_GROUP}. Con 0 paramos todos los procesos.Con 1 los arrancamos.">>${LOG_EJEC}
echo "#################################################################################################################################">>${LOG_EJEC}
echo >> ${LOG_EJEC}

token=`curl -k "${ID_HOST}/nifi-api/access/token" -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' --data "username=${ORAUSER}&password=${ORAPASS}"`

echo $token

if [ ${ACCION} -ne 1 ];then
        # CREATE DT SRV_ALL_ALL_PRO_CHECK-NIFI-COMPONENTS - control nagios de xitfjctrlstopped
			/usr/bin/curl http://slx00010798.eroski.es:4440/api/1/job/$ID_JOB_NAGIOS_STOP/run?authtoken=gphmi4f84nuLv97ir2Bb9mrkiizcR9EO --data-urlencode "argString=-hostname $ID_HOST_CTRL_STOPPED -servicedesc $ID_CTRL_STOPPED -comment 'Generado por script xitfjadmingruponifi'"
			echo >> ${LOG_EJEC}
			echo "#####################################################################################">>${LOG_EJEC}
			echo "`date +%d%m%Y%H:%M:%S` : Ponemos el service ${ID_CTRL_STOPPED} del host de nagios ${ID_HOST_NAGIOS_1} y ${ID_HOST_NAGIOS_2} en DT" >> ${LOG_EJEC}
			echo "#####################################################################################">>${LOG_EJEC}
			echo >> ${LOG_EJEC}
			
		#Si se informa el service de NAGIOS a parar
		if [ "$ID_SERVICE_NAGIOS" != "" ]
		then
			# CREATE DT - una llamada por ID_HOST_NAGIOS
			/usr/bin/curl http://slx00010798.eroski.es:4440/api/1/job/$ID_JOB_NAGIOS_STOP/run?authtoken=gphmi4f84nuLv97ir2Bb9mrkiizcR9EO --data-urlencode "argString=-hostname $ID_HOST_NAGIOS_1 -servicedesc $ID_SERVICE_NAGIOS -comment 'Generado por script xitfjadmingruponifi'"
			/usr/bin/curl http://slx00010798.eroski.es:4440/api/1/job/$ID_JOB_NAGIOS_STOP/run?authtoken=gphmi4f84nuLv97ir2Bb9mrkiizcR9EO --data-urlencode "argString=-hostname $ID_HOST_NAGIOS_2 -servicedesc $ID_SERVICE_NAGIOS -comment 'Generado por script xitfjadmingruponifi'"
			echo >> ${LOG_EJEC}
			echo "#####################################################################################">>${LOG_EJEC}
			echo "`date +%d%m%Y%H:%M:%S` : Ponemos el service ${ID_SERVICE_NAGIOS} del host de nagios ${ID_HOST_NAGIOS_1} y ${ID_HOST_NAGIOS_2} en DT" >> ${LOG_EJEC}
			echo "#####################################################################################">>${LOG_EJEC}
			echo >> ${LOG_EJEC}
		fi

		#Parada de los consumidores del grupo Nifi
		/home/itf/fuente/scripts/xitfj_adminconsum_nifi.sh $ID_GROUP $ACCION
		#Ponemos un sleep para dar tiempo a tratar los flowfiles que esten ecolados
		#sleep 900
		sleep 10
		# Se para el Grupo de Nifi pasado por parametro.
        #/usr/bin/curl -v -i -H "Authorization: Bearer $token" -H 'Content-Type: application/json' -XPUT -d '{"id":"'${ID_GROUP}'","state":"STOPPED"}' ${ID_HOST}/nifi-api/flow/process-groups/${ID_GROUP}
        /usr/bin/curl -v -i -k -H "Authorization: Bearer $token" -H 'Content-Type: application/json' -XPUT -d '{"id":"'${ID_GROUP}'","state":"STOPPED"}' ${ID_HOST}/nifi-api/flow/process-groups/${ID_GROUP}

        RESULTADO=$?

        # Ponemos un sleep para dar tiempo a que todos los procesadores del flujo paren antes de comprobar que esta todo parado
        sleep 30
		
        /usr/bin/curl -k -H "Authorization: Bearer $token" ${ID_HOST}/nifi-api/process-groups/${ID_GROUP}/ -o /home/itf/datos/tmp/xitfjadmingruponifi.json
		# Miramos si todos los procesos del grupo estan parados
        run=`jq .component.runningCount /home/itf/datos/tmp/xitfjadmingruponifi.json`
        if [[ ${run} -gt ${UMBRAL_PROCESS_NOTSTOP} ]]; then
			echo "Abort : Hay $run procesos activos">>${LOG_EJEC}
			##LOGFIN LOG=${LOG_EJEC}
			exit 1
        else
			echo "Todos los procesos parados">>${LOG_EJEC}
        fi
else
		# Se arranca el Grupo de Nifi pasado por parametro.
        #/usr/bin/curl -v -i -H "Authorization: Bearer $token" -H 'Content-Type: application/json' -XPUT -d '{"id":"'${ID_GROUP}'","state":"RUNNING"}' ${ID_HOST}/nifi-api/flow/process-groups/${ID_GROUP}
        /usr/bin/curl -v -i -k -H "Authorization: Bearer $token" -H 'Content-Type: application/json' -XPUT -d '{"id":"'${ID_GROUP}'","state":"RUNNING"}' ${ID_HOST}/nifi-api/flow/process-groups/${ID_GROUP}
		
        RESULTADO=$?
        /usr/bin/curl -k -H "Authorization: Bearer $token" ${ID_HOST}/nifi-api/process-groups/${ID_GROUP}/ -o /home/itf/datos/tmp/xitfjadmingruponifi.json

        # Ponemos un sleep para dar tiempo a que todos los procesadores del flujo arranquen antes de comprobar que esta todo arrancado
        sleep 30

        # Miramos si todos los procesos del grupo estan arrancados
		stop=`jq .component.stoppedCount /home/itf/datos/tmp/xitfjadmingruponifi.json`
		if [[ $stop != 0 ]]; then
			echo "Abort : Hay $stop procesos parados">>${LOG_EJEC}
			##LOGFIN LOG=${LOG_EJEC}
			exit 1
        else
			echo "Todos los procesos activados.">>${LOG_EJEC}
			# DELETE DT - una llamada por ID_HOST_NAGIOS
			/usr/bin/curl http://slx00010798.eroski.es:4440/api/1/job/$ID_JOB_NAGIOS_START/run?authtoken=gphmi4f84nuLv97ir2Bb9mrkiizcR9EO --data-urlencode "argString=-hostname $ID_HOST_CTRL_STOPPED -servicedesc $ID_CTRL_STOPPED -comment 'Generado por script xitfjadmingruponifi'"
			echo >> ${LOG_EJEC}
			echo "######################################################################################################################################################################">>${LOG_EJEC}
			echo "`date +%d%m%Y%H:%M:%S` : Quitamos el DT del service ${ID_CTRL_STOPPED} del host de nagios ${ID_HOST_NAGIOS_1} y ${ID_HOST_NAGIOS_2}" >> ${LOG_EJEC}
			echo "######################################################################################################################################################################">>${LOG_EJEC}
			echo >> ${LOG_EJEC}	
			#Si se informa el service de NAGIOS a arrancar
			if [ "$ID_SERVICE_NAGIOS" != "" ]
			then	
			# DELETE DT - una llamada por ID_HOST_NAGIOS
			/usr/bin/curl http://slx00010798.eroski.es:4440/api/1/job/$ID_JOB_NAGIOS_START/run?authtoken=gphmi4f84nuLv97ir2Bb9mrkiizcR9EO --data-urlencode "argString=-hostname $ID_HOST_NAGIOS_1 -servicedesc $ID_SERVICE_NAGIOS -comment 'Generado por script xitfjadmingruponifi'"
			/usr/bin/curl http://slx00010798.eroski.es:4440/api/1/job/$ID_JOB_NAGIOS_START/run?authtoken=gphmi4f84nuLv97ir2Bb9mrkiizcR9EO --data-urlencode "argString=-hostname $ID_HOST_NAGIOS_2 -servicedesc $ID_SERVICE_NAGIOS -comment 'Generado por script xitfjadmingruponifi'"
			echo >> ${LOG_EJEC}
			echo "######################################################################################################################################################################">>${LOG_EJEC}
			echo "`date +%d%m%Y%H:%M:%S` : Quitamos el DT del service ${ID_SERVICE_NAGIOS} del host de nagios ${ID_HOST_NAGIOS_1} y ${ID_HOST_NAGIOS_2}" >> ${LOG_EJEC}
			echo "######################################################################################################################################################################">>${LOG_EJEC}
			echo >> ${LOG_EJEC}
			fi
        fi
		
fi

echo "RESULTADO ${RESULTADO}.">>${LOG_EJEC}
echo $RESULTADO
echo $RESULTADO >>${LOG_EJEC}

# Informo al LOG
echo >> ${LOG_EJEC}
echo "#####################################################################################">>${LOG_EJEC}
echo "`date +%d%m%Y%H:%M:%S` : Fin del Proceso ${SH_NAME}" >> ${LOG_EJEC}
echo "#####################################################################################">>${LOG_EJEC}
echo >> ${LOG_EJEC}

/usr/bin/SUTSPILO APR_ITF:${SH_NAME}.sh:Completed Fin OK en la ejecución del proceso
cat ${LOG_EJEC} >> ${LOG}
##LOGFIN LOG=${LOG_EJEC}
exit 0
