/*GERAL PERFORMANCE BD_02*/
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
			 DMC02.SIGLA_FIL
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
			,(CASE 		
				WHEN VRCE.RAZAO IS NOT NULL THEN 'REDESPACHO' 
				WHEN DRECE3.CPF_PROPRIETARIO IS NOT NULL AND DMC02.DT_ENTREGA IS NOT NULL THEN 'DISTRIBUI��O'
				WHEN DRECE3.CPF_PROPRIETARIO IS NOT NULL AND SO03.CODIGO_OCOR IN(104,67)  THEN 'ENTREGANDO'
				WHEN DRECE3.CPF_PROPRIETARIO IS NOT NULL AND SO03.CODIGO_OCOR IN(89)  THEN 'CT-E_RETIDO_NO_CLIENTE'
				WHEN DRECE3.CPF_PROPRIETARIO IS NOT NULL   THEN 'RETORNO '
				WHEN DMFCE03.NRO_MANIFESTO IS NULL THEN 'FIL ORIGEM'
				WHEN DMFCE03.DT_CHEGADA IS NULL THEN 'TRANSFERENCIA'
				WHEN (DMFCE03.FIL_BAIXA_MNF = DMC02.RT3) THEN 'FIL DESTINO'
				WHEN (DMFCE03.FIL_BAIXA_MNF <> DMC02.RT3) THEN 'HUB'
				ELSE '-' END) AS STATUS_MOVIMENTO
			,(CASE 		
				WHEN VRCE.RAZAO IS NOT NULL THEN 'REDESPACHO' 
				ELSE 'DISTRIBUI��O' END) AS TIPO_ENTREGA
			,(CASE 		
				WHEN VRCE.RAZAO IS NOT NULL THEN VRCE.RAZAO
				WHEN DRECE3.CPF_PROPRIETARIO IS NOT NULL AND DMC02.DT_ENTREGA IS NOT NULL THEN VCC.PLACA_PRINCIPAL
				WHEN  DRECE3.CPF_PROPRIETARIO IS NOT NULL AND SO03.CODIGO_OCOR IN(104,67)  THEN VCC.PLACA_PRINCIPAL
				WHEN DRECE3.CPF_PROPRIETARIO IS NOT NULL AND SO03.CODIGO_OCOR IN(89)  THEN DMC02.DESTINATARIO
				WHEN DRECE3.CPF_PROPRIETARIO IS NOT NULL   THEN SO03.DESCRICAO_OCOR
				WHEN DMFCE03.NRO_MANIFESTO IS NULL THEN DMC02.SIGLA_FIL
				WHEN DMFCE03.DT_CHEGADA IS NULL THEN 'TRANSFERENCIA'
				WHEN (DMFCE03.FIL_BAIXA_MNF = DMC02.RT3) THEN DMC02.RT3
				WHEN (DMFCE03.FIL_BAIXA_MNF <> DMC02.RT3) THEN DMFCE03.FIL_BAIXA_MNF
				ELSE '-' END) AS NOME_PROP
			,SO03.CODIGO_OCOR
			,SO03.DESCRICAO_OCOR
			,SO03.DATA_OCORRENCIA
			,(CASE 				
				WHEN SO03.CODIGO_OCOR IN(1,2,62,84,94,100,117,119,120,121,301,303) AND DMC02.DT_ENTREGA IS NULL THEN 'SISTEMA' 	
				WHEN YEAR(DMC02.PREVISAO_ENTREGA) = 1900 THEN 'TABELA' 		
				WHEN SO03.FALHA_CLIENTE = 'S' THEN 'CLIENTE' 			
				ELSE 'OPERACIONAL' 				
				END) AS RESPONSABILIDADE 
			,(CASE 	 			
				WHEN SO03.CODIGO_OCOR IN(10) THEN 'COMERCIAL' 		
				WHEN SO03.CODIGO_OCOR IN(1,43,49,52,67,89,76,94,98,101,300,302,25,102) THEN 'CONTROL TOWER' 				
				WHEN SO03.CODIGO_OCOR IN(0,13,19,20,21,44,97,103,104) THEN 'DISTRIBUI��O' 				
				WHEN SO03.CODIGO_OCOR IN(11,14,18,33,62,78,82,84,119,120,141,143,144,200,201,202,203,204) THEN 'Expedi��o/Opera��o' 		
				WHEN SO03.CODIGO_OCOR IN(116) THEN 'FINANCEIRO' 			
				WHEN SO03.CODIGO_OCOR IN(5,6,9,17,26,29,30,46,60,70,100,117,121,145,303,304,124) THEN 'PENDENCIA ADM' 		
				WHEN SO03.CODIGO_OCOR IN(61) THEN 'REVERSA' 					
				WHEN SO03.CODIGO_OCOR IN(4,2,88,91) THEN 'SAC' 		
				ELSE 'CONTROL TOWER' 				
				END) AS Sub_RESPONSABILIDADE 
			,DMFCE03.DT_EMISSAO_MANIFESTO
			,DMFCE03.DT_CHEGADA
			,DMFCE03.DT_BAIXA
			,DMFCE03.FIL_BAIXA_MNF
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
			,DMC02.COD_DADOS_MOVIMENTO_CUSTO_EMIS
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
			(SELECT DISTINCT  dbo.fn_ret_notas_cte(DMCE01.NR_ENTRADA, DMCE01.SIGLA_FIL) AS NOTA_AGRUP , DMCE01.* FROM   tb_dados_movimento_custo_emis AS DMCE01 WHERE DMCE01.TIPO_DOC IN('NF','CO') and DMCE01.DT_EMISSAO between '20200301' and '20200504') DMC02
		LEFT JOIN 
			(SELECT * FROM tb_solid_ocorrencias AS SO01 WHERE SO01.DATA_OCORRENCIA = (SELECT MAX(SO02.DATA_OCORRENCIA) FROM tb_solid_ocorrencias AS SO02 WHERE SO02.NR_ENTRADA = SO01.NR_ENTRADA AND SO02.SIGLA_FIL = SO01.SIGLA_FIL ) OR SO01.DATA_OCORRENCIA IS NULL and SO01.DATA_OCORRENCIA > '20200101' ) AS SO03 
			ON DMC02.NR_ENTRADA = SO03.NR_ENTRADA AND DMC02.SIGLA_FIL = SO03.SIGLA_FIL
		LEFT JOIN 
			(SELECT * FROM tb_dados_manifesto_custo_emis AS DMFCE01 WHERE DMFCE01.DT_EMISSAO_MANIFESTO = 
							(SELECT MAX(DMFCE02.DT_EMISSAO_MANIFESTO) FROM tb_dados_manifesto_custo_emis AS DMFCE02 WHERE DMFCE02.NR_ENTRADA = DMFCE01.NR_ENTRADA AND DMFCE02.SIGLA_FIL = DMFCE01.SIGLA_FIL ) and DMFCE01.DT_EMISSAO_MANIFESTO > '20200101' ) AS DMFCE03 
			ON DMC02.NR_ENTRADA = DMFCE03.NR_ENTRADA AND DMC02.SIGLA_FIL = DMFCE03.SIGLA_FIL
		LEFT JOIN 
			(SELECT * FROM tb_valores_redespacho_custo_em WHERE TIPO_MANIFESTO = 'MRD'   ) AS VRCE
			ON DMC02.NR_ENTRADA  = VRCE.NR_ENTRADA AND DMC02.SIGLA_FIL = VRCE.SIGLA_FIL
		LEFT JOIN
			( SELECT * FROM tb_dados_rom_entrega_custo_em DRECE2  where 
					DRECE2.DT_EMISS_ROM_ENT = (select max(DRECE1.DT_EMISS_ROM_ENT) from tb_dados_rom_entrega_custo_em DRECE1 where DRECE1.NR_ENTRADA = DRECE2.NR_ENTRADA AND DRECE1.SIGLA_FIL = DRECE2.SIGLA_FIL )
					 AND DRECE2.NRO_ROMANEIO_ENTREGA = (select max(DRECE1.NRO_ROMANEIO_ENTREGA) from tb_dados_rom_entrega_custo_em DRECE1 where DRECE1.NR_ENTRADA = DRECE2.NR_ENTRADA AND DRECE1.SIGLA_FIL = DRECE2.SIGLA_FIL )
			) AS DRECE3
			ON DMC02.NR_ENTRADA = DRECE3.NR_ENTRADA AND DMC02.SIGLA_FIL = DRECE3.SIGLA_FIL
		LEFT JOIN
			(SELECT DISTINCT PLACA_PRINCIPAL, FIL_CONTRATO ,NUM_CONTRATO FROM Tb_valores_contrato_custo WHERE DT_EMIS_CONTRATO > '20200101' ) AS VCC
			ON DRECE3.NUM_CONTRATO  = VCC.NUM_CONTRATO AND DRECE3.FIL_CONTRATO = VCC.FIL_CONTRATO
		LEFT JOIN 
			(SELECT * FROM tb_solid_dados_cliente AS SDC01  WHERE SDC01.DT_INCL_CLI = (SELECT MAX(SDC02.DT_INCL_CLI) FROM tb_solid_dados_cliente AS SDC02 WHERE SDC02.CGC = SDC01.CGC) ) AS SDC03 
			ON DMC02.CGC_CONSIG = SDC03.CGC
		LEFT JOIN 
			(SELECT cli.nr_cnpj_cpf , (CASE WHEN part.tde2 = 1 THEN 'SIM' ELSE 'NAO' END) AS DEDICADO FROM tb_cliente cli INNER JOIN  tb_particularidades_cliente part ON part.cod_cliente = cli.cod_cliente) AS DEDICADOS
			ON DMC02.CGC_DEST =  DEDICADOS.nr_cnpj_cpf
		LEFT JOIN 		
			(select  distinct  cli.nr_cnpj_cpf , usu.nm_usuario from bd_portal_tsv.dbo.tb_usuario usu inner join bd_portal_tsv.dbo.tb_usuario_cliente uCli on uCli.id_usuario = usu.cod_user inner join bd_fin_tsv.dbo.tb_cliente cli on cli.cod_cliente  = uCli.id_cliente where usu.fl_status = 'A' and usu.funcao = 'ATENDENTE' and usu.ds_funcao = 'A'  and uCli.dt_cancela is null ) AS SAC 	
			ON DMC02.CGC_CONSIG = SAC.nr_cnpj_cpf 
	) AS TABELA 
		
		/*
			where
			TABELA.DT_EMISSAO > dateadd(DD,-2,GETDATE())
			or TABELA.DT_ENTREGA > dateadd(DD,-2,GETDATE()) 
			or TABELA.DT_BAIXA > dateadd(DD,-2,GETDATE()) 
			or TABELA.DT_EMISSAO_MANIFESTO > dateadd(DD,-2,GETDATE()) 
			or DATA_OCORRENCIA > dateadd(DD,-2,GETDATE()) 
		*/