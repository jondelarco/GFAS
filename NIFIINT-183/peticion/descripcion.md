Dentro del PROG-112: Automatismo BR Ciempozuelos y NECESNEG-3860 para la ejecucion de los desarrollos, para el interfaz de CONFIRMACION DE ORDENES DE SALIDA que se enviara desde Viadat a Infolog, adjuntamos el mapeo de los campos y la forma en al que se tienen que coger del mensaje que nos llegará por parte de Viadat.

Este interfaz enviará respuesta a los mensajes que se hayan recibido mediante el interfaz de Ordenes de Salida (EXPLOT-8892).

Un caso a tener en cuenta es que, aunque desde Viadat recibiremos un mensaje json con información de varias claves de transacción, en función de ciertos criterios tenemos que ir generando diferentes mensajes que se enviarán a Infolog (77.56 / 77.66 / 77.58 que corresponda en cada caso).

El fichero con la información a mapear va en el mismo formato que el fichero de confirmación de entradas, en el lado izquierdo he puesto los campos definidos en Infolog para el interfaz de confirmación de salidas (mensajes 77.56, 77.58 y 77.66). Aquí nos va a llegar 1 mensaje json del que obtendremos la información y hay que conformar los mensajes con la siguiente lógica:

 
 * Para el *{color:#de350b}77.56{color}* en el que informamos de las líneas preparadas para ese soporte, podemos conformar un mensaje con todas las líneas que nos vengan por artículo, no es necesario hacer Split por cada línea de preparación que nos llegue, pero si que tenemos que indicar el header 00.00 y footer 99.99 (añadiendo este primer y último registro en el mensaje), generando una estructura similar a esta:

{{*00.00*}}

{{77.56}}

{{77.56}}

{{77.56}}

{{77.66}}

{{77.58}}

{{*99.00*}}

Este mensaje siempre se tiene que enviar en primer lugar, antes del 77.66 y 77.58.
 * Para el {color:#de350b}*77.66*{color} se generaría el mensaje con la información indicada en el mapeo, a tener en cuenta que es únicamente 1 mensaje 77.56 por cada json. Sería el mensaje para la impresión de la etiqueta.

 
 * Para el {*}{color:#de350b}77.58{color}{*}, se generaría el mensaje con la información indicada en el mapeo, al igual que en el 77.66, y únicamente generaríamos 1 mensaje de este tipo hacia Infolog con cada json de confirmación que nos llegue por parte de Viadat, sería el mensaje para la validación del soporte preparado.

 

En este interfaz tenemos que contemplar también el envío de los soportes faltantes que llegarán desde VIADAT.

En el JSON que nos llegará a EKAR, debemos tener en cuenta el valor que se indique en el campo de numero de envases (en el fichero Excel está con interrogación ya que tengo pendiente de obtener esa info por parte de Toyota), ya que sera el que nos indique si se ha enviado mercancia/soporte o si va en faltante.

*_Si numenvases <> 0_*

_00.00_
_77.56             lu434606    20240318125129076949050000001A001000100             00000000320241231LOTE1               00000000000                                         444400407694905013                    0000     000000000_                               
_77.66 444400407694905013ITEST410_                                                                                                                                                                                                                                
_77.58                   444400407694905013   M01 00000000000  A999000200_                                                                                                                                                                                      
_99.00_

 

El mapeo se realizará como hasta ahora, indicando N mensajes 77.56 dentro del bloque como líneas vengan en el array del mensaje de Viadat. Se añadirá posteriormente el 77.66 con la orden de impresión de la etiqueta y el 77.58 con la información del cierre de soporte.

 

*SI numemvases = '0'*

_00.00_
_77.56             lu434606    20240318125149076949050000001A001000100             00000000320241231LOTE1               00000000000                                         444400407694905020                    0000     000000000_                               
_99.00_

En este caso, que será cuando se envíe un soporte faltante, únicamente informaremos de N mensajes 77.56 dentro del bloque como líneas vengan en el array del mensaje de Viadat. En este caso no es necesario mapear los mensajes 77.66 ni 77.58.

 

Una aclaración más, que en Son Morro generó dudas y lo dejamos así indicado en el interfaz en su momento, y es sobre el campo de *numsoporte* ({*}ORDERID{*}) y que en el mensaje a enviar a infolog, Este valor lo enviamos en el interfaz de orden de salidas y es el soporte ficticio que envia Infolog. En el interface de confirmación de salidas se tiene que devolver tal cual para que Infolog lo relacione con su soporte. Cada NUMSUP de Infolog puede generar 1 o más soportes en Viadat. Por ejemplo, {_}si un NUMSUP X da lugar a 3 soportes: 01, 02, 03. Si otro NUMSUP Y da lugar a 2: 01, 02{_}.

 

Si por ejemplo en el ORDERID nos llegase el siguiente valor: {*}358054057{*}, a la hora de trocearlo para enviarlo en la vuelta a infolog, sería de la siguiente forma:

!image-2026-08-27-16-56-25-325.png!

 

Lo hemos marcado como un string de 11 posiciones de cara a mapear este valor de vuelta.

 

Para cuadrar las posiciones que debería tener el mensaje a enviar en INFOLOG, hemos cuadrado campo a campo con la información que nos llega de VIADAT, por lo que las celdas contienen diferentes colores y nombres, lo hemos hecho con la siguiente lógica para que te ayude a la hora de preparar el mensaje:
 * *Verde:* por ejemplo orderid o shipcoid, que indica que se trata de una campo/prioridad que vendrá en el JSON de Viadat, y que se corresponde con el campo de Infolog que se ha puesto en la tabla izquierda. Ejemplo:
 ** {*}shipcoid{*}, de tipo String, y que se corresponde con el campo SSCSUP de Infolog, que comienza en la posición 170 del mensaje 77.56 a general y que tendría una longitud de 18

 * *Amarillo:* Son valores fijos, es decir, información que no vendrá en el JSON que llega de Viadat pero que tenemos que completar en el mensaje a generar para INFOLOG. Ejemplo:
 ** *Celdas I3: I5* en las que metemos un valor fijo en el que vamos a informar de la cabecera del mensaje a insertar en Infolog

 
 * {*}Blanco{*}: Aquí hay celdas en las que hemos escrito BLANCOS o CEROS, ambas con fondo blanco, lo que indica en ese caso es que habrá que indicar ese valor fijo (porque no nos llega en el JSON de Viadat) en el mensaje que enviaremos a Infolog. Ejemplo:
 ** BLANCOS: en la celda I6, que se corresponde con el campo TRTEXC de Infolog, y que empieza en la posición 6 del mensaje, con longitud 1, habrá que indicar ahí tantos blancos como marca la longitud que he marcado (en este caso, 1 blanco)
 ** CEROS: en la celda I23, que se corresponde con el campo PDNLIV de Infolog, y que empieza en la posición 118 del mensaje a Infolog, habrá que indicar ahí tantos 0 como marque la longitud que hemos indicado, en este caso al tener longitud 11
 **  
 * {*}Celdas I15:I18{*}, en este rango verás que hemos puesto unos valores con *“?????”,* aquí hay una serie de campos en los que vamos a especificar la ubicación que se defina en Infolog para el Auto. Este valor no está en Viadat pero es información que Infolog necesita en los mensajes de vuelta, y además se repetirá en todos los mensajes de este interfaz (y en otros). En su momento lo que se hizo en Son Morro fue poner valores fijos pero posteriormente se declararon como constantes para poder utilizarlo en diferentes interfaces (no solo este de confirmación de entradas, si no que también puede ir en Ajustes de Stock o Consulta de Stock):

 

!image-2026-08-27-16-57-54-121.png!

 

En cuanto me pasen los valores definitivos de estas zonas que se pueden crear como constantes, os pasaré la tabla de como tienen que alimentarse en la integración, pero al menos para ir avanzando en este interfaz.

 