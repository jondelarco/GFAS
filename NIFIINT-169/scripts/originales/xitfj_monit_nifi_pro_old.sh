#-----------------------------------------------------------------------
#Nombre: xitfj_monit_nifi.sh
#Fecha:28/04/2021                               Autor:Zigor Uriarte
#-----------------------------------------------------------------------
#Codigo de Retorno :
#                       0 -> Ejecucion correcta
#                       1 -> Ejecucion incorrecta
#
#			Parametros:
#						1 - Host de la aplicacion nifi
#						2 - ID del grupo a controlar. 
#						3 - Tiempo maximo en ms
#						4 - Numero maximo de mensajes
#						5-	Indica si es critico o no el flujo (opcional)
#						6 - Cod_dest de la aplicacion que se quiera monitorizar (opcional)
#-----------------------------------------------------------------------
# Dado el ID de un grupo nifi, revisamos que no haya en ninguna cola, mensajes esperando mas de X tiempo. 

#EJEMPLOS DE EJECUCION
#DES
#https://slx00012150.eroski.es:8443 03910ad2-e881-3a1a-eba1-80c69333ce25 '' 100 N  425

#PRO
#https://slx00011234.eroski.es:8443 38db1a1d-0196-1000-0000-0000032f7fd2 '' 100 N  425

# IMPORTS
. /home/itf/.entorno # Cargo las variables de Entorno de la Aplicacion.

finlog() {
    
    # Informo al LOG
    echo | tee -a ${LOG_EJEC}
    echo "#####################################################################################"| tee -a ${LOG_EJEC}
    echo "`date +%d\/%m\/%Y\ %H:%M:%S`: Fin del Proceso ${SH_NAME}" | tee -a ${LOG_EJEC}
    echo "#####################################################################################"| tee -a ${LOG_EJEC}
    echo | tee -a ${LOG_EJEC}

    cat ${LOG_EJEC} >> ${LOG}
    ##LOGFIN LOG=${LOG_EJEC}

    if [[ $1 -ne 0 ]]; then
        /usr/bin/SUTSPILO ARQ:${SH_NAME}.sh:KO proceso $SH_NAME
    else
        /usr/bin/SUTSPILO ARQ:${SH_NAME}.sh:OK proceso $SH_NAME
    fi

}


SH_NAME="xitfj_monit_nifi"
DIR_FICHERO_LOG="/home/itf/datos/log"
MSGID=`date +%Y%m%d%H%M%S`$RANDOM
NOM_FICHERO_LOG=$SH_NAME"_"`date +%Y%m%d`".log"
NOM_FICHERO_LOG_EJEC=${SH_NAME}_${MSGID}.log.ejec
LOG=$DIR_FICHERO_LOG"/"$NOM_FICHERO_LOG
LOG_EJEC=$DIR_FICHERO_LOG"/"$NOM_FICHERO_LOG_EJEC
VAL_SALIDA=0
COD_INT=6011
COD_ORI=424


ID_HOST=$1
ID_GROUP=$2
TIEMPO_MAX=$3
CANT_MSGS=$4

# Usuario cdp_srv_itf
. $EROSKI/fuente/scripts/OUTSORUS.sh $GDEAPPL \$0

#Usuario Integracion
USER_ITF=$ORAUSER
PW_ITF=$ORAPASS

# Conexión a PINTERF
# . $EROSKI/fuente/scripts/OUTSORUS.sh $GDEAPPL2 \$0

# Quinto parametro opcional.  Indica si es incidencia o no el flujo
#  - S: Es INCIDENCIA, el proceso aborta para que genere incidencia desde PLATON
#  - N por defecto si no se indica el parametro: No es INCIDENCIA, envia mail de aviso pero no aborta
if test -z "$5"
then	
	INCIDENCIA="N"
else
	INCIDENCIA=$5
fi
# Sexto parametro opcional. Cod_dest de la aplicacion que se quiera monitorizar
if test -z "$6"
then    
    cod_dest=""
else
    cod_dest=$6
fi

FICH="/home/itf/datos/tmp"
# 6 horas que en ms es 21.600.000 ( 1 hora 3.600.000 ms )
#TIEMPO_MAX=21600000

recorrer_grupo () {
echo $1
#Recuperamos todos los componentes del grupo pasado por parametro
/usr/bin/curl -k -H "Authorization: Bearer $token" ${ID_HOST}/nifi-api/process-groups/$1 -o $FICH/${1}_${MSGID}_grupo_completo.json

#Recuperamos todos los grupos del grupo
/usr/bin/curl -k -H "Authorization: Bearer $token" ${ID_HOST}/nifi-api/process-groups/$1/process-groups -o $FICH/${1}_${MSGID}_grupo_grupos.json

#Recuperamos las colas del grupo pasado por parametro
/usr/bin/curl -k -H "Authorization: Bearer $token" ${ID_HOST}/nifi-api/process-groups/$1/connections -o $FICH/${1}_${MSGID}_grupo_connections.json

	#echo grupo = $1
	#.processGroups[].component.id
	#Recorremos los grupos del grupo
	for g in $(jq -r '.processGroups[].component.id' $FICH/${1}_${MSGID}_grupo_grupos.json); do
			recorrer_grupo ${g}
	done

#Recorremos las colas del grupo
for k in $(jq '.connections | keys | .[]' $FICH/${1}_${MSGID}_grupo_connections.json); do

	  value=$(jq -r ".connections[$k]" $FICH/${1}_${MSGID}_grupo_connections.json);
		
		#echo value = $value
		
	  # Identificador de la cola
		ID_QUEUE=$(jq -r '.id' <<< "$value");
		
	  # Identificador del procesador origen
		ID_ORIGEN_NAME=$(jq -r '.component.source.name' <<< "$value");
		
	  # Identificador del procesador destino
		ID_DESTINO_NAME=$(jq -r '.component.destination.name' <<< "$value");
		
		# Identificador del grupo al que pertenece el destino de la cola
		ID_GROUP_DESTINO=$(jq -r '.component.destination.groupId' <<< "$value");
		
		# tipo de objeto destino
		ID_DESTINO_TYPE=$(jq -r '.component.destination.type' <<< "$value");

		QUEUE_NAME=$(jq -r '.status.name' <<< "$value");
		
		#echo $ID_QUEUE  -  $ID_ORIGEN_NAME  -  $ID_DESTINO_NAME - $ID_DESTINO_TYPE
		
		# descartamos las colas que tienen como destino los FUNNEL para evitar falsos positivos. 
		if [ ${ID_DESTINO_TYPE} != "FUNNEL" ]
		then
				
				# recuperamos el id de la lista de mensajes de al cola
				/usr/bin/curl -k -X POST -H "Authorization: Bearer $token" ${ID_HOST}/nifi-api/flowfile-queues/${ID_QUEUE}/listing-requests -o $FICH/${ID_QUEUE}_${MSGID}_lista_cola.json
				ID_LIST_QUEUE=$(jq -r ".listingRequest.id" $FICH/${ID_QUEUE}_${MSGID}_lista_cola.json);
				echo "LISTA COLA: ${ID_QUEUE}"

				# Con el ID de la lista de mensajes de la cola, recuperamos los ID de cada mensaje de la cola
				/usr/bin/curl -k -H "Authorization: Bearer $token" ${ID_HOST}/nifi-api/flowfile-queues/${ID_QUEUE}/listing-requests/$ID_LIST_QUEUE -o $FICH/${ID_LIST_QUEUE}_${MSGID}_lista_cola_detalle.json
				
				#miramos si hay mensajes pendientes acumulados
				V_CONT=$(jq -r ".listingRequest.queueSize.objectCount" $FICH/${ID_LIST_QUEUE}_${MSGID}_lista_cola_detalle.json)
				
				#sacamos el id de lista de mensajes
				V_ID_LISTA=$(jq -r ".listingRequest.id" $FICH/${ID_LIST_QUEUE}_${MSGID}_lista_cola_detalle.json)
				echo V_CONT: $V_CONT
				if [ ${V_CONT} -ne 0 ]
				then
					#Se mira si la cola contiene NO_MONIT en el nombre, si es así no se monitoriza
					case "$QUEUE_NAME" in
							*NO_MONIT*) echo "Esta cola no se monitoriza" ;;
							*no_monit*) echo "Esta cola no se monitoriza" ;;
							*)  if [ ! -z $TIEMPO_MAX ]
									then
											#llamamos a la funcion que evalua la cola por tiempo de retraso de mensajes
											evaluar_cola_tiempo ${ID_LIST_QUEUE}
									fi
									if [ ! -z $CANT_MSGS ]
									then
											#llamamos a la funcion que evalua la cola por tiempo de retraso de mensajes
											evaluar_cola_cantidad ${ID_LIST_QUEUE}
									fi;;
					esac
				fi
		fi



done 

}

#evalua si ha de saltar avisar o no en función del tiempo que lleven los mensajes encolados en la cola deseada
evaluar_cola_tiempo () {
    #recuperamos el tiempo del primer mensaje de la cola
		V_TIEMPO_PASADO=$(jq -r ".listingRequest.flowFileSummaries[0].queuedDuration" $FICH/$1_${MSGID}_lista_cola_detalle.json)
		V_TOTAL_MENSAJES=$(jq -r ".listingRequest.queueSize.objectCount" $FICH/$1_${MSGID}_lista_cola_detalle.json)
		
		if [ $V_TIEMPO_PASADO -gt $TIEMPO_MAX ]
		then
				#recuperamos el numero de registros que se pasan de tiempo 
				V_PASADOS=$(jq -r "[.listingRequest.flowFileSummaries[] | select(.queuedDuration > $TIEMPO_MAX)] | length" $FICH/$1_${MSGID}_lista_cola_detalle.json)
				#echo $V_PASADOS
				#echo Tenemos $V_PASADOS mensjaes encolados demasiado tiempo entre el proceso ${ID_ORIGEN_NAME} y el proceso ${ID_DESTINO_NAME}
				
				echo >> ${LOG_EJEC}
				echo "#####################################################################################">>${LOG_EJEC}
				echo "Tenemos al menos $V_PASADOS mensajes encolados demasiado tiempo entre el proceso ${ID_ORIGEN_NAME} y el proceso ${ID_DESTINO_NAME}">>${LOG_EJEC}
				echo "El ID de la cola que los contiene es ${ID_QUEUE} y tiene un total de ${V_TOTAL_MENSAJES} encolados.">>${LOG_EJEC}
				echo "$ID_ORIGEN_NAME --${V_TOTAL_MENSAJES}--> $ID_DESTINO_NAME">>${LOG_EJEC}
				echo "Se debe revisar que el flujo funciona correctamente.">>${LOG_EJEC}
				echo "#####################################################################################">>${LOG_EJEC}
				echo >> ${LOG_EJEC}
				
				# Si hay varias colas afectadas, lo agrupamos en el mismo log
				VAL_SALIDA=1
				
				#exit 1
		fi
}

#evalua si ha de saltar avisar o no en función de la cantidad de mensajes encolados en la cola deseada
evaluar_cola_cantidad () {
		V_TOTAL_MENSAJES=$(jq -r ".listingRequest.queueSize.objectCount" $FICH/$1_${MSGID}_lista_cola_detalle.json)
		
		if [ $V_TOTAL_MENSAJES -gt $CANT_MSGS ]
		then
				echo >> ${LOG_EJEC}
				echo "#####################################################################################">>${LOG_EJEC}
				echo "Tenemos más de $CANT_MSGS mensajes encolados entre el proceso ${ID_ORIGEN_NAME} y el proceso ${ID_DESTINO_NAME}">>${LOG_EJEC}
				echo "El ID de la cola que los contiene es ${ID_QUEUE} y tiene un total de ${V_TOTAL_MENSAJES} encolados.">>${LOG_EJEC}
				echo "$ID_ORIGEN_NAME --${V_TOTAL_MENSAJES}--> $ID_DESTINO_NAME">>${LOG_EJEC}
				echo "Se debe revisar que el flujo funciona correctamente.">>${LOG_EJEC}
				echo "#####################################################################################">>${LOG_EJEC}
				echo >> ${LOG_EJEC}
				
				# Si hay varias colas afectadas, lo agrupamos en el mismo log
				VAL_SALIDA=1
		fi
}


#recogemos los correos a los que hay que mandar el mail
p_select_mails() {
    CORREOS_ADICIONALES=$(sqlplus -s "$ORAUSER/$ORAPASS@$ORAHOST" <<EOF
        SET HEADING OFF
        SET FEEDBACK OFF
        SET PAGESIZE 0
        SET TRIMSPOOL ON
        SET LINESIZE 1000
        SET TERMOUT OFF

        SELECT RTRIM(XMLAGG(XMLELEMENT(e, texto || ',') ORDER BY texto).EXTRACT('//text()'), ',')
        FROM param_mail
        WHERE cod_int = $COD_INT
          AND cod_ori = $COD_ORI
          AND cod_dest = $cod_dest
          AND flg_activo = 'S';
EOF
    )

    # Limpieza: quitar espacios, saltos de línea y coma final si existe
    CORREOS_ADICIONALES=$(echo "$CORREOS_ADICIONALES" | tr -d '[:space:]' | sed 's/,$//')
}

echo >> ${LOG_EJEC}
echo "#####################################################################################">>${LOG_EJEC}
echo "`date +%d%m%Y%H:%M:%S` : Inicio del Proceso ${SH_NAME}.sh" >> ${LOG_EJEC}
echo "Recorremos al Grupo de Nifi de ${ID_GROUP} en busca de mensajes acumulados.">>${LOG_EJEC}
echo "#####################################################################################">>${LOG_EJEC}
echo >> ${LOG_EJEC}

# if [ $# -ne 3 -a $# -ne 4 ]
# then
	  # /usr/bin/SUTSPILO APR_ITF:${SH_NAME}.sh: Aborted: Número o tipo de argurmentos incorrecto
	  # echo >> ${LOG_EJEC}
	  # echo "Aborted: Número o tipo de argurmentos incorrecto" >> ${LOG_EJEC}
	  # echo >> ${LOG_EJEC}
		# echo "#####################################################################################">>${LOG_EJEC}
		# echo "`date +%d%m%Y%H:%M:%S` : Fin KO del Proceso ${SH_NAME}" >> ${LOG_EJEC}
		# echo "#####################################################################################">>${LOG_EJEC}
		# cat ${LOG_EJEC} >> ${LOG}
	  # exit 1
# fi



# el entorno esta securizado asique tenemos que crearnos un TOKEN para las consultas a la API
# token=`curl -s -k "${ID_HOST}/nifi-api/access/token" -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' --data 'username=nifi_integracion&password=Itfcoladm1'`
token=`curl -k "${ID_HOST}/nifi-api/access/token" -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' --data "username=${USER_ITF}&password=${PW_ITF}"`

echo $token

# recuperamos todo el grupo y lo recorremos las conexiones ( colas )
recorrer_grupo ${ID_GROUP}

#Borramos ficheros temporales.
rm $FICH/*_${MSGID}_grupo_completo.json
rm $FICH/*_${MSGID}_lista_cola.json
rm $FICH/*_${MSGID}_lista_cola_detalle.json
rm $FICH/*_${MSGID}_grupo_grupos.json
rm $FICH/*_${MSGID}_grupo_connections.json


##LOGFIN LOG=${LOG_EJEC}
if [ ${VAL_SALIDA} -ne 0 ]
then  
		if [ "${INCIDENCIA}" != "N" ]
		then
		        finlog 1
				exit 1
		else
			#CUERPO="El circuito de NiFi $ID_GROUP tiene un total de ${V_TOTAL_MENSAJES} encolados. \nRevisar el circuito, mayor detalle en el log ${LOG_EJEC} del  proceso ${SH_NAME}.sh del nodo de NiFi ${ID_HOST}."
			DESTINATARIO="pses-integracion@eroski.es"
			ASUNTO="ALERTA - Circuito de nifi con mensajes acumulados"
			CUERPO=`cat ${LOG_EJEC}`
			
			if [ ! -z "$cod_dest" ]
			then
				# Recuperamos los correos a los que se enviara el mail
				# p_select_mails		
				$EROSKI/fuente/scripts/xitfjemail.sh "${DESTINATARIO}" "${ASUNTO}" "${CUERPO}" "" "${cod_dest}"
			else
				# Correo base
				$EROSKI/fuente/scripts/xitfjemail.sh "${DESTINATARIO}" "${ASUNTO}" "${CUERPO}"
			fi
			
			RESULTADO=$?

			if [ $RESULTADO -eq 0 ];then
				echo "mail enviado correctamente" >>${LOG_EJEC}
			else
				echo "No se ha podido enviar el mail de aviso" >>${LOG_EJEC}
			fi

		fi
fi

finlog 0
exit 0

