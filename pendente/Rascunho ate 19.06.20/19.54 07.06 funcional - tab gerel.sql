SELECT  DISTINCT
 (CASE WHEN CL.DESCR_GRUPO_CLIENTE = '' THEN MONF.CONSIGNATARIO ELSE
	(CASE WHEN CL.DESCR_GRUPO_CLIENTE IS NULL THEN MONF.CONSIGNATARIO ELSE
	CL.DESCR_GRUPO_CLIENTE
	END)
	END) AS CLIENTE_GRUPO, 
(CASE WHEN MONF.DT_ENTREGA is NOT null THEN 
(DATEDIFF(dd,MONF.PREVISAO_ENTREGA ,  DT_ENTREGA) ) 
-(DATEDIFF(wk, MONF.PREVISAO_ENTREGA,  DT_ENTREGA) * 2) 
-(CASE WHEN DATEPART(dw, MONF.PREVISAO_ENTREGA) = 1 THEN 1 ELSE 0 END) 
-(CASE WHEN DATEPART(dw,  DT_ENTREGA) = 7 THEN 1 ELSE 0 END) 
ELSE 
(DATEDIFF(dd,MONF.PREVISAO_ENTREGA ,  GETDATE())) 
-(DATEDIFF(wk, MONF.PREVISAO_ENTREGA,  GETDATE()) * 2) 
-(CASE WHEN DATEPART(dw, MONF.PREVISAO_ENTREGA) = 1 THEN 1 ELSE 0 END) 
-(CASE WHEN DATEPART(dw,  GETDATE()) = 7 THEN 1 ELSE 0 END) 	END) as DIAS_ATRASO, 
(CASE WHEN MONF.DT_ENTREGA is null THEN 
(CASE WHEN (DATEDIFF(dd,MONF.PREVISAO_ENTREGA ,  GETDATE()) ) < 0 THEN 'EM ABERTO'  ELSE 'EM ATRASO' END) 
ELSE 
(CASE WHEN (DATEDIFF(dd,MONF.PREVISAO_ENTREGA ,  GETDATE()) ) < 0 THEN 'NO PRAZO'  ELSE 'ATRASADO' END) 
END) AS STATUS_ENTREGA
,GETDATE() AS ATUALIZACAO_PAINEL
,MONF.* 
FROM  (
SELECT DISTINCT 
O.DATA_OCORRENCIA, 
(CASE 
WHEN O.RESPONSAVEL = 'AUTOMATICO' THEN 'SEM ACOMPANHAMENTO' 
WHEN O.RESPONSAVEL IS NULL THEN 'SEM ACOMPANHAMENTO' 
ELSE 'COM ACOMPANHAMENTO' END) AS  OCORRENCIA 
, O.CODIGO_OCOR, (CASE 
 WHEN O.FALHA_CLIENTE = 'S' THEN 'CLIENTE' 
 WHEN O.FALHA_OPERACIONAL = 'S' THEN 'TSV'
 WHEN O.CODIGO_OCOR =1 AND M.DT_ENTREGA IS NULL THEN 'SISTEMA' ELSE 'INDEFINIDO' END) AS RESPONSABILIDADE
 , O.DESCRICAO_OCOR
, M.*	 FROM 	tb_dados_movimento_custo_emis AS M	
LEFT JOIN 	tb_solid_ocorrencias AS O	
ON 	concat(cast(M.NR_ENTRADA as char) , M.SIGLA_FIL) = concat(cast(O.NR_ENTRADA as CHAR), O.SIGLA_FIL)
WHERE
M.TIPO_DOC = 'CO'
AND M.DT_EMISSAO >= '20180101' 	
AND O.DATA_OCORRENCIA = 
(SELECT 
COALESCE(MAX(ODM.DATA_OCORRENCIA),
(SELECT 
MAX(ODM2.DATA_OCORRENCIA)	
FROM tb_solid_ocorrencias AS ODM2
WHERE
ODM2. NR_ENTRADA = 	O. NR_ENTRADA
AND	ODM2.SIGLA_FIL =	O.SIGLA_FIL)) 
FROM tb_solid_ocorrencias AS ODM
WHERE ODM. NR_ENTRADA = O. NR_ENTRADA
AND	ODM.SIGLA_FIL =	O.SIGLA_FIL
AND ODM.RESPONSAVEL != 'AUTOMATICO') 
UNION ALL
SELECT  NULL,NULL, 	NULL, NULL,NULL,  MNF.*
FROM	tb_dados_movimento_custo_emis AS MNF 
WHERE 
TIPO_DOC = 'NF'	
AND	MNF.DT_EMISSAO >= '20180101') MONF 
LEFT JOIN tb_solid_dados_cliente AS CL ON  MONF.CGC_CONSIG = CL.CGC