#!/bin/ksh
#-----------------------------------------------------------------------
# Nombre : xitfj_smv_mdmcpb.sh
#
# Fecha: 07/06/2023     Autor: Integracion 
#
#-----------------------------------------------------------------------
#
# Script que recoge fichero de SMV, lo carga en la tabla intermedia en PINTERF
# lo filtra y transforma en otro fichero para el MDMCPB de clientes (ClubCaprabo)
#
##-----------------------------------------------------------------------
# Cargo las variables de Entorno de la Aplicacion.
# $HOME,$FUENTE,$EXEC,$DATOS, $EROSKI.
. $vPATHSC/../../.entorno >/dev/null

# Referenciamos otras maquinas (Cargo la variable nodo iniciador)
. $EROSKI/fuente/scripts/exj-name

# Variables locales
# Se recoge un aleatorio de longitud 5
long=0
while [ "long" -ne "5" ]
do
   ALE=$RANDOM
   long=${#ALE}
done

# Variables locales
DIR_DATOS=$DATOS/in/eroskiclub/smvcpb
FICH_ENT="caprabo_movimientos_tarjetas_*.csv"
LOGSQLLOADER=$DATOS/log/SMVtoMDMCPB_`date '+%Y%m%d%H%M%S'`.log
SH_NAME="xitfj_smv_mdmcpb"
DIR_SALIDA="/home/itf/datos/out/erkclub"
FECHA_FICH_OUT=`date +%Y%m%d%H%M%S`
FICH_SALIDA=${DIR_SALIDA}/SMVtoMDM_SALDOS_CANCELADOS_CPB.${FECHA_FICH_OUT}.DAT # Si no especificamos extension, pone .lst por defecto
SQL_NAME="SMV_MDMCPB"

#SQL_NAME1="P_INICIO_DIRECTO"
#SQL_NAME2="P_FIN_HIJOS_DIRECTO"
#COD_APL_S=9999856
#COD_APL_E=9999854
#INTERFAZ=1267
#ESTADO_NO_OK=-140
#ESTADO_OK=140
FEC_LOG=`date +%Y%m%d`
FECHA_INI=`date +%Y%m%d%H%M%S`
MSGID=`date +%Y%m%d%H%M%S`$ALE

if [ "${vREP_NAME}" = "" ]; then
   SECUENCIA_LPU="PLATON"
else
   SECUENCIA_LPU=LPU:${vREP_NAME}
   USUARIO_LPU="LPU"
fi

# Tarjetas de control de la carga de la tabla con sqlloader.
CONTROL=$FUENTE/sql/SMV_MDMCPB.ctl

# Establezco Nombre Fichero LOG del Script.
# Existira un log por dia para que incluira los resultados de ejecucion
LOG=$DATOS/log/${SH_NAME}_$FEC_LOG.log ; export LOG
LOG_EJEC=$DATOS/log/${SH_NAME}_$FECHA_INI.log.ejec

# Informo al LOG
# Escribimos la hora de inicio del proceso
echo >> ${LOG_EJEC}
echo '####################################################################'>> ${LOG_EJEC}
echo "`date '+%d/%m/%Y %H:%M:%S'` :- Inicio del Proceso ${SH_NAME}">> ${LOG_EJEC}
echo '####################################################################'>> ${LOG_EJEC}
echo >> ${LOG_EJEC}

# Cargamos las variables de conexion a la base de datos
. $EROSKI/fuente/scripts/OUTSORUS.sh $GDEAPPL \$0

## Se ejecuta el PL pk_itf_batch.p_inicio
#${ORACLE_HOME}/bin/sqlplus -s -l ${ORAUSER}/${ORAPASS}@${ORAHOST} \
#    @${FUENTE}/sql/${SQL_NAME1}.sql $MSGID $COD_APL_S $INTERFAZ $SECUENCIA_LPU "${USUARIO_LPU}" \
#    >> ${LOG_EJEC}
#
#RESULTADO1=$?
#
## Comprobamos errores
#if [ ${RESULTADO1} -ne 0 ]
#then
#   echo >>${LOG_EJEC}
#   echo Código ${RESULTADO1}: ***ERROR*** ejecutando ${FUENTE}/sql/${SQL_NAME1}.sql >> ${LOG_EJEC}
#   echo >>${LOG_EJEC}
#else
#   echo >>${LOG_EJEC}
#   echo Proceso ***OK*** ${FUENTE}/sql/${SQL_NAME1}.sql terminado correctamente >>${LOG_EJEC}
#   echo >>${LOG_EJEC}
#fi

if [ `ls -1 ${DIR_DATOS}/${FICH_ENT}|wc -l` -gt 0 ]
then
#*************VACIADO DE ITFCOLADM.T_SMV_MDMCPB ANTES DE LA CARGA ***********************************************
sqlplus ${ORAUSER}/${ORAPASS}@${ORAHOST}  <<eof >>${LOG_EJEC}
truncate table ITFCOLADM.T_SMV_MDMCPB;
commit;
eof

#*************CARGANDO EN ITFCOLADM.ITFCOLADM.T_SMV_MDM *** usando sqlloader ***********************************************
RESULTADO2=0

    for j in `ls -1 ${DIR_DATOS}/${FICH_ENT}`
    do
        i=`basename $j`
        echo '....................................................................'>> ${LOG_EJEC}
        echo "`date '+%d/%m/%Y %H:%M:%S'` :- Se va a cargar el fichero $i ">> ${LOG_EJEC}
        echo '....................................................................'>> ${LOG_EJEC}
        
        ### Llamar a Sql*Loader para cargar los datos del fichero copia en la tabla de la B.D.
        sqlldr ${ORAUSER}/${ORAPASS}@${ORAHOST} CONTROL=$CONTROL DATA=${DIR_DATOS}/${i}  LOG=${LOGSQLLOADER} \
        DISCARD=${DIR_DATOS}/fich_error/${i}.dsc BAD=${DIR_DATOS}/fich_error/${i}.bad
        RESULTADO=$?

        #Al finalizar la ejecucion del loader movemos el fichero con el que hemos estado trabajando
        if [ $RESULTADO -eq 0 ]
        then
            mv ${DIR_DATOS}/${i} ${DIR_DATOS}/copias/${i}.ok
        else
            RESULTADO2=$RESULTADO
            cat ${LOGSQLLOADER} >> ${LOG_EJEC}
            mv ${DIR_DATOS}/${i} ${DIR_DATOS}/fich_error/${i}
        fi
    done

else
    echo '####################################################################'>> ${LOG_EJEC}
    echo "`date '+%d/%m/%Y %H:%M:%S'` :- No se ha encontrado fichero de entrada ">> ${LOG_EJEC}
    echo '####################################################################'>> ${LOG_EJEC}
fi

# *****************************************************************************************************

echo RESULTADO_CARGA : $RESULTADO2 >>${LOG_EJEC}
echo RESULTADO_CARGA : $RESULTADO2

if [ ${RESULTADO2} -ne 0 ]
then
   /usr/bin/SUTSPILO APR_ITF :${SH_NAME}.sh:Aborted. Error de carga de datos en tabla T_SMV_MDMCPB
   mensaje="Error de carga de datos en tabla T_SMV_MDMCPB"

#   #Se ejecuta el PL que informa el estado de todos los destinos a error
#   FECHA_MERCA=`date +%Y%m%d%H%M%S`
#   ${ORACLE_HOME}/bin/sqlplus -s -l ${ORAUSER}/${ORAPASS}@${ORAHOST} \
#      @${FUENTE}/sql/${SQL_NAME2}.sql $MSGID $COD_APL_E $INTERFAZ $ESTADO_NO_OK "$mensaje" $FECHA_INI $FECHA_MERCA  \
#      >> ${LOG_EJEC}
#
#   RESULTADO3=$?
#   if [ ${RESULTADO3} -ne 0 ]
#   then
#      echo >>${LOG_EJEC}
#      echo Error $RESULTADO3 ejecutando el archivo ${FUENTE}/sql/${SQL_NAME2}.sql con $MSGID $COD_APL_E $INTERFAZ $ESTADO_NO_OK "$mensaje" $FECHA_INI $FECHA_MERCA >> ${LOG_EJEC}
#      echo >>${LOG_EJEC}
#   else
#      echo >>${LOG_EJEC}
#      echo Proceso ${SQL_NAME2}.sql terminado correctamente >>${LOG_EJEC}
#      echo >>${LOG_EJEC}
#   fi

   . $EROSKI/fuente/scripts/SUTSAVIS.sh $$ $mensaje
   cat ${LOG_EJEC}>>${LOG}
   ##LOGFIN LOG=${LOG_EJEC}
   exit 1
else
   echo >>${LOG_EJEC}
   echo "Carga de datos en tabla T_SMV_MDMCPB ejecutado correctamente" >> ${LOG_EJEC}
   echo >>${LOG_EJEC}
   #Se ejecuta ek PL que informa el estado de todos los destinos a error
#   FECHA_MERCA=`date +%Y%m%d%H%M%S`
#   ${ORACLE_HOME}/bin/sqlplus -s -l ${ORAUSER}/${ORAPASS}@${ORAHOST} \
#      @${FUENTE}/sql/${SQL_NAME2}.sql $MSGID $COD_APL_E $INTERFAZ $ESTADO_OK "Ejecucion correcta." $FECHA_INI $FECHA_MERCA  \
#      >> ${LOG_EJEC}
#
#   RESULTADO3=$?
#   if [ ${RESULTADO3} -ne 0 ]
#   then
#      echo >>${LOG_EJEC}
#      echo Error ejecutando el archivo ${FUENTE}/sql/${SQL_NAME2}.sql >> ${LOG_EJEC}
#      echo >>${LOG_EJEC}
#   else
#      echo >>${LOG_EJEC}
#      echo Proceso ${SQL_NAME2}.sql terminado correctamente >>${LOG_EJEC}
#      echo >>${LOG_EJEC}
#   fi

   # Extraer los datos de la tabla para generar el fichero de salida
   #export NLS_LANG=SPANISH_SPAIN.WE8ISO8859P15
   export NLS_LANG=SPANISH_SPAIN.AL32UTF8
   ${ORACLE_HOME}/bin/sqlplus -s -l ${ORAUSER}/${ORAPASS}@${ORAHOST} \
   @${FUENTE}/sql/${SQL_NAME}.sql ${FICH_SALIDA} ${MSGID}

   RESULTADO4=$?

   echo RESULTADO_EXTRACCION : $RESULTADO4 >>${LOG_EJEC}
   echo RESULTADO_EXTRACCION : $RESULTADO4

   # Si hay error eliminar el fichero con la descripcion del error
   if [ $RESULTADO4 -eq 0 ]
   then
      # Si el fichero generado esta vacio (la consulta no devuelve datos)
      # se borra
      if [ ! -s $FICH_SALIDA ]
      then
            rm -f ${FICH_SALIDA}

            echo "Fichero $FICH_SALIDA vacio.  Se borra"
            echo
            echo "Fichero $FICH_SALIDA vacio.  Se borra" >>${LOG_EJEC}
            echo >>${LOG_EJEC}
     else 
           echo "Generado fichero $FICH_SALIDA"
           echo "Generado fichero $FICH_SALIDA" >>${LOG_EJEC}
           echo >>${LOG_EJEC}
      fi
   else
       echo "Error en la extraccion"
       echo
       echo "Error en la extraccion" >>${LOG_EJEC}
       echo >>${LOG_EJEC}       

       if [ -f $FICH_SALIDA ]
       then
             rm -f ${FICH_SALIDA}
 
             echo "Fichero $FICH_SALIDA Se borra"
             echo
             echo "Fichero $FICH_SALIDA Se borra" >>${LOG_EJEC}
             echo >>${LOG_EJEC}
       fi       

       # Si aborta aqui, el fichero de entrada se quedara en la entrada
       # no lo movemos a fich_error
       /usr/bin/SUTSPILO APR_ITF :${SH_NAME}.sh:Aborted. Error de extraccion de datos en tabla T_SMV_MDMCPB
       mensaje="Error de extraccion de datos en tabla T_SMV_MDMCPB"

      . $EROSKI/fuente/scripts/SUTSAVIS.sh $$ $mensaje
       cat ${LOG_EJEC}>>${LOG}
       ##LOGFIN LOG=${LOG_EJEC}
       exit 1

   fi

fi

/usr/bin/SUTSPILO ITF_ITF:${SH_NAME}:Completed Fin OK en la ejecucion de la carga de datos.

echo >> ${LOG_EJEC}
echo '####################################################################'>> ${LOG_EJEC}
echo "`date '+%d/%m/%Y %H:%M:%S'` :- Fin del Proceso ${SH_NAME}">> ${LOG_EJEC}
echo '####################################################################'>> ${LOG_EJEC}
echo >> ${LOG_EJEC}
cat ${LOG_EJEC}>>${LOG}
##LOGFIN LOG=${LOG_EJEC}
exit 0

