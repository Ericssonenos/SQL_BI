select cte.NUM_DOC , cte.SIGLA_FIL , cte.DT_EMISSAO , cte.SIGLA_FIL_DEST, cte.FRETE,  rdc.FRETE_RESPACHO redespacho , rdc.SIGLA_FIL_ROM_REDESP , rdc.TIPO_MANIFESTO , vRed.RAZAO 'placa', 'REDESPACHO' AS TIPO
from tb_dados_movimento_custo_emis cte
inner join tb_dados_rom_redesp_custo_emi   rdc on cte.NR_ENTRADA = rdc.NR_ENTRADA and cte.SIGLA_FIL  = rdc.SIGLA_FIL 
inner join tb_valores_redespacho_custo_em vRed on vRed.NUM_ROM_REDESP = rdc.NRO_ROMANEIO_REDESPACHO and vRed.FILIAL_ROMANEIO = rdc.SIGLA_FIL_ROM_REDESP
where cte.DT_EMISSAO >= '20200701'

/*
 rdc.DT_EMISS_ROM_RED > ''
*/