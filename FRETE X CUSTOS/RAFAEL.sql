select NUM_CONTRATO , FIL_CONTRATO, cast(DATA_PAGAMENTO as date) dataP , TIPO_CONTRATO ,  PLACA_PRINCIPAL 
, cast(SUM(VALOR_CONTRATO) as float) valor,coleta , entrega ,  cast((peso_coleta)as float) peso_col,  cast((peso_entrega)as float) peso_ent
,  cast((frete_coleta)as float) frete_col,  cast((frete_entrega)as float) frete_ent   
from tb_valores_contrato_custo vcc
outer apply (select sum((case when rpd.vl_rat_ponto >= 1 then 1 else 0 end)) ponto
				,sum((case when rpd.vl_rat_peso >= 1 then 1 else 0 end)) peso
				,sum((case when rpd.ds_tipo = 'COLETA' then 1 else 0 end)) coleta
				,sum((case when rpd.ds_tipo = 'ENTREGA' then 1 else 0 end)) entrega
			 from tb_rel_romaneio_prop_dados rpd 
			 where rpd.NUM_CONTRATO = vcc.NUM_CONTRATO and  rpd.FIL_CONTRATO = vcc.FIL_CONTRATO 
			  and  rpd.pagamento = cast(vcc.DATA_PAGAMENTO as date) and rpd.DESCR_TIPO_PAGTO = vcc.DESCR_TIPO_PAGTO) dd

outer apply (select  sum((case when rpd.ds_tipo = 'COLETA' then  nr_peso_rel else 0 end)) peso_coleta
					,sum((case when rpd.ds_tipo = 'ENTREGA' then nr_peso_rel else 0 end)) peso_entrega
			 from tb_rel_romaneio_prop_dados rpd 
			 where rpd.NUM_CONTRATO = vcc.NUM_CONTRATO and  rpd.FIL_CONTRATO = vcc.FIL_CONTRATO 
			  and  rpd.pagamento = cast(vcc.DATA_PAGAMENTO as date)  and rpd.DESCR_TIPO_PAGTO = 
					(select top 1 DESCR_TIPO_PAGTO 
					 from tb_rel_romaneio_prop_dados ppT 
					 where ppT.NUM_CONTRATO = rpd.NUM_CONTRATO and ppT.FIL_CONTRATO = rpd.FIL_CONTRATO 
			    and ppT.pagamento = rpd.pagamento    and vl_rat_peso > 0   )) pp

outer apply (select  sum((case when rpd.ds_tipo = 'COLETA' then  FRETE else 0 end)) frete_coleta
					,sum((case when rpd.ds_tipo = 'ENTREGA' then FRETE else 0 end)) frete_entrega
			 from tb_rel_romaneio_prop_dados rpd 
			 inner join tb_dados_movimento_custo_emis dmc on dmc.NR_ENTRADA = rpd.NR_ENTRADA and dmc.SIGLA_FIL = rpd.SIGLA_FIL
			 where rpd.NUM_CONTRATO = vcc.NUM_CONTRATO and  rpd.FIL_CONTRATO = vcc.FIL_CONTRATO 
			  and  rpd.pagamento = cast(vcc.DATA_PAGAMENTO as date)   ) frete

where year(DATA_PAGAMENTO)  = 2020 and   month(DATA_PAGAMENTO) = 5 and DEB_CRED_TIPO_PAGTO = 'C'  
 
group by NUM_CONTRATO , FIL_CONTRATO , DATA_PAGAMENTO , TIPO_CONTRATO ,  PLACA_PRINCIPAL ,coleta , entrega, peso_coleta,peso_entrega,frete.frete_coleta , frete.frete_entrega