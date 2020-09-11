SELECT DISTINCT 
SAC.nm_usuario

,(CASE
	WHEN MONFCL.DIAS_ATRASO BETWEEN  1 AND 3 THEN '1 A 3'
	WHEN MONFCL.DIAS_ATRASO BETWEEN  4 AND 6 THEN '4 A 6'
	WHEN MONFCL.DIAS_ATRASO BETWEEN  7 AND 15 THEN '7 A 15'
	WHEN MONFCL.DIAS_ATRASO BETWEEN  16 AND 30 THEN '16 A 30'
	WHEN MONFCL.DIAS_ATRASO >30 THEN ' > 30'
	WHEN MONFCL.DIAS_ATRASO = 0 THEN 'HOJE'
ELSE 'NO PRASO'
END) AS FAIXA_ATRASO
, MONFCL.* FROM 
( SELECT  DISTINCT
	 ( CASE 
		WHEN CL.DESCR_GRUPO_CLIENTE = '' THEN MONF.CONSIGNATARIO 
		WHEN CL.DESCR_GRUPO_CLIENTE IS NULL THEN MONF.CONSIGNATARIO 
		ELSE
		CL.DESCR_GRUPO_CLIENTE
	  END) AS CLIENTE_GRUPO

	, (DATEDIFF(dd,MONF.PREVISAO_ENTREGA ,  GETDATE())) 
		-(DATEDIFF(wk, MONF.PREVISAO_ENTREGA,  GETDATE()) * 2) 
		-(CASE WHEN DATEPART(dw, MONF.PREVISAO_ENTREGA) = 1 THEN 1 ELSE 0 END) 
		-(CASE WHEN DATEPART(dw,  GETDATE()) = 7 THEN 1 ELSE 0 END) 	
	  as DIAS_ATRASO

	, (CASE WHEN (DATEDIFF(dd,MONF.PREVISAO_ENTREGA ,  GETDATE()) ) <= 0 THEN 'EM ABERTO'  ELSE 'EM ATRASO' END) AS STATUS_ENTREGA

	, GETDATE() AS ATUALIZACAO_PAINEL

	,MONF.* 

		FROM  
		(
			SELECT DISTINCT 
			O.DATA_OCORRENCIA

			, (CASE 
				WHEN O.RESPONSAVEL = 'AUTOMATICO' THEN 'SEM ACOMPANHAMENTO' 
				WHEN O.RESPONSAVEL IS NULL THEN 'SEM ACOMPANHAMENTO' 
			 ELSE 'COM ACOMPANHAMENTO' 
			 END) AS  ACOMPANHAMENTO 
			, O.CODIGO_OCOR
			, (CASE 
				 WHEN O.DESCRICAO_OCOR = 'ENTREGA REALIZADA NORMALMENTE' AND M.DT_ENTREGA IS NULL THEN 'SISTEMA'
				 WHEN YEAR(M.PREVISAO_ENTREGA) = 1900 THEN 'TABELA'
				 WHEN O.FALHA_CLIENTE = 'S' THEN 'CLIENTE' 
				 WHEN O.FALHA_OPERACIONAL = 'S' THEN 'OPERACIONAL'
			 ELSE 'INDEFINIDO' 
			 END) AS RESPONSABILIDADE

			, O.DESCRICAO_OCOR

			, M.*	
			FROM 	tb_dados_movimento_custo_emis AS M	
				LEFT JOIN 	tb_solid_ocorrencias  AS O	
				ON 	concat(cast(M.NR_ENTRADA as char) , M.SIGLA_FIL) = concat(cast(O.NR_ENTRADA as CHAR), O.SIGLA_FIL)
			WHERE
				M.TIPO_DOC = 'CO'
				AND M.DT_EMISSAO >= '20200401' 	
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

			SELECT  NULL,NULL, 	NULL, 'NF DE SERVI�O',NULL,  MNF.*
			FROM	tb_dados_movimento_custo_emis AS MNF 
			WHERE 
				TIPO_DOC = 'NF'	
				AND	MNF.DT_EMISSAO >= '20200401'
		) MONF 
		LEFT JOIN tb_solid_dados_cliente AS CL ON  MONF.CGC_CONSIG = CL.CGC
		where
		cl.DT_INCL_CLI = 
			(
				SELECT MAX(TBCL.DT_INCL_CLI) FROM tb_solid_dados_cliente AS TBCL
				WHERE TBCL.CGC = CL.CGC
			)
) MONFCL
LEFT JOIN (
	   SELECT distinct SAC1.nr_cnpj_cpf, SAC1.nm_usuario FROM
			(select  distinct usu.cod_user,usu.fl_status,usu.funcao,usu.ds_funcao,uCli.dt_cancela, uCli.id_usuario,cli.cod_cliente,nr_cnpj_cpf,nm_usuario
			from bd_portal_tsv.dbo.tb_usuario usu        
				inner join bd_portal_tsv.dbo.tb_usuario_cliente uCli on uCli.id_usuario = usu.cod_user
				inner join bd_fin_tsv.dbo.tb_cliente cli on cli.cod_cliente  = uCli.id_cliente      
				where usu.fl_status = 'A' and usu.funcao = 'ATENDENTE' and usu.ds_funcao = 'A'  and uCli.dt_cancela is null
			) AS SAC1
		WHERE 
			SAC1.id_usuario = (			
						SELECT  MAX(CLDMX.id_usuario) FROM bd_portal_tsv.dbo.tb_usuario_cliente AS CLDMX			
								WHERE 
									CLDMX.id_cliente = SAC1.cod_cliente			
									and  SAC1.fl_status = 'A' and SAC1.funcao = 'ATENDENTE' and SAC1.ds_funcao = 'A'  and SAC1.dt_cancela is null
					)			

        ) AS SAC
	ON MONFCL.CGC_CONSIG = SAC.nr_cnpj_cpf
	WHERE 
		MONFCL.DT_ENTREGA is  null
		AND MONFCL.DESCR_TIPO_TRANSP  IN('RODO','SUBCONTRATACAO','ICMS SUBCONT')