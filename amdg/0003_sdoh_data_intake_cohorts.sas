 /*----------------------------------------------------------------*\
 | STANDALONE SDOH CAMPAIGN FOR XO - MERCK													|
 | PROGRAM 0002 - POST-CAMPAIGN SDOH DATA INTAKE										|
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

%macro data_clms(rdvz=,dsvz=,rpvz=,testobs=);                                                                                                                    
                                                                                                                                                                 
*IMPORT SDOH DATA MACRO;                                                                                                                                         
%macro pim_sdoh(fn_sdoh_inp=,fn_sdoh_out=);                                                                                                                      
	data &fn_sdoh_out.;                                                                                                                                             
		infile "&fn_sdoh_inp." delimiter = '|' missover dsd lrecl=32767 firstobs=2;                                                                                   
		informat mbi		                      $12.    	;                                                                                                             
		informat srvc_dt                      yymmdd10.	;                                                                                                             
		informat icd_code                     $7.			 	;                                                                                                             
		informat icd_code_description         $130.    	;                                                                                                             
		informat ref_ful											$3.      	;                                                                                                             
		informat common_name_roll_up          $24.			;                                                                                                             
		informat common_name_detail_display   $24.      ;                                                                                                             
		format mbi		                       	$12.    	;                                                                                                             
		format srvc_dt                       	yymmdd10.	;                                                                                                             
		format icd_code                      	$7.			 	;                                                                                                             
		format icd_code_description          	$130.    	;                                                                                                             
		format ref_ful												$3.      	;                                                                                                             
		format common_name_roll_up           	$24.			;                                                                                                             
		format common_name_detail_display    	$24.      ;                                                                                                             
		input  mbi		                       	$   	                                                                                                                  
		       srvc_dt                       	                                                                                                                        
		       icd_code                      	$ 	                                                                                                                    
		       icd_code_description          	$                                                                                                                       
		       ref_ful												$   	                                                                                                                  
		       common_name_roll_up           	$		                                                                                                                    
		       common_name_detail_display    	$                                                                                                                       
		;                                                                                                                                                             
	run;                                                                                                                                                            
	/*proc contents data=_last_ order=varnum; title "QA: Raw SDoH Results Contents (&fn_sdoh_inp.)"; run;                                                           
	proc print data=_last_(obs=10); title "QA: Raw SDoH Results 10 Rows (&fn_sdoh_inp.)"; run;*/                                                                    
	/*proc freq data=_last_; tables common_name_detail_display common_name_roll_up; run;*/
%mend;                                                                                                                                                           
                                                                                                                                                                 
%pim_sdoh(fn_sdoh_inp=&om_data./02_input/merck_diab_2_202009_sdoh_v5.txt,fn_sdoh_out=t&rdvz.&dsvz.&rpvz._sdoh_raw_01);                                           
                                                                                                                                                               
*REFERRAL TYPE LOOP;                                                                                                                                             
%let commons1 = Health Services|Low Income|EducationAndEmployment|Housing|Psychosocial|Nutrition|Family Circumstances|Transportation;    
%let commons2 = Disability_Mobility|EducationAndEmployment_Education|EducationAndEmployment_Employment|Family Circumstances_Family Support|Family Circumstances_Social Isolation|Health Services_Access to Care|Health Services_Alzheimers Support|Health Services_Counseling|Health Services_Lack of Fitness|Health Services_Personal Care|Health Services_Respite Care|Health Services_Safety|Housing_Housing|Housing_Safety|Low Income_Child Care|Low Income_LIS|Low Income_Low Income|Low Income_Medical Cost|Low Income_MSP|Low Income_Necessity Cost|Low Income_Prescription Cost|Low Income_SNAP|Nutrition_Malnutrition|Nutrition_Nutrition|Psychosocial_Justice System Support|Psychosocial_Lifestyle Issues|Psychosocial_Social Environment|Psychosocial_Substance Abuse|Psychosocial_Trauma|Transportation_Transportation;
%let commons_get = &commons2.;
%let commons_1 = 0;
%let cur_st = '01Apr2020'd;
%let cur_end = '30Jun2020'd;
%let num_cm = 30;         
%let i = 1;                                                                                                                                                      
%let cn = %scan(&commons_get.,&i.,"|");                                                                                                                              
%do %while (&cn ne);                                                                                                                                             
                                                                                                                                                                 
*STAGE RAW REFERRAL DATA;                                                                                                                                        
data t&rdvz.&dsvz.&rpvz._sdoh_raw_&i.;  
	length common_get_fld $50;                                                                                                                         
	set t&rdvz.&dsvz.&rpvz._sdoh_raw_01;  
	%if &commons_1. %then common_get_fld = tranwrd(common_name_roll_up," & ","And");                                                                                                                         
									%else common_get_fld = catx('_',tranwrd(common_name_roll_up," & ","And"),tranwrd(common_name_detail_display,"'","")); ;                                                                                                                         
	if find(common_get_fld,"&cn.") gt 0;                                                                                                                 
run;        
   	/*proc freq data=_last_; tables common_name_roll_up*common_get_fld; run;
   	proc freq data=_last_; tables common_name_detail_display*common_get_fld; run;
   	proc freq data=_last_; tables common_name_detail_display common_get_fld; run;    */                                                                                                                                        
                                                                                                                                                                 
*TIME BETWEEN REFERRAL AND FULFILMENT;                                                                                                                           
proc sort data=t&rdvz.&dsvz.&rpvz._sdoh_raw_&i.; by &person_id. srvc_dt descending ref_ful; run;                                                                 
/*proc print data=_last_(obs=200); var &person_id. &commons_fld. srvc_dt ref_ful; title "QA: _sdoh_raw_&i. &cn."; run;*/                                   
data t&rdvz.&dsvz.&rpvz._sdoh_adj_&i.	;                                                                                                                           
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
	if last.&person_id. and ref and &cur_st. le ref_dt le &cur_end. then output;                                                                                                                        
	keep &person_id. ref ful ref_dt ful_dt ref_2_ful;                                                                                                               
	format ref_dt ful_dt mmddyy10.;                                                                                                                                 
run;                                                                                                                                                             
proc means data=_last_(drop=&person_id.) n mean min max sum maxdec=4;                                                                                            
	title "QA: _sdoh_adj_&i. &cn.";                                                                                                                                 
run;                                                                                                                                                            

%if &i. eq 1 %then %do;
	data rep.v&rdvz.&dsvz.&rpvz._sdoh_post_covid; length ref_typ $50; set t&rdvz.&dsvz.&rpvz._sdoh_adj_&i.; retain ref_typ "&cn."; run;
%end;
%if &i. gt 1 %then %do;
	data t&rdvz.&dsvz.&rpvz._sdoh_adj_&i.; length ref_typ $50; set t&rdvz.&dsvz.&rpvz._sdoh_adj_&i.; retain ref_typ "&cn."; run; 
	proc sql; insert into rep.v&rdvz.&dsvz.&rpvz._sdoh_post_covid select tmp.* from t&rdvz.&dsvz.&rpvz._sdoh_adj_&i. tmp; quit;
%end;
                                                                                                                                                       
*END REFERRAL TYPE LOOP;                                                                                                                                         
%let i = %eval(&i.+1);                                                                                                                                           
%let cn = %scan(&commons_get.,&i.,"|");                                                                                                                              
%end;                                                                                                                                                            
                                                                                                                                                                 
*DELETE ANY LEFTOVER DATA;                                                                                                                                       
proc datasets nolist; delete t:; quit;   

%mend;                                                                                                                                                                                                                                                                                       

/*-----------------------------------------------------------------*/
/*---> EXECUTE <---------------------------------------------------*/
/**/
%data_clms(rdvz=1,dsvz=1,rpvz=4,testobs=);



