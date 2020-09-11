 SELECT  DISTINCT
			 ( CASE 
				WHEN CL.DESCR_GRUPO_CLIENTE = '' THEN MONF.CONSIGNATARIO 
				WHEN CL.DESCR_GRUPO_CLIENTE IS NULL THEN MONF.CONSIGNATARIO 
				ELSE
				CL.DESCR_GRUPO_CLIENTE
			  END) AS CLIENTE_GRUPO

			,(CASE WHEN  MONF.DT_ENTREGA IS NULL THEN
				(DATEDIFF(dd,MONF.PREVISAO_ENTREGA ,  GETDATE())) 
				-(DATEDIFF(wk, MONF.PREVISAO_ENTREGA,  GETDATE()) * 2) 
				-(CASE WHEN DATEPART(dw,  GETDATE()) = 1 THEN 1 ELSE 0 END) 
				-(CASE WHEN DATEPART(dw,  GETDATE()) = 7 THEN 1 ELSE 0 END) 	
			 ELSE
			    (DATEDIFF(dd,MONF.PREVISAO_ENTREGA ,   MONF.DT_ENTREGA)) 
				-(DATEDIFF(wk, MONF.PREVISAO_ENTREGA,   MONF.DT_ENTREGA) * 2) 
				-(CASE WHEN DATEPART(dw, MONF.DT_ENTREGA) = 1 THEN 1 ELSE 0 END) 
				-(CASE WHEN DATEPART(dw, MONF.DT_ENTREGA) = 7 THEN 1 ELSE 0 END) 
				END) as DIAS_ATRASO
			,(CASE WHEN  MONF.DT_ENTREGA IS NULL THEN
				'ENTREGUE'
			 ELSE
			    'PENDENTE'
				END) as STATUS_ENTREGA

			
			, GETDATE() AS ATUALIZACAO_PAINEL

			,MONF.* 

				FROM  
				(
					SELECT DISTINCT 

					 O.DESCRICAO_OCOR

					, M.*	
					FROM 	tb_dados_movimento_custo_emis AS M	
						LEFT JOIN 	tb_solid_ocorrencias  AS O	
						ON 	concat(cast(M.NR_ENTRADA as char) , M.SIGLA_FIL) = concat(cast(O.NR_ENTRADA as CHAR), O.SIGLA_FIL)
					WHERE
						M.TIPO_DOC = 'CO'
						AND M.DT_EMISSAO >= '20180101' 	
							AND O.DATA_OCORRENCIA = 
								( SELECT 
									COALESCE(MAX(ODM.DATA_OCORRENCIA),
										(SELECT 
											MAX(ODM2.DATA_OCORRENCIA)	
										FROM tb_solid_ocorrencias AS ODM2
										WHERE
											ODM2. NR_ENTRADA = 	O. NR_ENTRADA
											AND	ODM2.SIGLA_FIL = O.SIGLA_FIL
										)
									) as DXM
								FROM tb_solid_ocorrencias AS ODM
								WHERE ODM. NR_ENTRADA = O. NR_ENTRADA
								AND	ODM.SIGLA_FIL =	O.SIGLA_FIL
								AND ODM.RESPONSAVEL != 'AUTOMATICO'
							   )
						and O.CODIGO_OCOR = 
						  ( SELECT 
								COALESCE(MIN(ODM.CODIGO_OCOR),
									(SELECT 
										MIN(ODM2.CODIGO_OCOR)	
									FROM tb_solid_ocorrencias AS ODM2
									WHERE
										ODM2. NR_ENTRADA = 	O. NR_ENTRADA
										AND	ODM2.SIGLA_FIL = O.SIGLA_FIL
										AND ODM2.DATA_OCORRENCIA = O.DATA_OCORRENCIA
									)
								) as DXM
							FROM tb_solid_ocorrencias AS ODM
							WHERE ODM. NR_ENTRADA = O. NR_ENTRADA
							AND	ODM.SIGLA_FIL =	O.SIGLA_FIL
							AND ODM.RESPONSAVEL != 'AUTOMATICO'
							AND ODM.DATA_OCORRENCIA = O.DATA_OCORRENCIA
						   )
	 
					UNION ALL

					SELECT  NULL,  MNF.*
					FROM	tb_dados_movimento_custo_emis AS MNF 
					WHERE 
						TIPO_DOC = 'NF'	
						AND	MNF.DT_EMISSAO >= '20180101'
				) MONF 
				LEFT JOIN tb_solid_dados_cliente AS CL ON  MONF.CGC_CONSIG = CL.CGC
				where
				cl.DT_INCL_CLI = 
					(
						SELECT MAX(TBCL.DT_INCL_CLI) FROM tb_solid_dados_cliente AS TBCL
						WHERE TBCL.CGC = CL.CGC
					)
	

   