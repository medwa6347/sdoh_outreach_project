 /*----------------------------------------------------------------*\
 | REPORTING FORMATS												|
 | AUTHOR: MICHAEL W EDWARDS 2019-04-19 AMDG                        |
 \*----------------------------------------------------------------*/													
/**/

proc format; 
 	value mbr_rpt_age_fmt												low-<18				= '001_Less than 18'	  
 																		18-29   			= '002_18 to 29'
 																		30-39   			= '003_30 to 39'
 																		40-49   			= '004_40 to 49'
 																		50-59   			= '005_50 to 59'
 																		60-69   			= '006_60 to 69'
 																		70-79   			= '007_70 to 79' 																								
 																		80-high 			= '008_80+'
 																		other				= '999_Other/Unknown';	
	value score_grp_fmt													low-<0.15			= '001_Low'
																		0.15-<0.2			= '002_Low_Medium'																		
																		0.2-<0.25			= '003_Medium'
																		0.25-high			= '004_High'                                                
                                    									other				= '000_Member Not Scored';
run;

/*-----------------------------------------------------------------*/
/*---> CREATE CUSTOM TEMPLATES FOR CHARTS AND EXCEL OUTPUTS <------*/
/**/

	* APPLIES TO PROC GPLOT/GCHART OUTPUTS;
	ods path(prepend) work.templat(update);
	proc format;
	   picture pctfmt (round) 0-high='000%';
	run;	
	* APPLIES TO ODS EXCEL PROC PRINT OUTPUTS;
	ods path(prepend) work.templat(update);
	proc template;
		define style styles.XLsansPrinter; 						/* <== DECLARE EXCEL STYLE TO APPLY TO ALL EXCEL OUTPUTS.   */
			parent = styles.sansPrinter;      											
			class systemtitle /               											
			fontsize = 10pt;									/* <== FONT FOR TITLE STMTS AND PROC PRINT OUTPUTS */
			style header from header /        					
			foreground = cxFFFFFF								/* <== HEXIDECIMAL COLOR CODES TO CUSTOMIZE CELL FILLS FOR HEADERS */
			background = cx63666A;                         
	end; run;	