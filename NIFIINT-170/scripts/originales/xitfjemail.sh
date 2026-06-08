if  test -d /home/eroski ; then
#!/bin/sh
. /home/eroski/fuente/copy/.passwdmail
else
#!/bin/bash
. /home/platon/.passwdmail
fi

#-----------------------------------------------------------------------
# Nombre: xitfjemail.sh
# Fecha:                  Autor:                     Ultimos Cambios
#-----------------------------------------------------------------------
#  10-03-2014      Oscar Salvador Magallanes
#  17-10-2016      Rosa Fonseca (Modificacion para generar valores por defecto)
#                                y que pueda ser compatible con las premisas de PLATON [parametros sin   blancos ni , ]  
#  29-11-2019      Oscar Salvador Magallanes . Modificacion para anexar ficheros pdf [ tamanio] se genera REQUEST como fichero en lugar de texto 
#  19-12-2024      Rosa  Fonseca             . Modificacion para cambiar Bus de Servicios a GERSOA2 , se pasa de uuencode a base64                                             
#  19-02-2025      Rosa  Fonseca             . Control de ENDPOINT con https o http (con versiones obsoletas de curl )                                                         
#  28-11-2025      Rosa  Fonseca             . Se modifica el Cuerpo del mail para que respete las lineas del fichero                                                         
#-----------------------------------------------------------------------
# Descripcion Funcional:
# 						Script para el envio de mails desde Unix para EROSKI. 
# 						Este script utiliza el servicio web de GERSOA2 de mails. 
#							Los adjuntos se codifican en base64 para el envio a través del WS. La codificación se realiza con base64 mediante openssl.
#
#/ Uso:
#/  
#/  Para obtener ayuda       $EROSKI/scripts/xitfjemail.sh --help
#/       $EROSKI/scripts/xitfjemail.sh  
#/
#/                      $1 -> Email del destinatario (destinatario(s) separados por ; )
#/                      $2 -> Asunto del Email  
#/                      $3 -> Cuerpo del Email [ contenido o nombre de fichero  ] 
#/                                   "Path/Fichero"          [Nombre del fichero que contiene el texto -Asegura formato con lineas- ]    
#/                                   "$( cat Path/Fichero )" [Contenido del fichero que contiene el texto  -lo envia todo en 1 linea ]    
#/                                   "Texto que contiene el cuerto del mail "    
#/
#/                      $4 -> [opcional] Ficheros adjuntos separados por ; . Ejemplo path/fichero1;path/fichero2
#/                      $5 -> [opcional] Email del destinatario en copia (destinatario(s) separados por ;)
#/                      $6 -> [opcional] Email del destinatario en copia oculta (destinatario(s) separados por ;)
#/                      $7 -> [opcional] Remitente del mail por defecto noreply@eroski.es 
#/
#/ Ejemplo de lanzamiento
#/          vFILE=`cat $LOG_EJEC | grep pa1828 | grep Com | tr -s " " " " | grep -v '?'  | cut -d" " -f12`
#/          BODY="The file $vFILE has been processed automatically at `date +"%Y-%m-%d : %H:%M:%S"`"
#/          Email='s2469@eroski.es;rosa_maria_fonseca@eroski.es'
#/          Asunto='File received'
#/
#/          $EROSKI/fuente/scripts/xitfjemail.sh "${Email}" "${Asunto}" "$LOG_EJEC" 
#/          o
#/          $EROSKI/fuente/scripts/xitfjemail.sh "${Email}" "${Asunto}" "$(cat $LOG_EJEC)" 
#/          o
#/          $EROSKI/fuente/scripts/xitfjemail.sh "${Email}" "${Asunto}" "${BODY}" 
#
# Codigo de Retorno :
#       0 -> Ejecucion correcta
#       1 -> Ejecucion incorrecta
#
usage() { grep '^#/' "$0" | cut -c4- ; exit 0 ; }
expr "$*" : ".*--help" > /dev/null && usage


# Montamos el MSGID
MSGID=$( date +%Y%m%d%H%M%S )

#Recuperamos los parametros por medio de argumentos

FROM="${7:-no-reply@eroski.es}"  # -f no-reply@eroski.es (remitente)

TO=$( echo ${1}| tr -s ";" "," )                      #  -t destinatario@destinatario.com		
CUSER="platonibermatica:${passwdmail}"             # -c usuario y contraseña para autentificacion con servidor

SUBJECT="${2}"                 # -s asunto
SUBJECT=$( echo $SUBJECT |    iconv -f ISO-8859-1 -t UTF-8 )    # -s asunto
#SUBJECT=$( echo $SUBJECT |  iconv -f UTF-8 -t Windows-1252  |  iconv -f ISO-8859-1 -t UTF-8 ) 


BODY="${3}"                   # -b BODY
BODY=$( echo $BODY |  iconv -f ISO-8859-1 -t UTF-8 )
#BODY=$( echo $BODY | iconv -f UTF-8 -t Windows-1252  |  iconv -f ISO-8859-1 -t UTF-8 )    #  -b BODY


CC=$( echo ${5}| tr -s ";" "," )   # - Destinatario en copia

BCC=$( echo ${6} | tr -s ";" "," ) # - Destinatario en copia oculta

if [ !  -z "$4" ];then
  ATTACHMENTS=$( echo $4 |tr -s ";" " " )
else
  ATTACHMENTS=
fi

#Si el TO es nulo salimos con error
if [ -z "$TO" ];then
	echo "Se debe indicar el destinatario del mail "
	exit 1
fi

#Si el SUBJECT es nulo salimos con error
if [ -z "$SUBJECT" ];then
	echo "Se debe indicar el asunto del mail "
	exit 1
fi

#Si el BODY es nulo salimos con error
if [ -z "$BODY" ];then
	echo "Se debe indicar el cuerpo del mail "
	exit 1
fi


#Obtenemos el usuario y contraseña
	#Si nos lo pasan por parametro usamos ese, sino lo obtenemos de las variables de entorno
	#Si en ambos casos no tenemos usuario entonces salimos con error
if [ -z "$CUSER" ];then
		echo "Se debe indicar el usuario y contraseña de GERSOA2 "
		exit 1
fi

##ENDPOINT='https://gersoa2prepro.eroski.es/services/Email202311Service'

	#Definimos el EDNPOINT
HTTP=https
WSENDPOINT="://gersoa2.eroski.es/services/Email202311Service"
ENDPOINT=${HTTP}${WSENDPOINT}

opcionTLS="-k "  # Test de URL operativa  -k para que obvie TLS


# Test para verificar acceso a $ENDPOINT cn -k (obvia acceso por TLS )
TestUrl=$( curl $opcionTLS  -s -w HTTP_CODE=%{http_code} --connect-timeout "15"  ${ENDPOINT}?wsdl  2>/tmp/curltest$$  | grep 'HTTP_CODE=200' | wc -l ) 

# Test para verificar si version curl admite https
Testcurl=$( cat /tmp/curltest$$ 2>/dev/null | grep "k is unknown" | wc -l )

if [ $Testcurl -eq 1 ];then
   # Si curl no admite -k pasamos a http
   HTTP=http
   ENDPOINT=${HTTP}${WSENDPOINT}
   opcionTLS=
   TestUrl=$( curl $opcionTLS  -s -w HTTP_CODE=%{http_code} --connect-timeout "15"  ${ENDPOINT}?wsdl  2>/tmp/curltest$$  | grep 'HTTP_CODE=200' | wc -l ) 
fi

if [ $TestUrl -eq 1 ];then

	#ENDPOINT admite peticiones #Montamos la REQUEST

        # Verifico si es un fichero para permitir que se respete el formato de lineas
        if test -f "${BODY}" ;then
                   cat "${BODY}"  > /tmp/mail-request-tmpsf_${MSGID}.$$
                   # Formatear para conservar las lineas
                   sed  "s/$/<br>/"  /tmp/mail-request-tmpsf_${MSGID}.$$ > /tmp/mail-request-tmp_${MSGID}.$$
        else
                   echo "$BODY" > /tmp/mail-request-tmp_${MSGID}.$$
        fi
        BODY=$( cat /tmp/mail-request-tmp_${MSGID}.$$ )

		
	REQUEST="<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ema=\"http://www.eroski.es/CAAI/schema/Email\">
		<soapenv:Header/>
		<soapenv:Body>
		<ema:EmailRequest>
		<ema:From>${FROM}</ema:From>
		<ema:To>
			<ema:recipient>"${TO}"</ema:recipient>
		</ema:To>
		<ema:Cc>
			<ema:recipient>"${CC}"</ema:recipient>
		</ema:Cc>
		<ema:Bcc>
			<ema:recipient>"${BCC}"</ema:recipient>
		</ema:Bcc>
		<ema:Subject><![CDATA["${SUBJECT}"]]></ema:Subject>
		<ema:Body><![CDATA["${BODY}"]]></ema:Body>
		"

	 	
	#Montamos los adjuntos (attachments) si tenemos
	if [ !  -z "$ATTACHMENTS" ];then
           for ATTACHMENT in $ATTACHMENTS ;do
			
		REQUEST="${REQUEST} <ema:Attachments>"
			
		#Si el fichero no existe se ignora
		if [ -s ${ATTACHMENT} ];then 

			#obtenemos el tipo MIME del adjunto
			CONTENTTYPE=$( file -i ${ATTACHMENT} | cut -d : -f 2 | tr -d ' ' ) 
			FILENAME=$( basename ${ATTACHMENT} )
			base64=$( cat  ${ATTACHMENT} | openssl base64 )

			#Pegamos el contenido en la request
			REQUEST="${REQUEST} <ema:item>
					<ema:Name>"$FILENAME"</ema:Name>
 					<ema:ContentType>"${CONTENTTYPE}"</ema:ContentType>
		              		<ema:Content>"${base64}"</ema:Content>
		          	 </ema:item>"
			else
		  		echo "El siguiente fichero no existe  o esta vacio y se ignora: " ${ATTACHMENT}
	  	fi
	       		REQUEST="${REQUEST} </ema:Attachments>"	         
              done
	fi         
		
	#Cierro la request
	REQUEST="${REQUEST} </ema:EmailRequest></soapenv:Body></soapenv:Envelope>"

        echo "$REQUEST" > /tmp/mail-request-tmp_${MSGID}.$$
        REQUEST="/tmp/mail-request-tmp_${MSGID}.$$"

	#--------------------------------		
	#--------------------------------		
	#Llamada al WS, timeout de 10 segundos con formato https -k o http segun corresponda ) 
	#--------------------------------		
	ERROR=$( curl $opcionTLS  -s -m 10 -X POST -w %{http_code} -H "Content-Type:text/xml; charset=utf-8" -H "SOAPAction:EmailOperation"  -d @"${REQUEST}" "${ENDPOINT}" -u "${CUSER}" -o /tmp/mailtmp_${MSGID}.$$ )  
	echo RESULTADO=$?
        echo ERROR="$ERROR"
	#--------------------------------		
	#--------------------------------		

        #Retorno de errores. $ERROR contiene el HTTP_CODE de la llamada al WS.
        if [ $ERROR -eq 200 ];then
                        echo "WS Correcto"
                        rm /tmp/mailtmp*_${MSGID}.$$ 2>/dev/null
                        rm -f tmp/curltest$$   2>/dev/null
                        rm ${REQUEST} 2>/dev/null
                        exit 0
        else
                        echo REQUEST:
                        cat ${REQUEST}
                        rm ${REQUEST} 2>/dev/null
                        echo RESPONSE:
                        cat /tmp/mailtmp_${MSGID}.$$
                        rm /tmp/mailtmp*_${MSGID}.$$ 2>/dev/null
                        echo "WS FAIL"
                        echo $RESULTADO
                        echo $ERROR
                        exit 1
        fi
 else
     echo "$ENDPOINT KO "
fi
