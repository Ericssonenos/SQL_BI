
SELECT DISTINCT 
SAC.nm_usuario
,(CASE WHEN DAY(MONFCL.DT_EMISSAO) < DAY(GETDATE())  THEN 'ATIVO' ELSE 'DESATIVO'END) AS MESES_COM
,(CASE WHEN DAY(MONFCL.DT_EMISSAO) < DAY(GETDATE()) AND MONTH(MONFCL.DT_EMISSAO) <= MONTH(GETDATE()) THEN 'ATIVO' ELSE 'DESATIVO'END) AS ANOS_COM
, MONFCL.* FROM 
(
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
(CASE WHEN (DATEDIFF(dd,MONF.PREVISAO_ENTREGA ,  GETDATE()) ) <= 0 THEN 'EM ABERTO'  ELSE 'EM ATRASO' END) 
ELSE 
(CASE WHEN (DATEDIFF(dd,MONF.PREVISAO_ENTREGA ,  GETDATE()) ) <= 0 THEN 'NO PRAZO'  ELSE 'ATRASADO' END) 
END) AS STATUS_ENTREGA
,GETDATE() AS ATUALIZACAO_PAINEL
,MONF.* 
FROM  (
SELECT DISTINCT 
O.DATA_OCORRENCIA, 
(CASE 
WHEN O.RESPONSAVEL = 'AUTOMATICO' THEN 'SEM ACOMPANHAMENTO' 
WHEN O.RESPONSAVEL IS NULL THEN 'SEM ACOMPANHAMENTO' 
ELSE 'COM ACOMPANHAMENTO' END) AS  ACOMPANHAMENTO 
, O.CODIGO_OCOR, (CASE 
 WHEN O.CODIGO_OCOR =1 AND M.DT_ENTREGA IS NULL THEN 'SISTEMA'
 WHEN YEAR(M.PREVISAO_ENTREGA) = 1900 THEN 'TABELA'
 WHEN O.FALHA_CLIENTE = 'S' THEN 'CLIENTE' 
 WHEN O.FALHA_OPERACIONAL = 'S' THEN 'OPERACIONAL'
 ELSE 'INDEFINIDO' END) AS RESPONSABILIDADE
 , O.DESCRICAO_OCOR
, M.*	 FROM 	tb_dados_movimento_custo_emis AS M	
LEFT JOIN 	tb_solid_ocorrencias AS O	
ON 	concat(cast(M.NR_ENTRADA as char) , M.SIGLA_FIL) = concat(cast(O.NR_ENTRADA as CHAR), O.SIGLA_FIL)
WHERE
M.TIPO_DOC = 'CO'
AND M.DT_EMISSAO >= '20200101' 	
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
AND	MNF.DT_EMISSAO >= '20200101') MONF 
LEFT JOIN tb_solid_dados_cliente AS CL ON  MONF.CGC_CONSIG = CL.CGC
where
cl.DT_INCL_CLI = 
(
SELECT MAX(TBCL.DT_INCL_CLI) FROM tb_solid_dados_cliente AS TBCL
WHERE TBCL.CGC = CL.CGC
)
) MONFCL
LEFT JOIN
(select  distinct  cli.nr_cnpj_cpf , usu.nm_usuario
from bd_portal_tsv.dbo.tb_usuario usu        
inner join bd_portal_tsv.dbo.tb_usuario_cliente uCli on uCli.id_usuario = usu.cod_user and uCli.dt_cancela is null 
inner join bd_fin_tsv.dbo.tb_cliente cli on cli.cod_cliente  = uCli.id_cliente      
where usu.fl_status = 'A' and usu.funcao = 'ATENDENTE' and usu.ds_funcao = 'A') SAC
ON MONFCL.CGC_CONSIG = SAC.nr_cnpj_cpf