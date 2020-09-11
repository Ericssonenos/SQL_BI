/*
O = Dabela de Ocorrências
M = Dabela de Movimentação
ODM = Dabela de Ocorrências Data Máxima
MDM = Dabela de Movimentação Data Máxima 
*/

SELECT  	DISTINCT		TOP 50	O.DATA_OCORRENCIA,			
	O.DESCRICAO_OCOR,			O.CODIGO_OCOR,		M.*	
FROM 	tb_solid_ocorrencias AS O						
	LEFT JOIN 		tb_dados_movimento_custo_emis AS M				
	ON 	concat(cast(O.NR_ENTRADA as NCHAR) ,  + o.SIGLA_FIL) =	concat(cast(M.NR_ENTRADA as nchar) , m.SIGLA_FIL)						
	WHERE						
	M.TIPO_DOC = 'CO'									
	AND

	O.DATA_OCORRENCIA = 						
	(	SELECT  	MAX(ODM.DATA_OCORRENCIA)				
		FROM	tb_solid_ocorrencias AS ODM				
			INNER JOIN 		tb_dados_movimento_custo_emis AS MDM					
			ON 	concat(cast(ODM.NR_ENTRADA as NCHAR) ,  + ODM.SIGLA_FIL) =	concat(cast(MDM.NR_ENTRADA as nchar) , MDM.SIGLA_FIL)				
			WHERE				
			MDM.TIPO_DOC = 			'CO'	
			AND				
			ODM. NR_ENTRADA = 		O. NR_ENTRADA	
			AND				
			ODM.SIGLA_FIL =			O.SIGLA_FIL

	)				
	
UNION ALL	

SELECT	NULL, 	NULL, 	NULL,  MNF.*				
FROM	tb_dados_movimento_custo_emis AS MNF						
	WHERE						
	TIPO_DOC =		'NF'				
	ORDER BY M.DT_EMISSAO DESC