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
%macro adisrchg_check(v=);
data adisrchg_check1(keep=usubjid &v);
set ad.adisrchg;
run;
%mend;
***************;

data ofc.adisrchg_guide(keep= dataset variable var_order length derivation source_var origin);
set nm.adam_guide;
where dataset eq "adisrchg";
run;

***********************************************************************************************************;

***********************************************************************************************************;
*first importing ae dataset from sdtm;
data ae_sh(keep=usubjid aerefid aecat aemodify aetoxgr);
set sd.ae;
run;

*filtering out values from ae where aemodify = "" and aecat= ""..in other terms, aemodify and aecat should be missing;

data ae1_sh;
set ae_sh;
where (cmiss(aemodify) and cmiss(aecat));
run;

*copying the value of ae1_sh to ae1a_sh so that we will not change the values of ae1_sh.so ae1a_sh is just the duplicate of ae1_sh;

data ae1a_sh;
set ae1_sh;
run;


* I want to know if there are duplicate values of aerefid in each usubjid, if there are any then they are stored in
ae2_sh;
proc sort data=ae1a_sh nodupkey dupout=ae2_sh;
by usubjid aerefid;
run;

*now form ae1_sh , only getting those values which are present in ae2_sh----->by left join;
data ae3_sh(keep=usubjid aerefid);
set ae2_sh;
run;

proc sort data=ae1_sh;
by usubjid aerefid;
run;
proc sort data=ae3_sh;
by usubjid aerefid;
run;


data ofc.ae4_sh;
merge ae3_sh(in=x) ae1_sh(in=y);
by usubjid aerefid;
if x;
run;


*since there are only 2 repeats of each aerefid in each usubjid, we can use first.aerefid and last.aerefid to find out
aetoxgr;
data ae5_sh(keep=usubjid aerefid aetoxgr sum_sh);
set ofc.ae4_sh;
by usubjid aerefid;
retain sum_sh;
if first.aerefid then sum_sh= aetoxgr;
else sum_sh= sum_sh+aetoxgr;
run;

data ae6_sh(keep=usubjid aerefid);
set ae5_sh;
if sum_sh eq 3;
run;

data ae7_sh(keep=usubjid aerefid);
merge ae6_sh(in=x) ae5_sh(in=y);
by usubjid aerefid;
if x;
run;

*loading adaeisr;
data adaeisr1_sh;
set ad.adaeisr;
run;

proc sort data=adaeisr1_sh;
by usubjid aerefid;
run;
proc sort data=ae7_sh;
by usubjid aerefid;
run;

data ofc.adisrchg1;
merge ae7_sh(in=x) adaeisr1_sh(in=y);
by usubjid aerefid;
if x;
run;


data ofc.adisrchg2_sh;
set ofc.adisrchg1 (keep=STUDYID SITEID USUBJID LTSUBJID AGE AGEU SEX RACE
COUNTRY SCRNFL SAFFL ITTEFL PPROTFL ENRLFL
LTFUFL TRT01P TRT01PN TRT01A TRT01AN TRTP
TRTPN TRTA TRTAN TRTSDT TRTEDT MNTEDT
WEIGHTBL APHASE APHASEN AESTDTC ASTDT ASTDTC
ASTDTF AEENDTC AENDT AENDTC AENDTF AESEQ
AETERM AEDECOD AEBODSYS AEBDSYCD ADURN ADURU
ADURC AEACN AEREFID AESER AEOUT AEOUTN AEREL AFTRTSTC
ALTRTSTC ATTRTSTC AEWD AECAT ALAT DRUG);
run;

*************************************************************************************************************
*ASEQ	59
*AE.AESEQ WHERE AE.AEMODIFY = ' ' AND AE.AECAT=' ' AND AE.ARREFID = ADAEISR.AEREFID;

data ae_a_sh(keep=usubjid aeseq aerefid);
set sd.ae;
where cmiss(aemodify) and cmiss(aecat);
run;

data adaeisr_a_sh(keep=usubjid aerefid);
set ad.adaeisr;
run;

proc sort data=ae_a_sh;
by usubjid aerefid;
run;
proc sort data=adaeisr_a_sh;
by usubjid aerefid;
run;

data aeseq1_sh;
merge ae_a_sh adaeisr_a_sh;
by usubjid aerefid;
rename aeseq = ASEQ;
run;

%left_join(l=ofc.adisrchg2_sh, r= aeseq1_sh, b= usubjid aerefid, o= ofc.adisrchg3_sh);

%adisrchg_check(v=aerefid aeseq aseq);
*************************************************************************************************************;

*INTGDCHN	60

*AE.ATOXGR WHERE AE.AEMODIFY = ' ' AND AE.AECAT=' ' AND AE.ARREFID = ADAEISR.AEREFID;


data intg1_sh(keep=usubjid aetoxgr aerefid);
set sd.ae;
where cmiss(aemodify) and cmiss(aecat);
run;

data intg2_sh(keep=usubjid aerefid);
set ad.adaeisr;
run;

proc sort data=intg1_sh;
by usubjid aerefid;
run;
proc sort data=intg2_sh;
by usubjid aerefid;
run;

data intg3_sh;
merge intg1_sh intg2_sh;
by usubjid aerefid;

run;

%left_join(l=ofc.adisrchg3_sh, r= intg3_sh, b= usubjid aerefid, o= ofc.adisrchg4_sh);

%adisrchg_check(v=aerefid intgdchn);

data ofc.adisrchg5_sh(drop=aetoxgr);
set ofc.adisrchg4_sh;
INTGDCHN = input(strip(AETOXGR), best.);
run;


***********************************************************************************************************;
*INTGRDCH	61	19	
DECODE OF INTGDCHN;

proc format;
value intgrdch
1 =	"MILD OR GRADE 1"
2 =	"MODERATE OR GRADE 2"
3 =	"SEVERE OR GRADE 3"
4 =	"POTENTIALLY LIFE-THREATENING OR GRADE 4"
5 =	"DEATH OR GRADE 5"
;
run;

data ofc.adisrchg6_sh;
length INTGRDCH $ 19.;
set ofc.adisrchg5_sh;
INTGRDCH = put(intgdchn, intgrdch.);
run;

************************************************************************************************************;
*CHDTC	62	10	
*AE.AESTDTC WHERE AE.AEMODIFY = ' ' AND AE.AECAT= ' ' AND AE.ARREFID = ADAEISR.AEREFID	;

data chdtc1_sh(keep=usubjid aestdtc aerefid);
set sd.ae;
where cmiss(aemodify) and cmiss(aecat);
run;

data chdtc2_sh(keep=usubjid aerefid);
set ad.adaeisr;
run;

proc sort data=chdtc1_sh;
by usubjid aerefid;
run;
proc sort data=chdtc2_sh;
by usubjid aerefid;
run;

data chdtc3_sh;
merge chdtc1_sh chdtc2_sh;
by usubjid aerefid;

run;

data chdtc4_sh(drop=aestdtc);
set chdtc3_sh;
CHDTC= input(aestdtc, yymmdd10.);
format CHDTC yymmdd10.;
run;



%left_join(l=ofc.adisrchg6_sh, r= chdtc4_sh, b= usubjid aerefid, o= ofc.adisrchg7_sh);

%adisrchg_check(v=aerefid chdtc);

**********************************************************************************************************;
*CHDT	63	8	;
*Convert AE.AESTDTC to SAS date value using the IS8601DA informat.;
*ACHDTC	64	9	
*AE.AESTDTC in date9 format with no imputation.
; 

data ofc.adisrchg8_sh;
set ofc.adisrchg7_sh;
CHDT = CHDTC;
ACHDTC = CHDTC;
format CHDT ACHDTC date9.;
run;
***********************************************************************************************************;

*ANL01FL	65	1
*After joining with AE
 (where AE.AEDECOD='' and AECAT= '' and AE.AEREFID=ADAEISR.AEREFID),
 sort by USUBJID, AEREFID, AESTDTC, ASEQ and flag the earliest record as
 'Y' to indicate the first occurrence of the AE.;
/*   */
/* data anl1_sh(keep=usubjid aerefid aedecod aecat aemodify aestdtc1); */
/* set sd.ae; */
/* where aemodify eq "" and aecat eq ""; */
/* aestdtc1 = input(aestdtc, yymmdd10.); */
/* format aestdtc1 date9.; */
/* run; */
/*  */
/* data anl2_sh(keep=usubjid aerefid); */
/* set ad.adaeisr; */
/* run; */
/*  */
/* proc sort data=anl1_sh; */
/* by usubjid aerefid; */
/* run; */
/* proc sort data=anl2_sh; */
/* by usubjid aerefid; */
/* run; */
/*  */
/* data anl3_sh; */
/* merge anl1_sh anl2_sh; */
/* by usubjid aerefid; */
/* run; */
/*  */

data adisrchg9_sh;
set ofc.adisrchg8_sh;
run;

proc sort data=adisrchg9_sh;
by usubjid aerefid chdtc aseq;
run;

data ofc.adisrchg10_sh;
set adisrchg9_sh;
by usubjid aerefid;
if first.aerefid then ANL01FL= "Y";
run;



**********************************************************************************************************;

%adisrchg_check(v= aerefid achdtc aseq anl01fl);



**************************************************************
code ayusa;

/* ASEQ */
/* AE.AESEQ WHERE AE.AEMODIFY = ' ' AND AE.AECAT=' ' AND AE.ARREFID = ADAEISR.AEREFID */

/* filtering observations with missing aemodify and aecat */
data ofc.adisrchg1_am;
	set sd.ae(keep=usubjid aerefid aemodify aecat aeseq);
	where cmiss(aemodify) and  cmiss(aecat);
run;

/* retrieving aerefid from ADAEISR dataset */
data ofc.adisrchg2_am;
	set ad.adaeisr(keep=usubjid aerefid);
	rename aerefid=aeref;
run;

proc sort data=ofc.adisrchg1_am;
by usubjid aerefid;
run;
proc sort data=ofc.adisrchg2_am;
by usubjid aeref;
run;
************************************************************************************************;


proc sql noprint;
create table combined2 as
select * from ofc.adisrchg1_am a
join ofc.adisrchg2_am b
on a.usubjid = b.usubjid;
quit;
run;

data combined3(drop=aecat aemodify);
set combined2;
if aerefid eq aeref;
run;
******************************************************************************************************;