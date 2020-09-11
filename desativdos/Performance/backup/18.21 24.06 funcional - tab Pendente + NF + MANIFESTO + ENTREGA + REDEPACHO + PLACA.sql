SELECT DISTINCT
 	 (CASE  		WHEN MONFCLMNF.STATUS_ENTREGA = 'EM_ATRASO' THEN MONFCLMNF.NUM_DOC 
		END) AS DOC_ATRASADO
	,MNFE.DT_EMISSAO_MANIFESTO
	,MNFE.DT_CHEGADA
	,MNFE.DT_BAIXA
	,MNFE.FIL_BAIXA_MNF
	,(CASE 		
		WHEN RDPC.RAZAO IS NOT NULL THEN RAZAO
		WHEN  ENT.CPF_PROPRIETARIO IS NOT NULL AND MONFCLMNF.CODIGO_OCOR IN(104,67)  THEN pl.PLACA_PRINCIPAL
		WHEN ENT.CPF_PROPRIETARIO IS NOT NULL AND MONFCLMNF.CODIGO_OCOR IN(89)  THEN MONFCLMNF.DESTINATARIO
		WHEN ENT.CPF_PROPRIETARIO IS NOT NULL   THEN MONFCLMNF.DESCRICAO_OCOR
		WHEN MNFE.NRO_MANIFESTO IS NULL THEN MONFCLMNF.SIGLA_FIL
		WHEN MNFE.DT_CHEGADA IS NULL THEN 'TRANSFERENCIA'
		WHEN (MNFE.FIL_BAIXA_MNF = MONFCLMNF.RT3) THEN MONFCLMNF.RT3
		WHEN (MNFE.FIL_BAIXA_MNF <> MONFCLMNF.RT3) THEN MNFE.FIL_BAIXA_MNF
		ELSE '0' END) AS NOME_PROP
	 ,(CASE 		
		WHEN RDPC.RAZAO IS NOT NULL THEN 'REDESPACHO'
		WHEN  ENT.CPF_PROPRIETARIO IS NOT NULL AND MONFCLMNF.CODIGO_OCOR IN(104,67)  THEN 'ENTREGANDO'
		WHEN ENT.CPF_PROPRIETARIO IS NOT NULL AND MONFCLMNF.CODIGO_OCOR IN(89)  THEN 'CT-E_RETIDO_NO_CLIENTE'
		WHEN ENT.CPF_PROPRIETARIO IS NOT NULL   THEN 'RETORNO '
		WHEN MNFE.NRO_MANIFESTO IS NULL THEN 'FIL ORIGEM'
		WHEN MNFE.DT_CHEGADA IS NULL THEN 'TRANSFERENCIA'
		WHEN (MNFE.FIL_BAIXA_MNF = MONFCLMNF.RT3) THEN 'FIL DESTINO'
		WHEN (MNFE.FIL_BAIXA_MNF <> MONFCLMNF.RT3) THEN 'HUB'
		ELSE '0' END) AS STATUS_MOVIMENTO
		,MONFCLMNF.* FROM
			(SELECT DISTINCT
				COALESCE(SAC.nm_usuario,'SAC NORMAL') AS ATENDENTE
				,(CASE 			WHEN MONFCL.ESTADO_DEST IN ('DF','GO','MS','MT') THEN 'Centro-Oeste'
					WHEN MONFCL.ESTADO_DEST IN ('AL','BA','CE','MA','PB','PE','PI','RN','SE') THEN 'Nordeste' 
					WHEN MONFCL.ESTADO_DEST IN ('AC','AM','AP','PA','RO','RR','TO') THEN 'Norte' 
					WHEN MONFCL.ESTADO_DEST IN ('ES','MG','RJ','SP') THEN 'Sudeste' 	
					WHEN MONFCL.ESTADO_DEST IN ('PR','RS','SC') THEN 'Sul' 		
					END) AS REGIAO 
				,(CASE 			
					WHEN MONFCL.DIAS_OCORRENCIA BETWEEN  0 AND 3 THEN '1 A 3'
					WHEN MONFCL.DIAS_OCORRENCIA BETWEEN  4 AND 6 THEN '4 A 6' 
					WHEN MONFCL.DIAS_OCORRENCIA BETWEEN  7 AND 14 THEN '7 A 14' 	
					WHEN MONFCL.DIAS_OCORRENCIA BETWEEN  15 AND 30 THEN '15 A 30' 
					WHEN MONFCL.DIAS_OCORRENCIA >30 THEN ' > 30' 	
					WHEN MONFCL.DIAS_OCORRENCIA = 0 THEN 'HOJE' 	
					ELSE 'NF DE SERVI�O' 		
					END) AS FAIXA_OCORRENCIA 	
				,(CASE 	
					WHEN MONFCL.DIAS_ATRASO BETWEEN  1 AND 3 THEN '1 A 3' 	
					WHEN MONFCL.DIAS_ATRASO BETWEEN  4 AND 6 THEN '4 A 6' 	
					WHEN MONFCL.DIAS_ATRASO BETWEEN  7 AND 14 THEN '7 A 14' 
					WHEN MONFCL.DIAS_ATRASO BETWEEN  15 AND 30 THEN '15 A 30' 
					WHEN MONFCL.DIAS_ATRASO >30 THEN ' > 30' 	
					WHEN MONFCL.DIAS_ATRASO = 0 THEN 'HOJE'
					ELSE 'NO PRAZO' 
					END) AS FAIXA_ATRASO
				,NFS.COD_SOLID_NFS_CTES 
				,NFS.NUM_NOTA_FISCAL AS NF
				,NFS.SERIE 
				,NFS.VOLUMES 	
				,NFS.PESO 	
				,NFS.ITEM 	
				,NFS.CHAVE_ACESSO_NFE 	
				,NFS.DT_EMISS_NF 
				,NFS.NR_RECEPCAO 	
				,NFS.DT_RECEPCAO 	
				,NFS.DT_CAR 	
				,NFS.DT_DESCAR 	
				,NFS.NR_PEDIDO_ENTREGA 	
				,NFS.NR_EMBARQUE 
				,MONFCL.Sub_RESPONSABILIDADE 
				,MONFCL.CLIENTE_GRUPO
				,MONFCL.STATUS_ENTREGA 	
				,MONFCL.ATUALIZACAO_PAINEL
				,MONFCL.DATA_OCORRENCIA 	
				,MONFCL.ACOMPANHAMENTO 	
				,MONFCL.CODIGO_OCOR 	
				,MONFCL.DESCRICAO_OCOR 	
				,MONFCL.RESPONSABILIDADE 	
				,MONFCL.DIAS_ATRASO 	
				,MONFCL.DIAS_OCORRENCIA 	
				,MONFCL.COD_DADOS_MOVIMENTO_CUSTO_EMIS 		
				,MONFCL.SIGLA_FIL 	
				,MONFCL.NR_ENTRADA 	
				,concat( MONFCL.SIGLA_FIL,' ', cast(MONFCL.NUM_DOC as char)) AS NUM_DOC 
				,MONFCL.TIPO_FRETE 	
				,MONFCL.TIPO_DOC 
				,MONFCL.SERIE_DOC 
				,MONFCL.RT1 
				,MONFCL.RT2 	
				,MONFCL.RT3 	
				,(CASE 
					WHEN MONFCL.RT4 = 'I' THEN 'INTERIOR' 
					WHEN MONFCL.RT4 = 'C' THEN 'CAPITAL' 	
					ELSE 'INTERIOR 02' 	
					END) AS RT4 
				,MONFCL.CIDADE 	
				,MONFCL.ESTADO 
				,MONFCL.CIDADE_DESTINO 	
				,MONFCL.ESTADO_DESTINO 	
				,MONFCL.REMETENTE 	
				,MONFCL.DESTINATARIO 
				,MONFCL.CONSIGNATARIO 
				,MONFCL.CGC_CONSIG 	
				,MONFCL.CGC_REMET 	
				,MONFCL.CGC_DEST 	
				,MONFCL.VENDEDOR 	
				,MONFCL.FATOR_CONVERSAO_CLIENTE 
				,MONFCL.FATOR_CONVERSAO_PADRAO 	
				,MONFCL.FIL_RESP_FRETE 	
				,MONFCL.NR_COLETA 
				,MONFCL.DT_EMISSAO 	
				,MONFCL.DT_ATUALIZADO 		
				,MONFCL.PREVISAO_ENTREGA 	
				,MONFCL.DESCR_TIPO_TRANSP 	
				,MONFCL.DATA_COLETA 	
				,MONFCL.SIGLA_FIL_DEST 	
				,MONFCL.CODIGO_ROTA_ENTREGA 	
				,MONFCL.TIPO_TAB 	
				,MONFCL.ENDERECO_DEST 	
				,MONFCL.CIDADE_DEST 	
				,MONFCL.ESTADO_DEST 	
				,MONFCL.BAIRRO_DEST 	
				,MONFCL.CEP_DEST 
				,MONFCL.LOCAL_ENTREGA
				FROM 		
					(SELECT DISTINCT 		
					(CASE 	
						WHEN CL.DESCR_GRUPO_CLIENTE = '' THEN MONF.CONSIGNATARIO 	
						WHEN CL.DESCR_GRUPO_CLIENTE IS NULL THEN MONF.CONSIGNATARIO 
						ELSE CL.DESCR_GRUPO_CLIENTE  
						END) AS CLIENTE_GRUPO 	
					,(DATEDIFF(dd,MONF.DATA_OCORRENCIA ,  GETDATE()))-(DATEDIFF(wk, MONF.DATA_OCORRENCIA, GETDATE()) * 2)-(CASE WHEN DATEPART(dw,  GETDATE()) = 1 THEN 1 ELSE 0 END)-(CASE WHEN DATEPART(dw, GETDATE()) = 7 THEN 1 ELSE 0 END) AS DIAS_OCORRENCIA
					,(DATEDIFF(dd,MONF.PREVISAO_ENTREGA ,  GETDATE()))-(DATEDIFF(wk, MONF.PREVISAO_ENTREGA,  GETDATE()) * 2)-(CASE WHEN DATEPART(dw,  GETDATE()) = 1 THEN 1 ELSE 0 END)-(CASE WHEN DATEPART(dw,  GETDATE()) = 7 THEN 1 ELSE 0 END) AS DIAS_ATRASO
					,(CASE
						WHEN (DATEDIFF(dd,MONF.PREVISAO_ENTREGA ,  GETDATE()) ) <= 0 THEN 'EM_ABERTO'  ELSE 'EM_ATRASO'  
						END) AS STATUS_ENTREGA 	
					, GETDATE() AS ATUALIZACAO_PAINEL 	
					,MONF.* 		
					FROM 	
						(SELECT DISTINCT 	
						O.DATA_OCORRENCIA 	
						,(CASE 		
							WHEN O.RESPONSAVEL = 'AUTOMATICO' THEN 'AUTOMATICO' 	
							WHEN O.RESPONSAVEL IS NULL THEN 'AUTOMATICO' 			
							ELSE 'MANUAL' 				
							END) AS  ACOMPANHAMENTO 	
						,O.CODIGO_OCOR 			
						,(CASE 				
						WHEN CODIGO_OCOR IN(1,2,62,84,94,100,117,119,120,121,301,303) AND M.DT_ENTREGA IS NULL THEN 'SISTEMA' 	
						WHEN YEAR(M.PREVISAO_ENTREGA) = 1900 THEN 'TABELA' 		
						WHEN O.FALHA_CLIENTE = 'S' THEN 'CLIENTE' 			
						ELSE 'OPERACIONAL' 				
						END) AS RESPONSABILIDADE 
					,(CASE 	 			
						WHEN CODIGO_OCOR IN(10) THEN 'COMERCIAL' 		
						WHEN CODIGO_OCOR IN(1,43,49,52,67,89,76,94,98,101,300,302,25,102) THEN 'CONTROL TOWER' 				
						WHEN CODIGO_OCOR IN(0,13,19,20,21,44,97,103,104) THEN 'DISTRIBUI��O' 				
						WHEN CODIGO_OCOR IN(11,14,18,33,62,78,82,84,119,120,141,143,144,200,201,202,203,204) THEN 'Expedi��o/Opera��o' 		
						WHEN CODIGO_OCOR IN(116) THEN 'FINANCEIRO' 			
						WHEN CODIGO_OCOR IN(5,6,9,17,26,29,30,46,60,70,100,117,121,145,303,304,124) THEN 'PENDENCIA ADM' 		
						WHEN CODIGO_OCOR IN(61) THEN 'REVERSA' 					
						WHEN CODIGO_OCOR IN(4,2,88,91) THEN 'SAC' 		
						ELSE 'CONTROL TOWER' 				
						END) AS Sub_RESPONSABILIDADE 			
					,O.DESCRICAO_OCOR 	
					, M.* 		
						FROM 	 
						(select * from tb_dados_movimento_custo_emis WHERE 	TIPO_DOC = 'CO' AND DT_EMISSAO >= '20200101' ) AS M 	
						LEFT JOIN 	tb_solid_ocorrencias  AS O 	
						ON 	concat(cast(M.NR_ENTRADA as char) , M.SIGLA_FIL) = concat(cast(O.NR_ENTRADA as CHAR), O.SIGLA_FIL) 			
						WHERE 					M.TIPO_DOC = 'CO' 					AND M.DT_EMISSAO >= '20200101' 		
						AND O.DATA_OCORRENCIA =  
							(SELECT MAX(ODM2.DATA_OCORRENCIA)  		
								FROM tb_solid_ocorrencias AS ODM2  		
								WHERE  				
								ODM2. NR_ENTRADA = O. NR_ENTRADA 	
								AND	ODM2.SIGLA_FIL = O.SIGLA_FIL 	
							)
						AND O.CODIGO_OCOR =  
							(SELECT MIN(ODM2.CODIGO_OCOR)  	
								FROM tb_solid_ocorrencias AS ODM2 	
								WHERE 			
								ODM2. NR_ENTRADA = O. NR_ENTRADA 				
								AND	ODM2.SIGLA_FIL = O.SIGLA_FIL 		
								AND ODM2.DATA_OCORRENCIA = O.DATA_OCORRENCIA 		
							) 	
						or  O.DATA_OCORRENCIA  is null
					UNION ALL  		
					SELECT NULL,'NF DE SERVI�O',0, 'NF DE SERVI�O', 'NF DE SERVI�O','NF DE SERVI�O',  MNF.* FROM tb_dados_movimento_custo_emis AS MNF WHERE TIPO_DOC = 'NF' AND	MNF.DT_EMISSAO >= '20200101'
					)MONF 

				LEFT JOIN tb_solid_dados_cliente AS CL
				ON  MONF.CGC_CONSIG = CL.CGC
				where 	
				cl.DT_INCL_CLI = 	
					(SELECT MAX(TBCL.DT_INCL_CLI) 	
						FROM tb_solid_dados_cliente AS TBCL 	
						WHERE TBCL.CGC = CL.CGC  
					) 	    
			) MONFCL
			LEFT JOIN 		
			(select  distinct  cli.nr_cnpj_cpf , usu.nm_usuario from bd_portal_tsv.dbo.tb_usuario usu inner join bd_portal_tsv.dbo.tb_usuario_cliente uCli on uCli.id_usuario = usu.cod_user inner join bd_fin_tsv.dbo.tb_cliente cli on cli.cod_cliente  = uCli.id_cliente where usu.fl_status = 'A' and usu.funcao = 'ATENDENTE' and usu.ds_funcao = 'A'  and uCli.dt_cancela is null ) AS SAC 	
			ON MONFCL.CGC_CONSIG = SAC.nr_cnpj_cpf 
			LEFT JOIN   tb_solid_nfs_ctes AS NFS  
			ON concat(cast(MONFCL.NR_ENTRADA as char) , MONFCL.SIGLA_FIL) = concat(cast(NFS.NR_ENTRADA as CHAR), NFS.SIGLA_FIL) 
			WHERE 			
				MONFCL.DT_ENTREGA is  null
		) AS MONFCLMNF

		LEFT JOIN 	tb_dados_manifesto_custo_emis AS MNFE 	
		ON 	concat(cast(MONFCLMNF.NR_ENTRADA as char) , MONFCLMNF.SIGLA_FIL) = concat(cast(MNFE.NR_ENTRADA as CHAR), MNFE.SIGLA_FIL) 
		LEFT JOIN  
			(SELECT * FROM tb_valores_redespacho_custo_em WHERE TIPO_MANIFESTO = 'MRD' ) AS  RDPC 	ON 	concat(cast(MONFCLMNF.NR_ENTRADA as char) , MONFCLMNF.SIGLA_FIL) = concat(cast(RDPC.NR_ENTRADA as CHAR), RDPC.SIGLA_FIL)
		LEFT JOIN 	tb_dados_rom_entrega_custo_em AS ENT 	ON 	concat(cast(MONFCLMNF.NR_ENTRADA as char) , MONFCLMNF.SIGLA_FIL) = concat(cast(ENT.NR_ENTRADA as CHAR), ENT.SIGLA_FIL) 
		LEFT JOIN Tb_valores_contrato_custo AS PL 	ON 	concat(cast(ENT.NUM_CONTRATO AS char) , ENT.FIL_CONTRATO) = concat(cast(PL.NUM_CONTRATO as CHAR), PL.FIL_CONTRATO) 	
		WHERE 		
		MNFE.DT_EMISSAO_MANIFESTO = 
			( SELECT MAX(MNFDX.DT_EMISSAO_MANIFESTO) FROM tb_dados_manifesto_custo_emis AS MNFDX 	
				WHERE MNFDX.NR_ENTRADA = 	MNFE.NR_ENTRADA 
				AND	MNFDX.SIGLA_FIL = MNFE.SIGLA_FIL 			
			) 		
			OR  	
			MNFE.DT_EMISSAO_MANIFESTO IS NULL