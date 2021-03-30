%macro left_join(l=, r=, b=, o=);
proc sort data=&l;
by &b;
run;

proc sort data=&r;
by &b;
run;

data &o;
merge &l(in=x) &r(in=y);
by &b;
if x;
run;
%mend left_join;
************************************************************************************************;

*****macro for check*****;
%macro adxw_check(v=);
data adxw_check1(keep=usubjid &v);
set ad.adxw;
run;
%mend;
***************;
*************************************************************************************************;
*macros to extract predecessors;

*extract pred from file from which usubjid is taken;
%macro pred_usubj(meta_source=, dataset=, pull_from=, library=, output_name=);

proc import datafile= "&meta_source"
		out=meta_file_sh dbms=xlsx;
	sheet="Variables";
	getnames=yes;
run;

data sh1;
set meta_file_sh;
where dataset eq "&dataset" and prxmatch("m/^&pull_from/I", source_var);
run;

proc sql noprint;
select variable into:sh_names separated by " "
from sh1;
quit;

%put naam= &sh_names.;

%let sh3= .;


data &output_name(keep= &sh_names.);
	set &library&sh3&pull_from;
run;

%mend;



*extract pred from other files from where usubjid is not taken;
%macro pred_other(prev_file=, dataset=,  pull_from=, library=, output_name=);


proc sort data=&prev_file;
by usubjid;
run;
%let sh4= .;


data sh4a;
set meta_file_sh;
where dataset eq "&dataset" and prxmatch("m/^&pull_from/I", source_var);
run;

proc sql noprint;
select variable into:sh_naam separated by " "
from sh4a;
quit;

%put naam: &sh_naam.;

data sh5(keep=USUBJID &sh_naam.);
set &library&sh4&pull_from;
run;


proc sort data=sh5;
by usubjid;
run;

data &output_name;
merge &prev_file(in=x) sh5(in=y);
by usubjid;
if x;
run;


%mend;
**************************************************************************************************;

/* data ofc.adxw_guide(keep= dataset variable var_order length derivation source_var origin); */
/* set nm.adam_guide; */
/* where dataset eq "adxw"; */
/* run; */

*Creating predecessors using macros pred_usubj and pred_other;


%pred_usubj(meta_source=/folders/myfolders/New_Study_master/adam/ADAM_Metadata_Reviewer_Aid_28APR2020.xlsm, dataset=adxw, pull_from=xw, library=sd, output_name=ofc.adxw1_sh);
%pred_other(prev_file=ofc.adxw1_sh, dataset=adxw, pull_from=adsl, library=ad, output_name=ofc.adxw2_sh);

*resolving these variables which were not added by macros;
*trtp trtpn trta trtan PARCAT1 param paramcd;

*TRTP	20	9		ADSL.TRT01P
*TRTPN	21	8		ADSL.TRT01PN
*TRTA	22	9		ADSL.TRT01A
*TRTAN	23	8		ADSL.TRT01AN;

data ofc.adxw3_sh;
set ofc.adxw2_sh;
TRTP = TRT01P;
TRTPN= TRT01PN;
TRTA = TRT01A;
TRTAN = TRT01AN;
run;

*PARCAT1	37	21		XW.XWCAT
*PARAM	38	39		XW.XWTEST
*PARAMCD	39	8		XW.XWTESTCD;

data xw1(keep=usubjid PARCAT1 PARAM PARAMCD);


set sd.xw;
length PARCAT1 $ 37.;
length PARAM $ 39.;
length PARAMCD $ 39.;
PARCAT1= xwcat;
PARAM=xwtest;
PARAMCD=xwtestd;
run;


%left_join(l=ofc.adxw3_sh, r=xw1, b=usubjid, o=ofc.adxw4_sh);
***************************************************************************************************;
*AVISIT	31	8	;
*AVISITN	32	8	Numeric version of AVISIT;

***************************************************************************************************;
*ADT	35	8	;
*Numeric date part of XW.XWDTC.;
data ofc.adxw5_sh;
set ofc.adxw4_sh;
ADT= input(xwdtc, yymmdd10.);
format ADT date9.;
run;
**************************************************************************************************;
*ADY	36	8	;
*If ADT>=ADSL.TRTSDT then ADT-ADSL.TRTSDT+1, else ADT-ADSL.TRTSDT.;

data ofc.adxw6_sh;
set ofc.adxw5_sh;
if adt>=trtsdt then ADY =adt-trtsdt+1;
else ADY= adt-trtsdt;
run;

**************************************************************************************************;
*AVAL	40	8	;
*If XWSTRESC = "I AM INTERESTED IN RESEARCH OF NEW THERAPIES" then AVAL = 1.  
If XWSTRESC = "LIKE TO BE ON A LESS FREQ DOSING REGIMEN" then AVAL=2. 
If XWSTRESC="MY CLINICIAN ASKED ME TO PARTICIPATE" then AVAL=3. 
If XWSTRESC="COST OF CURRENT HIV DRUG OR TO RECEIVE FREE STUDY DRUG" then AVAL=4. 
If XWSTRESC ="OTHER" then AVAL=9.
;
data xw2(keep=usubjid xwstresc);
set sd.xw;
run;

proc format;
value $ aval
"I AM INTERESTED IN RESEARCH OF NEW THERAPIES"=1
"LIKE TO BE ON A LESS FREQ DOSING REGIMEN"=2
"MY CLINICIAN ASKED ME TO PARTICIPATE"=3
"COST OF CURRENT HIV DRUG OR TO RECEIVE FREE STUDY DRUG"=4
"OTHER"=9
;
run;

data xw3(keep=usubjid aval);
set xw2;
AVAL= input(put(xwstresc, aval.), best.);
run;

%left_join(l=ofc.adxw6_sh, r=xw3, b=usubjid, o=ofc.adxw7_sh);
***************************************************************************************************;

*AVALC	41	54	;
proc format;
value avalc
1= "I AM INTERESTED IN RESEARCH OF NEW THERAPIES"
2="LIKE TO BE ON A LESS FREQ DOSING REGIMEN"
3="MY CLINICIAN ASKED ME TO PARTICIPATE"
4="COST OF CURRENT HIV DRUG OR TO RECEIVE FREE STUDY DRUG"
9="OTHER"
;
run;

data ofc.adxw8_sh;
length AVALC $ 54.;
set ofc.adxw7_sh;
AVALC = put(aval, avalc.);
run;
**************************************************************************************************;
*aphase:
*pulling out variables  from adsl; 

data aphase_adsl(keep=usubjid lstinjdt lstorldt mth12sdt trtsdt mntedt trt01an ltartsdt ltfufl); *lstinjdt_adj lstorldt_adj);
set ad.adsl;
/* lstinjdt_adj = lstinjdt+67; */
/* lstorldt_adj =lstorldt+1; */
/* format lstinjdt_adj lstorldt_adj date9.; */
run;


*our domain here is xw...we also need to check if epoch and egtpt column are present in xw.
since epoch column is only present we can apply following conditions only as per aphase_sh.sas.;

*The values for rows of these columns are set to Y if any of the following conditions are met;

*1st case:
If trtsdt and adt are not missing, then a bunch of conditions are applied;

*2nd case:
If trtsdt is missing and adt is not missing then corresponding rows in aphase_phase1 are set to "Y";

*3rd case:
If trt01an=2 i.e. arm's value is not q2m but dtg+rpv then aphase_phase3 is set to "" empty value.
since DTG + RPV arm subjects cannot enter long term follow up Phase;

*most of the conditions and values for aphase are derived from 1st case:

so
*1st case:
If trtsdt and adt are not missing, then following conditions are checked:
	1. if lstinjdt is not missing and lstorldt is not missing then in such cases,
		--->if adt>max(lstinjdt, lstorldt) then aphase_phase3= "Y"	
		
	[the above conditions apply for both trt01an values 1 and 2..i.e for q2m and dtg+rpv]
	2. if trt01an=2 ..meaning trt01a value is dtg+rpv:
		--->if mth12sdt is not missing then apply following:
					:if epoch is present in column of my domain[xw for example] but egtpt column is not present then:
							if adt>trtsdt and adt<=mth12sdt then aphase_phase2= "Y".
		---->if mth12sdt is missing: apply following:
					:if epoch is present in column of my domain[xw for example]but egtpt column is not present then:
							if adt>trtsdt then aphase_phase2= "Y".
	
	3. if trt01an=1..meaning trt01a value is q2m:
		---->if ltartsdt is not missing then apply following:
					:if epoch is present in column of my domain[xw for example]but egtpt column is not present then:
							if adt>trtsdt and adt<=ltartsdt then aphase_phase2= "Y".
	    
		---->if ltartsdt is missing then apply following:
					::if epoch is present in column of my domain[xw for example]but egtpt column is not present then:
							if adt>trtsdt then aphase_phase2= "Y".
	4. :if epoch is present in column of my domain[xw for example]but egtpt column is not present then:
					: if adt<=trtsdt then aphase_phase1= "Y"

    


*for adxw, naming the adxw file as aphase_temp1;

data aphase_temp1(keep=usubjid xwseq adt);
set ofc.adxw8_sh;
run;

*merging adsl and our dataset;
proc sort data=aphase_adsl nodup;
by usubjid;
run;

proc sort data=aphase_temp1 nodup;
by usubjid;
run;

data aphase_temp2;
merge aphase_temp1(in=x) aphase_adsl(in=y);
by usubjid;
if x;
run;


data aphase_temp3;
set aphase_temp2;

*1st condition;
/* if trtsdt ne . and adt ne . then; do; */
if not(cmiss(trtsdt) and (cmiss(adt))) then; do;	
	if not(cmiss(lstinjdt)  and cmiss(lstorldt)) then; do;
		if adt>lstinjdt and adt>lstorldt then aphase_phase3= "Y";	
	end;
	
	*****************************************************;
	
	if trt01an eq 2 then do;
		if not(cmiss(mth12sdt)) then do;
			if adt>trtsdt and adt<=mth12sdt then aphase_phase2= "Y";
		end;
		if cmiss(mth12sdt) then do;
			if adt>trtsdt then aphase_phase2= "Y";
		end;
	end;
	
	*******************************************************;
	
	if trt01an eq 1 then do;
		if not(cmiss(ltartsdt)) then do;
			if adt>trtsdt and adt<=ltartsdt then aphase_phase2= "Y";
		end;
		if cmiss(ltartsdt) then do;
			if adt>trtsdt then aphase_phase2= "Y";
		end;
	end;
	
	********************************************************;
	
	if adt<=trtsdt then aphase_phase1= "Y";
	
end;

*2nd condition;
*If trtsdt is missing and adt is not missing then corresponding rows in aphase_phase1 are set to "Y";
if cmiss(trtsdt) and not(cmiss(adt)) then do;
	aphase_phase1 = "Y";
end;

*3rd condition
If trt01an=2 i.e. arm's value is not q2m but dtg+rpv then aphase_phase3 is set to "" empty value.
since DTG + RPV arm subjects cannot enter long term follow up Phase;

if trt01an eq 2 then aphase_phase3 = "";

run;

*now checking if any rows have Ys in adjacent aphase_phase1 or 2 or 3;
data check_aphase;
set aphase_temp3;
if (not(cmiss(aphase_phase1)) and not(cmiss(aphase_phase2) or cmiss(aphase_phase3)) ) or
	(not(cmiss(aphase_phase2)) and not(cmiss(aphase_phase1) or cmiss(aphase_phase3)) ) or
	(not(cmiss(aphase_phase3)) and not(cmiss(aphase_phase2) or cmiss(aphase_phase1)) );
run;

*since there are no rows in which 2 phases have Y in them..we can use the following conditions to determine aphase and
aphasen.


we have 3 extra cols aphase_phase1 aphase_phase2 and aphase_phase3 with Y values filled in some rows:
if the row has value aphase_phase1= "Y" then for that aphase= 'Screeening' and aphasen=1.
if the row has value aphase_phase2= "Y" then for that aphase= 'Maintenance' and aphasen=2.
if the row has value aphase_phase3= "Y" then for that aphase= 'Long term follow up' and aphasen=3.
;

data aphase_temp4(keep=usubjid xwseq aphase aphasen);
set aphase_temp3;
if aphase_phase1 eq "Y" then do;APHASE= "Screening";APHASEN=1;end;
else if aphase_phase2 eq "Y" then do; APHASE= "Maintenance";APHASEN=2;end;
else if aphase_phase3 eq "Y" then do; APHASE= "Long-term Follow-up";APHASEN=3;end;
run;

%left_join(l=ofc.adxw8_sh, r=aphase_temp4, b=usubjid xwseq, o=ofc.adxw9_sh);
**************************************************************************************************;
*


%adxw_check(v=aphase xwseq);

**************************************************************************************************;
*TRTSTATE	42	32
*since aphase is screening only, we can say that trtstate is  "Pre-treatment".;
data ofc.adxw10_sh;
set ofc.adxw9_sh;
if aphase eq "Screening" then
TRTSTATE =  "Pre-treatment";
run;	
**************************************************************************************************;
*AVISIT meets the following condtion;
*If APHASE = "Screening" or "Maintenance" then:
 If sDY <= 1 and TRTSTATE = "Pre-treatment" then AVISIT = "Baseline";
 
data ofc.adxw11_sh;
set ofc.adxw10_sh;
if (aphase eq "Screening" or aphase eq "Maintenance") and ady<=1 and trtstate eq "Pre-treatment" then do;AVISIT= "Baseline";AVISITN=0;end;
run;
***************************************************************************************************;



**************************************************************************************************; 
