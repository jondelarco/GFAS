#!/bin/ksh
#-----------------------------------------------------------------------
# Nombre : xitfjent_pil_P_U.sh
# Fecha: 29/10/13     Autor: SOPPLAN          Ultimos Cambios
#
# Descripci n Funcional:
#       Interfaz para extraer los registros que contienen las PILADAS PLANOGRAMADAS de SIA e integrarlos en UNIDIN en la misma tabla.
#       Consta de los siguientes pasos:
#       - Ejecuta el PL PK_ITF_BATCH_DIRECTO.P_INICIO_USER
#       - Ejecuta el mapa de mercator itf_73_1664_203.mms
#       - Ejecuta el PL PK_ITF_BATCH_DIRECTO.P_ACT_EST_ALL_DEST
#
# Uso:
#       $FUENTE/scripts/xitfjent_pil_P_U.sh 
#
# Codigo de Retorno 
#       0 -> Ejecucion correcta
#       1 -> Ejecucion incorrecta
#
# Cargo las variables de Entorno de la Aplicacion.
# $HOME,$FUENTE,$EXEC,$DATOS, $EROSKI.
. $vPATHSC/../../.entorno >/dev/null

# Referenciamos otras máquinas (Cargo la variable nodo iniciador)
. $EROSKI/fuente/scripts/exj-name

#No hay argumentos

# Cargamos las variables de conexion a la base de datos
# Se conecta a DEINTERF con ITFCOLADM
. $EROSKI/fuente/scripts/OUTSORUS.sh $GDEAPPL \$0

#
# Variables locales
# Se recoge un aleatorio de longitud 5
long=0
while [ "$long" -ne "5" ]
do
   ALE=$RANDOM
   long=${#ALE}
done   

SH_NAME="xitfjent_pil_P_U"
SQL_NAME1="P_INICIO_DIRECTO"
SQL_NAME2="P_FIN_HIJOS_DIRECTO"
MAPA="itf_73_1664_203"
MSGID=`date +%Y%m%d%H%M%S`$ALE
FECHA_INI=`date +%Y%m%d%H%M%S`
FEC_LOG=`date +%Y%m%d`
FEC_LOG_EJEC=`date +%Y%m%d`$RANDOM
COD_APL_S=73
COD_APL_E=203
INTERFAZ=1664
ESTADO_NO_OK=-140
ESTADO_OK=140
MENSAJE_ERROR="Se ha generado un error durante la ejecución del script."
MDQ_UNIDIN="/home/itf/exec/mercator/mdq/itf_unidin.mdq"

if [ "${vREP_NAME}" = "" ]; then
   SECUENCIA_LPU="PLATON"
else
   SECUENCIA_LPU=LPU:${vREP_NAME}
   USUARIO_LPU=$1
fi

# Establezco Nombre Fichero LOG del Script.
# Existirá un log por día donde se incluirán los resultados de ejecución
LOG=$DATOS/log/${SH_NAME}_$FEC_LOG.log ; export LOG
LOG_EJEC=$DATOS/log/${SH_NAME}_$FEC_LOG_EJEC.log.ejec

# Escribimos la hora de inicio del proceso
echo >> ${LOG_EJEC}
echo "#####################################################################################">>${LOG_EJEC}
echo "`date +%d%m%Y%H:%M:%S` : Inicio del Proceso ${SH_NAME} para el MSGID ${MSGID}" >> ${LOG_EJEC}
echo "-------------------------------------------------------------------------------------">>${LOG_EJEC}
echo " MAPA : $MAPA " >> ${LOG_EJEC}
echo "-------------------------------------------------------------------------------------">>${LOG_EJEC}
echo "#####################################################################################">>${LOG_EJEC}
echo >> ${LOG_EJEC}


# Inicio: Informar a PLATON
/usr/bin/SUTSPILO APR_ITF:${SH_NAME}.sh:Inicio del proceso de ${SH_NAME}


# Se ejecuta el PL pk_itf_batch.p_inicio
${ORACLE_HOME}/bin/sqlplus -s -l ${ORAUSER}/${ORAPASS}@${ORAHOST} \
    @${FUENTE}/sql/${SQL_NAME1}.sql $MSGID $COD_APL_S $INTERFAZ $SECUENCIA_LPU "${USUARIO_LPU}" \
    >> ${LOG_EJEC}

RESULTADO1=$?

# Comprobamos errores
if [ ${RESULTADO1} -ne 0 ]
then
    echo >>${LOG_EJEC}
    echo Código ${RESULTADO1}: ***ERROR*** ejecutando ${FUENTE}/sql/${SQL_NAME1}.sql >> ${LOG_EJEC}
    echo >>${LOG_EJEC}
else
    echo >>${LOG_EJEC}
    echo Proceso ***OK*** ${FUENTE}/sql/${SQL_NAME1}.sql terminado correctamente >>${LOG_EJEC}
    echo >>${LOG_EJEC}
fi


# Cargamos las variables de conexion a la base de datos
# Se conecta a DEINTERF con ITFCOLADM
. $EROSKI/fuente/scripts/OUTSORUS.sh $GDEAPPL3 \$0

#Primero actulizamos el msgid en la tabla PILADAS_PLANOGRAMADAS
UPDATEMSGID="-MDQ $MDQ_FILE -DBNAME GREDAPR  -STMT UPDATE piladas_planogramadas SET msgid = ''${MSGID}'' WHERE  flg_enviado_ac = ''N''"
VDATABASE1="-MDQ $MDQ_FILE  -DBNAME GREDAPR  -STMT  SELECT  COD_LOC, COD_ART_FORMLOG, TIPO_PILADA, ANO_PILADA, COD_PILADA, CANT_IMPLANTACION_MIN_UDS, CANT_CAPACIDAD_MAX_UDS, FEC_INICIO, FEC_FIN, COD_ORIGEN, FLG_VENTA_NORMAL, FLG_PILADA_OFERTA, FLG_PILADA_CABECERA, FLG_PILADA_CAMPANA, FEC_GEN, FLG_ENVIADO_AC, MSGID, NUM_OFERTA, CREATED_BY, CREATION_DATE, LAST_UPDATED_BY, LAST_UPDATE_DATE, LAST_UPDATE_LOGIN, TECLE, TCN, DESC_PERIODO, ESPACIO_PROMO  FROM piladas_planogramadas WHERE msgid = ''${MSGID}''"
VDATABASEU1="-MDQ ${MDQ_UNIDIN} -DBNAME UNIDIN -TABLE piladas_planogramadas -UPDATE"

#Se llama al mapa de mercator
ERROR=`mercator $HOME"/exec/mercator/mmc/"$MAPA  -ID1B "'$UPDATEMSGID'" -ID2B "'$VDATABASE1'" -IE3 $MSGID  \
	  -OD1B  "'$VDATABASEU1'" -OE2 -R0`
 
RESULTADO2=$?

echo RESULTADO_MAPA : $RESULTADO2 >>${LOG_EJEC}
echo RESULTADO_MAPA : $RESULTADO2 
echo ERROR : $ERROR >>${LOG_EJEC}
echo ERROR : $ERROR

# Cargamos las variables de conexion a la base de datos
# Se conecta a INTERF con ITFCOLADM
. $EROSKI/fuente/scripts/OUTSORUS.sh $GDEAPPL \$0

if [ $RESULTADO2 -eq 9 ]
then
		#Al escribir el patrón WTX-Fichero-pte-conexKO en el log, GADI generará incidiencia a BBDD.
		/usr/bin/SUTSPILO APR_ITF :${SH_NAME}.sh:Aborted WTX no consigue conexion con BBDD "UNIDIN"
		echo " WTX-Fichero-pte-conexKO  " >>${LOG_EJEC}
    echo "Registros por error de conexión los dejamos con el flag sin tratar" >> ${LOG_EJEC}
		
		mensaje="Error de conexión ejecutando $MAPA"		
				
		#Se ejecuta el PL que informa el estado de todos los destinos a error 
    FECHA_MERCA=`date +%Y%m%d%H%M%S`
    ${ORACLE_HOME}/bin/sqlplus -s -l ${ORAUSER}/${ORAPASS}@${ORAHOST} \
       @${FUENTE}/sql/${SQL_NAME2}.sql $MSGID $COD_APL_E $INTERFAZ $ESTADO_NO_OK "$mensaje" $FECHA_INI $FECHA_MERCA  \     
       >> ${LOG_EJEC}
       
    RESULTADO3=$?
   
    if [ ${RESULTADO3} -ne 0 ]    
    then
   	    echo >>${LOG_EJEC}
        echo Error $RESULTADO3 ejecutando el archivo ${FUENTE}/sql/${SQL_NAME2}.sql con $MSGID $COD_APL_E $INTERFAZ $ESTADO_NO_OK "$mensaje" $FECHA_INI $FECHA_MERCA >> ${LOG_EJEC}
        echo >>${LOG_EJEC}
    else
        echo >>${LOG_EJEC}
        echo Proceso ${SQL_NAME2}.sql terminado correctamente >>${LOG_EJEC}
        echo >>${LOG_EJEC}   
    fi
    . $EROSKI/fuente/scripts/SUTSAVIS.sh $$ $mensaje    
		cat ${LOG_EJEC}>>${LOG}
##LOGFIN LOG=${LOG_EJEC}
		exit 1 
elif [ ${RESULTADO2} -ne 0 ]
then
   echo >>${LOG_EJEC}
   echo Error $RESULTADO2 ejecutando mapa $MAPA de Mercator >> ${LOG_EJEC}
   echo >>${LOG_EJEC}
   #Se ejecuta ek PL que informa el estado de todos los destinos a error
   FECHA_MERCA=`date +%Y%m%d%H%M%S`
   ${ORACLE_HOME}/bin/sqlplus -s -l ${ORAUSER}/${ORAPASS}@${ORAHOST} \
     @${FUENTE}/sql/${SQL_NAME2}.sql $MSGID $COD_APL_E $INTERFAZ $ESTADO_NO_OK "$MENSAJE_ERROR" $FECHA_INI $FECHA_MERCA  \
    >> ${LOG_EJEC}

    RESULTADO3=$?
    if [ ${RESULTADO3} -ne 0 ]
    then
        echo >>${LOG_EJEC}
        echo Error ejecutando el archivo ${FUENTE}/sql/${SQL_NAME2}.sql >> ${LOG_EJEC}
        echo >>${LOG_EJEC}
    else
        echo >>${LOG_EJEC}
        echo Proceso ${SQL_NAME2}.sql terminado correctamente >>${LOG_EJEC}
        echo >>${LOG_EJEC}
   fi 
   mensaje="Error $RESULTADO2 ejecutando el mapa $MAPA de Mercator"
   . $EROSKI/fuente/scripts/SUTSAVIS.sh $$ $mensaje
   cat ${LOG_EJEC} >> ${LOG}
##LOG FIN LOG=${LOG_EJEC}        
   exit 1 
else
	 echo >>${LOG_EJEC}
   echo "Mapa $MAPA de Mercator ejecutado correctamente" >> ${LOG_EJEC}
   echo >>${LOG_EJEC}
   #Se ejecuta ek PL que informa el estado de todos los destinos a error
   FECHA_MERCA=`date +%Y%m%d%H%M%S`
   ${ORACLE_HOME}/bin/sqlplus -s -l ${ORAUSER}/${ORAPASS}@${ORAHOST} \
     @${FUENTE}/sql/${SQL_NAME2}.sql $MSGID $COD_APL_E $INTERFAZ $ESTADO_OK "Ejecucion correcta." $FECHA_INI $FECHA_MERCA  \
    >> ${LOG_EJEC}

    RESULTADO3=$?
    if [ ${RESULTADO3} -ne 0 ]
    then
        echo >>${LOG_EJEC}
        echo Error ejecutando el archivo ${FUENTE}/sql/${SQL_NAME2}.sql >> ${LOG_EJEC}
        echo >>${LOG_EJEC}
    else
        echo >>${LOG_EJEC}
        echo Proceso ${SQL_NAME2}.sql terminado correctamente >>${LOG_EJEC}
        echo >>${LOG_EJEC}
   fi 
fi 

# Informo al LOG 
echo >> ${LOG_EJEC}
echo "#####################################################################################">>${LOG_EJEC}
echo "`date +%d%m%Y%H:%M:%S` : Fin del Proceso ${SH_NAME}" >> ${LOG_EJEC}
echo "#####################################################################################">>${LOG_EJEC}
echo >> ${LOG_EJEC}

/usr/bin/SUTSPILO APR_ITF :${SH_NAME}.sh:Completed Fin OK en la ejecución del PL/SQL ${SH_NAME}.sql 
# Por mandato de EyS ponemos exit 0 para que PLATON funcione bien 
cat ${LOG_EJEC} >> ${LOG}

exit 0 
