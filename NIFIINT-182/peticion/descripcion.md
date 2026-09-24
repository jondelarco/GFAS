Dentro del PROG-112: Automatismo BR Ciempozuelos y NECESNEG-3860 para la ejecucion de los desarrollos, para el interfaz de AJUSTES DE STOCK que se enviara desde Viadat a Infolog, adjuntamos el mapeo de los campos y la forma en al que se tienen que coger del mensaje que nos llegará por parte de Viadat.

Desde Viadat el usuario puede realizar ajustes de stock bien al estar haciendo picking o bien por alguna acción del operario, y Viadat esta parametrizado para enviar la información correspondiente en una clave de transacción distinta. En función de la clave de transacción que nos llegue informada en ese interfaz, vamos a saber si se trata de un ajuste negativo o positivo, teniendo en cuenta estas claves de transacción:

*Clave 72 o 76 ajuste positivo -->* sumaríamos en la cantidad a enviar a infolog (campo SENMVT enviariamos el signo positivo)
*Clave 70 o 74 ajuste negativo -->* restaríamos en la cantidad a enviar a infolog (campo SENMVT, enviariamos el signo negativo)

El fichero con la información a mapear va en el mismo formato que los demás ficheros para la mensajería de Viadat a Infolog que hemos ido pasando, en el lado izquierdo he puesto los campos definidos en Infolog para este interfaz (mensajes 77.80) aunque este interfaz es mas sencillo y nos quedaremos únicamente con uno de los 2 campos que nos van a enviar en el json.

 

Para cuadrar las posiciones que debería tener el mensaje a enviar en INFOLOG, hemos cuadrado campo a campo con la información que nos llega de VIADAT, por lo que las celdas contienen diferentes colores y nombres, lo hemos hecho con la siguiente lógica para que te ayude a la hora de preparar el mensaje:
 * *Verde:* por ejemplo partty, que indica que se trata de una campo/prioridad que vendrá en el JSON de Viadat, y que se corresponde con el campo de Infolog que se ha puesto en la tabla izquierda. Ejemplo:
 ** partty, de tipo string, y que se corresponde con el campo CODACT de Infolog, que comienza en la posición 39 del mensaje 77.80 y que tendría una longitud de 3

 
 * *Amarillo:* Son valores fijos, es decir, información que no vendrá en el JSON que llega de Viadat pero que tenemos que completar en el mensaje a generar para INFOLOG. Ejemplo:
 ** *Celdas I3: I5* en las que metemos un valor fijo en el que vamos a informar de la cabecera del mensaje a insertar en Infolog

 
 * {*}Blanco{*}: Aquí hay celdas en las que hemos escrito BLANCOS o CEROS, ambas con fondo blanco, lo que indica en ese caso es que habrá que indicar ese valor fijo (porque no nos llega en el JSON de Viadat) en el mensaje que enviaremos a Infolog. Ejemplo:
 ** BLANCOS: en la celda I6, que se corresponde con el campo TRTEXC de Infolog, y que empieza en la posición 6 del mensaje, con longitud 1, habrá que indicar ahí tantos blancos como marca la longitud que he marcado (en este caso, 1 blanco)
 ** CEROS: en la celda I12, que se corresponde con el campo VALPRO de Infolog, y que empieza en la posición 59 del mensaje a Infolog, habrá que indicar ahí tantos 0 como marque la longitud que hemos indicado, en este caso al tener longitud 2

 