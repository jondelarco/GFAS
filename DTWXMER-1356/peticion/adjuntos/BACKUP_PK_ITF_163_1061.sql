DECLARE
      p_cod_plataforma  itf_gestion_men_clientes.cod_plataforma%TYPE := 361;
      p_cod_cab_mensaje          cab_mensaje.cod_cab_mensaje%TYPE := 99;
      p_restauracion             itf_gestion_men_clientes.flg_restauracion%TYPE := 'N';
      p_msgid                    errores_integracion.MSGID%TYPE := '20260630';
      p_men_loc_sga              APPS.v_t_t_men_loc_sga;
      p_cod_error                pk_arq_errores.t_cod_error;
      p_msg_error                pk_arq_errores.t_msg_error;
      
      TYPE cur_typ IS REF CURSOR;

      c_datos                cur_typ;
      v_datos                men_loc_sga%ROWTYPE;
      v_men_loc_sga          v_t_r_men_loc_sga;
      i                      NUMBER;
      e_no_datos             EXCEPTION;
      e_parametros_nulos     EXCEPTION;
      e_llamada              EXCEPTION;
      v_destinos             APPS.PK_ITF_163_1061.T_DESTINOS;
      v_query                VARCHAR2 (10000);
      v_query_destinos       VARCHAR2 (10000);
      v_query_destinos_n1    VARCHAR2 (1000);
      v_query_destinos_n2    VARCHAR2 (1000);
      v_query_destinos_n3    VARCHAR2 (1000);
      v_query_destinos_loc   VARCHAR2 (1000);
      aux_e                  NUMBER;
         k_si           CONSTANT VARCHAR2 (1) := 'S';
	   k_no           CONSTANT VARCHAR2 (1) := 'N';
	   k_parentesis   CONSTANT VARCHAR2 (1) := ')';
	   k_parentesis_abrir   CONSTANT VARCHAR2 (1) := '(';
	   k_and          CONSTANT VARCHAR2 (5) := ' AND ';
	   k_or           CONSTANT VARCHAR2 (5) := ' OR ';
	   k_where        CONSTANT VARCHAR2 (7) := ' WHERE ';
	   k_cero         CONSTANT NUMBER (1)   := 0;
	   k_id_iklog     CONSTANT NUMBER (1)   := 6;
	   k_pkg_name     CONSTANT VARCHAR2 (20) := 'PK_ITF_163_1061';

      TYPE t_query_destinos_lin IS TABLE OF VARCHAR2 (10000);

      v_query_destinos_lin   t_query_destinos_lin;
      v_query_fecha_envio    VARCHAR2 (1000);
      v_query_order          VARCHAR2 (1000);
      v_error                pk_arq_errores.t_r_error;
      v_fecha_envio          DATE;
      v_destino_exc          BOOLEAN                             := FALSE;
      v_hay_n                BOOLEAN                             := FALSE;
      contador_loc           BOOLEAN                             := FALSE;
      v_hay_cod_nivel        BOOLEAN                             := FALSE;
      v_t_rel_plat_sga       pk_apr_tipos_datos.t_t_rel_plat_sga;
      v_es_iklog             BOOLEAN;
      v_cif_eroski           sociedades.cif_ue2%TYPE;
      contador               NUMBER                              := 0;
      v_msg_error             errores_integracion.desc_error%TYPE;
      v_e_error            VARCHAR2 (200);
      --v_error                   pk_arq_errores.t_r_error;
      v_entra               BOOLEAN                              :=FALSE;
	  --GFAS EXPLOT-579
	  v_franquiciado		VARCHAR2(1);

   BEGIN
      --Se controla si son nulos los parametros de entrada.
      IF p_cod_plataforma IS NULL OR p_cod_cab_mensaje IS NULL
      THEN
         DBMS_OUTPUT.put_line ('Parametro de entrada nulo. ');
         RAISE e_parametros_nulos;
      END IF;

      --se inicializan las variables de salida
      v_men_loc_sga :=
         v_t_r_men_loc_sga (NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
							NULL,
							NULL,
							NULL,
							NULL
                           );
      p_men_loc_sga := v_t_t_men_loc_sga (v_men_loc_sga);
      --se extiende el tama¿o de la variable de salida.
      p_men_loc_sga.EXTEND (1);
      --se inicializa el contador a 0.
      i := 0;
      --se inicializan las variables de error
      p_cod_error := pk_apr_constantes.k_no_error;                         --0
      p_msg_error := 'Correcto';
      v_query_destinos_lin := t_query_destinos_lin (NULL);
      --Se comprueba si se trata de una plataforma iklog.
      pk_apr_general.p_apr_leer_datos_sga (p_cod_plataforma,
                                           NULL,
                                           v_t_rel_plat_sga,
                                           v_error
                                          );

      IF v_error.v_cod_error <> pk_apr_constantes.k_no_error
      THEN
         v_e_error:='Error llamada a p_apr_leer_datos_sga. Cod_plataforma:'||p_cod_plataforma ||' '|| SQLERRM;
         RAISE e_llamada;
      END IF;

      IF v_t_rel_plat_sga (1).id_sga = k_id_iklog
      THEN
         v_es_iklog := TRUE;
      ELSE
         v_es_iklog := FALSE;
      END IF;

      --Se comprueba si se trata de una plataforma con clientes concretos
      APPS.PK_ITF_163_1061.p_obtener_men_loc_sga_destinos (p_cod_plataforma, v_destinos, v_error);

      IF v_error.v_cod_error = pk_apr_constantes.k_no_error
      THEN
         v_destino_exc := TRUE;

         --Si hay datos parametrizados para la plataforma se genera la parte de la
         -- query parametrizada
         FOR i IN v_destinos.FIRST .. v_destinos.LAST
         LOOP
            v_hay_n := FALSE;
            v_query_destinos_n1 := NULL;
            v_query_destinos_n2 := NULL;
            v_query_destinos_n3 := NULL;

            IF v_destinos (i).cod_n1 IS NOT NULL
            THEN
               v_query_destinos_n1 :=
                      ' cod_n1 in (' || v_destinos (i).cod_n1 || k_parentesis;
               v_hay_n := TRUE;
            END IF;

            IF v_destinos (i).cod_n2 IS NOT NULL
            THEN
               v_query_destinos_n2 :=
                      ' cod_n2 in (' || v_destinos (i).cod_n2 || k_parentesis;

               IF v_hay_n
               THEN
                  v_query_destinos_n2 := k_and || v_query_destinos_n2;
               END IF;

               v_hay_n := TRUE;
            END IF;

            /*IF v_destinos (i).cod_n3 IS NOT NULL
            THEN
               v_query_destinos_n3 :=
                      ' cod_n3 in (' || v_destinos (i).cod_n3 || k_parentesis;

               IF v_hay_n
               THEN
                  v_query_destinos_n3 := k_and || v_query_destinos_n3;
               END IF;

               v_hay_n := TRUE;
            END IF;*/
            IF v_hay_n
            THEN
               contador := contador + 1;
               v_hay_cod_nivel := TRUE;

               IF contador > 1
               THEN
                  v_query_destinos_lin.EXTEND (1);
               END IF;

               v_query_destinos_lin (contador) :=
                     NVL (v_query_destinos_n1, ' ')
                  || NVL (v_query_destinos_n2, ' ');
--                  || NVL (v_query_destinos_n3, ' ');
            END IF;

            IF v_destinos (i).cod_loc IS NOT NULL
            THEN
               IF NOT contador_loc
               THEN
                  v_query_destinos_loc :=
                                    ' cod_cli in (' || v_destinos (i).cod_loc;
               ELSE
                  v_query_destinos_loc :=
                       v_query_destinos_loc || ' ,' || v_destinos (i).cod_loc;
               END IF;

               contador_loc := TRUE;
            END IF;
         END LOOP;

         FOR j IN v_query_destinos_lin.FIRST .. v_query_destinos_lin.LAST
         LOOP
            IF j > 1
            THEN
               v_query_destinos :=
                     v_query_destinos
                  || k_or
                  || k_parentesis_abrir
                  || v_query_destinos_lin (j)
                  || k_parentesis;
            ELSE
               v_query_destinos :=
                     v_query_destinos
                  || k_parentesis_abrir
                  || v_query_destinos_lin (j)
                  || k_parentesis;
            END IF;
         END LOOP;

         IF contador_loc
         THEN
            IF v_hay_cod_nivel
            THEN
               v_query_destinos :=
                     v_query_destinos
                  || k_or
                  || v_query_destinos_loc
                  || k_parentesis;
            ELSE
               v_query_destinos :=
                     v_query_destinos || v_query_destinos_loc || k_parentesis;
            END IF;
         END IF;
     
      ELSIF v_error.v_cod_error =
                                pk_apr_constantes.k_error_datos_no_encontrados
      THEN
         DBMS_OUTPUT.put_line ('No hay destinos exclusivos');
      ELSE
         --Si hay error
         v_e_error:='Error p_obtener_men_loc_sga_destinos: Plataforma:'||p_cod_plataforma ||' '|| SQLERRM;
         RAISE e_llamada;
      END IF;

      --Se genera la consulta de extraccion.
      v_query := 'SELECT * FROM men_loc_sga';
      v_query_order := ' ORDER BY cod_cli';

      --Si se trata de una restauracion no se mira la fecha de envio.
      IF p_restauracion = k_si
      THEN
         --Si tiene destinos exclusivos
         IF v_destino_exc
         THEN
            v_query := v_query || k_where || v_query_destinos;
         END IF;
      ELSE
         --Se otbtiene la ultima fecha de envio para solo enviar las modificaciones
         --mas recientes que la ultima fecha.
         SELECT MAX (fecha_envio)
           INTO v_fecha_envio
           FROM itf_gestion_men_clientes
          WHERE cod_plataforma = p_cod_plataforma
            AND flg_restauracion IN (k_si, k_no);

         --Si la fecha de envio es null,no se ha enviado nunca la informacion a la plataforma
         -- por no se filtra por fecha.
         IF v_fecha_envio IS NOT NULL
         THEN
            v_query_fecha_envio :=
                          ' last_update_date >= ''' || v_fecha_envio || ''' ';
            v_query := v_query || k_where || v_query_fecha_envio;

            IF v_destino_exc
            THEN
               v_query := v_query || k_and || v_query_destinos;
            END IF;
         ELSE
            IF v_destino_exc
            THEN
               v_query := v_query || k_where || v_query_destinos;
            END IF;
         END IF;
      END IF;

      v_query := v_query || v_query_order;

      DBMS_OUTPUT.put_line (SUBSTR (v_query, 1, 254));
      DBMS_OUTPUT.put_line (SUBSTR (v_query, 255, 254));

      --Se obtiene el cif de eroski
      /*SELECT cif_ue2
        INTO v_cif_eroski
        FROM sociedades
       WHERE cod_soc = 1;

      OPEN c_datos FOR v_query;

      LOOP
         FETCH c_datos
          INTO v_datos;

         EXIT WHEN c_datos%NOTFOUND;

         v_entra:=TRUE;

         i := i + 1;

             IF i > 1
             THEN
                p_men_loc_sga.EXTEND (1);
             END IF;

         --Debido a que ni sislog, ni iklog no procesa carcateres especiales, se hace
         --una diferenciacion entre IKLOG y el resto.

         BEGIN
         aux_e:= 0;


         IF v_es_iklog
         THEN
            --se guardan los datos de salida.

            v_men_loc_sga :=
               v_t_r_men_loc_sga (i,
                                  v_datos.cod_men_loc_sga,
                                  p_cod_plataforma,  --v_datos.cod_plataforma,
                                  v_datos.cod_cli,
                                  v_datos.cod_n1,
                                  v_datos.cod_n2,
                                  v_datos.cod_ruta,
                                  SUBSTR(v_datos.nombre,0,30),--v_datos.nombre,
                                  SUBSTR(v_datos.direccion,0,30),-- v_datos.direccion,
                                  SUBSTR(v_datos.poblacion,0,30),-- v_datos.poblacion,
                                  v_datos.razon_social,
                                  v_datos.telefono,
                                  SUBSTR(LPAD(v_datos.cod_postal,10,'0'),-6), -- rellenamos a 10 y usamos solo los 6 ultimos - 11/11/2019
                                  v_datos.cod_ensena,
                                  v_datos.letra_cif,
                                  LPAD(v_datos.cif,8),
                                  v_t_rel_plat_sga (1).id_sga,
                                  v_cif_eroski,
								  NULL,
								  NULL,
								  NULL,
								  NULL
                                 );
         ELSE


			--GFAS EXPLOT-579
			select decode(cod_tp_loc,3,'S','N')
                 into v_franquiciado
                 from localizaciones
                 where cod_loc= v_datos.cod_cli;

                      --Si el destino no es de iklog, se quitan los caracteres especiales.
            v_men_loc_sga :=
               v_t_r_men_loc_sga
                  (i,
                   v_datos.cod_men_loc_sga,
                   p_cod_plataforma,                 --v_datos.cod_plataforma,
                   v_datos.cod_cli,
                   v_datos.cod_n1,
                   v_datos.cod_n2,
                   v_datos.cod_ruta,
                   pk_itf_conversiones.f_convert_to_us7ascii (SUBSTR(v_datos.nombre,0,30)),
                   pk_itf_conversiones.f_convert_to_us7ascii (SUBSTR(v_datos.direccion,0,30)),
                   pk_itf_conversiones.f_convert_to_us7ascii (SUBSTR(v_datos.poblacion,0,30)),
                   pk_itf_conversiones.f_convert_to_us7ascii (v_datos.razon_social),
                   pk_itf_conversiones.f_convert_to_us7ascii (v_datos.telefono),
                   pk_itf_conversiones.f_convert_to_us7ascii (SUBSTR(LPAD(v_datos.cod_postal,10,'0'),-6)),
                   v_datos.cod_ensena,
                   pk_itf_conversiones.f_convert_to_us7ascii (v_datos.letra_cif),
                   pk_itf_conversiones.f_convert_to_us7ascii (v_datos.cif),
                   v_t_rel_plat_sga (1).id_sga,
                   v_cif_eroski,
                  lpad( v_datos.cod_n1, 4,'0') ,
				   v_datos.cod_n2,
				   v_datos.cod_n3,
				   v_franquiciado
                  );
         END IF;

          p_men_loc_sga (i) := v_men_loc_sga;

         EXCEPTION

            WHEN OTHERS THEN
                --Actualizamos indices
                 IF i > 1
                 THEN
                        p_men_loc_sga.DELETE (i);
                 END IF;

                 i:=i-1;
                 p_cod_error := 88;
                 p_msg_error :=  'Errores funcionales. Revisar tabla errores_integracion para msgid: '||p_msgid;
                 --Se deja un registro en la tabla errores_integración
                  v_msg_error :=
                      SQLERRM || '- Error al cargar v_t_r_men_loc_sga para men_loc_sga='||v_datos.cod_men_loc_sga||' y Plataforma='||p_cod_plataforma||' '
                  || CHR (10);
                 pk_itf_gestion_errores.p_actualizar_error ('',
                                                          p_msgid,
                                                          k_pkg_name,
                                                          v_msg_error,
                                                          v_error.v_cod_error,
                                                          v_error.v_msg_error
                                                         );
         END;


      END LOOP;

      IF i = 0
      THEN
         DBMS_OUTPUT.put_line ('No hay datos ');
         RAISE e_no_datos;
      END IF;*/
   EXCEPTION
       WHEN e_llamada
       THEN
             p_cod_error := 88;
             p_msg_error := 'Errores funcionales. Revisar tabla errores_integracion para msgid: '||p_msgid;
            --Se deja un registro en la tabla errores_integración
             v_msg_error :=v_e_error
                      || CHR (10);
                     pk_itf_gestion_errores.p_actualizar_error ('',
                                                              p_msgid,
                                                              k_pkg_name,
                                                              v_msg_error,
                                                              v_error.v_cod_error,
                                                              v_error.v_msg_error
                                                             );
      WHEN e_parametros_nulos
      THEN
         p_cod_error := pk_apr_constantes.k_error_oracle;--99
         p_msg_error :=
               'Parametro(s) nulo(s):-p_cod_plataforma '
            || p_cod_plataforma
            || ' -p_cod_cab_mensaje '
            || p_cod_cab_mensaje;
      WHEN e_no_datos
      THEN
        IF v_entra
        THEN
            p_cod_error := pk_apr_constantes.k_error_datos_no_encontrados;
            p_msg_error := 'Errores funcionales. Ningún registro válido. Revisar tabla errores_integracion para msgid: '||p_msgid;

        ELSE
            p_cod_error := pk_apr_constantes.k_error_datos_no_encontrados;   --1
            p_msg_error := 'Sin datos pendientes.';
        END IF;
      WHEN OTHERS
      THEN
         p_cod_error := pk_apr_constantes.k_error_oracle;--99
         p_msg_error := substr(dbms_utility.format_error_backtrace||':'||SQLERRM,1,4000);
           --Se deja un registro en la tabla errores_integración
         v_msg_error :=
                 ' Error.'|| substr(dbms_utility.format_error_backtrace||':'||SQLERRM,1,4000) ||'.'
                 || CHR (10);
                 pk_itf_gestion_errores.p_actualizar_error ('',
                                                          p_msgid,
                                                          k_pkg_name,
                                                          v_msg_error,
                                                          v_error.v_cod_error,
                                                          v_error.v_msg_error
                                                         );
   END;