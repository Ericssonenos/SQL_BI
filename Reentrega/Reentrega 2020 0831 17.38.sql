
       SELECT DISTINCT REENTREGAS.*
	   , SAIDAS -(CASE WHEN REENTREGAS.ecomerce = 'SIM'THEN 3 ELSE 1 END) as Saida_DESP
	   ,(SAIDAS -(CASE WHEN REENTREGAS.ecomerce = 'SIM'THEN 3 ELSE 1 END)) * REENTREGAS.FRETE as FRETE_DESP
	   FROM
			(
				select 
					cte.FIL_CONTRATO
					,cte.NUM_DOC
					,cte.PREVISAO_ENTREGA
					,CTE.FRETE
					,cte.ecomerce
					, COUNT(CTE.NUM_DOC) AS SAIDAS
					, COUNT(CTE.NUM_DOC) -1 as REENTREGAS
					, max(DT_EMISS_ROM_ENT) Ultima_entrega
					,AVG(cte.cont_cliente) as Ocors_Cliente
					,avg(CTE.cont_Operacional) as Ocors_Operacional
				from 
				(
						SELECT DISTINCT DMC02.CONSIGNATARIO, 
										DMC02.SIGLA_FIL, 
										DMC02.NR_ENTRADA, 
										CONCAT( DMC02.SIGLA_FIL,' ', cast(DMC02.NUM_DOC as char)) AS NUM_DOC,
										DRECE3.DT_EMISS_ROM_ENT ,  
										VCC.PLACA_PRINCIPAL, 
										VCC.NOME_MOT , 
										vcc.FIL_CONTRATO, 
										DMC02.PREVISAO_ENTREGA, 
										FRETE, 
										cont_cliente ,cont_Operacional ,
										(CASE WHEN CONSIGNATARIO in(
							'FRIOVIX COM REFRIGERACAO LTDA', 
							'FAST SHOP SA', 
							'FRIGELAR COMERCIO E INDUSTRIA LTDA', 
							'ELETRORARO COMERCIO DE ELETRO-DOMESTICO EIRELLE', 
							'COMERCIAL PENA E LOPES LTDA', 
							'IRMAOS MUFFATO CIA LTDA', 
							'A ANGELONI CIA LTDA ', 
							'FERTAK', 
							'CGW BRASIL', 
							'GOLDEN (SERRA)', 
							'COPY SUPPLY MATRIZ', 
							'ATIVA (GRUPO COPY SUPPLY)', 
							'JSB SINALIZAÇÃO', 
							'KAMELL', 
							'TOTAL FILTROS', 
							'BRAZIT', 
							'CAIXOT IN', 
							'VILA ERVAS', 
							'M GERAIS', 
							'DOG 27', 
							'4 BIS', 
							'OMQF ', 
							'TONIELQUE', 
							'CASA TEMA ', 
							'CABICEIRA ', 
							'GAVETEIRO ', 
							'CENTRAL DO FRETE ', 
							'MAIS BARRATO ', 
							'CIA MAIS ', 
							'CARREGO ', 
							'CHD', 
							'CS2 ', 
							'Colchoes Orthovida', 
							'Web compras', 
							'IMATEB', 
							'LOJAS SIMONET', 
							'EBBA MOVEIS', 
							'UNIAR COM DE ELETRO-ELETRONICOS E SERVICOS', 
							'UNIAR COMERCIO DE ELETRO-ELETRONICOS E SERVICOS LT', 
							'LGF COMERCIO ELETRONICO LTDA', 
							'FIDOTI TRANSPORTES TAPECARIA E DECORACOES LTDA', 
							'INOVAKASA COM DE MOVEIS LTDA', 
							'INOVAKASA COMERCIO DE MOVEIS LTDA', 
							'CADEIRAS DESIGN.COM LTDA-ME', 
							'JOAO BATISTA DA SILVA', 
							'M P S DISTRIBUIDORA MERCANTIL LTDA', 
							'PRIVALIA SERVICOS DE INFORMACAO LTDA'
							) THEN 'SIM' ELSE 'NÃO'END) AS ecomerce
								FROM   tb_dados_movimento_custo_emis  AS DMC02  with(nolock) 
							INNER JOIN 
								(SELECT DISTINCT SO01.NR_ENTRADA, SO01.SIGLA_FIL, count(case when SO01.FALHA_CLIENTE = 'S' then 1 else null end) as cont_cliente, count(case when SO01.FALHA_OPERACIONAL = 'S' then 1 else null end) as cont_Operacional   FROM tb_solid_ocorrencias AS SO01  with(nolock)
														group by  SO01.NR_ENTRADA, SO01.SIGLA_FIL
														
								) AS SO03 
							ON DMC02.NR_ENTRADA = SO03.NR_ENTRADA AND DMC02.SIGLA_FIL = SO03.SIGLA_FIL
	
						INNER JOIN
							( SELECT DISTINCT DRECE2.NR_ENTRADA,DRECE2.SIGLA_FIL, NUM_CONTRATO, FIL_CONTRATO , DT_EMISS_ROM_ENT FROM tb_dados_rom_entrega_custo_em DRECE2  with(nolock)  ) AS DRECE3
							ON DMC02.NR_ENTRADA = DRECE3.NR_ENTRADA AND DMC02.SIGLA_FIL = DRECE3.SIGLA_FIL
						LEFT JOIN
							(SELECT DISTINCT  PLACA_PRINCIPAL, FIL_CONTRATO ,NUM_CONTRATO , NOME_MOT ,VALOR_CONTRATO  FROM Tb_valores_contrato_custo  with(nolock)) AS VCC
							ON DRECE3.NUM_CONTRATO  = VCC.NUM_CONTRATO AND DRECE3.FIL_CONTRATO = VCC.FIL_CONTRATO
				 ) as CTE
				group by 
					 cte.FIL_CONTRATO
					,CTE.NUM_DOC
					,cte.PREVISAO_ENTREGA
					,CTE.FRETE
					,cte.ecomerce
					having  COUNT(CTE.NUM_DOC) > (CASE WHEN ecomerce = 'SIM'THEN 3 ELSE 1 END) and  max(DT_EMISS_ROM_ENT) > DATEADD(DD,-5,GETDATE())
			) AS REENTREGAS



