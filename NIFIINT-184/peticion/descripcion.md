Dentro del PROG-112: Automatismo BR Ciempozuelos y NECESNEG-3860 para la ejecución de los desarrollos, para el interfaz de *CONSULTA DE STOCK* que se enviara desde Viadat a Infolog (como respuesta a una llamada a la API de Viadat), adjuntamos el mapeo de los campos y la forma en al que se tienen que coger del mensaje que nos llegará por parte de Viadat.

Posteriormente, y en la explot que corresponda, se pedirá crear la opción de lpu y platonizar este lanzamiento de la consulta de stock (al igual que el que ya tenemos en la PLAT-NIFI para Son Morro).

En este caso, con la consulta de stock el objetivo es compartir el stock de Viadat en un instante determinado del tiempo, y mediante este interfaz Viadat comunica a Infolog el stock que dispone, para lo cual se generará un mensaje bidireccional.

En primer lugar, se generará un mensaje hacia Viadat, de tipo “{_}Consulta Stock{_}”, cuya respuesta se integrará en Infolog mediante el {*}77.90{*}, acordado con Toyota que se podría hacer así (la idea con la consulta de stock es que nos llegue la foto de stock agrupada por articulo, sin diferenciar por lote o caducidad aunque estén alimentados).

Revisando la documentación de Toyota sobre la llamada que podemos hacer para invocar la generación de la foto, creo que el GET se puede lanzar incluyendo el campo de codalmacen y cliente, similar a Son Morro (aunque esto lo haré en una EXPLOT a posteriori, lo dejo adjunto en el documento para que lo tengamos documentado).

En la pestaña CONS. STOCK del documento viene indicado el mapeo de los campos que hay que hacer para generar el fichero 77.90 a insertar en infolog. En este caso nos van a insertar un json sin cabecera, si no con un array de objetos y a la hora de conformar el mensaje a insertar en Infolog, se necesita añadir header y footer, para que el inicio del mensaje sea con 00.00 y el cierre con 99.00 (añadiendo este primer y último registro en el mensaje):

*00.00*

77.90

77.90

77.90

77.90

*99.00*

 

El fichero con la información a mapear va en el mismo formato que los demás ficheros para la mensajería de Viadat a Infolog que hemos ido pasando, en el lado izquierdo he puesto los campos definidos en Infolog para este interfaz (mensajes 77.90).

 

Para cuadrar las posiciones que debería tener el mensaje a enviar en INFOLOG, hemos cuadrado campo a campo con la información que nos llega de VIADAT, por lo que las celdas contienen diferentes colores y nombres, lo hemos hecho con la siguiente lógica para que te ayude a la hora de preparar el mensaje:
 * *Verde:* por ejemplo partty, que indica que se trata de una campo/prioridad que vendrá en el JSON de Viadat, y que se corresponde con el campo de Infolog que se ha puesto en la tabla izquierda. Ejemplo:
 ** partty, de tipo string, y que se corresponde con el campo CODACT de Infolog, que comienza en la posición 39 del mensaje 77.80 y que tendría una longitud de 3

 
 * *Amarillo:* Son valores fijos, es decir, información que no vendrá en el JSON que llega de Viadat pero que tenemos que completar en el mensaje a generar para INFOLOG. Ejemplo:
 ** *Celdas I3: I5* en las que metemos un valor fijo en el que vamos a informar de la cabecera del mensaje a insertar en Infolog

 
 * {*}Blanco{*}: Aquí hay celdas en las que hemos escrito BLANCOS o CEROS, ambas con fondo blanco, lo que indica en ese caso es que habrá que indicar ese valor fijo (porque no nos llega en el JSON de Viadat) en el mensaje que enviaremos a Infolog. Ejemplo:
 ** BLANCOS: en la celda I6, que se corresponde con el campo TRTEXC de Infolog, y que empieza en la posición 6 del mensaje, con longitud 1, habrá que indicar ahí tantos blancos como marca la longitud que he marcado (en este caso, 1 blanco)
 ** CEROS: en la celda I12, que se corresponde con el campo VALPRO de Infolog, y que empieza en la posición 59 del mensaje a Infolog, habrá que indicar ahí tantos 0 como marque la longitud que hemos indicado, en este caso al tener longitud 2
 * *Celdas I18:I21:* En este rango verás que hemos puesto unos valores con *“?????”,* aquí hay una serie de campos en los que vamos a especificar la ubicación que se defina en Infolog para el Auto. Este valor no está en Viadat pero es información que Infolog necesita en los mensajes de vuelta, y además se repetirá en todos los mensajes de este interfaz (y en otros). En su momento lo que se hizo en Son Morro fue poner valores fijos pero posteriormente se declararon como constantes para poder utilizarlo en diferentes interfaces (no solo este de confirmación de entradas, si no que también puede ir en Ajustes de Stock o Consulta de Stock):

 

!image-2026-08-28-16-55-21-654.png!

 