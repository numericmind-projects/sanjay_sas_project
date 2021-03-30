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
%macro adc1_check(v=);
data adc1_check1(keep=usubjid &v);
set ad.adc1;
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

data ofc.adc1_guide(keep= dataset variable var_order length derivation source_var origin);
set nm.adam_guide;
where dataset eq "adc1";
run;

*Making some changes according to documentation part of dataset sheet of adc1;
*Instruction given:
*Exclude records where C1.C1CAT in ("PREVIOUS ANTIEPILEPTIC DRUG" "CARDIOVASCULAR MEDICATION")
 or (C1.C1CAT="OTHER TRIAL STUDY TREATMENT") or (C1.C1CAT=" " and C1.C1DECOD=" ") 
;
data ofc.c1;
set sd.c1;
where not(prxmatch("/PREVIOUS ANTIEPILEPTIC DRUG|CARDIOVASCULAR MEDICATION/", c1cat) or c1cat eq "OTHER TRIAL STUDY TREATMENT" or (c1cat=" " and c1decod=" "));
run;




*Creating predecessors using macros pred_usubj and pred_other;


%pred_usubj(meta_source=/folders/myfolders/New_Study_master/adam/ADAM_Metadata_Reviewer_Aid_28APR2020.xlsm,
 dataset=adc1, pull_from=c1, library=ofc, output_name=ofc.adc1_1_sh);

%pred_other(prev_file=ofc.adc1_1_sh, dataset=adc1, pull_from=adsl, library=ad, output_name=ofc.adc1_2_sh);


*not resolved variables;
*TRTP trtpn trta trtan;

data ofc.adc1_3_sh;
set ofc.adc1_2_sh;
TRTP= TRT01P;
TRTPN= TRT01PN;
TRTA=TRT01A;
TRTAN=TRT01AN;
run;
**************************************************************************************************;

*Predecessors are completed and the following codes are for assigned and derived variables;

*ASTDT	27	8	
*Numeric version of C1.C1STDTC. 
When month and day are missing from C1STDTC set to 1st January,
when C1STDTC is missing just the day set to the 1st of the month.
See RAP section 13.7.2.1 for further details.;

*ASTDTF	28	1	WHEN C1.C1STDTC IS JUST THE YEAR, 
AND THEREFORE MONTH AND DAY HAVE BEEN IMPUTED SET TO 'M, 
WHEN C1.C1STDTC IS THE YEAR AND MONTH, AND THEREFORE ONLY DAY HAS BEEN IMPUTED SET TO 'D. 
FOR BOOSTER DRUGS, SET TO 'Y', 
OTHERWISE SET TO MISSING.	;

data date1(keep=usubjid c1stdtc);
set ofc.adc1_3_sh;
run;
data date2(keep=usubjid astdt astdtf);
set date1;
ml= length(strip(c1stdtc));
if length(strip(c1stdtc)) eq 7 then do; ASTDT1 = cats(c1stdtc, "-01"); ASTDTF = "D";end;
else if length(strip(c1stdtc)) eq 4 then do; ASTDT1 = cats(c1stdtc, "-01-01"); ASTDTF = "M";end;
else ASTDT1 = c1stdtc;
ASTDT= input(ASTDT1, yymmdd10.);
format ASTDT date9.;
run;

%left_join(l=ofc.adc1_3_sh, r=date2, b=usubjid, o=ofc.adc1_4_sh);

**************************************************************************************************;

*ASTDY	29	8	;
*If ASTDT>=ADSL.TRTSDT then ASTDT-ADSL.TRTSDT+1, else ASTDT-ADSL.TRTSDT.;

data ofc.adc1_5_sh;
set ofc.adc1_4_sh;
if astdt>=trtsdt then ASTDY = astdt-trtsdt+1;
else ASTDY = astdt-trtsdt;
run;

***************************************************************************************************;

*AENDT	30	8	;
*Numeric version of C1.C1ENDTC. 
When month and day are missing from C1ENDTC set to 31st December, 
when C1ENDTC is missing just the day set to last day of the month. 
When C1.C1STRF='BEFORE' set to min(imputed end date,TRTSDT-1), 
otherwise set to imputed end date. 

See RAP section 13.7.2.1 for further details.
;


*AENDTF	31	1	
WHEN C1.C1ENDTC IS JUST THE YEAR, AND THEREFORE MONTH AND DAY HAVE BEEN IMPUTED SET TO 'M', 
WHEN C1.C1ENDTC IS THE YEAR AND MONTH, AND THEREFORE ONLY DAY HAS BEEN IMPUTED SET TO 'D'. 
NOTE THAT IF C1STRF="BEFORE" AND C1ENDTC IS A PARTIAL DATE 
AND TRTSDT-1<AENDT AND WE IMPUTE AENDT=TRTSDT-1 SET TO 'Y'. 
FOR BOOSTER DRUGS SET TO 'Y', 
OTHERWISE SET TO MISSING.	;


data c1e(keep=usubjid c1endtc c1strf);
set sd.c1;
run;

data c2e(keep=usubjid trtsdt);
set ofc.adc1_5_sh;
run;

%left_join(l=c2e, r=c1e, b=usubjid, o=c3e);


*data month;
data guess_last_day;
first_day_of_feb_date = intnx('month', '03feb2021'd, 0, 'b');
end_day_of_feb_date = intnx('month', '03feb2021'd, 0, 'e');
format first_day_of_feb_date end_day_of_feb_date date9.;
run;


data c4e;
set c3e;
if length(strip(c1endtc)) eq 7 then do;
c1endtc2=intnx('month', input(cats(strip(c1endtc),"-01"), yymmdd10.), 0, "e");
val1= "D";
end;
else if length(strip(c1endtc)) eq 4 then do;
c1endtc2 = input(cats(strip(c1endtc), "12-31"), yymmdd10.);
val1 = "M";
end;
else c1endtc2 = input(c1endtc, yymmdd10.);
format c1endtc2 date9.;
run;

*When C1.C1STRF='BEFORE' set to min(imputed end date,TRTSDT-1), 
otherwise set to imputed end date. ;
data c5e;
set c4e;
if c1strf eq "BEFORE" then AENDT= min(c1endtc2, intnx('day', trtsdt, -1, 's'));
else AENDT = c1endtc2;
format AENDT date9.;
run;

*NOTE THAT IF C1STRF="BEFORE" AND C1ENDTC IS A PARTIAL DATE 
AND TRTSDT-1<AENDT AND WE IMPUTE AENDT=TRTSDT-1 SET TO 'Y'. 
;

data c6e;
set c5e;
if c1strf eq "BEFORE" and (val1 eq "D" or val1 eq "M") and 
AENDT eq intnx('day', trtsdt, -1, 's') then val1 = "Y";
run;

data c7e(keep=usubjid aendt aendtf);
set c6e;
rename val1 = AENDTF;
run;


%left_join(l=ofc.adc1_5_sh, r=c7e, b=usubjid, o=ofc.adc1_6_sh);

****************************************************************************************;

*AENDY	32	8	;
*If AENDT>=ADSL.TRTSDT then AENDT-ADSL.TRTSDT+1, else AENDT-ADSL.TRTSDT.;
data ofc.adc1_7_sh;
set ofc.adc1_6_sh;
if aendt>=trtsdt then AENDY = aendt-trtsdt+1;
else AENDY = aendt-trtsdt;
run;

****************************************************************************************;

*DRGCOLCD	40	8	
SUPPC1.QVAL WHERE QNAM = "DRGCOLCD";

data supp1(keep=usubjid  DRGCOLCD);
set sd.suppc1;
if prxmatch("m/DRGCOLCD/I", qnam);
rename qval = DRGCOLCD;
run;


proc sql noprint;
create table supp2 as
select * from ofc.adc1_7_sh x
join supp1 y
on x.usubjid = y.usubjid;
quit;
run;


data trnsp1(keep=usubjid idvar idvarval qnam qval);
set sd.suppc1;
if prxmatch("m/DRGCOLCD/I", qnam) and idvar eq "C1SEQ";
run;

data trnsp2(drop=idvar idvarval qnam);
set trnsp1;
C1SEQ= input(idvarval, best.);
rename qval = DRGCOLCD;
run;

%left_join(l=ofc.adc1_7_sh, r=trnsp2, b=usubjid c1seq, o=ofc.adc1_8_sh);

**************************************************************************************************;
*ADECOD	41	178	
FOR SINGLE-INGREDIENT MEDICATION SET TO C1.C1DECOD.
 FOR MULTIPLE-INGREDIENT MEDICATION,
 PERFORM ONE-TO-MANY MERGE OF C1 AND SUPPC1 ON C1.USUBJID=SUPPC1.USUBJID AND
 C1.C1SEQ=NUMERIC SUPPC1.IDVARVAL
 (WHERE SUPPC1.IDVAR='C1SEQ' AND 
 SUPPC1.QNAM='C1DECODX' WHERE X IS AN INTEGER 1 TO N) 
 AND SET TO SUPPC1.QVAL,
 RESULTING IN N+1 RECORDS PER USUBJID, C1SEQ.
 FOR THE ORIGINAL RECORD SET TO 'C1DECOD1+C1DECOD2+..+C1DECODN'.	;
 
*choosing values of multiple ingredients from adc1 created ; 
data ade1(keep=usubjid c1seq);
set ofc.adc1_8_sh;
where c1decod eq "MULTIPLE";
run;

*filtering out values from c1 with help of ade1 file above;
data c1ade(keep=usubjid c1seq);
set sd.c1;
run;
%left_join(l=ade1, r=c1ade, b=usubjid c1seq, o=ade2);







*PERFORM ONE-TO-MANY MERGE OF C1 AND SUPPC1 ON C1.USUBJID=SUPPC1.USUBJID AND
 C1.C1SEQ=NUMERIC SUPPC1.IDVARVAL
 (WHERE SUPPC1.IDVAR='C1SEQ' AND 
 SUPPC1.QNAM='C1DECODX' WHERE X IS AN INTEGER 1 TO N) 
 AND SET TO SUPPC1.QVAL,
 RESULTING IN N+1 RECORDS PER USUBJID, C1SEQ.
 FOR THE ORIGINAL RECORD SET TO 'C1DECOD1+C1DECOD2+..+C1DECODN'.	;

*choosing values from suppc1 where idvar eq c1seq and qnam contains c1decod;
data supade1(keep=usubjid qnam qval idvarval idvar);
set sd.suppc1;
where idvar eq "C1SEQ" and prxmatch("m/c1decod/I", qnam);
run;
proc sort data=supade1;
by usubjid idvarval qnam qval;
run;


data supade2;
length ADECOD $ 178.;
set supade1;
by usubjid idvarval;
retain ADECOD;
if first.idvarval then ADECOD = QVAL;
else ADECOD = cats(ADECOD, "+", QVAL);
run;

data supade3(keep=usubjid ADECOd C1SEQ);
set supade2;
by usubjid idvarval;
if last.idvarval;
C1SEQ = input(idvarval, best.);
run;

*changing supade2 for merging with supade3;
data supade2a(drop=idvarval);
set supade2(keep=usubjid idvarval qval);
C1SEQ= input(idvarval, best.);
rename qval= ADECOD;
run;
*now stacking supade3 on  supade2a(appending);
proc sort data=supade2a;
by usubjid c1seq;
run;
proc sort data=supade3;
by usubjid c1seq;
run;

data final_ade;
length ADECOD $ 178.;
set supade2a supade3;
by usubjid c1seq;
run;

*performing one to many join of ade2 on final_ade;
proc sql noprint;
create table ade3 as
select * from ade2 x
left join final_ade y
on x.usubjid=y.usubjid and x.c1seq=y.c1seq;*x.usubjid=y.usubjid and x.c1seq=y.c1seq;
quit;
proc sort data=ade3;
by usubjid c1seq adecod;
run;


proc sql noprint;
create table ofc.adc1_9_sh as
select * from ofc.adc1_8_sh x
left join ade3 y
on x.usubjid=y.usubjid and x.c1seq=y.c1seq;
quit;

*filling empty adecod with c1decod;
data ofc.adc1_10_sh;
set ofc.adc1_9_sh;
if cmiss(adecod) then ADECOD = c1decod;
run;
***********************************************************************************************;

*C1BASE	43	50	;


*47	adc1	C1ONGO	47	3	
WHEN C1CAT NOT IN ("OTHER TRIAL STUDY TREATMENT" "PRIOR ANTIRETROVIRAL MEDICATION") 
AND C1.C1STRF NOT EQUAL "BEFORE" AND AENDT IS MISSING SET TO 'YES', 
OTHERWISE SET TO 'NO'.	;

data ofc.adc1_11_sh;
set ofc.adc1_10_sh;
if prxmatch("m/OTHER TRIAL STUDY TREATMENT|PRIOR ANTIRETROVIRAL MEDICATION/I", c1cat) and 
C1STRF ne "BEFORE" AND cmiss(AENDT) then C1ONGO= "YES";
else C1ONGO = "NO";
run;

**********************************************************************************************;
*BOOSDG	48	1	
SUPPC1.QVAL WHERE QNAM = "BOOSDG";

data boo1(keep=usubjid BOOSDG c1seq);
set sd.suppc1;
where qnam eq "BOOSDG" and idvar eq "C1SEQ";
C1SEQ= input(idvarval, best.);
rename qval =BOOSDG;
run;


%left_join(l=ofc.adc1_11_sh, r=boo1, b= usubjid c1seq, o=ofc.adc1_12_sh);

************************************************************************************************;
*ANL01FL	49	1	
SINGLE INGREDIENT DRUGS AND ONLY INDIVIDUAL COMPONENTS OF MULTIPLE INGREDIENT DRUGS ARE FLAGGED.	
;
data ofc.adc1_13_sh;
set ofc.adc1_12_sh;
if index(adecod, "+")=0 then ANL01FL= "Y";
run;

************************************************************************************************;
*ANL02FL	50	1	
SINGLE INGREDIENT DRUGS AND MULTIPLE INGREDIENT DRUGS EXPRESSED IN
 TERM A + TERM B FORMAT ARE FLAGGED 
 (INDIVIDUAL COMPONENTS OF MULTIPLE INGREDIENT RECORDS ARE EXCLUDED).	
;

data ofc.adc1_14_sh;
set ofc.adc1_13_sh;
if c1decod ne "MULTIPLE" or (c1decod eq "MULTIPLE" and index(adecod, "+")>0) then ANL02FL= "Y";
run;
***********************************************************************************************;
*ANL03FL	51	1	
FLAG FOR ART MEDICATIONS. I.E. 
IF C1CAT IN 
("OTHER TRIAL STUDY TREATMENT" "PRIOR ANTIRETROVIRAL MEDICATION" "ANTIRETROVIRAL MEDICATION") 
SET TO 'Y, OTHERWISE SET TO MISSING.	
;

data ofc.adc1_15_sh;
set ofc.adc1_14_sh;
if prxmatch("m/OTHER TRIAL STUDY TREATMENT|PRIOR ANTIRETROVIRAL MEDICATION|ANTIRETROVIRAL MEDICATION/I", c1cat)
then ANL03FL = "Y";
run;

*LPDBLFL	52	1	



***********************************************************************************************;
*booster drugs??[astdtf, aendtf]...ans:boosdg solved;
*gskdrug dataset missing[c1base(43)];
*cmdrgcol??[c1basecd(44)]--gsk file;
*c1base1[45];