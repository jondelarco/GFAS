#!/bin/ksh
#-----------------------------------------------------------------------
# Nombre : xitfjm59inftms_cebi.sh
#   Fecha            Autor               Últimos Cambios
#-----------------------------------------------------------------------
# 10/04/2015        SOPPLAN      Creacion del interface
#-----------------------------------------------------------------------
# Descripción Funcional:
#       Ejecuta el PL pk_itf_batch.p_inicio
#       Ejecuta el PL APPS.PK_APR_GESTION_PEDIDOS.P_APR_OBT_FEC_PREPARACION
#       Ejecuta el mapa de mercator itf_199_6317_9999858
#       Ejecuta el PL pk_itf_batch.p_act_est_todos_dest si ha habido algún error
#
# Crear un proceso para cargar en tms un fichero de infolog
#
# Uso:
#       $FUENTE/scripts/xitfjm59inftms_cebi.sh <Plataforma>
# Codigo de Retorno :
#       0 -> Ejecucion correcta
#       1 -> Ejecucion incorrecta
#
# Cargo las variables de Entorno de la Aplicacion.
# $HOME, $FUENTE, $EXEC, $DATOS, $EROSKI.
. $vPATHSC/../../.entorno

# Referenciamos otras máquinas (Cargo la variable nodo iniciador)
#. $EROSKI/fuente/scripts/exj-name

SH_NAME="xitfjm59inftms_cebi"

# Comprobamos el número de argumentos
# No hay parametros de entrada

LONG=0

while [ $LONG -ne 5 ]
do
  ALEATORIO=$RANDOM
  LONG=${#ALEATORIO}
done

# Variables locales
SQL_NAME1="P_INICIO_USER"
SQL_NAME2="P_FIN_HIJOS_NO_OK"
SQL_NAME3="P_APR_OBT_FEC_TRANSPORTE"
MAPA="itf_199_6317_9999858"
MSGID=`date +%Y%m%d%H%M%S`$ALEATORIO
FECHA_INI=`date +%Y%m%d%H%M%S`
FEC_LOG=`date +%Y%m%d`
FEC_LOG_EJEC=`date +%Y%m%d`$ALEATORIO
COD_APL_S=199
COD_APL_E=9999858
COD_INT=6317
ESTADO_NO_OK=-140
ESTADO_OK=140
ESTADO_NO_DATOS=999
MENSAJE_ERROR="Se ha generado un error durante la ejecución del script."

# Establezco Nombre Fichero LOG del Script.
# Existirá un log por día donde se incluirán los resultados de ejecución
LOG=$DATOS/log/${SH_NAME}_$FEC_LOG.log ; export LOG
# Existirá un log por ejecución
LOG_EJEC=$DATOS/log/${SH_NAME}_$FEC_LOG_EJEC.log.ejec


if [ $# -ne 1 ]
then
   /usr/bin/SUTSPILO APR_ITF :${SH_NAME}.sh:Aborted ERROR Numero de parametros erroneo
   echo "Numero de parametros erroneo. Inserte el codigo de plataforma por favor."
   echo "Numero de parametros erroneo. Inserte el codigo de plataforma por favor." >> ${LOG_EJEC}
   cat ${LOG_EJEC}>>${LOG}
   ##LOGFIN LOG=${LOG_EJEC}
   exit 1
fi
PLAT=$1

FICH_ENTRADA="M59SECOIN_${PLAT}_*.dat"
DIR_ENTRADA=$DATOS"/in/apr/m59/cebi/"

if [ "${vREP_NAME}" = "" ]; then
   SECUENCIA_LPU="PLATON"
else
   SECUENCIA_LPU=LPU:${vREP_NAME}
fi

# Escribimos la hora de inicio del proceso
echo >> ${LOG_EJEC}
echo "#####################################################################################">>${LOG_EJEC}
echo "`date +%d%m%Y%H:%M:%S` : Inicio del Proceso ${SH_NAME} para el MSGID ${MSGID}" >> ${LOG_EJEC}
echo " Parametro de entrada:" >> ${LOG_EJEC}
echo " PLATAFORMA: ${PLAT}" >> ${LOG_EJEC}
echo "-------------------------------------------------------------------------------------">>${LOG_EJEC}
echo "#####################################################################################">>${LOG_EJEC}
echo >> ${LOG_EJEC}

# Inicio: Informar a PLATON
/usr/bin/SUTSPILO APR_ITF:${SH_NAME}.sh:Inicio del proceso de extraccion para la interfaz ${COD_INT}

# En Linux las variables de BBDD se recuperan tras los parámetros
# Cargamos las variables de conexion a la base de datos
# Se conecta a DEINTERF con ITFCOLADM
. $EROSKI/fuente/scripts/OUTSORUS.sh $GDEAPPL \$0

# Se ejecuta el PL pk_itf_batch.p_inicio
${ORACLE_HOME}/bin/sqlplus -s -l ${ORAUSER}/${ORAPASS}@${ORAHOST} \
    @${FUENTE}/sql/${SQL_NAME1}.sql $MSGID $COD_APL_S $COD_INT $SECUENCIA_LPU "${USUARIO_LPU}" \
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

#se coge el fichero mas nuevo
FICH_LS_ENT=`ls -1tr $DIR_ENTRADA$FICH_ENTRADA 2>/dev/null | tail -1`

#Se comprueba si existe algun fichero, de no ser asi se encola un 999
if [ ! -f $FICH_LS_ENT  -o -z $FICH_LS_ENT ]
then
  echo "No hay ficheros de entrada para los parametros indicados" >>${LOG_EJEC}
  #Se ejecuta el PL que informa el estado de todos los destinos a no hay datos
   FECHA_MERCA=`date +%Y%m%d%H%M%S`
   ${ORACLE_HOME}/bin/sqlplus -s -l ${ORAUSER}/${ORAPASS}@${ORAHOST} \
     @${FUENTE}/sql/${SQL_NAME2}.sql $MSGID $COD_APL_S $COD_INT $ESTADO_NO_DATOS "" $FECHA_INI $FECHA_MERCA  \
    >> ${LOG_EJEC}

    RESULTADO3=$?
    if [ ${RESULTADO3} -ne 0 ]
    then
        echo >>${LOG_EJEC}
        echo Error $RESULTADO3 ejecutando archivo ${FUENTE}/sql/${SQL_NAME2}.sql con $MSGID $COD_APL_S $COD_INT $ESTADO_NO_DATOS "$MENSAJE_ERROR" $FECHA_INI $FECHA_MERCA >> ${LOG_EJEC}
        echo >>${LOG_EJEC}
    else
        echo >>${LOG_EJEC}
        echo Proceso ${SQL_NAME2}.sql terminado correctamente >>${LOG_EJEC}
        echo >>${LOG_EJEC}
    fi
    /usr/bin/SUTSPILO APR_ITF :${SH_NAME}.sh:Completed Fin OK en la ejecución del proceso de extraccion para la interfaz ${COD_INT}

    # Fin del proceso
    echo >>${LOG_EJEC}
    echo '##########################################################################'>> ${LOG_EJEC}
    echo "`date '+%d/%m/%Y %H:%M:%S'` :- Fin del Proceso ${SH_NAME} "         >> ${LOG_EJEC}
    echo '##########################################################################'>> ${LOG_EJEC}
    echo >>${LOG_EJEC}

    cat ${LOG_EJEC}>>${LOG}
    ##LOGFIN LOG=${LOG_EJEC}
    exit 0
fi

#Se recogen todos los ficheros del directorio de entrada
FICH_LS_ENT=`ls -1tr $DIR_ENTRADA$FICH_ENTRADA 2>/dev/null`

#Se inicializa la variable error mapa que será la variable a utilizar para encolar el estado
#Si la variable es 1 se encola un -140 si es 0 un 140.
ERROR_MAPA=0

#Se ejecuta el mapa para cada fichero, y se comprueban los errores devueltos
for FICH_ENT in $FICH_LS_ENT
do
    echo "------------------------------------------------------------------------------"
    echo "------------------------------------------------------------------------------" >> ${LOG_EJEC}
    NOM_FICH_ENT=`basename $FICH_ENT`
    MASCARA_AUX=`echo ${NOM_FICH_ENT}|cut -d "." -f1`
    FECHAHORA_DESDE=`date +%Y%m%d%H%M%S`

    # Si el fichero está vacío no se trata
     if [ ! -s $FICH_ENT ]
     then
        gzip -f -9 -c $FICH_ENT > $DIR_ENTRADA"copias/"$NOM_FICH_ENT".gz"
        rm $FICH_ENT
        echo "Fichero $FICH_ENT vacio, se mueve a copias " >>${LOG_EJEC}
        echo "Fichero $FICH_ENT vacio, se mueve a copias "
    else
        echo "FICHERO_ENTRADA: "$FICH_ENT >>${LOG_EJEC}
        echo "FICHERO_ENTRADA: "$FICH_ENT

        #Eliminamos el 00.00 y el 99.00 Del medio del fichero por si vienen ficheros concatenados
        CABECERA=`head -n 1 ${FICH_ENT}`
        COLA=`grep "^99\.00" ${FICH_ENT}|head -n 1`
        grep -v "^99\.00" ${FICH_ENT} | grep -v "^00\.00" > ${FICH_ENT}.tmp
        #Se eliminan las lineas que no empiecen por 59.20 con TRTEXC = 1 (pos. 6) y ETASUP = 10 (posic. 19)
        grep "^59\.201............10" ${FICH_ENT}.tmp > ${FICH_ENT}.tmp2

        #Se cuenta el numero lineas 59.20 con TRTEXC = 1 (pos. 6) y ETASUP = 10 (posic. 19)
        TOTAL_5920=`grep "^59\.201............10" ${FICH_ENT}.tmp2 | wc -l | tr -d " "`

        INDICE=0
        RESULTADO5=0
        NUMLIN=0
        CONT_OK=0

        if [ ${TOTAL_5920} -eq 0 ]
        then
           echo "No hay registros 59.20 a tratar"
           echo "No hay registros 59.20 a tratar" >> ${LOG_EJEC}
           echo >>${LOG_EJEC} 
        else
           echo "REGISTROS 59.20 A TRATAR: "$TOTAL_5920
           echo "REGISTROS 59.20 A TRATAR: "$TOTAL_5920 >> ${LOG_EJEC}
           echo >>${LOG_EJEC} 

           #Se concatenan cabecera, lineas y pie (este es el fichero que se pasa a copias o a fich error, pero se tratan los individuales con 59.20 solamente)
           echo "${CABECERA}" > ${FICH_ENT}.cab
           echo "${COLA}" > ${FICH_ENT}.pie
           cat ${FICH_ENT}.cab ${FICH_ENT}.tmp2 ${FICH_ENT}.pie > ${FICH_ENT}
           
           #Se ordena el fichero por los campos NUMVAG y NUMSUP
           sort -k 1.75,1.83 -k 1.7,1.15 ${FICH_ENT}.tmp2 > ${FICH_ENT}.tmp 2>/dev/null
           
           #Recorremos el fichero generado con los 59.20 para eliminar las líneas duplicadas (tienen el mismo NUMVAG y NUMSUP)
           NUMVAG_ANT=""
           NUMSUP_ANT=""
           CONTDUP=0           
           mv ${FICH_ENT}.tmp ${FICH_ENT}.tmp2
           
           while read LINEA              
           do
              NUMVAG=`echo "${LINEA}" | cut -c75-82`
              NUMSUP=`echo "${LINEA}" | cut -c7-14`
              
              if [ "${NUMVAG}" != "${NUMVAG_ANT}" ]
              then
                 echo "${LINEA}" >> ${FICH_ENT}.tmp
                 NUMVAG_ANT=${NUMVAG}
                 NUMSUP_ANT=${NUMSUP}
              else
                 if [ "${NUMSUP}" != "${NUMSUP_ANT}" ]
                 then
                    echo "${LINEA}" >> ${FICH_ENT}.tmp
                    NUMSUP_ANT=${NUMSUP} 
                 else
                    CONTDUP=`expr ${CONTDUP} + 1`                
                 fi
              fi              
           done < ${FICH_ENT}.tmp2
           
           if [ ${CONTDUP} -ne 0 ]
           then
              echo "Se han descartado ${CONTDUP} lineas duplicadas (mismo NUMVAG y NUMSUP)" >>${LOG_EJEC}
              echo >>${LOG_EJEC}
           fi
           
           #Recorremos el fichero generado con los 59.20 (ya sin lineas duplicadas) para pasar al mapa el 59.20 con cabecera y pie
           NUMVAG_ANT=""
           
           while read LINEA
           do
              NUMLIN=`expr ${NUMLIN} + 1`
              NUMVAG=`echo "${LINEA}" | cut -c75-82`
              FICHERO_INDIVIDUAL=${DIR_ENTRADA}${MASCARA_AUX}${NUMLIN}.dat
                                         
              if [ "${NUMVAG}" != "${NUMVAG_ANT}" ]
              then
                 PATRON_NUMVAG="^59\.201............10......................................................${NUMVAG}"
                 TOTAL_MENSAJES=`grep "${PATRON_NUMVAG}" ${FICH_ENT}.tmp | wc -l | tr -d " "`
                 echo "NUMVAG=${NUMVAG} - ${TOTAL_MENSAJES} REGISTROS A TRATAR" >>${LOG_EJEC}
                 NUMVAG_ANT=${NUMVAG}
              fi
              
              INDICE=`head -n ${NUMLIN} ${FICH_ENT}.tmp | grep "${PATRON_NUMVAG}" | wc -l | tr -d " "`
              
              #Se cogen las 12 primeras posiciones de REFLIV para obtener fecha de transporte
              REFLIV=`echo "${LINEA}" | cut -c126-137`                               
                
               # Se conecta a PGREDAPR con APPS
              . $EROSKI/fuente/scripts/OUTSORUS.sh $GDEAPPL3 \$0     
                 
              echo "PAQUETE : ${SQL_NAME3}" >>${LOG_EJEC}        
                 
              ERROR_PL=`${ORACLE_HOME}/bin/sqlplus -s -l ${ORAUSER}/${ORAPASS}@${ORAHOST} \
                          @${FUENTE}/sql/${SQL_NAME3}.sql ${REFLIV}`

              RESULTADO4=$?
                 
              COD_ERROR=`echo "${ERROR_PL}" | cut -f2 -d "#"`
              MSG_ERROR=`echo "${ERROR_PL}" | cut -f3 -d "#"`
              FECHA_TRANS=`echo "${ERROR_PL}" | cut -f1 -d "#"`
                 
              echo "ERROR: ${COD_ERROR} - ${MSG_ERROR}" >>${LOG_EJEC}
              echo "FECHA_TRANS: ${FECHA_TRANS}" >>${LOG_EJEC}                 
                 
              if [ ${RESULTADO4} -ne 0 ]
              then
                 FECHA_TRANS=0
                 echo Error ${RESULTADO4} ejecutando el archivo ${FUENTE}/sql/${SQL_NAME3}.sql con REFLIV ${REFLIV} >> ${LOG_EJEC}
                 echo >>${LOG_EJEC}                    
              else
                 echo Proceso {SQL_NAME3}.sql terminado correctamente >>${LOG_EJEC}
                 echo >>${LOG_EJEC}                    
              fi             
                 
              # Se vuelve a conectar a DEINTERF con ITFCOLADM
              . $EROSKI/fuente/scripts/OUTSORUS.sh $GDEAPPL \$0
              
              #Se concatenan cabecera, linea y pie y se llama al mapa
              cat ${FICH_ENT}.cab > ${FICHERO_INDIVIDUAL}
              echo "${LINEA}" >> ${FICHERO_INDIVIDUAL}
              cat ${FICH_ENT}.pie >> ${FICHERO_INDIVIDUAL}             
                 
              echo "MAPA : ${MAPA}" >>${LOG_EJEC}
              ERROR=`mercator $HOME/exec/mercator/mmc/$MAPA -IF1 ${FICHERO_INDIVIDUAL} -IE2 ${MSGID} -IE3 ${PLAT} -IE4 ${FECHAHORA_DESDE} -IE5 ${TOTAL_MENSAJES} -IE6 ${INDICE} -IE7 ${FECHA_TRANS} -IE8 "'${NOM_FICH_ENT}'" -R0`

              RESULTADO5=$?

              echo "TRATANDO REG: $INDICE. RESULTADO: $RESULTADO5" >>${LOG_EJEC}
              echo "ERROR: " $ERROR >>${LOG_EJEC}

              if [ ${RESULTADO5} -eq 9 -o ${RESULTADO5} -eq 30 ]
              then
                 echo Error de conexion ${RESULTADO5} ejecutando mapa de Mercator >> ${LOG_EJEC}
                 echo >>${LOG_EJEC}
                 #Al escribir el patrón WTX-Fichero-pte-conexKO en el log, GADI generará incidiencia a BBDD.
                 /usr/bin/SUTSPILO APR_ITF :${SH_NAME}.sh:Aborted WTX no consigue conexion con MDQ: TMS_CAPRABO TMSCL01DB2.com_inbox
                 echo " WTX-Fichero-pte-conexKO  " >>${LOG_EJEC}
              elif [ ${RESULTADO5} -eq 8 ]
              then
                 echo Error de formato ${RESULTADO5} ejecutando mapa de Mercator >> ${LOG_EJEC}
                 echo >>${LOG_EJEC}
                 #Se genera incidencia a Planificacion
                 /home/eroski/fuente/scripts/SUTSGADI WTX-FormatoErroneo ITF `basename ${FICHERO_INDIVIDUAL}` AHDPLANIFIC NO ${LOG_EJEC} FICHERO ${FICHERO_INDIVIDUAL}
                 mv ${FICHERO_INDIVIDUAL} $DIR_ENTRADA"fich_error/"${MASCARA_AUX}${NUMLIN}.dat
              elif [ ${RESULTADO5} -ne 0 ]
              then
                 echo Error ${RESULTADO5} ejecutando mapa de Mercator >> ${LOG_EJEC}
                 echo >>${LOG_EJEC}                    
              else
                 echo Mapa de Mercator terminado correctamente >>${LOG_EJEC}
                 CONT_OK=`expr ${CONT_OK} + 1`
                 echo "Fichero individual ${FICHERO_INDIVIDUAL} movido a copias" >>${LOG_EJEC}
                 echo "Fichero individual ${FICHERO_INDIVIDUAL} movido a copias"
                 mv ${FICHERO_INDIVIDUAL} $DIR_ENTRADA"copias/"${MASCARA_AUX}${NUMLIN}.dat
                 gzip -f -9 $DIR_ENTRADA"copias/"${MASCARA_AUX}${NUMLIN}.dat
                 echo >>${LOG_EJEC}
              fi              
            
           done < ${FICH_ENT}.tmp
        fi
        echo "NOM_FICH_ENT: "${NOM_FICH_ENT}
        echo "NUMLIN: "${NUMLIN}
        echo "CONT_OK: "${CONT_OK}        
        if [ ${NUMLIN} -gt ${CONT_OK} ]
        then
           ERROR_MAPA=1
           #gzip -f -9 -c $FICH_ENT > $DIR_ENTRADA"fich_error/"$NOM_FICH_ENT".gz"
            # rm -f $FICH_ENT
           echo "Fichero $NOM_FICH_ENT   lo dejamos en directorio para que se reprocese " >>${LOG_EJEC}
           echo "Fichero $NOM_FICH_ENT   lo dejamos en directorio para que se reprocese "
        else
           gzip -f -9 -c $FICH_ENT > $DIR_ENTRADA"copias/"$NOM_FICH_ENT".gz"
           rm -f $FICH_ENT
           echo "Fichero $NOM_FICH_ENT   movido a copias " >>${LOG_EJEC}
           echo "Fichero $NOM_FICH_ENT   movido a copias "
        fi

        rm -f ${FICH_ENT}.tmp
        rm -f ${FICH_ENT}.tmp2
        rm -f ${FICH_ENT}.pie
        rm -f ${FICH_ENT}.cab
    fi
    echo "------------------------------------------------------------------------------"
    echo "------------------------------------------------------------------------------" >> ${LOG_EJEC}
done

#Se encola el estado
if [ $ERROR_MAPA -eq 0 ]
then
  #Se ejecuta el PL que informa el estado de todos los destinos a OK
   FECHA_MERCA=`date +%Y%m%d%H%M%S`
   ${ORACLE_HOME}/bin/sqlplus -s -l ${ORAUSER}/${ORAPASS}@${ORAHOST} \
     @${FUENTE}/sql/${SQL_NAME2}.sql $MSGID $COD_APL_S $COD_INT $ESTADO_OK "" $FECHA_INI $FECHA_MERCA  \
    >> ${LOG_EJEC}

    RESULTADO_ENCOLAR=$?
    if [ ${RESULTADO_ENCOLAR} -ne 0 ]
    then
        echo >>${LOG_EJEC}
        echo Error $RESULTADO_ENCOLAR ejecutando el archivo ${FUENTE}/sql/${SQL_NAME2}.sql con $MSGID $COD_APL_S $COD_INT $ESTADO_OK "" $FECHA_INI $FECHA_MERCA >> ${LOG_EJEC}
        echo >>${LOG_EJEC}
    else
        echo >>${LOG_EJEC}
        echo Proceso ${SQL_NAME2}.sql terminado correctamente >>${LOG_EJEC}
        echo >>${LOG_EJEC}
    fi
elif [ $ERROR_MAPA -eq 1 ]
then
#Se ejecuta el PL que informa el estado de todos los destinos a error
   FECHA_MERCA=`date +%Y%m%d%H%M%S`
   ${ORACLE_HOME}/bin/sqlplus -s -l ${ORAUSER}/${ORAPASS}@${ORAHOST} \
     @${FUENTE}/sql/${SQL_NAME2}.sql $MSGID $COD_APL_S $COD_INT $ESTADO_NO_OK "$MENSAJE_ERROR" $FECHA_INI $FECHA_MERCA  \
    >> ${LOG_EJEC}

    RESULTADO_ENCOLAR=$?
    if [ ${RESULTADO_ENCOLAR} -ne 0 ]
    then
        echo >>${LOG_EJEC}
        echo Error $RESULTADO_ENCOLAR ejecutando el archivo ${FUENTE}/sql/${SQL_NAME2}.sql con $MSGID $COD_APL_S $COD_INT $ESTADO_NO_OK $MENSAJE_ERROR $FECHA_INI $FECHA_MERCA >> ${LOG_EJEC}
        echo >>${LOG_EJEC}
    else
        echo >>${LOG_EJEC}
        echo Proceso ${SQL_NAME2}.sql terminado correctamente >>${LOG_EJEC}
        echo >>${LOG_EJEC}
    fi
    /usr/bin/SUTSPILO APR_ITF :${SH_NAME}.sh:Aborted ERROR ejecutando $FUENTE/sql/${SQL_NAME2}.sql
    cat ${LOG_EJEC}>>${LOG}
    ##LOGFIN LOG=${LOG_EJEC}
    exit 1
fi

# Fin del proceso
echo >>${LOG_EJEC}
echo '##########################################################################'>> ${LOG_EJEC}
echo "`date '+%d/%m/%Y %H:%M:%S'` :- Fin del Proceso ${SH_NAME} "         >> ${LOG_EJEC}
echo '##########################################################################'>> ${LOG_EJEC}
echo >>${LOG_EJEC}

# Por mandato de EyS ponemos exit 0 para que PLATON funcione bien
/usr/bin/SUTSPILO APR_ITF :${SH_NAME}.sh:Completed Fin OK en la ejecución del proceso de extraccion para la interfaz ${COD_INT}
cat ${LOG_EJEC}>>${LOG}
##LOGFIN LOG=${LOG_EJEC}
exit 0