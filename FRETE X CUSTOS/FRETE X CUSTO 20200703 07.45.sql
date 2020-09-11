/* 
	Tabelas
	 -> VCC - Tb_valores_contrato_custo: Custos de distribuição e coleta
	 -> DRECE - tb_dados_rom_entrega_custo_em: Romaneio de Entrega -> 

*/

SELECT ( CASE
		WHEN v.DEB_CRED_TIPO_PAGTO = 'D' THEN v.VALOR_CONTRATO *-1
		ELSE v.VALOR_CONTRATO
		END) AS VALOR_CONTRATO_2, v.* FROM tb_valores_contrato_custo v
		WHERE V.DT_EMIS_CONTRATO between '20200501' and '20200531'
		and V.FIL_CONTRATO = 'RIO'

/**/

select DISTINCT
	 VCC.DESCR_TIPO_PAGTO
	,VCC.DEB_CRED_TIPO_PAGTO
	,VCC.DT_EMIS_CONTRATO
	,VCC.FIL_CONTRATO
	,VCC.NUM_CONTRATO
	,VCC.PLACA_PRINCIPAL
	,( CASE
		WHEN VCC.DEB_CRED_TIPO_PAGTO = 'D' THEN VCC.VALOR_CONTRATO *-1
		ELSE VCC.VALOR_CONTRATO
		END) AS VALOR_CONTRATO
	,( CASE
		WHEN VCC.DEB_CRED_TIPO_PAGTO = 'C' THEN (Frete_Cte.NUM_DOCs/VCC_COUNT.QTD_DEB_CRED_TIPO_PAGTO)
		ELSE 0 
		END) AS NUM_DOCs_RATEIO
	,( CASE
		WHEN VCC.DEB_CRED_TIPO_PAGTO = 'C' THEN (Frete_Cte.FRETE/VCC_COUNT.QTD_DEB_CRED_TIPO_PAGTO) 
		END) AS FRETE_RATEIO 
	,Frete_Cte.FRETE,QTD_DEB_CRED_TIPO_PAGTO
	FROM
		(
			select DISTINCT  dmce.NUM_CONTRATO, DMCE.FIL_CONTRATO ,count(DMCE.NUM_DOC) as NUM_DOCs, sum(DRECE.frete) as FRETE from tb_dados_rom_coleta_custo_emis  as DMCE
			left  JOIN
			tb_dados_movimento_custo_emis DRECE
			ON DMCE.NR_ENTRADA = DRECE.NR_ENTRADA AND DMCE.SIGLA_FIL = DRECE.SIGLA_FIL
			group by 
			 dmce.NUM_CONTRATO, DMCE.FIL_CONTRATO 
		) as Frete_Cte
		 inner JOIN
		(SELECT DISTINCT DESCR_TIPO_PAGTO, DEB_CRED_TIPO_PAGTO, DT_EMIS_CONTRATO, PLACA_PRINCIPAL, FIL_CONTRATO ,NUM_CONTRATO, sum(VALOR_CONTRATO) as VALOR_CONTRATO FROM  Tb_valores_contrato_custo WHERE DESCR_TIPO_PAGTO != 'TOTALBRUTO' group by DESCR_TIPO_PAGTO, DEB_CRED_TIPO_PAGTO, DT_EMIS_CONTRATO, PLACA_PRINCIPAL, FIL_CONTRATO ,NUM_CONTRATO) AS VCC
			ON Frete_Cte.NUM_CONTRATO  = VCC.NUM_CONTRATO AND Frete_Cte.FIL_CONTRATO = VCC.FIL_CONTRATO
		inner join 
		(SELECT DISTINCT  FIL_CONTRATO ,NUM_CONTRATO, COUNT(distinct DESCR_TIPO_PAGTO) QTD_DEB_CRED_TIPO_PAGTO   FROM  Tb_valores_contrato_custo WHERE DESCR_TIPO_PAGTO != 'TOTALBRUTO' and DEB_CRED_TIPO_PAGTO = 'C' group by FIL_CONTRATO ,NUM_CONTRATO) AS VCC_COUNT
			ON Frete_Cte.NUM_CONTRATO  = VCC_COUNT.NUM_CONTRATO AND Frete_Cte.FIL_CONTRATO = VCC_COUNT.FIL_CONTRATO
		WHERE VCC.DT_EMIS_CONTRATO between '20200501' and '20200531'
		and VCC.FIL_CONTRATO = 'RIO'
	
	select * 
	from tb_dados_movimento_custo_emis dmc
	left join tb_dados_rom_coleta_custo_emis drc on drc.NR_ENTRADA = dmc.NR_ENTRADA and dmc.SIGLA_FIL = drc.SIGLA_FIL
	where drc.COD_DADOS_ROM_COLETA_CUSTO_EMIS is null
