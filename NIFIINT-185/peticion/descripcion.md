Dentro del PROG-112: Automatismo BR Ciempozuelos y NECESNEG-3860 para la ejecucion de los desarrollos, para el interfaz de BLOQUEO DE OLA que se enviara desde Viadat a Infolog, adjuntamos el mapeo de los campos y la forma en al que se tienen que coger del mensaje que nos llegará por parte de Viadat.

En este caso, una vez enviamos una ORDEN DE SALIDA desde Infolog a Viadat y comience a prepararse en el auto, debería venir este mensaje de vuelta e integrarse en Infolog para bloquear esa ola y evitar modificaciones.

El fichero con la información a mapear va en el mismo formato que los demás ficheros para la mensajería de Viadat a Infolog que hemos ido pasando, en el lado izquierdo he puesto los campos definidos en Infolog para este interfaz (mensajes 77.50) aunque este interfaz es mas sencillo y nos quedaremos únicamente con uno de los 2 campos que nos van a enviar en el json.

 

Para cuadrar las posiciones que debería tener el mensaje a enviar en INFOLOG, hemos cuadrado campo a campo con la información que nos llega de VIADAT, por lo que las celdas contienen diferentes colores y nombres, lo hemos hecho con la siguiente lógica para que te ayude a la hora de preparar el mensaje:
 * *Verde:* por ejemplo hostwaverid, que indica que se trata de una campo/prioridad que vendrá en el JSON de Viadat, y que se corresponde con el campo de Infolog que se ha puesto en la tabla izquierda. Ejemplo:
 ** hostwaverid, de tipo number, y que se corresponde con el campo NUMVAG de Infolog, que comienza en la posición 7 del mensaje 77.50 y que tendría una longitud de 8

 
 * *Amarillo:* Son valores fijos, es decir, información que no vendrá en el JSON que llega de Viadat pero que tenemos que completar en el mensaje a generar para INFOLOG. Ejemplo:
 ** *Celdas I3: I5* en las que metemos un valor fijo en el que vamos a informar de la cabecera del mensaje a insertar en Infolog

 
 * {*}Blanco{*}: Aquí hay celdas en las que hemos escrito BLANCOS o CEROS, ambas con fondo blanco, lo que indica en ese caso es que habrá que indicar ese valor fijo (porque no nos llega en el JSON de Viadat) en el mensaje que enviaremos a Infolog. Ejemplo:
 ** BLANCOS: en la celda I6, que se corresponde con el campo TRTEXC de Infolog, y que empieza en la posición 6 del mensaje, con longitud 1, habrá que indicar ahí tantos blancos como marca la longitud que he marcado (en este caso, 1 blanco)
 ** CEROS: en la celda I9, que se corresponde con el campo PRPWCS de Infolog, y que empieza en la posición 17 del mensaje a Infolog, habrá que indicar ahí tantos 0 como marque la longitud que hemos indicado, en este caso al tener longitud 1

 