SELECT * FROM dbo.tb_dados_movimento_custo_emis
WHERE DT_EMISSAO = '20200101' 
AND 
TIPO_DOC = 'CO'
OR
TIPO_DOC = 'NF'