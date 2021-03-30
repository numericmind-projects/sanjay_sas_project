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
%macro adaeisr1_check(v=);
data adaeisr1_check(keep=usubjid &v);
set ad.adaeisr;
run;
%mend;

***************;

**************************************************************************************************;
%macro pred_usubj1(meta_source=, dataset=, pull_from=, library=, output_name=);

proc import datafile= "&meta_source"
		out=meta_file_sh dbms=xlsx;
	sheet="Variables";
	getnames=yes;
run;


data sh1;
set meta_file_sh;
where dataset eq "&dataset" and scan(source_var, 1, ".") eq upper("&pull_from");*prxmatch("m/^&pull_from/I", source_var);
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



/* extract pred from other files from where usubjid is not taken; */
%macro pred_other1(prev_file=, dataset=,  pull_from=, library=, output_name=);


proc sort data=&prev_file;
by usubjid;
run;
%let sh4= .;





data sh4a;
set meta_file_sh;
where dataset eq "&dataset" and scan(source_var, 1, ".") eq upper("&pull_from");*prxmatch("m/^&pull_from/I", source_var);
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
/***************************************************************************************************; */
/* data ofc.adaeisr_guide(keep= dataset variable var_order length derivation source_var origin); */
/* set nm.adam_guide; */
/* where dataset eq "adaeisr"; */
/* run; */
*************************************************************************************************;

*How to import dataset from adae?
Includes all safety population subjects on the 'CAB LA + RPV LA' treatment ARM. 
ISRs are taken from ADAE where APHASE = "Maintenance" and
 (    (AETERM includes "STUDY DRUG INJECTION SITE" and AESER = "Y")
 or AECAT = "INJECTION SITE REACTION"     ).;
 
 
data ofc.adae;
set ad.adae;
where aphase eq "Maintenance" and ((prxmatch("m/STUDY DRUG INJECTION SITE/I", aeterm) and aeser eq "Y")
 or aecat eq "INJECTION SITE REACTION");
run;

*extracting predecessors from ofc.adae;
%pred_usubj1(meta_source=/folders/myfolders/New_Study_master/adam/ADAM_Metadata_Reviewer_Aid_28APR2020.xlsm, 
dataset=adaeisr, pull_from=adae, library=ofc, output_name=ofc.adaeisr1_sh);
%pred_other1(prev_file=ofc.adaeisr1_sh, dataset=adaeisr,  pull_from=adsl, library=ad, output_name=ofc.adaeisr2_sh);


*not resolved:

*trtp
*trtpn
*trta
*trtan
;

data ofc.adaeisr3_sh;
set ofc.adaeisr2_sh;
TRTP=TRT01P;
TRTPN= TRT01PN;
TRTA= TRT01A;
TRTAN=TRT01AN;
RUN;
***********************************************************************************************;

*AENIMDY	40	8	
*Populated for all ISR records. 
If analysis AE end date is not missing then 
AENIMDY = 
analysis AE end date (ADAE.AENDT)  - date of first exposure to treatment (ADSL.TRTSDT) + 1. 
If analysis AE end date is missing then 
AENIMDY = date of last study contact -  date of first exposure to treatment (ADSL.TRTSDT) + 1. 
For Figures 3.3-3.5.


*missing aendt;
data aendt_miss(keep=usubjid aeseq trtsdt);
set ofc.adaeisr3_sh;
if cmiss(aendt);
run;


*extracting date of last study contact from sv dataset;
data sv_for_miss(keep=usubjid svstdtc1 svendtc1 date_of_last_study_contact);
set sd.sv;
svstdtc1= input(svstdtc, yymmdd10.);
svendtc1= input(svendtc, yymmdd10.);
format svstdtc1 svendtc1 date9.;
if svstdtc1>svendtc1 then date_of_last_study_contact = svstdtc1;
else date_of_last_study_contact= svendtc1;
format svstdtc1 svendtc1 date_of_last_study_contact date9.;
run;

*taking the latest date from sv_for_miss;
proc sort data=sv_for_miss;
by usubjid descending date_of_last_study_contact;
run;

data latest_sv(drop=svstdtc1 svendtc1);
set sv_for_miss;
by usubjid;
if first.usubjid;
run;

*calculating aendt for aendt_miss;
%left_join(l=aendt_miss, r=latest_sv, b=usubjid, o=aendt_miss1);

data aendt_miss2(keep=usubjid aeseq aenimdy);
set aendt_miss1;
AENIMDY= datdif(trtsdt, date_of_last_study_contact, "act/act")+1;
run;

%left_join(l=ofc.adaeisr3_sh, r=aendt_miss2, b=usubjid aeseq, o=ofc.adaeisr4_sh);

*for missing values in aenimdy, we can add aendt-trtsdt+1;
data ofc.adaeisr5_sh;
set ofc.adaeisr4_sh;
if cmiss(aenimdy) then AENIMDY= datdif(trtsdt, aendt, "act/act")+1;
run;


***********************************************************************************************;

/*  */
/* data ghgh; */
/* set ad.adaeisr; */
/* if usubjid eq "116482.000478"; */
/* run; */
/*  */
/*  */
/* data check1; */
/* xyz= datdif("09oct2018"d, "03jan2020"d, "act/act")+1; */
/* run; */

*************************************************************************************************;

*ISRCAT	84	20	
*Set to 'CAB LA and/or RPV LA' for all ISRs from either CAB, RPV or both;
*ISRCATCD	85	6	IF ISRCAT='CAB LA AND/OR RPV LA' THEN ISRCATCD='ISRALL'
;
data ofc.adaeisr6_sh;
set ofc.adaeisr5_sh;
length ISRCAT $ 20.;
if prxmatch("m/cab|rpv/I", drug) then do; 
ISRCAT =  "CAB LA and/or RPV LA";
ISRCATCD = "ISRALL";
end;
run;

***************************************************************************************************;

*AEDURGP	86	4	
*If  1<=ADURN<=7 then '1-7', 
else if 8<=ADURN<=14 then '8'-14', 
else if ADURN>14 then '>14', 
else blank;

proc format;
value aedurgp
1-7= "1-7"
8-14= "8-14"
15-high = ">14"
;
run;

data ofc.adaeisr7_sh;
set ofc.adaeisr6_sh;
AEDURGP = put(adurn, aedurgp.);
run;

data dumm(keep=usubjid adurn aedurgp);
set ofc.adaeisr7_sh;
run;
***************************************************************************************************;

*AEDURCD	87	8	
IF AEDURGP='1-7' THEN 1,
 IF AEDURGP='8-14' THEN 2,
 IF AEDURGP='>14' THEN 3,
 OTHERWISE MISSING	
;
proc format;
value $ aedurcd
"1-7"=1
"8-14"=2
">14"=3
;
run;
data ofc.adaeisr8_sh;
set ofc.adaeisr7_sh;
AEDURCD = input(put(aedurgp, aedurcd.), best.);
run;
**************************************************************************************************;


*MAXDUR	88	8	;
*Maximum ADURN by USUBJID and APHASE;
data maxdur1;
set ofc.adaeisr8_sh(keep=usubjid aeseq aphase adurn);
run;
proc sort data=maxdur1;
by usubjid aphase descending adurn;
run;

data maxdur2;*(keep=usubjid aeseq MAXDUR);
set maxdur1;
by usubjid aphase;
retain MAXDUR;
if first.aphase then MAXDUR= ADURN;
else MAXDUR= MAXDUR;
run;

%left_join(l=ofc.adaeisr8_sh, r=maxdur2, b=usubjid aeseq, o=ofc.adaeisr9_sh);
************************************************************************************************;
*CMAXDUR	89	8	;
*Maximum ADURN by USUBJID, AEDECOD and APHASE;
data cmaxdur1(keep=usubjid aeseq aedecod aphase adurn);
set ofc.adaeisr9_sh;
run;
proc sort data=cmaxdur1;
by usubjid aphase aedecod descending adurn;
run;
data cmaxdur2(keep=usubjid aeseq cmaxdur);
set cmaxdur1;
by usubjid aphase aedecod;
retain CMAXDUR;
if first.aedecod then CMAXDUR =adurn;
else CMAXDUR= CMAXDUR;
run;

%left_join(l=ofc.adaeisr9_sh, r=cmaxdur2, b=usubjid aeseq, o=ofc.adaeisr10_sh);


************************************************************************************************;
*MXSUBDR	90	4
If 1<=MAXDUR<=7 then '1-7', 
If 8<=MAXDUR<=14 then '8-14', 
If 14<MAXDUR then '>14', 
otherwise blank	
;

proc format;
value mxsubdr
1-7= "1-7"
8-14= "8-14"
15-high = ">14"
;
run;

data ofc.adaeisr11_sh;
set ofc.adaeisr10_sh;
MXSUBDR = put(maxdur, mxsubdr.);
run;
*************************************************************************************************;
*MXSBDRCD	91	8
IF MXSUBDR =  '1-7' THEN 1, 
IF MXSUBDR =  '8-14' THEN 2, 
IF MXSUBDR ='>14' THEN 3, 
OTHERWISE MISSING;

proc format;
value $ mxsbdrcd
"1-7"=1
"8-14"=2
">14"=3
;
run;

data ofc.adaeisr12_sh;
set ofc.adaeisr11_sh;
MXSBDRCD = input(put(mxsubdr, mxsbdrcd.), best.);
run;
*************************************************************************************************;
*CMXSBDR	92	4	
*If 1<=CMAXDUR<=7 then '1-7', 
If 8<=CMAXDUR<=14 then '8-14', 
If 14<CMAXDUR then '>14', 
otherwise blank;

*using the same proc format of mxsubdr;
data ofc.adaeisr13_sh;
set ofc.adaeisr12_sh;
CMXSBDR = put(cmaxdur, mxsubdr.);
run;
**************************************************************************************************;
*CMXSDRCD	93	8	
IF CMXSBDR =  '1-7' THEN 1, 
IF CMXSBDR =  '8-14' THEN 2, 
IF CMXSBDR ='>14' THEN 3, 
OTHERWISE MISSING	

using the same proc fromat of mxbrcd;
data ofc.adaeisr14_sh;
set ofc.adaeisr13_sh;
CMXSDRCD = input(put(cmxsbdr, mxsbdrcd.), best.);
run;
**************************************************************************************************;
*GR35FL	94	1	;
*Y' if AETOXGRN in (3 4 5);
data ofc.adaeisr15_sh;
set ofc.adaeisr14_sh;
if aetoxgrn in (3, 4, 5) then GR35FL = "Y";
run;
**************************************************************************************************;
*NUMINJ	98	8
*Number of injections by USUBJID and APHASE. 
Calculated via the number of entries for each USUBJID in SDTM.EX 
where EX.EXROUTE = 'INTRAMUSCULAR' and EX.EXTPT in ('CAB IM DOSE' 'RPV IM DOSE').;

data ex1;
set sd.ex;
where exroute eq "INTRAMUSCULAR" and extpt in ("CAB IM DOSE", "RPV IM DOSE");
run;

data ex2(keep=usubjid usub_counts);
set ex1;
by usubjid;
retain usub_counts;
if first.usubjid then usub_counts =1;
else usub_counts= usub_counts+1;
run;

data ex3(keep=usubjid NUMINJ);
set ex2;
by usubjid;
if last.usubjid;
rename usub_counts= NUMINJ;
run;

%left_join(l=ofc.adaeisr15_sh, r=ex3, b=usubjid, o=ofc.adaeisr16_sh);
**************************************************************************************************;
*NUMINJCB	99	8	
*Number of CAB injections by USUBJID and APHASE. 
Calculated via the number of entries for each USUBJID in SDTM.EX where 
EX.EXROUTE = 'INTRAMUSCULAR' and EX.EXTPT in ('CAB IM DOSE').
;
data numi1(keep=usubjid);
set sd.ex;
where exroute eq "INTRAMUSCULAR" and extpt eq "CAB IM DOSE";
run;
data numi2(keep=usubjid NUMINJCB);
set numi1;
by usubjid;
retain NUMINJCB;
if first.usubjid then NUMINJCB=1;
else NUMINJCB = NUMINJCB+1;
if last.usubjid;
run;


%left_join(l=ofc.adaeisr16_sh, r=numi2, b=usubjid, o=ofc.adaeisr17_sh);
*************************************************************************************************;
*NUMINJRV	100	8;
*Number of RPV injections by USUBJID and APHASE. 
Calculated via the number of entries for each USUBJID in SDTM.EX where 
EX.EXROUTE = 'INTRAMUSCULAR' and EX.EXTPT in ('RPV IM DOSE').
;
data numi11(keep=usubjid);
set sd.ex;
where exroute eq "INTRAMUSCULAR" and extpt eq "RPV IM DOSE";
run;
data numi21(keep=usubjid NUMINJRV);
set numi11;
by usubjid;
retain NUMINJRV;
if first.usubjid then NUMINJRV=1;
else NUMINJRV = NUMINJRV+1;
if last.usubjid;
run;


%left_join(l=ofc.adaeisr17_sh, r=numi21, b=usubjid, o=ofc.adaeisr18_sh);
*************************************************************************************************;
*NUMEVE	101	8	
*Total ISRs by USUBJID and APHASE. 
Count the number of ISRs each USUBJID has from ADAE. 
An ISR is an Adverse Event where 
(AETERM includes 'STUDY DRUG INJECTION SITE' and AESER='Y') or AECAT='INJECTION SITE REACTION'
;

data numeve1(keep=usubjid aeterm aeser aecat);
set ad.adae;
where(prxmatch("m/STUDY DRUG INJECTION SITE/I" ,AETERM) and aeser eq 'Y') or aecat eq 'INJECTION SITE REACTION';
run;
data numeve2(keep=usubjid numeve);
set numeve1;
by usubjid;
retain NUMEVE;
if first.usubjid then NUMEVE=1;
else NUMEVE = NUMEVE+1;
if last.usubjid;
run;

%left_join(l=ofc.adaeisr18_sh, r=numeve2, b=usubjid, o=ofc.adaeisr19_sh);
*************************************************************************************************;
*NUMEVECT	102	5	
If NUMEVE=0 then 'Zero', 
If NUMEVE=1 then 'One', 
If NUMEVE=2 then 'Two', 
If NUMEVE=3 then 'Three', 
If NUMEVE=4 then 'Four', 
If NUMEVE=5 then 'Five', 
If 6<=NUMEVE<=10 then '6-10', 
If 11<=NUMEVE<=15 then '11-15', 
If 16<=NUMEVE<=20 then '16-20', 
if NUMEVE>20 then '>20'
;
proc format;
value numevect
0 = "Zero"
1= "One"
2= "Two"
3= "Three"
4= "Four"
5="Five"
6-10 = "6-10"
11-15= "11-15"
16-20 = "16-20"
21-high = ">20"
;
run;

data ofc.adaeisr20_sh;
set ofc.adaeisr19_sh;
NUMEVECT = put(numeve, numevect.);
run;

************************************************************************************************;

*NUMEVECD	103	8	
IF NUMEVECT='ONE' THEN 1, 
IF NUMEVECT='TWO' THEN 2, 
IF NUMEVECT='THREE' THEN 3, 
IF NUMEVECT='FOUR' THEN 4, IF NUMEVECT='FIVE' THEN 5, 
IF NUMEVECT='6-10' THEN 6, 
IF NUMEVECT='11-15' THEN 11, 
IF NUMEVECT='16-20' THEN 16, 
IF NUMEVECT='>20' THEN 21	;

proc format;
value $ numevecd
"Zero"=0
"One"=1
"Two"=2
"Three"=3
"Four"=4
"Five"=5 
"6-10"=6 
"11-15"=11
"16-20"=16
">20"=21
;
run;

data ofc.adaeisr21_sh;
set ofc.adaeisr20_sh;
NUMEVECD = input(put(numevect, numevecd.), best.);
run;
*************************************************************************************************;
*CNUMEVE	104	8	
*Total ISRs by USUBJID, AEDECOD and APHASE;
data cnumeve1;
set ofc.adaeisr21_sh(keep=usubjid aeseq aedecod aphase);
run;
proc sort data=cnumeve1;
by usubjid aphase aedecod;
run;

data cnumeve2;
set cnumeve1;
by usubjid aphase aedecod;
retain CNUMEVE_decoy;
if first.aedecod then CNUMEVE_decoy=1;
else CNUMEVE_decoy= CNUMEVE_decoy+1;
run;

proc sort data=cnumeve2;
by usubjid aphase aedecod descending cnumeve_decoy;
run;

data cnumeve3(keep=usubjid aeseq CNUMEVE);
set cnumeve2;
by usubjid aphase aedecod;
retain CNUMEVE;
if first.aedecod then CNUMEVE= cnumeve_decoy;
else CNUMEVE= CNUMEVE;
run;
%left_join(l=ofc.adaeisr21_sh, r=cnumeve3, b=usubjid aeseq, o=ofc.adaeisr22_sh);

************************************************************************************************;

*CNUMEVCT	105	5	
*If CNUMEVE=0 then 'Zero', 
If CNUMEVE=1 then 'One', 
If CNUMEVE=2 then 'Two', 
If CNUMEVE=3 then 'Three', 
If CNUMEVE=4 then 'Four', 
If CNUMEVE=5 then 'Five', 
If 6<=CNUMEVE<=10 then '6-10', 
If 11<=CNUMEVE<=15 then '11-15', 
If 16<=CNUMEVE<=20 then '16-20', 
if CNUMEVE>20 then '>20';

*using proc format numevect;
data ofc.adaeisr23_sh;
set ofc.adaeisr22_sh;
CNUMEVCT= put(cnumeve, numevect.);
run;

*************************************************************************************************;
*CNUMEVCD	106	8	
IF CNUMEVCT='ONE' THEN 1, 
IF CNUMEVCT='TWO' THEN 2, 
IF CNUMEVCT='THREE' THEN 3, 
IF CNUMEVCT='FOUR' THEN 4, 
IF CNUMEVCT='FIVE' THEN 5, 
IF CNUMEVCT='6-10' THEN 6, 
IF CNUMEVCT='11-15' THEN 11, 
IF CNUMEVCT='16-20' THEN 16, 
IF CNUMEVCT='>20' THEN 21;

*using proc format 	numevecd;
data ofc.adaeisr24_sh;
set ofc.adaeisr23_sh;
CNUMEVCD= input(put(CNUMEVCT, numevecd.), best.);
run;

*************************************************************************************************;
*NUMINJVS	107	8;
*Number of injection visits by USUBJID and APHASE. 
Multiple injections on one day count as one visit.

*injection visits are present in ex dataset;

data jvs1(keep=usubjid visitnum);
    set sd.ex;
    where excat eq "MAINTENANCE PHASE" and exroute eq 'INTRAMUSCULAR' and extpt in ('CAB IM DOSE' 'RPV IM DOSE'); 
run;
proc sort data=jvs1 nodup;
by usubjid;
run;


data jvs2(drop=visitnum);
set jvs1;
by usubjid;
retain NUMINJVS;
if first.usubjid then NUMINJVS=1;
else NUMINJVS=NUMINJVS+1;
if last.usubjid;
run;

%left_join(l=ofc.adaeisr24_sh, r=jvs2, b=usubjid, o=ofc.adaeisr25_sh);
**************************************************************************************************;
*EVERATE	95	
*NUMEVE/NUMINJVS
;
data ofc.adaeisr26_sh;
set ofc.adaeisr25_sh;
EVERATE= numeve/numinjvs;
run;
**************************************************************************************************;

*GR35EVE	108	8	;
*Total number of grade 3-5 ISRs (GR35FL='Y') by USUBJID, APHASE;
data gr1;
set ofc.adaeisr26_sh(keep=usubjid aphase aeseq gr35fl);
if gr35fl eq "Y" then cnt=1;
else cnt =0;
run;
data gr2(keep=usubjid aphase GR35EVE);
set gr1;
by usubjid aphase;
retain GR35EVE;
if first.aphase then GR35EVE= cnt;
else GR35EVE= GR35EVE+cnt;
if last.aphase;
run;

proc sort data=gr2 nodup;
by usubjid;
run;

%left_join(l=ofc.adaeisr26_sh, r=gr2, b=usubjid aphase, o=ofc.adaeisr27_sh);
*************************************************************************************************;
*GR35EVCT	109	4	
*If GR35EVE=0 then 'Zero', 
If GR35EVE=1 then 'One', 
If GR35EVE=2 then 'Two', 
If GR35EVE=3 then 'Three', 
If GR35EVE=4 then 'Four', 
If GR35EVE=5 then 'Five', 
If 6<=GR35EVE<=10 then '6-10', 
If 11<=GR35EVE<=15 then '11-15', 
If 16<=GR35EVE<=20 then '16-20', 
if GR35EVE>20 then '>20';


*using proc format numevect;

data ofc.adaeisr28_sh;
set ofc.adaeisr27_sh;
GR35EVCT= put(GR35EVE, numevect.);
run;
*************************************************************************************************;
*GR35EVCD	110	8	
IF GR34EVCT='ONE' THEN 1, 
IF GR34EVCT='TWO' THEN 2, 
IF GR34EVCT='THREE' THEN 3, 
IF GR34EVCT='FOUR' THEN 4, 
IF GR34EVCT='FIVE' THEN 5, 
IF GR34EVCT='6-10' THEN 6, 
IF GR34EVCT='11-15' THEN 11, 
IF GR34EVCT='16-20' THEN 16, 
IF GR34EVCT='>20' THEN 21	;

*using proc format numevecd;
data ofc.adaeisr29_sh;
set ofc.adaeisr28_sh;
GR35EVCD= input(put(GR35EVCT, numevecd.), best.);
run;
*************************************************************************************************;
*CGR35EVE	111	8	
Total number of grade 3-5 ISRs (GR35FL='Y') by USUBJID, AEDECOD and APHASE;

data gr11;
set ofc.adaeisr26_sh(keep=usubjid aphase aeseq aedecod gr35fl);
if gr35fl eq "Y" then cnt=1;
else cnt =0;
run;
proc sort data=gr11;
by usubjid aphase aedecod;
run;

data gr21(keep=usubjid aphase aedecod CGR35EVE);
set gr11;
by usubjid aphase aedecod;
retain CGR35EVE;
if first.aedecod then CGR35EVE= cnt;
else CGR35EVE= CGR35EVE+cnt;
if last.aedecod;
run;

proc sort data=gr21 nodup;
by usubjid;
run;

%left_join(l=ofc.adaeisr29_sh, r=gr21, b=usubjid aphase AEDECOD, o=ofc.adaeisr30_sh);
*************************************************************************************************;
*CGR35EVC	112	4	
*SAME CONDITIN AS GR35EVCT;
*USING PROC FORMAT numevect;

data ofc.adaeisr31_sh;
set ofc.adaeisr30_sh;
CGR35EVC= put(CGR35EVE, numevect.);
run;

*CGR35ECD	113	8	;
data ofc.adaeisr32_sh;
set ofc.adaeisr31_sh;
CGR35ECD= input(put(CGR35EVC, numevecd.), best.);
run;
*************************************************************************************************;

*INCOMPLETE FROM HERE-----------------------------------\
														\
														\
														\
														\
														\
														\
														\


*ANDLCAT	114	12	
*For each ISR record, where EX.EXTRT=DRUG and 
EX.EXLAT=ALAT for EX.VISIT (including unscheduled visits) given 
by the most recent numeric date part of EX.EXSTDTC on or before ASTDT, 
find the corresponding needle length from 
SUPPEX.QVAL where QNAM=NDLLGTH. 
If QNAM=NDLLGTHU and QVAL^='in' 
then convert needle length to inches: 
if unit 'mm' then ANDLLGTH= NDLLGTH/25.4, 
if unit 'cm' then ANDLLGTH=NDLLGTH/2.54. 

If DRUG is missing and ALAT is not missing for an ISR, 
use ALAT to derive the associated needle length. 
If both DRUG and ALAT are missing, and the needle length(s) at 
its associated injection is/are the same, 
we can assume this needle length for this ISR.
;

data and1;
set ofc.adaeisr32_sh(keep=usubjid aeseq alat drug astdt);
run;

data and2;
set sd.ex(keep=usubjid exseq extrt exlat visit exstdtc);
rename usubjid=usubjid1;
run;

data and3;
set sd.suppex;
run;


*combining and1 and and2 for comparision;
proc sql noprint;
create table and4 as
select * from and1 x
join and2 y
on x.usubjid=y.usubjid1 and x.aeseq=y.exseq and x.alat=y.exlat and x.drug=y.extrt;
quit;


data and5;
set and4;
exstdtc1= input(scan(strip(exstdtc), 1, "T"), yymmdd10.);
format exstdtc1 date9.;
if exstdtc1<=astdt;
run;



*************************************************************************************************;
/* data dumm(keep=usubjid aeseq aphase adurn maxdur); */
/* set ofc.adaeisr9_sh; */
/* run; */
/*  */
/*  */
/* %adaeisr1_check(v=usubjid aeseq andlcat); */
