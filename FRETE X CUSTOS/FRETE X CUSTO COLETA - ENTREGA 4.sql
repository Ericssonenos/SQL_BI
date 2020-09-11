select
NUM_CONTRATO ,
FIL_CONTRATO,
cast(DATA_PAGAMENTO as date) dataP ,
TIPO_CONTRATO,
PLACA_PRINCIPAL,
cast(SUM(VALOR_CONTRATO) as float) valor,
coleta,
entrega,
cast((peso_coleta)as float) peso_col,
cast((peso_entrega)as float) peso_ent,
cast((frete_coleta)as float) frete_col,
cast((frete_entrega)as float) frete_ent,
'DISTRIBUICAO' tipo 
from tb_valores_contrato_custo vcc with(nolock) 	

	outer apply (select 
						 sum((case when rpd.vl_rat_ponto >= 1 then 1 else 0 end)) ponto 		
						,sum((case when rpd.vl_rat_peso >= 1 then 1 else 0 end))  peso
						,sum((case when rpd.ds_tipo = 'COLETA' then 1 else 0 end)) coleta
						,sum((case when rpd.ds_tipo = 'ENTREGA' then 1 else 0 end)) entrega 
				from tb_rel_romaneio_prop_dados rpd  with(nolock) 		
				where   
						rpd.NUM_CONTRATO = vcc.NUM_CONTRATO 
						and  rpd.FIL_CONTRATO = vcc.FIL_CONTRATO  		
						and  rpd.pagamento = cast(vcc.DATA_PAGAMENTO as date)
						and rpd.DESCR_TIPO_PAGTO = vcc.DESCR_TIPO_PAGTO) dd

	outer apply (select  
						sum((case when rpd.ds_tipo = 'COLETA' then  nr_peso_rel else 0 end)) peso_coleta 
						,sum((case when rpd.ds_tipo = 'ENTREGA' then nr_peso_rel else 0 end)) peso_entrega 	
				from tb_rel_romaneio_prop_dados rpd  with(nolock) 	
				where
					rpd.NUM_CONTRATO = vcc.NUM_CONTRATO and  rpd.FIL_CONTRATO = vcc.FIL_CONTRATO  		
					and  rpd.pagamento = cast(vcc.DATA_PAGAMENTO as date)  
					and rpd.DESCR_TIPO_PAGTO =  						
						(select top 1 DESCR_TIPO_PAGTO  						 
							from tb_rel_romaneio_prop_dados ppT  with(nolock) 
							where 
									ppT.NUM_CONTRATO = rpd.NUM_CONTRATO 
									and ppT.FIL_CONTRATO = rpd.FIL_CONTRATO
									and ppT.pagamento = rpd.pagamento
									and vl_rat_peso > 0   )) pp  
	outer apply (select  
						sum((case when rpd.ds_tipo = 'COLETA' then  FRETE else 0 end)) frete_coleta 		
						,sum((case when rpd.ds_tipo = 'ENTREGA' then FRETE else 0 end)) frete_entrega
						from tb_rel_romaneio_prop_dados rpd with(nolock)
						inner join tb_dados_movimento_custo_emis dmc with(nolock)
						on dmc.NR_ENTRADA = rpd.NR_ENTRADA and dmc.SIGLA_FIL = rpd.SIGLA_FIL
						where 
							rpd.NUM_CONTRATO = vcc.NUM_CONTRATO 
							and  rpd.FIL_CONTRATO = vcc.FIL_CONTRATO
							and  rpd.pagamento = cast(vcc.DATA_PAGAMENTO as date)  
							and rpd.DESCR_TIPO_PAGTO = 
														(select top 1 DESCR_TIPO_PAGTO
															from tb_rel_romaneio_prop_dados ppT  with(nolock)
															where 
																ppT.NUM_CONTRATO = rpd.NUM_CONTRATO 
																and ppT.FIL_CONTRATO = rpd.FIL_CONTRATO
																and ppT.pagamento = rpd.pagamento  
																and vl_rat_peso > 0   
														)  
				) frete
 where DATA_PAGAMENTO  > '20200101' and DEB_CRED_TIPO_PAGTO = 'C'  and DESCR_TIPO_PAGTO != 'TOTALBRUTO'    
 
 group by NUM_CONTRATO , FIL_CONTRATO ,  cast(DATA_PAGAMENTO as date) , TIPO_CONTRATO ,  PLACA_PRINCIPAL ,coleta , entrega, peso_coleta,peso_entrega,frete.frete_coleta , frete.frete_entrega  	union   select rdc.NRO_ROMANEIO_REDESPACHO, rdc.SIGLA_FIL_ROM_REDESP , rdc.DT_EMISS_ROM_RED, 'RED-' + rdc.TIPO_MANIFESTO , vRed.RAZAO 'placa'    ,  cast(sum(cast(replace(rdc.FRETE_RESPACHO,',','.') as numeric(18,6))) as float) 	, cast(sum((case when rdc.TIPO_MANIFESTO = 'COLETA' then 1 else 0 end))	 as float) 	, cast(sum((case when rdc.TIPO_MANIFESTO = 'COLETA' then 0 else 1 end)) as float) 	, cast(sum((case when rdc.TIPO_MANIFESTO = 'COLETA' then nr_peso_rel else 0 end)) as float) 	, cast(sum((case when rdc.TIPO_MANIFESTO = 'COLETA' then 0 else nr_peso_rel end)) as float) 	, cast(sum((case when rdc.TIPO_MANIFESTO = 'COLETA' then FRETE else 0 end)) as float) 	, cast(sum((case when rdc.TIPO_MANIFESTO = 'COLETA' then 0 else FRETE end)) as float) 	, 'REDESPACHO' tipo  from tb_dados_movimento_custo_emis cte inner join tb_dados_rom_redesp_custo_emi   rdc on cte.NR_ENTRADA = rdc.NR_ENTRADA and cte.SIGLA_FIL  = rdc.SIGLA_FIL  inner join tb_valores_redespacho_custo_em vRed on vRed.NUM_ROM_REDESP = rdc.NRO_ROMANEIO_REDESPACHO and vRed.FILIAL_ROMANEIO = rdc.SIGLA_FIL_ROM_REDESP  													and cte.NR_ENTRADA = vRed.NR_ENTRADA and cte.SIGLA_FIL  = vRed.SIGLA_FIL  where rdc.DT_EMISS_ROM_RED  > '20200101' group by rdc.NRO_ROMANEIO_REDESPACHO, rdc.SIGLA_FIL_ROM_REDESP , rdc.DT_EMISS_ROM_RED,  rdc.TIPO_MANIFESTO , vRed.RAZAO