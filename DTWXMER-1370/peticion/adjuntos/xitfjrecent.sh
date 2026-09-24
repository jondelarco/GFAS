#!/bin/ksh
#-----------------------------------------------------------------------
# Nombre : xitfjrecent.sh
#   Fecha            Autor               Últimos Cambios
#-----------------------------------------------------------------------
# 25/05/2009				Mikelats Garcia			Creacion del interface
#-----------------------------------------------------------------------
# Descripción Funcional:
#       Ejecuta el PL pk_itf_batch.p_inicio
#       Ejecuta el mapa de mercator itf_9999994_1105_154
#       Ejecuta el PL pk_itf_batch.p_act_est_todos_dest si ha habido algún error
#
# El programa se encarga de la recepción de la confirmacio de Notas de entrega
#
# Uso:
#       $FUENTE/scripts/xitfjrecent.sh 
# Codigo de Retorno :
#       0 -> Ejecucion correcta
#       1 -> Ejecucion incorrecta
#
# Cargo las variables de Entorno de la Aplicacion.
# $HOME, $FUENTE, $EXEC, $DATOS, $EROSKI.
. $vPATHSC/../../.entorno

# Referenciamos otras máquinas (Cargo la variable nodo iniciador)
#. $EROSKI/fuente/scripts/exj-name

SH_NAME="xitfjrecent"

# Comprobamos el número de argumentos
if [  $# -ne 3 ]
then
   /usr/bin/SUTSPILO APR_ITF:${SH_NAME}.sh: Aborted: Número o tipo de argurmentos incorrecto  
   exit 1
fi

# Se recoge la plataforma
PLATAFORMA="$1"
# Se recoge el código de almacén
COD_LOC_SGA="$2"
#Se guarda el origen
ORIGEN="$3"

if [ ${ORIGEN} != "S" -a ${ORIGEN} != "I" ]
then	
		/usr/bin/SUTSPILO APR_ITF:${SH_NAME}.sh: Aborted: Origen incorrecto  
   exit 1
fi


LONG=0

while [ $LONG -ne 5 ]
do 
	ALEATORIO=$RANDOM
	LONG=${#ALEATORIO}
done

# Variables locales
SQL_NAME="PK_ITF_1105_1154"
SQL_NAME1="P_INICIO_USER"
SQL_NAME2="P_FIN_HIJOS_NO_OK"
SQL_NAME3="F_INSERTA_EST_PROC_BATCH"
SQL_NAME4="F_ACT_ESTADO_PROC_BATCH"
MAPA_S="itf_9999994_1105_154"
MAPA_I="itf_9999964_1106_154"
MSGID=`date +%Y%m%d%H%M%S`$ALEATORIO
FECHA_INI=`date +%Y%m%d%H%M%S`
FEC_LOG=`date +%Y%m%d`
FEC_LOG_EJEC=`date +%Y%m%d`$ALEATORIO
COD_APL_SISLOG=9999994
COD_APL_INFOLOG=9999964
COD_APL_E=154
COD_INT_SISLOG=1105
COD_INT_INFOLOG=1106
ESTADO_NO_OK=-140
ESTADO_OK=140
ESTADO_NO_DATOS=999
MENSAJE_ERROR="Se ha generado un error durante la ejecución del script."
VAR_ERROR="N"


if [ $ORIGEN = "S" ]
then
		COD_APL_S=$COD_APL_SISLOG
		COD_INT=$COD_INT_SISLOG
		FICH_ENTRADA="receplatf_"$PLATAFORMA"_"$COD_LOC_SGA
		DIR_ENTRADA=$DATOS"/in/apr/entradas/sislog"
else
		COD_APL_S=$COD_APL_INFOLOG
		COD_INT=$COD_INT_INFOLOG
		FICH_ENTRADA="entrinfolog_"$PLATAFORMA"_"$COD_LOC_SGA
		DIR_ENTRADA=$DATOS"/in/apr/entradas/infolog"
fi
#Hay que modificar
COD_PROG=200007



if [ "${vREP_NAME}" = "" ]; then
   SECUENCIA_LPU="PLATON"
else
   SECUENCIA_LPU=LPU:${vREP_NAME}
fi


# Establezco Nombre Fichero LOG del Script.
# Existirá un log por día donde se incluirán los resultados de ejecución
LOG=$DATOS/log/${SH_NAME}_$FEC_LOG.log ; export LOG
# Existirá un log por ejecución
LOG_EJEC=$DATOS/log/${SH_NAME}_$FEC_LOG_EJEC.log.ejec 

# Escribimos la hora de inicio del proceso
echo >> ${LOG_EJEC}
echo "#####################################################################################">>${LOG_EJEC}
echo "`date +%d%m%Y%H:%M:%S` : Inicio del Proceso ${SH_NAME} para el MSGID ${MSGID}" >> ${LOG_EJEC}
echo "-------------------------------------------------------------------------------------">>${LOG_EJEC}
echo " PARÁMETROS DE ENTRADA: " >> ${LOG_EJEC}
echo "-------------------------------------------------------------------------------------">>${LOG_EJEC}
echo " PLATAFORMA=${PLATAFORMA}" >> ${LOG_EJEC}
echo " COD_LOC_SGA=${COD_LOC_SGA}" >> ${LOG_EJEC}
echo " ORIGEN=${ORIGEN}" >> ${LOG_EJEC}
echo "#####################################################################################">>${LOG_EJEC}
echo >> ${LOG_EJEC}

# Inicio: Informar a PLATON
/usr/bin/SUTSPILO APR_ITF:${SH_NAME}.sh:Inicio del proceso de ${SQL_NAME}

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

# Se conecta a PGREDAPR con APPS
. $EROSKI/fuente/scripts/OUTSORUS.sh $GDEAPPL3 \$0

# Se inserta en ESTADO_PROC_BATCH
ESTADO_PROC_BATCH=`${ORACLE_HOME}/bin/sqlplus -s -l ${ORAUSER}/${ORAPASS}@${ORAHOST} \
                      @${FUENTE}/sql/${SQL_NAME3}.sql $COD_PROG`
RESULTADO4=$?
# Se vuelve a conectar a la base de datos de Integración
. $EROSKI/fuente/scripts/OUTSORUS.sh $GDEAPPL \$0
# Comprobamos errores
if [ ${RESULTADO4} -ne 0 ]
then
    MSG_ERROR=`echo $ESTADO_PROC_BATCH | cut -f 3 -d "#"`
    echo >>${LOG_EJEC}
    echo Código ${RESULTADO4}: ***ERROR*** ejecutando ${FUENTE}/sql/${SQL_NAME3}.sql >> ${LOG_EJEC}
    echo ERROR: $MSG_ERROR >> ${LOG_EJEC}
    echo >>${LOG_EJEC}
    #Se ejecuta el PL que informa el estado de todos los destinos a no hay datos 
    FECHA_MERCA=`date +%Y%m%d%H%M%S`
    ${ORACLE_HOME}/bin/sqlplus -s -l ${ORAUSER}/${ORAPASS}@${ORAHOST} \
       @${FUENTE}/sql/${SQL_NAME2}.sql $MSGID $COD_APL_S $COD_INT $ESTADO_NO_OK "Error al insertar registro en estado_proc_batch" $FECHA_INI $FECHA_MERCA  \     
       >> ${LOG_EJEC}

    RESULTADO3=$?
    if [ ${RESULTADO3} -ne 0 ]
    then
        echo >>${LOG_EJEC}
        echo Error $RESULTADO3 ejecutando el archivo ${FUENTE}/sql/${SQL_NAME2}.sql con $MSGID $COD_APL_S $COD_INT $ESTADO_NO_DATOS "$MENSAJE_ERROR" $FECHA_INI $FECHA_MERCA >> ${LOG_EJEC}
        echo >>${LOG_EJEC}
    else
        echo >>${LOG_EJEC}
        echo Proceso ${SQL_NAME2}.sql terminado correctamente >>${LOG_EJEC}
        echo >>${LOG_EJEC}
    fi
    /usr/bin/SUTSPILO APR_ITF :${SH_NAME}.sh:Aborted ERROR ejecutando $FUENTE/sql/${SQL_NAME3}.sql ${COD_PROG} $1
    cat ${LOG_EJEC}>>${LOG}
	##LOGFIN LOG=${LOG_EJEC}
    exit 1
else
    echo >>${LOG_EJEC}
    echo Proceso ***OK*** ${FUENTE}/sql/${SQL_NAME3}.sql terminado correctamente >>${LOG_EJEC}
    echo >>${LOG_EJEC}
fi
# Se recuperan los datos
COD_CAB_MENSAJE=`echo $ESTADO_PROC_BATCH | cut -f 1 -d "#"`
echo COD_CAB_MENSAJE:$COD_CAB_MENSAJE
echo "COD_CAB_MENSAJE=$COD_CAB_MENSAJE" >> ${LOG_EJEC}
echo >> ${LOG_EJEC}


#se coge el fichero mas nuevo
FICH_LS_ENT=`ls -1tr $DIR_ENTRADA"/"$FICH_ENTRADA* 2>/dev/null | tail -1`

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
        echo Error $RESULTADO3 ejecutando el archivo ${FUENTE}/sql/${SQL_NAME2}.sql con $MSGID $COD_APL_S $COD_INT $ESTADO_NO_DATOS "$MENSAJE_ERROR" $FECHA_INI $FECHA_MERCA >> ${LOG_EJEC}
        echo >>${LOG_EJEC}
    else
        echo >>${LOG_EJEC}
        echo Proceso ${SQL_NAME2}.sql terminado correctamente >>${LOG_EJEC}
        echo >>${LOG_EJEC}
    fi
    /usr/bin/SUTSPILO APR_ITF :${SH_NAME}.sh:Completed Fin OK en la ejecución del PL/SQL ${SQL_NAME}.sql 
		
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
FICH_LS_ENT=`ls -1tr $DIR_ENTRADA"/"$FICH_ENTRADA* 2>/dev/null`

#Se inicializa la variable error mapa que será la variable a utilizar para encolar el estado
#Si la variable es 1 se encola un -140 si es 0 un 140.
ERROR_MAPA=0

#Se ejecuta el mapa para cada fichero, y se comprueban los errores devueltos
for FICH_ENT in $FICH_LS_ENT
do

		echo "------------------------------------------------------------------------------"
		echo "------------------------------------------------------------------------------" >> ${LOG_EJEC}
		
		# Si el fichero está vacío no se trata
   	if [ ! -s $FICH_ENT ]
   	then
		gzip -f -9 -c $FICH_ENT > $DIR_ENTRADA"/copias/"`basename $FICH_ENT`".gz"
		rm $FICH_ENT 
		echo "Fichero $FICH_ENT vacio, se mueve a copias " >>${LOG_EJEC}
		echo "Fichero $FICH_ENT vacio, se mueve a copias "
		
	else

		ls -ltr $FICH_ENT >>${LOG_EJEC}
		ls -ltr $FICH_ENT
		
		sleep 20   	

		echo "FICHERO_ENTRADA:"$FICH_ENT >>${LOG_EJEC}
		NOM_FICH_ENT=`basename $FICH_ENT`
		#Dependiendo del origen del fichero se ejecuta un mapa o otro.
		if [ $ORIGEN = "S" ]
		then

			#cat $FICH_ENT | sed -n '/CB/p' | awk '{ if ( substr ($0, 17, 4) == "    ") print $0 }'  > $DIR_ENTRADA"/"`basename $FICH_ENT`"_CAB_SIN_COD.tmp"
			cat $FICH_ENT | grep -E "^.{8}CB.*" | awk '{ if ( substr ($0, 17, 4) == "    ") print $0 }'  > $DIR_ENTRADA"/"`basename $FICH_ENT`"_CAB_SIN_COD.tmp"
			if [ -s  $DIR_ENTRADA"/"`basename $FICH_ENT`"_CAB_SIN_COD.tmp" ]
			then
					
				#Envio mail de aviso de fichero incompleto
				destinatarios="STEF_IBERIA_INFORMATICA@stef.com"
				CUERPO="Hola\nEl fichero $NOM_FICH_ENT contiene lineas incompletas, por lo que no puede ser procesado.\nRogamos vuelvan a enviarlo.\nGracias"
				ASUNTO="Fichero $NOM_FICH_ENT tiene lineas incompletas"
				echo -e "${CUERPO}" | mail -s "${ASUNTO}" -c "pses-integracion@eroski.es" "$destinatarios"
				#echo -e "${CUERPO}" | mail -s "${ASUNTO}" -c "sopplan@eroski.es" "sopplan@eroski.es"

				if [ $? -eq 0 ];then
						echo "mail enviado correctamente" >>${LOG_EJEC}
				else
						echo "No se ha podido enviar el mail de aviso" >>${LOG_EJEC}
				fi


				#Se mueve el fichero de entrada a fich_error.
				gzip -f -9 -c $FICH_ENT > $DIR_ENTRADA"/fich_error/"`basename $FICH_ENT`".gz"	
				rm -f $FICH_ENT 
				echo "El fichero $NOM_FICH_ENT contiene lineas incompletas" >>${LOG_EJEC}
				echo "Fichero $FICH_ENT movido a fich_error " >>${LOG_EJEC}
		
		
			else
				ERROR=`mercator $HOME/exec/mercator/mmc/$MAPA_S -IF1 ${FICH_ENT} -IE2 $COD_LOC_SGA -IE3 $NOM_FICH_ENT -IE4 $MSGID -OE6 -R0 `	
				RESULTADO_MAPA=$?				
		
			fi
		else
			
            #Eliminamos el 00.00 y el 99.00 Del medio del fichero por si vienen ficheros concatenados	  
            CABECERA=`head -n 1 ${FICH_ENT}`
            COLA=`tail -n 1 ${FICH_ENT}`
            grep -v "^99\.00" ${FICH_ENT} | grep -v "^00\.00" > ${FICH_ENT}.tmp
            echo "${CABECERA}" > ${FICH_ENT}.cab
            echo "${COLA}" > ${FICH_ENT}.pie
            cat ${FICH_ENT}.cab ${FICH_ENT}.tmp ${FICH_ENT}.pie > ${FICH_ENT}
            
            rm -f ${FICH_ENT}.tmp
            rm -f ${FICH_ENT}.pie
            rm -f ${FICH_ENT}.cab 
				
			ERROR=`mercator $HOME/exec/mercator/mmc/$MAPA_I -IF1 ${FICH_ENT} -IE2 $PLATAFORMA -IE3 $COD_LOC_SGA -IE4 $NOM_FICH_ENT -IE5 $MSGID -OF1 $DIR_ENTRADA"/fich_error/"$NOM_FICH_ENT".bad" -OE6 -R0 -TIOS -AEDU `
			RESULTADO_MAPA=$?
		fi
				
				
		COD_ERROR=`echo $ERROR | cut -f 1 -d "|"`
		COD_MSG_ERROR=`echo $ERROR | cut -f 2 -d "|"`
		
		

		 echo COD_ERROR=$COD_ERROR
		 echo COD_MSG_ERROR=$COD_MSG_ERROR
		 echo RESULTADO_MAPA=$RESULTADO_MAPA
		 echo FICHERO_ENTRADA:$FICH_ENT >>${LOG_EJEC}
		 echo RESULTADO_MAPA=$RESULTADO_MAPA >>${LOG_EJEC}
		 echo COD_ERROR=$COD_ERROR >>${LOG_EJEC}
		 echo COD_MSG_ERROR=$COD_MSG_ERROR >>${LOG_EJEC}
		 echo >> ${LOG_EJEC}
					
		echo ERROR:$ERROR 
		
		if [ $RESULTADO_MAPA -eq 0 ]
		then
			if [ $COD_ERROR -eq 0 -o $COD_ERROR -eq 88 ]
			then
					gzip -f -9 -c $FICH_ENT > $DIR_ENTRADA"/copias/"`basename $FICH_ENT`".gz"
					rm -f $FICH_ENT 
					echo "Fichero $FICH_ENT movido a copias " >>${LOG_EJEC}
					echo "Fichero $FICH_ENT movido a copias "
			elif [ -s  $DIR_ENTRADA"/"`basename $FICH_ENT`"_CAB_SIN_COD.tmp" ]
			then
				rm -f $DIR_ENTRADA"/"`basename $FICH_ENT`"_CAB_SIN_COD.tmp"
			else	
					/usr/bin/SUTSPILO APR_ITF :${SH_NAME}.sh:Aborted WTX no consigue conexion con BBDD SIA
					echo " WTX-Fichero-pte-conexKO  $FICH_ENT_CORTO  " >>${LOG_EJEC}
					echo "Fichero $NOM_FICH_ENT lo dejamos en directorio entrada" >> ${LOG_EJEC}
					echo "Fichero $NOM_FICH_ENT lo dejamos en directorio entrada"
					ERROR_MAPA=1
			fi
		elif [ $RESULTADO_MAPA -eq 8 -o $RESULTADO_MAPA -eq 9 -o $RESULTADO_MAPA -eq 21 -o $RESULTADO_MAPA -eq 28 -o $RESULTADO_MAPA -eq 235 ] 	
		then
				gzip -f -9 -c $FICH_ENT > $DIR_ENTRADA"/fich_error/"`basename $FICH_ENT`".gz"	
				rm -f $FICH_ENT 
				/usr/bin/SUTSPILO APR_ITF :${SH_NAME}.sh:Aviso  fichero formato erroneo $NOM_FICH_ENT 
				echo "WTX-Fichero-formatoErroneo  $NOM_FICH_ENT " >> ${LOG_EJEC}
				/home/eroski/fuente/scripts/SUTSGADI WTX-FormatoErroneo ITF $NOM_FICH_ENT  AHDPLANIFIC NO ${LOG_EJEC} FICHERO $FICH_ENT
				echo "Fichero $NOM_FICH_ENT movido a fich_error " >>${LOG_EJEC}
				echo "Fichero $NOM_FICH_ENT movido a fich_error "				

		else      
				/usr/bin/SUTSPILO APR_ITF :${SH_NAME}.sh:Aborted WTX no consigue conexion con BBDD SIA
				echo " WTX-Fichero-pte-conexKO  $NOM_FICH_ENT " >>${LOG_EJEC}
				echo "Fichero $NOM_FICH_ENT lo dejamos en directorio entrada" >> ${LOG_EJEC}
				echo "Fichero $NOM_FICH_ENT lo dejamos en directorio entrada"
				ERROR_MAPA=1
		 fi	
		#Si el fichero de errores generado esta vacio se borra
		if [ ! -s $DIR_ENTRADA"/fich_error/"$NOM_FICH_ENT".bad" ]
		then
				rm $DIR_ENTRADA"/fich_error/"$NOM_FICH_ENT".bad" 2> /dev/null
		fi
		
		if [ -f  $DIR_ENTRADA"/"`basename $FICH_ENT`"_CAB_SIN_COD.tmp" ]
		then
				rm -f $DIR_ENTRADA"/"`basename $FICH_ENT`"_CAB_SIN_COD.tmp"
		fi
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
     @${FUENTE}/sql/${SQL_NAME2}.sql $MSGID $COD_APL_S $COD_INT $ESTADO_NO_OK "" $FECHA_INI $FECHA_MERCA  \     
    >> ${LOG_EJEC}

    RESULTADO_ENCOLAR=$?
    if [ ${RESULTADO_ENCOLAR} -ne 0 ]
    then
        echo >>${LOG_EJEC}
        echo Error $RESULTADO_ENCOLAR ejecutando el archivo ${FUENTE}/sql/${SQL_NAME2}.sql con $MSGID $COD_APL_S $COD_INT $ESTADO_NO_OK "" $FECHA_INI $FECHA_MERCA >> ${LOG_EJEC}
        echo >>${LOG_EJEC}
    else
        echo >>${LOG_EJEC}
        echo Proceso ${SQL_NAME2}.sql terminado correctamente >>${LOG_EJEC}
        echo >>${LOG_EJEC}
    fi
		/usr/bin/SUTSPILO APR_ITF :${SH_NAME}.sh:Aborted ERROR ejecutando $FUENTE/sql/${SQL_NAME3}.sql ${COD_PROG} $1
		cat ${LOG_EJEC}>>${LOG}
		##LOGFIN LOG=${LOG_EJEC}
		exit 1
elif [ $ERROR_MAPA -eq 2 ]
then 
		#Se ejecuta el PL que informa el estado de todos los destinos a OK 
   FECHA_MERCA=`date +%Y%m%d%H%M%S`
   ${ORACLE_HOME}/bin/sqlplus -s -l ${ORAUSER}/${ORAPASS}@${ORAHOST} \
     @${FUENTE}/sql/${SQL_NAME2}.sql $MSGID $COD_APL_S $COD_INT $ESTADO_NO_OK "Formato de fichero incorrecto (Error 28). Se integran los albaranes correctos." $FECHA_INI $FECHA_MERCA  \     
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
fi

# Fin del proceso
echo >>${LOG_EJEC}
echo '##########################################################################'>> ${LOG_EJEC}
echo "`date '+%d/%m/%Y %H:%M:%S'` :- Fin del Proceso ${SH_NAME} "         >> ${LOG_EJEC}
echo '##########################################################################'>> ${LOG_EJEC}
echo >>${LOG_EJEC}

# Por mandato de EyS ponemos exit 0 para que PLATON funcione bien 
/usr/bin/SUTSPILO APR_ITF :${SH_NAME}.sh:Completed Fin OK en la ejecución del PL/SQL ${SQL_NAME}.sql 
cat ${LOG_EJEC}>>${LOG}
##LOGFIN LOG=${LOG_EJEC}

exit 0

