Dentro del PROG-112: Automatismo BR Ciempozuelos y NECESNEG-3860 para la ejecución de los desarrollos, para el interfaz de ORDENES DE SALIDA que se enviara desde Infolog a Viadat, adjuntamos el mapeo de campos con la correspondencia de los campos a recoger del mensaje 77.50 de Infolog y convertirlo en los mensajes JSON necesarios para enviarlos posteriormente a Viadat.

Esta petición es para empezar a montar este interfaz en el entorno de desarrollo, posteriormente en producción. Añado aquí comentarios que surgieron en su momento al montar los interfaces para Son Morro y que creo que nos pueden ayudar en este caso una vez se revise el fichero Excel con los mapeos.

En el excel aparecerán registros 77.51, 77.52, 77.53 y 77.55, ¿cuál define el principio de cada bloque, el 77.51? ¿el único que puede repetirse en el bloque es el 77.50? --> 

_El 77.50 es el que marca la cabecera de la ola y dentro tendrá tantos bloques 77.51 como cabeceras de pedido/soporte se incluyan en esa ola, sería de la siguiente forma:_

_!image-2026-08-25-15-29-22-017.png!_

_En este caso habrá que crear tantos JSON para enviar a Viadat como cabeceras de soporte vengan (bloques 77.51)._

Otro campo que hemos indicado en el mapeo, pero a tener en cuenta, es el campo prioridad (PTYDES en infolog) que mapearemos sobre el campo orderprio para Viadat. En este caso existe una tabla de prioridades que tenemos que cumplir para la ordenación de los pedidos:

 
|*PRIORIDAD INFOLOG*|*PRIORIDAD VIADAT*|
|1|1|
|2|2|
|3|3|
|4|4|
|5|5|
|6|6|
|7|7|
|8|8|
|9|8|

 

Es decir, los soportes/pedidos que se envíen en este interfaz tienen una prioridad marcada, que cogeremos de la primera posición del campo PTYDES, y es la que mapearemos hacia Viadat.

En este caso hay que tener en cuenta las siguientes peculiaridades (esto se tuvo que hacer en son Morro pero aquí la lógica va a cambiar un poco con respecto a lo ya montado):
 * las prioridades 8 y 9 de Infolog se mapearan contra la misma prioridad de Viadat, la 8
 * no lo tenemos anotado en la tabla, pero para evitar errores, en caso de que la prioridad que llegue de Infolog fuese un 0, actuaríamos como si nos hubiera llegado un 1, siendo el pedido de prioridad más alta para Viadat ( orderprio = 1 )
 * El resto de valores que puedan llegar, se indicarán directamente en el campo de Viadat sin tener que realizar cálculo o conversión.

En el campo _orderty_ que es donde indicamos el tipo de orden de salida, mapearemos de momento el valor fijo “{*}AF{*}” ya que es un campo obligatorio para Viadat pero no tenemos este campo en el interfaz de Infolog, de esta forma, cuando vayamos a generar el json por cada pedido de la ola, en ese campo indicaremos este valor, lo entrecomillo para que se distinga del resto de campos que sí que existen en el interfaz de Infolog y de los que nos traeremos información en el mapeo.