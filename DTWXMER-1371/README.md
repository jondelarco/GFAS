# DTWXMER-1371 — Revisar procesos - DWH/FIDELIZA - xitfj_smv_mdm.sh

Estado: Pendiente de Tratar
Asignado a: Jonathan Del Arco Parejo
Solicitante: Zigor Uriarte Martinez
Creada: 2026-09-23

## Qué piden
(ver `peticion/descripcion.md`)

## Bitácora
- 2026-09-23: carpeta creada automáticamente.

La select que se encarga de recoger los datos de la tabla intermedia

SET CONCAT ~
SET PAUSE OFF
SET NEWPAGE NONE
SET HEADING OFF
SET FEEDBACK OFF
SET VERIFY OFF
SET LINESIZE 3000
SET TRIMSPOOL ON
SET TRIMOUT ON
SET LONG 50000
SET LONGC 50000

--SET WRAP ON

WHENEVER SQLERROR EXIT SQL.SQLCODE;
WHENEVER OSERROR EXIT FAILURE;

SET TERMOUT OFF

SPOOL &1

    SELECT RPAD(NVL(TO_CHAR(TARJETA), ' '),9,' ')|| TO_CHAR(FECHA,'YYYYMMDD')
    FROM    ITFCOLADM.T_SMV_MDM
    WHERE TRIM(TIPO_MOVIMIENTO) in ('2005','2006')
    AND TRIM(CONCEPTO) = '502'
    AND upper(RESULT) = 'OK'
    group by tarjeta, fecha
    order by tarjeta desc, fecha desc;

SPOOL OFF;


REM "Fin de fichero."
REM "Activo la salida estandar por si hay algun error para que se retorne a la variable de ERROR del proceso"
REM "que invoca el sql."
SET TERMOUT ON

EXIT;

SET CONCAT ~
SET PAUSE OFF
SET NEWPAGE NONE
SET HEADING OFF
SET FEEDBACK OFF
SET VERIFY OFF
SET LINESIZE 3000
SET TRIMSPOOL ON
SET TRIMOUT ON
SET LONG 50000
SET LONGC 50000

--SET WRAP ON

WHENEVER SQLERROR EXIT SQL.SQLCODE;
WHENEVER OSERROR EXIT FAILURE;

SET TERMOUT OFF

SPOOL &1

    SELECT RPAD(NVL(TO_CHAR(TARJETA), ' '),10,' ')|| TO_CHAR(FECHA,'YYYYMMDD')
    FROM    ITFCOLADM.T_SMV_MDMCPB
    WHERE TRIM(TIPO_MOVIMIENTO) in ('2005','2006')
    AND TRIM(CONCEPTO) = '502'
    AND upper(RESULT) = 'OK'
    group by tarjeta, fecha
    order by tarjeta desc, fecha desc;

SPOOL OFF;


REM "Fin de fichero."
REM "Activo la salida estandar por si hay algun error para que se retorne a la variable de ERROR del proceso"
REM "que invoca el sql."
SET TERMOUT ON

EXIT;

