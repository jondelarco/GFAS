# EXPLOT-8708 — UM Alimentar el campo es_pool de t_trns_pedidos_tpte

Estado: Pendiente de Tratar
Asignado a: Jonathan Del Arco Parejo
Solicitante: Juan Carlos Diaz Gascueña
Creada: 2026-06-12

## Qué piden
(ver `peticion/descripcion.md`)

## Bitácora
- 2026-06-12: carpeta creada automáticamente.

Analisis de donde se utiliza t_trns_pedidos_tpte 
- NiFi Flow » ITF_DES » ULTIMA_MILLA-TOOKANE »  WEBHOOK_OrderIsCancelled_TOOKANE
- NiFi Flow » ITF_DES » ULTIMA_MILLA-TOOKANE »  WEBHOOK_OrderIsDone_TOOKANE
- NiFi Flow » ITF_DES » ULTIMA_MILLA-BRINGG »  BRINGG_WEBHOOK_TRANSPORT_GENERICO

Cambiar proceso
- NiFi Flow » ITF_DES » ULTIMA_MILLA-BRINGG »  PedidosOnLine_Transporte (INSERT)
- NiFi Flow » ITF_DES » ULTIMA_MILLA-TOOKANE »  WEBHOOKS_SaD_Trans_TOOKANE (INSERT)
- Introducir subconsulta a los INSERT
