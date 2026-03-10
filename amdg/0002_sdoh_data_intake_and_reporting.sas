 /*----------------------------------------------------------------*\
 | STANDALONE SDOH CAMPAIGN FOR XO - MERCK							|
 | PROGRAM 0002 - POST-CAMPAIGN SDOH DATA INTAKE					|
 | AUTHOR: MICHAEL EDWARDS 2020-08-12 AMDG                          |
 \*----------------------------------------------------------------*/													
/**/

* COMMAND LINE (USING .KSH);								
/*
cd /sasnas/ls_cs_nas/mwe/xo/merck_sdoh_202008/amdg
screen -dm -S xoa1 ./0001_xo_sdoh_shell.ksh
*/

/*-----------------------------------------------------------------*/
/*---> GLOBAL <----------------------------------------------------*/
/**/
%global person_id; %let person_id = mbi;
%util_dates(start_dt='01Jan2019'd,yr_num=1,months=12)

%macro data_clms(rdvz=,dsvz=,rpvz=,testobs=);                                                                                                                    
                                                                                                                                                                 
*IMPORT SDOH DATA MACRO;                                                                                                                                         
%macro pim_sdoh(fn_sdoh_inp=,fn_sdoh_out=);                                                                                                                      
	data &fn_sdoh_out.;                                                                                                                                             
		infile "&fn_sdoh_inp." delimiter = '|' missover dsd lrecl=32767 firstobs=2;                                                                                   
		informat mbi		                  	$12.;                                                                                                             
		informat srvc_dt                      	yymmdd10.;                                                                                                             
		informat icd_code                     	$7.;                                                                                                             
		informat icd_code_description         	$130.;                                                                                                             
		informat ref_ful					  	$3.;                                                                                                             
		informat common_name_roll_up          	$24.;                                                                                                             
		informat common_name_detail_display   	$24.;                                                                                                             
		format mbi		                       	$12.;                                                                                                             
		format srvc_dt                       	yymmdd10.;                                                                                                             
		format icd_code                      	$7.;                                                                                                             
		format icd_code_description          	$130.;                                                                                                             
		format ref_ful							$3.;                                                                                                             
		format common_name_roll_up           	$24.;                                                                                                             
		format common_name_detail_display    	$24.;                                                                                                             
		input  mbi		                       	$   	                                                                                                                  
		       srvc_dt                       	                                                                                                            
		       icd_code                      	$ 	                                                                                                                    
		       icd_code_description          	$                                                                                                                       
		       ref_ful							$   	                                                                                                                  
		       common_name_roll_up           	$		                                                                                                                    
		       common_name_detail_display    	$                                                                                                                       
		;                                                                                                                                                             
	run;                                                                                                                                                            
	/*proc contents data=_last_ order=varnum; title "QA: Raw SDoH Results Contents (&fn_sdoh_inp.)"; run;                                                           
	proc print data=_last_(obs=10); title "QA: Raw SDoH Results 10 Rows (&fn_sdoh_inp.)"; run;*/                                                                    
	proc freq data=_last_; tables common_name_detail_display common_name_roll_up; run;
%mend;                                                                                                                                                           
                                                                                                                                                                 
%pim_sdoh(fn_sdoh_inp=&om_data./02_input/merck_diab_2_202009_sdoh_v5.txt,fn_sdoh_out=t&rdvz.&dsvz.&rpvz._sdoh_raw_01);                                           
                                                                                                                                                               
*REFERRAL TYPE LOOP;                                                                                                                                             
%let commons1 = Health Services|Low Income|EducationAndEmployment|Housing|Psychosocial|Nutrition|Family Circumstances|Transportation;    
%let commons2 = Disability_Mobility|EducationAndEmployment_Education|EducationAndEmployment_Employment|Family Circumstances_Family Support|Family Circumstances_Social Isolation|Health Services_Access to Care|Health Services_Alzheimers Support|Health Services_Counseling|Health Services_Lack of Fitness|Health Services_Personal Care|Health Services_Respite Care|Health Services_Safety|Housing_Housing|Housing_Safety|Low Income_Child Care|Low Income_LIS|Low Income_Low Income|Low Income_Medical Cost|Low Income_MSP|Low Income_Necessity Cost|Low Income_Prescription Cost|Low Income_SNAP|Nutrition_Malnutrition|Nutrition_Nutrition|Psychosocial_Justice System Support|Psychosocial_Lifestyle Issues|Psychosocial_Social Environment|Psychosocial_Substance Abuse|Psychosocial_Trauma|Transportation_Transportation;
%let commons_get = &commons2.;
%let commons_1 = 0;

%let num_cm = 30;       
%let num_mo	=	9;  
%let last_mo = September;             
%let i = 1;                                                                                                                                                      
%let cn = %scan(&commons_get.,&i.,"|");                                                                                                                              
%do %while (&cn ne);                                                                                                                                             
                                                                                                                                                                 
*STAGE RAW REFERRAL DATA;                                                                                                                                        
data t&rdvz.&dsvz.&rpvz._sdoh_raw_&i.;  
	length common_get_fld $50;                                                                                                                         
	set t&rdvz.&dsvz.&rpvz._sdoh_raw_01;  
	%if &commons_1. %then common_get_fld = tranwrd(common_name_roll_up," & ","And");                                                                                                                         
									%else common_get_fld = catx('_',tranwrd(common_name_roll_up," & ","And"),tranwrd(common_name_detail_display,"'","")); ;                                                                                                                         
	/*if find(common_get_fld,"&cn.") gt 0; 	*/                                                                                                                   
run;        
   	proc freq data=_last_; tables common_name_roll_up*common_get_fld; run;
   	proc freq data=_last_; tables common_name_detail_display*common_get_fld; run;
   	proc freq data=_last_; tables common_name_detail_display common_get_fld; run;
   		
   		
endsas;                                                                                                                                                  
                                                                                                                                                                 
*TIME BETWEEN REFERRAL AND FULFILMENT;                                                                                                                           
proc sort data=t&rdvz.&dsvz.&rpvz._sdoh_raw_&i.; by &person_id. srvc_dt descending ref_ful; run;                                                                 
/*proc print data=_last_(obs=200); var &person_id. &commons_fld. srvc_dt ref_ful; title "QA: _sdoh_raw_&i. &cn."; run;*/                                   
data t&rdvz.&dsvz.&rpvz._sdoh_adj_&i.;                                                                                                                           
	length ref ful 3 ref_dt ful_dt 4 ref_2_ful 3;                                                                                                                   
	set t&rdvz.&dsvz.&rpvz._sdoh_raw_&i.;                                                                                                                           
	by &person_id.;                                                                                                                                                 
	retain ref ref_dt ful ful_dt ref_2_ful;                                                                                                                         
	if first.&person_id. then do; ref=0; fuf=0; ref_dt=0; ful_dt=0; ref_2_ful=0; end;                                                                               
	if first.&person_id. and find(lowcase(ref_ful),"ref") gt 0 then do;                                                                                             
		ref = 1;                                                                                                                                                                                                                                                                                                                      
		ful = 0;                                                                                                                                                      
		ref_dt = srvc_dt;                                                                                                                                             
	end;                                                                                                                                                            
	if find(lowcase(ref_ful),"ful") gt 0 and ref and ful = 0 then do;                                                                                               
		ful = 1;                                                                                                                                                      
		ful_dt = srvc_dt;                                                                                                                                             
		ref_2_ful = srvc_dt - ref_dt;                                                                                                                                 
	end;                                                                                                                                                            
	if last.&person_id. and ref then output;                                                                                                                        
	keep &person_id. ref ful ref_dt ful_dt ref_2_ful;                                                                                                               
	format ref_dt ful_dt mmddyy10.;                                                                                                                                 
run;                                                                                                                                                             
proc means data=_last_(drop=&person_id.) n mean min max sum maxdec=4;                                                                                            
	title "QA: _sdoh_adj_&i. &cn.";                                                                                                                                 
run;                                                                                                                                                             
                                                                                                                                                                 
*RAW REFERRAL VOLUMES BY MONTH, FULFILMENTS, TIME BETWEEN;                                                                                                       
%do ii = 1 %to &num_mo.;	                                                                                                                                              
	proc sql;                                                                                                                                                       
		create table t&rdvz.&dsvz.&rpvz._sdoh_rsum_&i._&ii. as (                                                                                                      
		select 	&ii. as rpt_month                                                                                                                                     
					,	"&cn." as referral_type length=50                                                                                                                               
					, sum(ref) as referrals                                                                                                                                 
		from t&rdvz.&dsvz.&rpvz._sdoh_adj_&i.                                                                                                                         
		where month(ref_dt) eq &ii.                                                                                                                                   
		);                                                                                                                                                            
		                                                                                                                                                              
		create table t&rdvz.&dsvz.&rpvz._sdoh_fsum_&i._&ii. as (                                                                                                      
		select 	&ii. as rpt_month                                                                                                                                     
					, sum(ful) as fulfillments                                                                                                                              
		from t&rdvz.&dsvz.&rpvz._sdoh_adj_&i.                                                                                                                         
		where month(ref_dt) eq &ii.                                                                                                                                   
		);                                                                                                                                                            
		                                                                                                                                                              
		create table t&rdvz.&dsvz.&rpvz._sdoh_rfsum_&i._&ii. as (                                                                                                     
		select 	&ii. as rpt_month                                                                                                                                     
				 , mean(ref_2_ful) as mean_referral_to_fulfillment                                                                                                        
				 , max(ref_2_ful) as max_referral_to_fulfillment                                                                                                          
		from t&rdvz.&dsvz.&rpvz._sdoh_adj_&i.                                                                                                                         
		where month(ref_dt) eq &ii.                                                                                                                                   
		);  	                                                                                                                                                        
	quit;	                                                                                                                                                          
%end;	                                                                                                                                                          
                                                                                                                                                                 
*RAW REFERRAL VOLUMES ALL TIME, FULFILMENTS, TIME BETWEEN;                                                                                                       
proc sql;                                                                                                                                                        
	create table t&rdvz.&dsvz.&rpvz._sdoh_rsum_&i._all as (                                                                                                         
	select 	"all" as rpt_month                                                                                                                                      
				,	"&cn." as referral_type  length=38                                                                                                                                 
				, sum(ref) as referrals                                                                                                                                   
	from t&rdvz.&dsvz.&rpvz._sdoh_adj_&i.                                                                                                                           
	);                                                                                                                                                          
	                                                                                                                                                                
	create table t&rdvz.&dsvz.&rpvz._sdoh_fsum_&i._all as (                                                                                                         
	select 	"all" as rpt_month                                                                                                                                      
				, sum(ful) as fulfillments                                                                                                                                
	from t&rdvz.&dsvz.&rpvz._sdoh_adj_&i.                                                                                                                           
	);                                                                                                                                                              
	                                                                                                                                                                
	create table t&rdvz.&dsvz.&rpvz._sdoh_rfsum_&i._all as (                                                                                                        
	select 	"all" as rpt_month                                                                                                                                      
			 , mean(ref_2_ful) as mean_referral_to_fulfillment                                                                                                          
			 , max(ref_2_ful) as max_referral_to_fulfillment                                                                                                            
	from t&rdvz.&dsvz.&rpvz._sdoh_adj_&i.                                                                                                                           
	);  	                                                                                                                                                          
quit;	                                                                                                                                                          
                                                                                                                                                                 
*END REFERRAL TYPE LOOP;                                                                                                                                         
%let i = %eval(&i.+1);                                                                                                                                           
%let cn = %scan(&commons_get.,&i.,"|");                                                                                                                              
%end;                                                                                                                                                            
                                                                                                                                                                 
*ASSEMBLE FINAL REPORTS;                                                                                                                                         
	*BY MONTH LOOP;                                                                                                                                                 
	%do ii = 1 %to &num_mo.;                                                                                                                                               
		*REFERRAL TYPE LOOP;                                                                                                                                          
		%let i = 1;                                                                                                                                                   
		%let cn = %scan(&commons_get.,&i.,"|");                                                                                                                           
		%do %while (&cn ne);			                                                                                                                                    
			data t&rdvz.&dsvz.&rpvz._&i._&ii._report;                                                                                                                   
				merge t&rdvz.&dsvz.&rpvz._sdoh_rsum_&i._&ii.	                                                                                                            
							t&rdvz.&dsvz.&rpvz._sdoh_fsum_&i._&ii.                                                                                                              
							t&rdvz.&dsvz.&rpvz._sdoh_rfsum_&i._&ii.;                                                                                                            
				by rpt_month;                                                                                                                                             
			run;			                                                                                                                                                  
		%let i = %eval(&i.+1);                                                                                                                                        
		%let cn = %scan(&commons_get.,&i.,"|");                                                                                                                           
		%end;		                                                                                                                                                      
	%end;                                                                                                                                                           
	*ALL;                                                                                                                                                           
		*REFERRAL TYPE LOOP;                                                                                                                                          
		%let i = 1;                                                                                                                                                   
		%let cn = %scan(&commons_get.,&i.,"|");                                                                                                                           
		%do %while (&cn ne);			                                                                                                                                    
			data t&rdvz.&dsvz.&rpvz._&i._all_report;                                                                                                                    
				merge t&rdvz.&dsvz.&rpvz._sdoh_rsum_&i._all	                                                                                                              
							t&rdvz.&dsvz.&rpvz._sdoh_fsum_&i._all                                                                                                               
							t&rdvz.&dsvz.&rpvz._sdoh_rfsum_&i._all;                                                                                                             
				by rpt_month;                                                                                                                                             
			run;			                                                                                                                                                  
		%let i = %eval(&i.+1);                                                                                                                                        
		%let cn = %scan(&commons_get.,&i.,"|");                                                                                                                           
		%end;		                                                                                                                                                      
	*FINAL MONTH REPORT;                                                                                                                                            
	%do ii = 1 %to &num_mo.;                                                                                                                                               
		data t&rdvz.&dsvz.&rpvz._&ii._report;                                                                                                                         
			set %do i = 1 %to &num_cm.; t&rdvz.&dsvz.&rpvz._&i._&ii._report %if &i. ne &num_cm. %then %str( ); %end; ;                                                                
			drop rpt_month;                                                                                                                                             
		run;                                                                                                                                                          
		proc sort data=t&rdvz.&dsvz.&rpvz._&ii._report; by descending referrals; run;	                                                                                
		proc sql noprint;                                                                                                                                             
			select sum(referrals) 										into : tot_referrals 										from t&rdvz.&dsvz.&rpvz._&ii._report;                                     
			select sum(fulfillments) 									into : tot_fulfillments 								from t&rdvz.&dsvz.&rpvz._&ii._report;                                     
			select mean(mean_referral_to_fulfillment) into : tot_mean_referral_to_fulfillment from t&rdvz.&dsvz.&rpvz._&ii._report;                                     
			select max(max_referral_to_fulfillment) 	into : tot_max_referral_to_fulfillment 	from t&rdvz.&dsvz.&rpvz._&ii._report;                                     
		quit;                                                                                                                                                                                                                                                                                                                        
		%put month 															= &ii.;                                                                                                               
		%put tot_referrals 											= &tot_referrals.; 											                                                                              
		%put tot_fulfillments 								  = &tot_fulfillments.; 								                                                                                
		%put tot_mean_referral_to_fulfillment   = &tot_mean_referral_to_fulfillment.;                                                                                 
		%put tot_max_referral_to_fulfillment 	  = &tot_max_referral_to_fulfillment.; 	  			                                                                        
		data t&rdvz.&dsvz.&rpvz._&ii._report_tot;                                                                                                                     
			length rnum 3 referral_type $50 referrals referrals_pct fulfillments fulfillments_pct mean_referral_to_fulfillment max_referral_to_fulfillment 6;           
			retain 	rnum 														1                                                                                                                   
							referral_type										"All referrals"                                                                                                     
							referrals												&tot_referrals.                                                                                                     
							referrals_pct										1                                                                                                                   
							fulfillments                    &tot_fulfillments.                                                                                                  
							fulfillments_pct								1                                                                                                                   
							mean_referral_to_fulfillment		&tot_mean_referral_to_fulfillment.                                                                                  
							max_referral_to_fulfillment			&tot_max_referral_to_fulfillment.							                                                                      
							;                                                                                                                                                   
		run;                                                                                                                                                          
		data t&rdvz.&dsvz.&rpvz._&ii._report;			                                                                                                                    
			length rnum 3 referral_type $50 referrals referrals_pct fulfillments fulfillments_pct mean_referral_to_fulfillment max_referral_to_fulfillment 6;           
			set t&rdvz.&dsvz.&rpvz._&ii._report;                                                                                                                        
			referrals_pct=referrals/&tot_referrals.;                                                                                                                    
			fulfillments_pct=fulfillments/&tot_fulfillments.;                                                                                                           
			rnum+1;                                                                                                                                                     
		run;                                                                                                                                                          
		data t&rdvz.&dsvz.&rpvz._&ii._report;                                                                                                                         
			set t&rdvz.&dsvz.&rpvz._&ii._report_tot t&rdvz.&dsvz.&rpvz._&ii._report;                                                                                    
			format referrals fulfillments comma12. referrals_pct fulfillments_pct percent9.1 mean_referral_to_fulfillment comma8.4 max_referral_to_fulfillment comma4.; 
		run;                                                                                                                                                          
		proc sort data=_last_; by rnum; run;	                                                                                                                        
		data t&rdvz.&dsvz.&rpvz._sdoh_adj_&ii.;                                                                                                                       
			set %do i = 1 %to &num_cm.; t&rdvz.&dsvz.&rpvz._sdoh_adj_&i. %if &i. ne &num_cm. %then %str( ); %end; ;                                    
		run;
		proc sql noprint;                                                                                                                                               
			select count(distinct &person_id.) 											into : total_patients 										from t&rdvz.&dsvz.&rpvz._sdoh_adj_&ii. where month(ref_dt) eq &ii.;                      
		quit; 				                                                                                                                                                      
		*SUMMARY TABLE, BY MONTH;                                                                                                                                     
		proc sql; create table t&rdvz.&dsvz.&rpvz._sdoh_sum_&ii. as (                                                                                                 
			select sum(ref)																			 	as sum_referrals	
					 , &total_patients. 															as total_patients										format=comma12.                                                   
					 , &tot_referrals. 																as total_referrals                  format=comma12.                                                   
					 , &tot_referrals./&total_patients.								as avg_referrals_per_patient				format=comma4.2                                                   
					 , &tot_fulfillments. 														as total_fulfilled_referrals        format=comma12.                                                   
					 , &tot_fulfillments./&total_patients. 						as avg_fulfilled_referrals_per_pat  format=comma4.2      
			from t&rdvz.&dsvz.&rpvz._sdoh_adj_&ii.                                             
		); quit;		
	proc print data=_last_(drop=sum_referrals); title "QA: t&rdvz.&dsvz.&rpvz._sdoh_sum_&ii."; run;			                                                                                                                                              
	%end;                                                                                                                                                           
	*FINAL SUMMARY TABLE, ALL TIME;                                                                                                                                 
	data t&rdvz.&dsvz.&rpvz._sdoh_adj_all;                                                                                                                          
		set %do i = 1 %to &num_cm.; t&rdvz.&dsvz.&rpvz._sdoh_adj_&i. %if &i. ne &num_cm. %then %str( ); %end; ;                                                                     
		drop rpt_month;                                                                                                                                               
	run;		                                                                                                                                                        
	data t&rdvz.&dsvz.&rpvz._sdoh_sum_all; set %do i = 1 %to &num_mo.; t&rdvz.&dsvz.&rpvz._sdoh_sum_&i. %if &i. ne &num_mo. %then %str( ); %end; ; run;                           
	proc sql noprint;                                                                                                                                               
		select count(distinct &person_id.) 											into : total_patients 										from t&rdvz.&dsvz.&rpvz._sdoh_adj_all;                      
	quit;                                                                                                                                                           
	proc sql; create table t&rdvz.&dsvz.&rpvz._sdoh_sum_all as (                                                                                                    
			select &total_patients. 																as total_patients                   format=comma12.                                                 
					 , sum(total_referrals) 														as total_referrals                  format=comma12.                                                 
					 , sum(total_referrals)/&total_patients.						as avg_referrals_per_patient        format=comma4.2                                                 
					 , sum(total_fulfilled_referrals) 									as total_fulfilled_referrals        format=comma12.                                                 
					 , sum(total_fulfilled_referrals)/&total_patients. 	as avg_fulfilled_referrals_per_pat	format=comma4.2    	                                                                                                                                                                                                             
			from t&rdvz.&dsvz.&rpvz._sdoh_sum_all                                                                                                                       
	); quit;                                                                                                                                                        
	%put month 															= all;                                                                                                                  
  %put total_patients										  =	&total_patients.;										                                                                                
  %put total_referrals                    =	&total_referrals.;                                                                                                  
  %put avg_referrals_per_patient				  =	&avg_referrals_per_patient.;				                                                                                  
  %put total_fulfilled_referrals          =	&total_fulfilled_referrals.;                                                                                        
  %put avg_fulfilled_referrals_per_pat    =	&avg_fulfilled_referrals_per_pat.;   	                                                                              
	*FINAL ALL TIME REPORT;                                                                                                                                         
	data t&rdvz.&dsvz.&rpvz._all_report;                                                                                                                            
		set %do i = 1 %to &num_cm.; t&rdvz.&dsvz.&rpvz._&i._all_report %if &i. ne &num_cm. %then %str( ); %end; ;                                                                   
		drop rpt_month;                                                                                                                                               
	run;                                                                                                                                                            
	proc sort data=t&rdvz.&dsvz.&rpvz._all_report; by descending referrals; run;	                                                                                  
	proc sql noprint;                                                                                                                                               
		select sum(referrals) 										into : tot_referrals 										from t&rdvz.&dsvz.&rpvz._all_report;                                        
		select sum(fulfillments) 									into : tot_fulfillments 								from t&rdvz.&dsvz.&rpvz._all_report;                                        
		select mean(mean_referral_to_fulfillment) into : tot_mean_referral_to_fulfillment from t&rdvz.&dsvz.&rpvz._all_report;                                        
		select max(max_referral_to_fulfillment) 	into : tot_max_referral_to_fulfillment 	from t&rdvz.&dsvz.&rpvz._all_report;                                        
	quit;                                                                                                                                                           
	%put month 															= all;                                                                                                                  
	%put tot_referrals 											= &tot_referrals.; 											                                                                                
	%put tot_fulfillments 								  = &tot_fulfillments.; 								                                                                                  
	%put tot_mean_referral_to_fulfillment   = &tot_mean_referral_to_fulfillment.;                                                                                   
	%put tot_max_referral_to_fulfillment 	  = &tot_max_referral_to_fulfillment.; 	  			                                                                          
	data t&rdvz.&dsvz.&rpvz._all_report_tot;                                                                                                                        
		length rnum 3 referral_type $50 referrals referrals_pct fulfillments fulfillments_pct mean_referral_to_fulfillment max_referral_to_fulfillment 6;             
		retain 	rnum 														1                                                                                                                     
						referral_type										"All referrals"                                                                                                       
						referrals												&tot_referrals.                                                                                                       
						referrals_pct										1                                                                                                                     
						fulfillments                    &tot_fulfillments.                                                                                                    
						fulfillments_pct								1                                                                                                                     
						mean_referral_to_fulfillment		&tot_mean_referral_to_fulfillment.                                                                                    
						max_referral_to_fulfillment			&tot_max_referral_to_fulfillment.							                                                                        
						;                                                                                                                                                     
	run;                                                                                                                                                            
	data t&rdvz.&dsvz.&rpvz._all_report;			                                                                                                                      
		length rnum 3 referral_type $50 referrals referrals_pct fulfillments fulfillments_pct mean_referral_to_fulfillment max_referral_to_fulfillment 6;             
		set t&rdvz.&dsvz.&rpvz._all_report;                                                                                                                           
		referrals_pct=referrals/&tot_referrals.;                                                                                                                      
		fulfillments_pct=fulfillments/&tot_fulfillments.;                                                                                                             
		rnum+1;                                                                                                                                                       
	run;                                                                                                                                                            
	data t&rdvz.&dsvz.&rpvz._all_report;                                                                                                                            
		set t&rdvz.&dsvz.&rpvz._all_report_tot t&rdvz.&dsvz.&rpvz._all_report;                                                                                        
		format referrals fulfillments comma12. referrals_pct fulfillments_pct percent9.1 mean_referral_to_fulfillment comma8.4 max_referral_to_fulfillment comma4.;   
	run;                                                                                                                                                            
	proc sort data=_last_; by rnum; run;	                                                                                                                          
                                                                                                                                                                 
/*-----------------------------------------------------------------*/                                                                                            
/*---> OUTPUT EXCEL FILE <-----------------------------------------*/                                                                                            
/**/                                                                                                                                                             
                                                                                                                                                                 
*DECLARE REPORT NAME;                                                                                                                                            
%let rp_nm 	= "&om_data./05_out_rep/v&rdvz.&dsvz.&rpvz._01_sdoh_activity_reporting.xls";                                                                        
                                                                                                                                                                 
* GRAPHICS ON;                                                                                                                                                                                                                                                                                                                    
ods listing gpath="&om_data./05_out_rep/";                                                                                                                       
ods output; ods graphics on;                                                                                                                                     
                                                                                                                                                                 
* BEGIN EXCEL OUTPUT;                                                                                                                                            
* NOTE: FIRST REPORT MUST CITE FILE, STYLE:                                                                                                                      
                                                                                                                                                                 
* FIRST SHEET OF OUTPUT;                                                                                                                                         
	ods excel file=&rp_nm.                                                                                                                                          
			options                                                                                                                                                     
			(                                                                                                                                                           
				sheet_name="SDoH_Activity_byMo"                                                                                                                           
				sheet_interval='none'                                                                                                                                     
				embedded_titles='yes'                                                                                                                                     
			);	                                                                                                                                                        
                                                                                                                                                                 
	title "Merck SDoH Campaign - 2020 Activity Reporting by Month";                                                                                                 
	title2 "Prepared for Cross-Optum, Merck , &sysdate_word.";                                                                                                      
	title3 "January, by Referral Type";                                                                                                                             
	proc print noobs data=t&rdvz.&dsvz.&rpvz._1_report(drop=rnum); run;		                                                                                          
	proc print noobs data=t&rdvz.&dsvz.&rpvz._sdoh_sum_1(drop=sum_referrals); 	                                                                                                        
			title "January Patient Summary";                                                                                                                            
			run;		                                                                                                                                                    
	%let months = January February March April May June July August September;                                                                                                            
	%do ii = 2 %to &num_mo.;                                                                                                                                               
	%let rpt_month = %scan(&months.,&ii.);                                                                                                                          
		proc print noobs data=t&rdvz.&dsvz.&rpvz._&ii._report(drop=rnum);                                                                                             
			title "&rpt_month., by Referral Type";                                                                                                                      
			run;                                                                                                                                                        
		proc print noobs data=t&rdvz.&dsvz.&rpvz._sdoh_sum_&ii.(drop=sum_referrals); 	                                                                                                    
			title "&rpt_month. Patient Summary";                                                                                                                        
			run;                                                                                                                                                        
	%end;                                                                                                                                                           
                                                                                                                                                                 
	%util_dummy_sheet; 															                                                                                                                
                                                                                                                                                                 
* SUBSEQUENT SHEETS OF OUTPUT;                                                                                                                                   
	ods excel            													                                                                                                                  
			options                                                                                                                                                     
			(                                                                                                                                                           
				sheet_name="SDoH_Activity_Overall"                                                                                                                        
				sheet_interval='none'                                                                                                                                     
				embedded_titles='yes'                                                                                                                                     
			);	                                                                                                                                                        
                                                                                                                                                                 
	title "Merck SDoH Campaign - 2020 Activity Reporting, Overall";                                                                                                 
	title2 "Prepared for Cross-Optum, Merck , &sysdate_word.";                                                                                                      
	title3 "January-September Summary";	                                                                                                                                
	proc print noobs data=t&rdvz.&dsvz.&rpvz._all_report(drop=rnum); run;                                                                                           
			title "by Referral Type";                                                                                                                                   
			run;                                                                                                                                                        
	proc print noobs data=t&rdvz.&dsvz.&rpvz._sdoh_sum_all; run;                                                                                                    
			title "Patient Summary";                                                                                                                                    
			run;		                                                                                                                                                    
                                                                                                                                                                 
*GRAPHICS OFF;																	                                                                                                                  
ods graphics off;                                                                                                                                                
*END EXCEL OUTPUT;															                                                                                                                  
ods excel close;                                                                                                                                                 
                                                                                                                                                                 
*CLEANUP LEFTOVER PNG FILES FROM GPLOT/GCHART PROCS;                                                                                                             
x "rm -f mypath/*.png";                                                                                                                                          
                                                                                                                                                                 
*DELETE ANY LEFTOVER DATA;                                                                                                                                       
proc datasets nolist; delete t:; quit;   

%mend;                                                                                                                                                                                                                                                                                       

/*-----------------------------------------------------------------*/
/*---> EXECUTE <---------------------------------------------------*/
/**/
%data_clms(rdvz=1,dsvz=1,rpvz=0,testobs=);



