CREATE FUNCTION dbo.fn_ret_notas_cte(@NR_ENTRADA_CTE INT, @SIGLA_FIL_CTE VARCHAR(MAX)) RETURNS VARCHAR(MAX) AS BEGIN
	
	DECLARE @Retorno as varchar(max)

					set  @Retorno =	(SELECT (  LTRIM(RTRIM(ISNULL(STUFF((      
                                    SELECT ', ' + CAST(nfs.NUM_NOTA_FISCAL AS VARCHAR(15))      
                                    FROM (      
                                                SELECT DISTINCT nfs.NUM_NOTA_FISCAL      
                                                FROM tb_solid_nfs_ctes AS nfs WITH(NOLOCK)      
                                                WHERE nfs.NR_ENTRADA =@NR_ENTRADA_CTE AND nfs.SIGLA_FIL = @SIGLA_FIL_CTE      
                                    ) nfs      
										ORDER BY nfs.NUM_NOTA_FISCAL FOR XML PATH ('')      
											 ), 1, 1, ''), '')))      
								 ) )  
	return @Retorno
end
	