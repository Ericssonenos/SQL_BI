SELECT
		 DIA05."DIAS",
		 (		SELECT sum("FRETE")
		FROM  "002_BD" 
		WHERE	 MONTH(TODAY())  = MONTH("DT_EMISSAO")
		 AND	YEAR(TODAY())  = YEAR("DT_EMISSAO")
)/ (business_days(start_day(month, today()), today()) + 1) AS RATEIO,
		 PEND.FRETE
FROM  "005_Dias" AS  DIA05
LEFT JOIN(	SELECT
			 "Day_Job_Emissao",
			 SUM(FRETE) AS FRETE
	FROM  "002_BD" 
	WHERE	 MONTH(TODAY())  = MONTH("DT_EMISSAO")
	 AND	YEAR(TODAY())  = YEAR("DT_EMISSAO")
	GROUP BY "Day_Job_Emissao"
) AS  PEND ON PEND."Day_Job_Emissao"  = DIA05."DIAS"  
WHERE	 DIA05."DIAS"  <= business_days(start_day(month, today()), end_day(month, today()))
