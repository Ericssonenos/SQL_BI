/* TABELAS 

     -> tb_dados_movimento_custo_emis                             - Documentos (CT-e)
		* TIPO_DOC = 'C'
		* DT_EMISSAO >= '20200101'

	 -> tb_solid_ocorrencias                                      - Ocorrência
		*  O.DATA_OCORRENCIA = 'data maxima'
		*  O.CODIGO_OCOR = 'codigo mínimo da data máxima'
			(há ocorrências máximas exatamente no mesmo minuto)

	 ->  dbo.fn_ret_notas_cte(dmc.NR_ENTRADA,dmc.SIGLA_FIL)        - Notas agrupadas 
	    * Retorna as Nfs agrupadas

	-> tb_dados_movimento_custo_emis                               - Documentos (Nota Fiscal de serviço)
		* TIPO_DOC = 'NF'
		* DT_EMISSAO >= '20200101'

    -> tb_solid_dados_cliente                                       - Definir o Grupo do Cliente

	-> tb_dados_manifesto_custo_emis                                - Manifestos - Tranferência
		* DT_EMISSAO_MANIFESTO = 'data máxima' 
	
	-> tb_valores_redespacho_custo_em                               - Redespacho - Parceiros
		* TIPO_MANIFESTO = 'MRD'

	-> tb_dados_rom_entrega_custo_em                                - Romaneio - Distribuição

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
				
SELECT DISTINCT * FROM
	(SELECT DISTINCT  dbo.fn_ret_notas_cte(DMCE01.NR_ENTRADA, DMCE01.SIGLA_FIL) AS NOTA_AGRUP , DMCE01.* FROM   tb_dados_movimento_custo_emis AS DMCE01 WHERE DMCE01.TIPO_DOC IN('NF','CO') AND DMCE01.DT_EMISSAO >= '20200101' AND DMCE01.DT_ENTREGA IS NULL) DMC02
LEFT JOIN 
	(SELECT * FROM tb_solid_ocorrencias AS SO01 WHERE SO01.DATA_OCORRENCIA = (SELECT MAX(SO02.DATA_OCORRENCIA) FROM tb_solid_ocorrencias AS SO02 WHERE SO02.NR_ENTRADA = SO01.NR_ENTRADA AND SO02.SIGLA_FIL = SO01.SIGLA_FIL ) OR SO01.DATA_OCORRENCIA IS NULL ) AS SO03 
	ON DMC02.NR_ENTRADA = SO03.NR_ENTRADA AND DMC02.SIGLA_FIL = SO03.SIGLA_FIL
LEFT JOIN 
	(SELECT * FROM tb_dados_manifesto_custo_emis AS DMFCE01 WHERE DMFCE01.DT_EMISSAO_MANIFESTO = (SELECT MAX(DMFCE02.DT_EMISSAO_MANIFESTO) FROM tb_dados_manifesto_custo_emis AS DMFCE02 WHERE DMFCE02.NR_ENTRADA = DMFCE01.NR_ENTRADA AND DMFCE02.SIGLA_FIL = DMFCE01.SIGLA_FIL )) AS DMFCE03 
	ON DMC02.NR_ENTRADA = DMFCE03.NR_ENTRADA AND DMC02.SIGLA_FIL = DMFCE03.SIGLA_FIL
LEFT JOIN 
	(SELECT * FROM tb_valores_redespacho_custo_em WHERE TIPO_MANIFESTO = 'MRD') AS VRCE
	ON DMC02.NR_ENTRADA  = VRCE.NR_ENTRADA AND DMC02.SIGLA_FIL = VRCE.SIGLA_FIL
LEFT JOIN
	tb_dados_rom_entrega_custo_em AS DRECE
	ON DMC02.NR_ENTRADA = DRECE.NR_ENTRADA AND DMC02.SIGLA_FIL = DRECE.SIGLA_FIL
LEFT JOIN
	(SELECT DISTINCT PLACA_PRINCIPAL, FIL_CONTRATO ,NUM_CONTRATO FROM Tb_valores_contrato_custo) AS VCC
	ON DRECE.NUM_CONTRATO  = VCC.NUM_CONTRATO AND DRECE.FIL_CONTRATO = VCC.FIL_CONTRATO
LEFT JOIN 
	(SELECT * FROM tb_solid_dados_cliente AS SDC01  WHERE SDC01.DT_INCL_CLI = (SELECT MAX(SDC02.DT_INCL_CLI) FROM tb_solid_dados_cliente AS SDC02 WHERE SDC02.CGC = SDC01.CGC)) AS SDC03 
	ON DMC02.CGC_CONSIG = SDC03.CGC
LEFT JOIN 		
	(select  distinct  cli.nr_cnpj_cpf , usu.nm_usuario from bd_portal_tsv.dbo.tb_usuario usu inner join bd_portal_tsv.dbo.tb_usuario_cliente uCli on uCli.id_usuario = usu.cod_user inner join bd_fin_tsv.dbo.tb_cliente cli on cli.cod_cliente  = uCli.id_cliente where usu.fl_status = 'A' and usu.funcao = 'ATENDENTE' and usu.ds_funcao = 'A'  and uCli.dt_cancela is null ) AS SAC 	
	ON DMC02.CGC_CONSIG = SAC.nr_cnpj_cpf 
	

/*
COALESCE(SAC.nm_usuario,'SAC NORMAL') AS ATENDENTE		
*/	