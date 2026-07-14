Se solicita corregir el problema detectado en la incidencia:
h1. Ticket#20260625101541032

con la mensajería de localizaciones de la plataforma 361

Existe un PK dentro de la BBDD PGREDAPR -> APPS.PK_ITF_163_1061.{*}P_OBTENER_163_1061{*}

Está componiendo la siguiente consulta:

SELECT *
FROM men_loc_sga
WHERE last_update_date >= '30-JUN-26'
AND ( cod_n1 IN (40) )
OR cod_cli IN (2125 , 2122)
ORDER BY cod_cli;

Y no es correcta porque está combinando clausulas AND y OR sin paréntesis.

El resultado de cuando construye la consulta SELECT, el output debería ser:

SELECT *
FROM men_loc_sga
WHERE last_update_date >= '30-JUN-26'
AND {color:#ff0000}*(*{color}( cod_n1 IN (40) )
OR cod_cli IN (2125 , 2122){color:#ff0000}*)*{color}
ORDER BY cod_cli;

Este cambio se debe a que este proceso de GAPR GCASTEJO que envía a la plataforma 361 la mensajería de localizaciones está enviando todos los días las localizaciones 2122 y 2125 sin que hayan tenido ninguna modificación.

*CAMBIOS A REALIZAR*
Se debe añadir este codigo:

-- Se envuelve todo el bloque de destinos entre paréntesis
-- para que el AND con la fecha de envío aplique al conjunto completo
*v_query_destinos := k_parentesis_abrir || v_query_destinos || k_parentesis;*

*Aquí:*

*!image-2026-07-02-12-19-39-026.png!*

 