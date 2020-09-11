/*GERAL simples*/
/*  >>>>>>>>> BD_001 <<<<<<<<<<<<<<   */
/* PENDENCIA BD_ 01*/


/*  TABELAS 

     -> tb_dados_movimento_custo_emis                             - Documentos (CT-e)
		* TIPO_DOC = 'C'
		* DT_EMISSAO >= '20200101'

	 -> tb_solid_ocorrencias                                      - Ocorr�ncia
		*  O.DATA_OCORRENCIA = 'data maxima'
		*  O.CODIGO_OCOR = 'codigo m�nimo da data m�xima'
			(h� ocorr�ncias m�ximas exatamente no mesmo minuto)

	 ->  dbo.fn_ret_notas_cte(dmc.NR_ENTRADA,dmc.SIGLA_FIL)        - Notas agrupadas 
	    * Retorna as Nfs agrupadas

	-> tb_dados_movimento_custo_emis                               - Documentos (Nota Fiscal de servi�o)
		* TIPO_DOC = 'NF'
		* DT_EMISSAO >= '20200101'

    -> tb_solid_dados_cliente                                       - Definir o Grupo do Cliente

	-> tb_dados_manifesto_custo_emis                                - Manifestos - Tranfer�ncia
		* DT_EMISSAO_MANIFESTO = 'data m�xima' 
	
	-> tb_valores_redespacho_custo_em                               - Redespacho - Parceiros
		* TIPO_MANIFESTO = 'MRD'

	-> tb_dados_rom_entrega_custo_em                                - Romaneio - Distribui��o

	-> Tb_valores_contrato_custo                                    - Placas 

	-> (SELECT  distinct  cli.nr_cnpj_cpf , usu.nm_usuario
			FROM bd_portal_tsv.dbo.tb_usuario AS usu 
			INNER JOIN bd_portal_tsv.dbo.tb_usuario_cliente AS  uCli on uCli.id_usuario = usu.cod_user
			INNER JOIN bd_fin_tsv.dbo.tb_cliente AS cli on cli.cod_cliente  = uCli.id_cliente
			WHERE usu.fl_status = 'A' AND usu.funcao = 'ATENDENTE' AND usu.ds_funcao = 'A'  and uCli.dt_cancela is null ) AS SAC 	

		* Referencia LEFT JOIN : ON CGC_CONSIG = nr_cnpj_cpf 
		* Coluna : COALESCE(SAC.nm_usuario,'SAC NORMAL') AS ATENDENTE 		
	*/

	/*TABELAS AS 
	-> DMC    - tb_dados_movimento_custo_emis + dbo.fn_ret_notas_cte(DMC01.NR_ENTRADA, DMC01.SIGLA_FIL)
	-> SO     - tb_solid_ocorrencias
	-> DMFCE  - tb_dados_manifesto_custo_emis
	-> VRCE   - tb_valores_redespacho_custo_em
	-> SDC    - tb_solid_dados_cliente
	-> DRECE  - tb_dados_rom_entrega_custo_em
	*/

/*  >>>>>>>>> BD_001 <<<<<<<<<<<<<<   */

SELECT DISTINCT
	TABELA.* 
	,(CASE 	
		WHEN TABELA.DIAS_ATRASO BETWEEN  1 AND 3 THEN '1 A 3' 	
		WHEN TABELA.DIAS_ATRASO BETWEEN  4 AND 6 THEN '4 A 6' 	
		WHEN TABELA.DIAS_ATRASO BETWEEN  7 AND 14 THEN '7 A 14' 
		WHEN TABELA.DIAS_ATRASO BETWEEN  15 AND 30 THEN '15 A 30' 
		WHEN TABELA.DIAS_ATRASO >30 THEN ' > 30' 	
		WHEN TABELA.DIAS_ATRASO = 0 THEN 'HOJE'
		ELSE 'NO PRAZO' 
		END) AS FAIXA_ATRASO
	 ,(CASE
		WHEN TABELA.STATUS_ENTREGA = 'ATRASADO' THEN TABELA.NUM_DOC 
		END) AS DOC_ATRASADO
	 , GETDATE() AS ATUALIZACAO_PAINEL
	FROM	
			(SELECT DISTINCT 
			DMC02.COD_DADOS_MOVIMENTO_CUSTO_EMIS
			,DMC02.SIGLA_FIL
			,CONCAT( DMC02.SIGLA_FIL,' ', cast(DMC02.NUM_DOC as char)) AS NUM_DOC
			,DMC02.NR_COLETA
			,DMC02.DATA_COLETA
			,DMC02.DT_EMISSAO
			,DMC02.DT_ENTREGA
			,DMC02.PREVISAO_ENTREGA
			,DMC02.NOTA_AGRUP AS NF
			,DMC02.CGC_REMET
			,DMC02.REMETENTE
			,DMC02.CGC_DEST
			,DMC02.DESTINATARIO
			,DMC02.CGC_CONSIG
			,DMC02.CONSIGNATARIO
			,DMC02.LOCAL_ENTREGA
			,DMC02.CIDADE_DESTINO
			,DMC02.ESTADO_DESTINO
			,DMC02.RT1
			,DMC02.RT2
			,DMC02.RT3
			,VAL_MERC_MOV
			,(CASE 
				WHEN DMC02.RT4 = 'I' THEN 'INTERIOR' 
				WHEN DMC02.RT4 = 'C' THEN 'CAPITAL' 	
				ELSE 'INTERIOR 02' 	
				END) AS RT4
			,(CASE 			
				WHEN DMC02.ESTADO_DESTINO IN ('DF','GO','MS','MT') THEN 'Centro-Oeste'
				WHEN DMC02.ESTADO_DESTINO IN ('AL','BA','CE','MA','PB','PE','PI','RN','SE') THEN 'Nordeste' 
				WHEN DMC02.ESTADO_DESTINO IN ('AC','AM','AP','PA','RO','RR','TO') THEN 'Norte' 
				WHEN DMC02.ESTADO_DESTINO IN ('ES','MG','RJ','SP') THEN 'Sudeste' 	
				WHEN DMC02.ESTADO_DESTINO IN ('PR','RS','SC') THEN 'Sul' 		
				END) AS REGIAO
			,DMC02.CIDADE
			,DMC02.ESTADO
			,DMC02.CEP_DEST
			,(CASE 	
				WHEN SDC03.DESCR_GRUPO_CLIENTE = '' THEN DMC02.CONSIGNATARIO 	
				WHEN SDC03.DESCR_GRUPO_CLIENTE IS NULL THEN DMC02.CONSIGNATARIO 
				ELSE SDC03.DESCR_GRUPO_CLIENTE  
				END) AS CLIENTE_GRUPO

			,COALESCE(DEDICADOS.DEDICADO,'NAO') AS DEDICADO
			,DMC02.TIPO_FRETE
			,DMC02.TIPO_DOC
			,DMC02.VOL_MOV 
			,DMC02.PESO_MOV 
			,DMC02.PESO_CUBADO
			,DMC02.PESO_CUBADO_2
			,DMC02.nr_peso_cub_pad
			,DMC02.nr_peso_rel
			,DMC02.vl_dist_col_prop
			,DMC02.vl_dist_col_red
			,DMC02.vl_dist_ent_prop
			,DMC02.vl_dist_ent_red
			,DMC02.VLR_FRETE_TAB_PADRAO
			,DMC02.PERC_SEGURO_IOF
			,DMC02.PERC_RCF_DC
			,DMC02.ALIQ_INSS
			,DMC02.ALIQ_COFINS
			,DMC02.ALIQ_PIS
			,DMC02.VALOR_ICMS
			,DMC02.VALOR_ICMS_INCENTIVO
			,DMC02.COMISSAO_VENDAS
			,DMC02.FRETE
			,DMC02.DESCR_TIPO_TRANSP
			,DMC02.VENDEDOR
			,DMC02.SIGLA_FIL_DEST
			,COALESCE(SAC.nm_usuario,'SAC NORMAL') AS ATENDENTE
			,(CASE 
				WHEN DMC02.DT_ENTREGA is  null THEN 
					(DATEDIFF(dd,DMC02.PREVISAO_ENTREGA ,  GETDATE()))-(DATEDIFF(wk, DMC02.PREVISAO_ENTREGA,  GETDATE()) * 2)-(CASE WHEN DATEPART(dw,  GETDATE()) = 1 THEN 1 ELSE 0 END)-(CASE WHEN DATEPART(dw,  GETDATE()) = 7 THEN 1 ELSE 0 END) 
				ELSE		
					(DATEDIFF(dd,DMC02.PREVISAO_ENTREGA ,  DMC02.DT_ENTREGA))-(DATEDIFF(wk, DMC02.PREVISAO_ENTREGA,  DMC02.DT_ENTREGA) * 2)-(CASE WHEN DATEPART(dw,  DMC02.DT_ENTREGA) = 1 THEN 1 ELSE 0 END)-(CASE WHEN DATEPART(dw,  DMC02.DT_ENTREGA) = 7 THEN 1 ELSE 0 END) 
				END)	AS DIAS_ATRASO
			,(CASE             
				WHEN DMC02.DT_ENTREGA is  null THEN 
					(CASE
						WHEN (DATEDIFF(dd,DMC02.PREVISAO_ENTREGA ,  GETDATE()) ) <= 0 THEN 'NO_PRAZO'  ELSE 'ATRASADO'  
						END)
				ELSE 
					(CASE
						WHEN (DATEDIFF(dd,DMC02.PREVISAO_ENTREGA ,  DMC02.DT_ENTREGA) ) <= 0 THEN 'NO_PRAZO'  ELSE 'ATRASADO'  
						END)
				END) AS STATUS_ENTREGA
			,DMC02.NR_ENTRADA
		FROM
			(SELECT DISTINCT  dbo.fn_ret_notas_cte(DMCE01.NR_ENTRADA, DMCE01.SIGLA_FIL) AS NOTA_AGRUP , DMCE01.* FROM   tb_dados_movimento_custo_emis  AS DMCE01 with(nolock) WHERE DMCE01.TIPO_DOC IN('NF','CO') and DMCE01.DT_EMISSAO BETWEEN dateadd(DD,-30,GETDATE()) AND dateadd(DD,-1,GETDATE()))  DMC02
		LEFT JOIN 
			(SELECT * FROM tb_solid_dados_cliente AS SDC01 with(nolock)  WHERE SDC01.DT_INCL_CLI = (SELECT MAX(SDC02.DT_INCL_CLI) FROM tb_solid_dados_cliente AS SDC02 with(nolock)  WHERE SDC02.CGC = SDC01.CGC) ) AS SDC03 
			ON DMC02.CGC_CONSIG = SDC03.CGC
		LEFT JOIN 
			(SELECT cli.nr_cnpj_cpf , (CASE WHEN part.tde2 = 1 THEN 'SIM' ELSE 'NAO' END) AS DEDICADO FROM tb_cliente cli INNER JOIN  tb_particularidades_cliente part with(nolock) ON part.cod_cliente = cli.cod_cliente) AS DEDICADOS
			ON DMC02.CGC_DEST =  DEDICADOS.nr_cnpj_cpf
		LEFT JOIN 		
			(select  distinct  cli.nr_cnpj_cpf , usu.nm_usuario from bd_portal_tsv.dbo.tb_usuario usu with(nolock) inner join bd_portal_tsv.dbo.tb_usuario_cliente uCli with(nolock) on uCli.id_usuario = usu.cod_user inner join bd_fin_tsv.dbo.tb_cliente cli on cli.cod_cliente  = uCli.id_cliente where usu.fl_status = 'A' and usu.funcao = 'ATENDENTE' and usu.ds_funcao = 'A'  and uCli.dt_cancela is null ) AS SAC 	
			ON DMC02.CGC_CONSIG = SAC.nr_cnpj_cpf 
	) AS TABELA 
		
	