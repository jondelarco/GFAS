Actualmente se está integrando un fichero de datos de piladas desde la base de datos de SIA producción a UNIDIN. Los datos se leen de la tabla de SIA PILADAS_PLANOGRAMADAS y se cargan en PILADAS_PLANOGRAMADAS.

1. Modificar esta extracción y carga (no conozco los procesos en Platón que lo hacen, quizá GTF/PBL: XITFJENTPLDS):

Leer los campos de SIA nuevos:

*SUSTITUIR* varchar2 (1byte)

*TIPO_MODIF* varchar2 (1byte)

*FECHA_HASTA_MODIF* date

*PORCENTAJE_MODIF* number(5,2)

*CANT_MAX_CENTRO* number(7,2)

*FLG_VALIDADO* varchar2(1 byte)

Estos campos se crearán en la petición MISUMI-783 (no está aún en producción)

 

2. Cuando se cargue en PILADAS_PLANOGRAMADAS el fichero de nombre PILADAS_SIA, cambiar para que el campo ORIGEN='S' (actualmente es 'P')

Al hacer este cambio no modificar las otras cargas que se están haciendo en PILADAS_PLANOGRAMADAS, para Planogramación y Vegalsa.

 