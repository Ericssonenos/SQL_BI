/*
O = Dabela de Ocorrências
M = Dabela de Movimentação
ODM = Dabela de Ocorrências Data Máxima
MDM = Dabela de Movimentação Data Máxima 
MONF = INNER JOIN de (Movimentação de Ct-e + Ocorrência) 
	  UNION ALL Movimentação de NF (Nota fisca de Serviço) 
	  Não é Nota fiscal Eletrónica
*/



SELECT DISTINCT   
	COALESCE(CL.DESCR_GRUPO_CLIENTE,cast(MONF.CONSIGNATARIO as char)) AS CLIENTE_GRUPO
	,( CASE WHEN MONF.DT_ENTREGA is NOT null THEN
		   (DATEDIFF(dd,MONF.PREVISAO_ENTREGA ,  DT_ENTREGA) )
		  -(DATEDIFF(wk, MONF.PREVISAO_ENTREGA,  DT_ENTREGA) * 2)
		  -(CASE WHEN DATEPART(dw, MONF.PREVISAO_ENTREGA) = 1 THEN 1 ELSE 0 END)
		  -(CASE WHEN DATEPART(dw,  DT_ENTREGA) = 7 THEN 1 ELSE 0 END)
	ELSE
		   (DATEDIFF(dd,MONF.PREVISAO_ENTREGA ,  GETDATE()) )
		  -(DATEDIFF(wk, MONF.PREVISAO_ENTREGA,  GETDATE()) * 2)
		  -(CASE WHEN DATEPART(dw, MONF.PREVISAO_ENTREGA) = 1 THEN 1 ELSE 0 END)
		  -(CASE WHEN DATEPART(dw,  GETDATE()) = 7 THEN 1 ELSE 0 END)
	END) as dias_Atazo
  ,( CASE WHEN MONF.DT_ENTREGA is null THEN 
			(CASE WHEN (DATEDIFF(dd,MONF.PREVISAO_ENTREGA ,  GETDATE()) ) < 0 THEN 'EM ABERTO'  ELSE 'EM ATRASO' END) 
	ELSE
			(CASE WHEN (DATEDIFF(dd,MONF.PREVISAO_ENTREGA ,  GETDATE()) ) < 0 THEN 'NO PRAZO'  ELSE 'ATRASADO' END) 
   END) AS STATUS_ENTREGA
  , MONF.*  
	 FROM 
(
SELECT DISTINCT
	  O.DATA_OCORRENCIA			
	, (CASE WHEN O.RESPONSAVEL IS NULL THEN 'NÃO TRATADO'ELSE O.DESCRICAO_OCOR END) AS  OCORRENICIA
	, O.CODIGO_OCOR
	, O.RESPONSAVEL AS RESPONSAVEL_OCOR
	, M.*	
FROM 	tb_solid_ocorrencias AS O						
	right JOIN 		tb_dados_movimento_custo_emis AS M				
	ON 	concat(cast(O.NR_ENTRADA as CHAR) ,   o.SIGLA_FIL) =	concat(cast(M.NR_ENTRADA as char) , m.SIGLA_FIL)						
	WHERE						
	M.TIPO_DOC = 'CO'									
	AND
	M.DT_EMISSAO >= '20200101'	
		AND
	O.RESPONSAVEL !=  'AUTOMATICO'
	AND
	O.DATA_OCORRENCIA = 						
	(	SELECT  	MAX(ODM.DATA_OCORRENCIA)				
		FROM	tb_solid_ocorrencias AS ODM				
			INNER JOIN 		tb_dados_movimento_custo_emis AS MDM					
			ON 	concat(cast(ODM.NR_ENTRADA as CHAR) ,   ODM.SIGLA_FIL) =	concat(cast(MDM.NR_ENTRADA as char) , MDM.SIGLA_FIL)				
			WHERE				
			MDM.TIPO_DOC = 	'CO'	
			AND				
			ODM. NR_ENTRADA = 	O. NR_ENTRADA	
			AND				
			ODM.SIGLA_FIL =		O.SIGLA_FIL 
			AND
			MDM.DT_EMISSAO  >= 	'20200101'
			AND
		    ODM.RESPONSAVEL != 'AUTOMATICO'
	)				
UNION ALL	
SELECT  	NULL, 	NULL, 	NULL, Null,  MNF.*				
FROM	tb_dados_movimento_custo_emis AS MNF						
	WHERE						
	TIPO_DOC = 'NF'				
	AND						
	MNF.DT_EMISSAO >= '20200101'					
) MONF
LEFT JOIN tb_solid_dados_cliente AS CL
ON  MONF.CGC_CONSIG = CL.CGC

ORDER BY MONF.DATA_OCORRENCIA