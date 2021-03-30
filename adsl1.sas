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
%macro adsl_check(v=);
data adsl_check1(keep=usubjid &v);
set adam_lib.adsl;
run;
%mend;
***************;


data adsl1.predecessor1(keep=variable var_order);
	set nm.adsl_guide;

	if origin eq 'PREDECESSOR' & prxmatch("/^DM/", source_var);
run;

proc transpose data=adsl1.predecessor1 out=adsl1.FOR_COLUMNS(drop=_name_ 
		_label_);
	id variable;
run;

proc sql noprint;
	select name into: adsl_cnames separated by " " from dictionary.columns where 
		LIBNAME='ADSL1' AND MEMNAME='FOR_COLUMNS';
QUIT;

%put naam= &adsl_cnames.;

data adsl1.adsl_final1(keep= &adsl_cnames.);
	set sdtm_lib.dm;
run;

*predecessors except srgender is solved;
*variable 21;
*srgender;
*	SC.SCSTRESC WHERE SC.SCTESTCD = "GENDER";

data adsl1.srgender(keep=USUBJID SRGENDER);
	set sdtm_lib.sc;
	where SCTESTCD eq 'GENDER';
	rename scstresc=SRGENDER;
run;

proc sort data=adsl1.srgender nodup;
	by usubjid;
run;

proc sort data=adsl1.adsl_final1 nodup;
	by usubjid;
run;

data adsl1.adsl_final1;
	merge adsl1.adsl_final1(in=adsl) adsl1.srgender(in=sgdr);
	by usubjid;

	if adsl;
run;

*  #11 AGEGR1N: IF . <AGE<35 THEN AGEGR1N=1, ELSE IF 35=<AGE<50 THEN AGEGR1N=2, ELSE IF AGE>=50 THEN AGEGR1N=3.;

proc format;
	value agegr1_num
	0-<35=1
	35-<50=2
	50-high=3;
run;

proc format;
	value agegr1_char
	0-<35="<35"
	35-<50="35-<50"
	50-high=">=50";
run;

*IF . <AGE=<18 THEN AGEGR2N=1, ELSE IF 19=<AGE=<64 THEN AGEGR2N=2, ELSE IF AGE>=65 THEN AGEGR2N=3.	;
proc format;
	value agegr2_num
	0-18 = 1
	19-64 =2
	65-high = 3
	other = .;
run;

proc format;
	value agegr2_char
	0-18 = "<19"
	19-64 = "19-64"
	65-high = ">64"
	other = .;
run;

*IF 18=<AGE=<64 THEN AGEGR3N=1, ELSE IF 65=<AGE=<84 THEN AGEGR3N=2, ELSE IF AGE>=85 THEN AGEGR3N=3.	;
proc format;
	value agegr3_num
	18-64 = 1
	65-84 = 2
	85-high =3
	;
run;

proc format;
	value agegr3_char
	18-64 = "18-64"
	65-84 = "65-84"
	85-high = ">85"
	other = "unknown";
run;

*IF .<AGE<50 THEN AGEGR4N=1, ELSE IF 50=<AGE THEN AGEGR4N=2.;
proc format;
	value agegr4_num
	0-49 = 1
	50-high = 2;
run;

proc format;
	value agegr4_char
	0-49 = "<50"
	50-high = ">=50";
run;	

data adsl1.adsl_final2;
	set adsl1.adsl_final1;
	
	AGEGR1N=input(put(age, agegr1_num.), best.);
	AGEGR1=PUT(age, agegr1_char.);
	
	AGEGR2N = input(put(age, agegr2_num.), best.);
	AGEGR2 = put(age, agegr2_char.);
	
	AGEGR3N= input(put(age, agegr3_num.), best.);
	AGEGR3= put(age, agegr3_char.);
	
	AGEGR4N = input(put(age, agegr4_num.), best.);
	AGEGR4 = put(age, agegr4_char.);
	
run;

**********************************************************************************************************;
*var 20:
SEXN
NUMERIC CODE VARIABLE OF SEX.

var 22:
SRGENDERN
NUMERIC CODE VARIABLE OF SRGENDER

;

proc format;
value $ sexn
"M" = 2
"F" =1
"MALE" =2
"FEMALE"=1;
run;



data adsl1.adsl_final3;
	set adsl1.adsl_final2;
	SEXN = input(put(sex, sexn.), best.);
	SRGENDERN= input(put(srgender, sexn.), best.);
run;

************************************************************************************************************;
*LTSUBJID:FOR RESCREENED SUBJECTS (I.E. SUBJECTS WITH MORE THAN ONE RECORD WHERE DS.VISITNUM=10 AND DS.DSSCAT ='SCREEN'), LTSUBJID=SUPPDM.QVAL WHERE SUPPDM.QNAM CONTAINS 'SUBJID' SELECTING THE LATEST RESCREENED SUBJIDX. ELSE LTSUBJID=DM.SUBJID. WHERE SUBJIDX=SUBJID2,SUBJID3 ... ETC
;
data adsl1.ltsub(keep = usubjid);
set sdtm_lib.ds;
if visitnum eq 10 and dsscat eq 'SCREEN';
run;

proc sort data=adsl1.ltsub nodupkey dupout=adsl1.ltsub_dups;
by usubjid;
run;


data adsl1.suppdm(keep= usubjid qval qnam);
set sdtm_lib.suppdm;
*if usubjid eq '116482.000116' and prxmatch("/SUBJID/", qnam);
run;

*only choosing the values present in ltsub_dups from suppdm by merging:;
proc sort data=adsl1.suppdm;
by usubjid;
run;
proc sort data=adsl1.ltsub_dups;
by usubjid;
run;

data adsl1.suppdm_req(keep= usubjid qval qnam);
merge adsl1.ltsub_dups(in=a1) adsl1.suppdm(in=a2);
by usubjid;
if a1 and prxmatch("/SUBJID/", qnam);
run;


data adsl1.suppdm_latest(keep= usubjid ltsubjid);
set adsl1.suppdm_req;
by usubjid;
if last.usubjid;
rename qval = LTSUBJID;
run;

data adsl1.adsl_final4;
merge adsl1.adsl_final3(in=a) adsl1.suppdm_latest(in=b);
by usubjid;
if a;
run;

data adsl1.adsl_final5;
set adsl1.adsl_final4;
if cmiss(LTSUBJID) then LTSUBJID = SUBJID;
run;

***********************************************************************************************************;
*RACEN	24	NUMERIC VERSION OF RACE;
proc format;
value $ racen
"AMERICAN INDIAN OR ALASKA NATIVE"=1
"ASIAN"=2
"BLACK OR AFRICAN AMERICAN"=3
"MULTIPLE"=4
"NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER"=5
"WHITE"=6;
run;


data adsl1.adsl_final6;
set adsl1.adsl_final5;
RACEN = input(put(race, racen.), best.);
run;
************************************************************************************************************;

*ARACE	25	
IF A SUBJECT HAS A SINGLE RACE INDICATED ON THE CRF FORM, THEN ARACE= SUPPDM.QVAL WHERE QNAM="RACEOR";
*IF A SUBJECT HAS MULTIPLE RACES INDICATED ON THE CRF FORM
(I.E. MULTIPLE RECORDS WHERE SUPPDM.QVAL="RACEX", OR NO RECORDS WHERE SUPPDM.QVAL="RACEX"
BUT MULTIPLE WHERE SUPPDM.QVAL="RACEORX"), BUT THESE ALL BELONG TO 
A SINGLE SDTM RACE VALUE (DM.RACE='WHITE' OR 'ASIAN'), THEN ARACE="M XXX RACE" 
WHERE XXX IS THE SDTM RACE VALUE ('WHITE' OR 'ASIAN');
*OTHERWISE, ARACE= "M".


REMAP "AFRICAN AMERICAN/AFRICAN HERITAGE" TO "BLACK OR AFRICAN AMERICAN",
AND "AMERICAN INDIAN OR ALASKAN NATIVE" TO "AMERICAN INDIAN OR ALASKA NATIVE".IF RACE IS MISSING THEN "MISSING"	


*1st part:
IF A SUBJECT HAS A SINGLE RACE INDICATED ON THE CRF FORM, THEN ARACE= SUPPDM.QVAL WHERE QNAM="RACEOR";
data single_race(keep=usubjid);
set adsl1.adsl_final6;
if race ne "MULTIPLE";
run;

proc sort data=single_race nodupkey;
by usubjid;
run;

data arace(keep= usubjid qval qnam);
set sdtm_lib.suppdm;
if qnam eq 'RACEOR';
run;
proc sort data=arace;
by usubjid;
run;
*now extracting values for single race by left join;
data single_race_value(keep=usubjid ARACE);
merge single_race(in=x) arace(in=y);
by usubjid;
if x;
rename qval = ARACE;
run;
*transferring these values to my own adsl file;
data adsl1.adsl_final7;
merge adsl1.adsl_final6(in=x) single_race_value(in=y);
by usubjid;
if x;
run;

*2nd part;
*IF A SUBJECT HAS MULTIPLE RACES INDICATED ON THE CRF FORM>>>>
FIND-> MULTIPLE RECORDS WHERE SUPPDM.QVAL="RACEX"
or
FIND MULTIPLE records WHERE SUPPDM.QVAL="RACEORX" but not SUPPDM.QVAL="RACEX"
In these conditions, ARACE="M XXX RACE"  WHERE XXX IS THE SDTM RACE VALUE ('WHITE' OR 'ASIAN');
*OTHERWISE, ARACE= "M".;
data multiple_race(keep=usubjid);
set adsl1.adsl_final6;
if race eq "MULTIPLE";
run;

data suppdm_m(keep=usubjid qval);
set sdtm_lib.suppdm;
if prxmatch("/RACE/", qval);
run;
*since the analysis shows no race or raceor containing statement, we can use the final condition to assign values
i.e arace = "M";
data adsl1.adsl_final8;
set adsl1.adsl_final7;
if race eq "MULTIPLE" then arace ="MULTIPLE";
run;

*3rd part:
REMAP "AFRICAN AMERICAN/AFRICAN HERITAGE" TO "BLACK OR AFRICAN AMERICAN",
AND "AMERICAN INDIAN OR ALASKAN NATIVE" TO "AMERICAN INDIAN OR ALASKA NATIVE".IF RACE IS MISSING THEN "MISSING"	
;

/* proc format; */
/* value $ xyz */
/* "AFRICAN AMERICAN/AFRICAN HERITAGE"="BLACK OR AFRICAN AMERICAN" */
/* "AMERICAN INDIAN OR ALASKAN NATIVE"="AMERICAN INDIAN OR ALASKA NATIVE" */
/* ; */
/* run; */
/* data dummy; */
/* length arace $ 50.; */
/* set adsl1.adsl_final8; */
/* arace = put(arace, xyz.); */
/* run; */


data adsl1.adsl_final9;
set adsl1.adsl_final8;

if arace eq "AFRICAN AMERICAN/AFRICAN HERITAGE" then arace = "BLACK OR AFRICAN AMERICAN";
else if arace eq "AMERICAN INDIAN OR ALASKAN NATIVE" then arace = "AMERICAN INDIAN OR ALASKA NATIVE";
run;

********************************************************************************************************************;

*ARACEN	26	NUMERIC VERSION OF ARACE;
proc format;
value $ aracen
"AMERICAN INDIAN OR ALASKA NATIVE"= 1
"MIXED ASIAN RACE"=10
"MIXED WHITE RACE" =11
"MULTIPLE"=12
"MISSING"=13
"ASIAN - CENTRAL/SOUTH ASIAN HERITAGE"=2
"ASIAN - EAST ASIAN HERITAGE"=3
"ASIAN - JAPANESE HERITAGE"=4
"ASIAN - SOUTH EAST ASIAN HERITAGE"=5
"BLACK OR AFRICAN AMERICAN"=6
"NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER"=7
"WHITE - ARABIC/NORTH AFRICAN HERITAGE"=8
"WHITE - WHITE/CAUCASIAN/EUROPEAN HERITAGE"=9
;
run;

data adsl1.adsl_final10;
set adsl1.adsl_final9;
ARACEN = input(put(arace, aracen.), best.);
run;
**************************************************************************************************************************;


*RACEGR1	27	 
IF RACE="WHITE" THEN RACEGR1="WHITE",
ELSE IF RACE IS NOT MISSING THEN RACEGR1="NON-WHITE".
IF RACE IS MISSING THEN RACEGR1="MISSING";
*RACEGR1N	28	8	NUMERIC VERSION OF RACEGR1;

data adsl1.adsl_final11;
length RACEGR1 $ 9.;
set adsl1.adsl_final10;
if race eq "WHITE" then do RACEGR1 = "WHITE"; RACEGR1N = 1; end;
else if cmiss(race) then  RACEGR1 = "MISSING";
else do RACEGR1 = "NON-WHITE"; RACEGR1N =2; end;
run;
****************************************************************************************************************************;


*RACEGR2	29	
length:26
IF RACE="BLACK OR AFRICAN AMERICAN" THEN RACEGR2="BLACK/AFRICAN AMERICAN",
 ELSE IF RACE IS NOT MISSING THEN RACEGR2="NON-BLACK/AFRICAN AMERICAN". 
 IF RACE IS MISSING THEN RACEGR2="MISSING"	
 
*RACEGR2N	30	8	NUMERIC VERSION OF RACEGR2;

data adsl1.adsl_final12;
set adsl1.adsl_final11;
length RACEGR2 $ 26.;
if race eq "BLACK OR AFRICAN AMERICAN" THEN
 do;
RACEGR2="BLACK/AFRICAN AMERICAN";
RACEGR2N = 1;
 end;
 
else if cmiss(race) then RACEGR2 = "MISSING";

else do;
 RACEGR2 = "NON-BLACK/AFRICAN AMERICAN"; 
RACEGR2N = 2;
 end;
 
run;
*****************************************************************************************************************************;
*ETHNICN	32	8	IF ETHNIC="HISPANIC OR LATINO" THEN ETHNICN=1,
ELSE IF ETHNIC="NOT HISPANIC OR LATINO" THEN ETHNICN=2;
data adsl1.adsl_final13;
set adsl1.adsl_final12;
length ETHNICN $ 32.;
if ethnic eq "HISPANIC OR LATINO" THEN ETHNICN=1;
ELSE IF ETHNIC="NOT HISPANIC OR LATINO" THEN ETHNICN=2;
run;

	
*AETHNIC	33	22	IF DM.ETHNIC IS NULL THEN ASSIGN AETHNIC TO "MISSING"; ELSE AETHNIC IS SAME AS DM.ETHNIC.;	

data adsl1.adsl_final14;
set adsl1.adsl_final13;
length AETHNIC $ 22.;

if cmiss(ETHNIC) then AETHNIC= "MISSING";
else AETHNIC = ETHNIC;

run;
*AETHNICN	34	8	IF ETHNICN IS NULL THEN ASSIGN AETHNICN TO 3; ELSE AETHNICN IS SAME AS ETHNICN	;	
data adsl1.adsl_final15;
set adsl1.adsl_final14;
if cmiss(ethnicn) then AETHNICN =3;
else AETHNICN=ETHNICN;
run;
*********************************************************************************************************************;
*COUNTRYN	36	8	NUMERIC CODE OF COUNTRY;
data adsl1.a16;
set adsl1.adsl_final15;
if country eq "USA" then COUNTRYN = 13;
else if country eq "CAN" then COUNTRYN =3;
run;

*********************************************************************************************************************;
*TRT01PN	58	8	IF DM.ARM CONTAINS 'CAB' THEN TRT01PN=1. IF DM.ARM CONTAINS 'ORAL' THEN TRT01PN=2.;
data adsl1.a17;
set adsl1.a16;
if prxmatch("m/CAB/I", arm) then TRT01PN = 1;
else if prxmatch("m/ORAL/I", arm) then TRT01PN =2;
run;

*TRT01P	57	12	DECODE OF NUMERIC VARIABLE TRT01PN;	
proc format;
value trt01p
1= "Q2M"
2= "DTG+RPV"
;
run;

data adsl1.a18;
set adsl1.a17;
length TRT01P $ 12.;
TRT01P = put(TRT01PN, trt01p.);
run;  
	
******************************************************************************************************;	
	
*ITTEFL	46	1	
IF TRT01P IS NOT MISSING AND SUBJECT HAS A RECORD WHERE EX.EXSTDTC IS NOT MISSING THEN ITTEFL="Y",
ELSE ITTEFL="N".;	
data trt_1(keep=usubjid trt01p);
set adsl1.a18;
run;
data ex_1(keep=usubjid exstdtc);
set sdtm_lib.ex;
run;

data ex_trt;
merge trt_1(in=t) ex_1(in=e);
by usubjid;
if t;
run;

*identifying ids containing missing values;
data msng(keep=usubjid);
set ex_trt;
if cmiss(trt01p) or cmiss(exstdtc);
run;
data msng_id;
set msng;
by usubjid;
ITTEFL = 'N';
if first.usubjid;
run;

*merging the missing value with original adsl and assigining the rest of the id "Y" value;
data adsl1.a19;
merge adsl1.a18(in=x) msng_id(in=y);
by usubjid;
if x;
run;
data adsl1.a20;
set adsl1.a19;
if cmiss(ITTEFL) then ITTEFL = "Y";
run;

******************************************************************************************************;


*PPROTFL	37	1	
IF ITTEFL=Y" AND SUBJECT HAS NO RECORDS WHERE SUPPDV.QVAL="Y" AND SUPPDV.QNAM="EXCLPPFL" THEN PPROTFL="Y",
ELSE PPROTFL="N";
data suppdv(keep=usubjid qval qnam);
set sdtm_lib.suppdv;
run;
proc sort data=suppdv;
by usubjid;
run;


data itt(keep=usubjid ittefl);
set adsl1.a20;
run;
data sup_itt;
merge itt(in=x) suppdv(in=y);
by usubjid;
run;
data sup_itt2;
set sup_itt;
if ittefl eq "N" or qval eq "Y" or qnam eq "EXCLPPFL";
run;


data pprotfl_y(keep=usubjid pprotfl);
set sup_itt2;
by usubjid;
if first.usubjid;
PPROTFL = 'N';
run;

*transferring usubjids with pprotfl eq to n in original adsl file and setting the rest to y;
data adsl1.a21;
merge adsl1.a20(in=x) pprotfl_y(in=y);
by usubjid;
if x;
run;

data adsl1.a22;
set adsl1.a21;
if cmiss(pprotfl) then pprotfl = 'Y';
run;
************************************************************************************************************;

*PPROTFN	38	8	NUMERIC VERSION OF PPROTFL;
data adsl1.a23;
set adsl1.a22;
if pprotfl eq "Y" then PPROTFN =1;
else if pprotfl eq "N" then pprotfn =0;
run;

*********************************************************************************************************;

*TRT01AN	60	8	
IF DM.ACTARM CONTAINS 'CAB' THEN TRT01AN=1. IF DM.ACTARM CONTAINS 'ORAL' THEN TRT01AN=2.	
*same as trt01pn;
*TRT01A	59	12	
DECODE OF NUMERIC VARIABLE TRT01AN;*same as trt01p;

**SAFFL	39	1	
IF TRT01A IS NOT MISSING AND SUBJECT HAS A RECORD
 WHERE EX.EXSTDTC IS NOT MISSING THEN SAFFL="Y", ELSE SAFFL="N".	

*the condition is same as ittefl:
*ITTEFL	46	1	
IF TRT01P IS NOT MISSING AND SUBJECT HAS A RECORD WHERE EX.EXSTDTC IS NOT MISSING THEN ITTEFL="Y",
ELSE ITTEFL="N".;

data adsl1.a24;
set adsl1.a23;
TRT01AN = trt01pn;
TRT01A = trt01p;
SAFFL = ittefl;
run;

*SAFFN	40	8
	NUMERIC VERSION OF SAFFL
;
data adsl1.a25;
set adsl1.a24;
if saffl eq "Y" then SAFFN= 1;
else if saffl eq "N" then saffn=0;
run;

*SCRNFL	41	1	
IF (UPCASE(DS.DSSCAT)="SCREEN" AND DS.DSSTDTC IS NOT NULL) OR (INT(VISITNUM)=10
 AND SV.SVSTDTC IS NOT NULL) THEN SCRNFL="Y", ELSE SCRNFL="N".;

data ds1(keep=usubjid dsscat dsstdtc visitnum);
set sdtm_lib.ds;
run;

data ds2;
set ds1;
where (dsscat=upcase("screen") and dsstdtc is not missing) or visitnum =10;
run;

data sv(keep=usubjid svstdtc);
set sdtm_lib.sv;

run;

data ds2_sv;
merge ds2 sv;
by usubjid;
run;

data ds2_sv_check;
set ds2_sv;
where ((DSSCAT="SCREEN" AND DSSTDTC IS NOT missing) OR (VISITNUM=10 AND SVSTDTC IS NOT missing));
run;

*since there are no values that meet the condition of scrnfl=n, we can supply scrnfl=y
in the unique ids;
data scrnfl_y(keep=usubjid SCRNFL);
set ds2_sv;
by usubjid;
if first.usubjid;
SCRNFL='Y';
run;

*using macros for join from now on;

*macros for left join:;



******************************;
%left_join(l=adsl1.a25, r=scrnfl_y, b=usubjid, o=adsl1.a26);

*******************************;


**********************************************************************************************************;
*SCRNFN	42	8	NUMERIC VERSION OF SCRNFL;
data adsl1.a27;
set adsl1.a26;
if SCRNFL='Y' then SCRNFN=1;
else if SCRNFL='N' then SCRNFN= 0;
run;
 
**********************************************************************************************************;

*ITTEFN	45	8	NUMERIC VERSION OF ITTEFL;
data adsl1.a28;
set adsl1.a27;
if ITTEFL= 'Y' then ITTEFN= 1;
else if ITTEFL= "N" then ITTEFN=0;
run;
*******************************************************************************************************;

*MNTFL	47	1	EQUIVALENT OF ITTEFL;
*MNTFN	48	8	NUMERIC VERSION OF MNTFL;


data adsl1.a29;
set adsl1.a28;
MNTFL = ITTEFL;
MNTFN = ITTEFN;
run;
********************************************************************************************************;


*ENRLFL	43	1	
ENRLFL ASSIGNED VALUE OF "N" UNLESS A SUBJECT HAS
A DISPOSITION RECORD WHERE THE VALUE OF DSDECOD SHOWS 'INFORMED CONSENT OBTAINED'
AND THE VALUE OF DSSCAT SHOWS 'STUDY'  THEN ENRLFL IS ASSIGNED "Y".	
;
*ENRLFN	44	8	NUMERIC VERSION OF ENRLFL;

data enrlfl_ds(keep= usubjid dsdecod dsscat);
set sdtm_lib.ds;
where prxmatch("m/INFORMED CONSENT OBTAINED/I", dsdecod) and dsscat eq "STUDY";
run;
data enrlfl_ds2(keep=usubjid ENRLFL ENRLFN);
set enrlfl_ds;
ENRLFL= "Y";
ENRLFN= 1;
run;

%left_join(l=adsl1.a28, r=enrlfl_ds2, b=usubjid, o=adsl1.a29);
data adsl1.a30;
set adsl1.a29;
if cmiss(enrlfl) then do;
ENRLFL = 'N';
ENRLFN = 0;
end;
run;


*********************************************************************************************************;

*LTFUFL	49	1	IF IN DS THERE IS A RECORD WITH
(DSSCAT='STUDY CONCLUSION' AND EPOCH='FOLLOW-UP' AND DSDECOD='COMPLETED') OR
 (DSDECOD = 'CONTINUATION TO FOLLOW UP PHASE') THEN LTFUFL = "Y". ELSE "N".	
;
data ltfufl1(keep= usubjid LTFUFL LTFUFN dsscat epoch dsdecod);
set sdtm_lib.ds;
where (DSSCAT eq 'STUDY CONCLUSION' AND EPOCH eq 'FOLLOW-UP' AND DSDECOD eq 'COMPLETED') OR (DSDECOD eq 'CONTINUATION TO FOLLOW UP PHASE');
LTFUFL="Y";
LTFUFN=1;
run;

%left_join(l=adsl1.a29, r= ltfufl1, b=usubjid, o=adsl1.a30);

data adsl1.a31;
set adsl1.a30;
if cmiss(LTFUFL) then do; 
LTFUFL= "N";
LTFUFN= 0;
end;
run;

***********************************************************************************************************;
*CVFFL	51	1	
IF SUBJECT HAS TWO CONSECUTIVE RECORDS (BUT ON DIFFERENT DAYS)
WHERE LB.LBTESTCD="HIV1RNA" AND LB.LBMETHOD="POLYMERASE CHAIN REACTION"
AND LB.LBSTRESN >= 200 THEN CVFFL="Y",
ELSE CVFFL="N".
NOTE: IF A SUBJECT HAS MORE THAN ONE RECORD ON THE SAME DAY,
THEN TAKE THE WORST VALUE (I.E. THE MAXIMUM VALUE).	
;

data cv1(keep = usubjid lbtestcd lbmethod lbstresn);
set sdtm_lib.lb;
if LBTESTCD="HIV1RNA" and LBMETHOD="POLYMERASE CHAIN REACTION" AND LBSTRESN >= 200;
run;

*since there are no consecutive records, cvffl must equal to no in all ids;
data adsl1.a32;
set adsl1.a31;
CVFFL= 'N';
CVFFN = 0;
run;

************************************************************************************************************;
*adsl	TRTSDT	61	Date of First Exposure to Treatment;
*Numeric date part of the earliest EX.EXSTDTC. where EXTRT contains CAB LA or RPV LA or DOLUTEGRAVIR;

/*  */
/* data ex1(keep=usubjid exstdtc exstdtc1 extrt datepart timepart); */
/* length exstdtc $ 30.; */
/* set sdtm_lib.ex; */
/*  */
/* where prxmatch("m/cab la|rpv la|dolutegravir/I", extrt); */
/* exstdtc= cats(exstdtc, ":00"); */
/* exstdtc1 = input(strip(exstdtc), anydtdtm.); */
/*  */
/* datepart= datepart(exstdtc1); */
/* timepart = timepart(exstdtc1); */
/* format exstdtc1 e8601dt. datepart date9. timepart time.; */
/* run; */
/*  */
/*  */
/* proc sort data=ex1; */
/* by usubjid exstdtc1; */
/* run; */

data ex1(keep=usubjid exstdtc exstdtc1 exstdtc2);
set sdtm_lib.ex;
where prxmatch("m/cab la|rpv la|dolutegravir/I", extrt);
exstdtc1= scan(exstdtc, 1, "T");
exstdtc2= input(exstdtc1, yymmdd10.);
format exstdtc2 date9.;
run;

proc sort data=ex1;
by usubjid exstdtc2;
run;

data ex2(keep=usubjid trtsdt);
set ex1;
by usubjid;
if first.usubjid;
rename exstdtc2=TRTSDT;
run;

%left_join(l=adsl1.a32, r= ex2, b=usubjid, o=adsl1.a33);

*Numeric date part of the latest of
EX.EXSTDTC and EX.EXENDTC. where EXTRT contains CAB LA or RPV LA or DOLUTEGRAVIR
;
data exen(keep= usubjid exstdtc1 exendtc1 exstdtc2 exendtc2);
set sdtm_lib.ex;
where prxmatch("m/cab la|rpv la|dolutegravir/I", extrt);
exstdtc1= scan(exstdtc, 1, "T");
exendtc1 = scan(exendtc, 1, "T");
exstdtc2= input(exstdtc1, yymmdd10.);
exendtc2= input(exendtc1, yymmdd10.);
format exstdtc2 exendtc2 date9.;
run;

data exen2;
set exen;
if exstdtc2>exendtc2 then latest_date = exstdtc2;
else latest_date= exendtc2;
format latest_date date9.;
run;

proc sort data=exen2;
by usubjid descending latest_date;
run;

data exen3(keep=usubjid trtedt);
set exen2;
by usubjid;
if first.usubjid;
rename latest_date = TRTEDT;
run;

%left_join(l= adsl1.a33, r=exen3, b=usubjid, o=adsl1.a34);
**********************************************************************************************************;
*MNTFL	47	1	EQUIVALENT OF ITTEFL
*MNTFN	48	8	NUMERIC VERSION OF MNTFL;

data adsl1.a35;
set adsl1.a34;
MNTFL =ITTEFL;
MNTFN= ITTEFN;
run;






***********************************************************************************************************;
*MNTCMPS	63	9	
IF SUBJECT WITH MNTFL VALUE OF "Y" ALSO HAS A RECORD WHERE
DS.DSSCAT="STUDY CONCLUSION" THEN MNTCMPS="COMPLETED",
 ELSE IF MNTFL="Y" AND DS.DSSCAT="STUDY TREATMENT DISCONTINUATION"
 THEN MNTCMPS="WITHDRAWN",
 ELSE IF MNTFL="Y" THEN  MNTCMPS="ONGOING".	
;

data mnt1(keep=usubjid mntfl);
set adsl1.a35;
run;
data mnt2(keep=usubjid dsscat);
set sdtm_lib.ds;
run;

proc sort data=mnt1;
by usubjid;
run;
proc sort data=mnt2;
by usubjid;
run;
data mnt3;
merge mnt1 mnt2;
by usubjid;
run;

********************;

data completed(keep=usubjid mntcmps);
set mnt3;
if mntfl eq "Y" and dsscat eq "STUDY CONCLUSION";
MNTCMPS = "COMPLETED";
run;
proc sort data=completed nodupkey;
by usubjid;
run;
%left_join(l=adsl1.a35, r= completed, b= usubjid, o=adsl1.a36);

******************;

data withdrawn(keep=usubjid mntcmps);
set mnt3;
if mntfl eq "Y" and dsscat eq "STUDY TREATMENT DISCONTINUATION";
MNTCMPS = "WITHDRAWN";
run;
proc sort data=withdrawn nodupkey;
by usubjid;
run;
%left_join(l=adsl1.a36, r= withdrawn, b= usubjid, o=adsl1.a37);

*******************;

data ongoing(keep=usubjid mntcmps);
set mnt3;
if mntfl ne "Y";
MNTCMPS = "."; 
run;
proc sort data=ongoing nodupkey;
by usubjid;
run;
%left_join(l=adsl1.a37, r= ongoing, b= usubjid, o=adsl1.a38);

data adsl1.a39;
set adsl1.a38;
if cmiss(mntcmps) then MNTCMPS = "ONGOING";
else if mntcmps eq "." then mntcmps = "";
run;

******************;

***********************************************************************************************************;

*MNTCMPSN	64	8	NUMERIC VERSION OF MNTCMPS;
data adsl1.a40;
set adsl1.a39;
if mntcmps= "ONGOING" then MNTCMPSN = 1;
else if mntcmps= "COMPLETED" then MNTCMPSN =2;
else if mntcmps = "WITHDRAWN" then MNTCMPSN=3;
run;

***********************************************************************************************************;

*MNTEDT	65	8	IF NO WITHDRAWAL REASON, MNTEDT=TRTEDT.
 ELSE MNTEDT IS THE DATE OF RECORD WHERE 
 INDEX(DSSCAT, "DISCONTINU") OR INDEX(DSDECOD, "WITHDRAW")	
;
data mntedt1(keep= usubjid dsscat dsdecod dsstdtc);
set sdtm_lib.ds;
run;

data withdrawl;
set mntedt1;
if prxmatch("m/withdraw/I", dsdecod);
run;
proc sort data=withdrawl nodupkey;
by usubjid;
run;


%left_join(l=withdrawl, r=mntedt1, b=usubjid, o=mntedt2);

*for mntedt,, not sure about withdrawal reason...66 and 116 mntedt values contradict..so just copying trtedt to mntedt for now:
;

data adsl1.a41;
set adsl1.a40;
MNTEDT = TRTEDT;
format mntedt date9.;
run;


**************************''''''''''''''''''
;
***********************************************************************************************************;
*LTFCMPS	66	7	IF SUBJECT HAS A RECORD WHERE DSSCAT='STUDY CONCLUSION' 
AND EPOCH='FOLLOW-UP' AND DSDECOD='COMPLETED'
 AND TRT01P NE 'DTG + RPV' THEN LTFCMPS='COMPLETED'. 
 ELSE IF DSDECOD='CONTINUATION TO FOLLOW UP PHASE' AND 
 TRT01P NE 'DTG + RPV' THEN LTFCMPS='ONGOING'.	
 ;
 
data ltf1;
set sdtm_lib.ds;
*where (dsscat eq "STUDY CONCLUSION" and epoch eq "FOLLOW-UP" AND DSDECOD='COMPLETED');
run;
data trt11(keep=usubjid trt01p);
set adsl1.a40;
trt01p = strip(trt01p);
run;
%left_join(l=ltf1, r=trt11, b=usubjid, o=lttrt);

data completed;
set lttrt;
where (trt01p ne 'DTG+RPV' AND EPOCH eq 'FOLLOW-UP' AND DSDECOD eq 'COMPLETED' AND DSSCAT eq 'STUDY CONCLUSION');
run;
*%left_join(l=adsl1.a41, r=completed, b=usubjid, o=adsl1.a42);


data ongoing(keep=usubjid LTFCMPS);
set lttrt;
where( DSDECOD='CONTINUATION TO FOLLOW UP PHASE' AND TRT01P NE 'DTG + RPV');
LTFCMPS = "ONGOING";
run;

%left_join(l=adsl1.a41, r=ongoing, b=usubjid, o=adsl1.a43);
**********************************************************************************************************;

*LTFCMPSN	67	8	
IF THE VALUE OF LTFCMPS SHOWS "ONGOING" THEN LTFCMPSN =1;
* IF IT SHOWS "COMPLETED" THEN LTFCMPSN =2; 
*IF IT SHOWS "WITHDRAWAL" THEN LTFCMPSN =3;	
proc format;
value $ ltfcmpsn
"ONGOING"=1
"COMPLETED"=2
"WITHDRAWAL"=3
;
run;
options missing=" ";
data adsl1.a44;
set adsl1.a43;
LTFCMPSN = input(put(LTFCMPS, ltfcmpsn.), best.);
run;

**********************************************************************************************************;

*LSEFL	68	1	

IF SUBJECT HAS A RECORD WHERE CE.CECAT="LIVER EVENT REPORTING" AND 
(SUPPCE.QNAM="LERMX" AND SUPPCE.QVAL="LIVER EVENT STOPPING CRITERIA") 
THEN LSEFL="Y", ELSE LSEFL="N".	
;
data ce1;
set sdtm_lib.ce;
run;

data suppce1;
set sdtm_lib.suppce;
run;
 
data ces;
merge ce1 suppce1;
by usubjid;
if cecat eq "LIVER EVENT REPORTING" and qnam eq "LERMX" and QVAL="LIVER EVENT STOPPING CRITERIA";
run;
 *no ids that meet the criteria hence all ids have N value for  lsefl;

data adsl1.a45;
set adsl1.a44;
LSEFL= "N";
LSEFN= 0;
run;



********************************************************************************************************;
*DTHFN	71	8	IF DTHFL="Y" THEN DTHFN=1, BLANK OTHERWISE.
;
proc format;
value $ dthfn
"Y" =1
;
run;

data adsl1.a46;
set adsl1.a45;
DTHFN = input(put(dthfl, dthfn.), best.);
run;
********************************************************************************************************;

*ACOUNTRY	72	13	WHEN COUNTRY='CAN' THEN ASSIGN ACOUNTRY='CANADA';
*ELSE WHEN COUNTRY='USA' ASSIGN ACOUNTRY='UNITED STATES'	;

data adsl1.a47;
LENGTH ACOUNTRY $ 13.;
set adsl1.a46;
if country eq "CAN" then ACOUNTRY = "CANADA";
ELSE IF COUNTRY EQ "USA" THEN ACOUNTRY = "UNITED STATES";
RUN;

**********************************************************************************************************;
*MDSFL	73	1	
IF SUBJECT HAS A RECORD WHERE THE VALUE OF VISIT CONTAINS 'END OF MAINTENANCE PHASE'
OR (DS.DSSCAT CONTAINS 'DISCONTINU' AND  'STUDY'). AND TRTSDT FOR THIS PERSON IS NOT MISSING, 
THEN MDSFL="Y". OTHERWISE MDSFL IS "N".	;


*DISCREAS  74	21	
*Only populate for subjects with MDSFL = "Y".
 Find records in DS where visit contains 'END OF MAINTENANCE PHASE' 
 or (DSSCAT contains "DISCONTINU" and  'STUDY'). 
 DISCREAS then equals DS.DSDECOD.
;

data mdsfl1(keep=usubjid trtsdt);
set adsl1.a47;
run;

data mdsfl2(keep=usubjid dsscat visit dsdecod);
set sdtm_lib.ds;
run;

*already sorted data so just merging;
data mdsfl3;
merge mdsfl1 mdsfl2;
by usubjid;
run;

data mdsfl4(keep=usubjid mdsfl discreas);
set mdsfl3;
where ((prxmatch("m/END OF MAINTENANCE PHASE/I", visit) or (prxmatch("m/discontinu/I", dsscat) and prxmatch("m/study/I", dsscat))) and trtsdt is not missing);
MDSFL= "Y";
rename dsdecod = DISCREAS;
run;

%left_join(l=adsl1.a47, r= mdsfl4, b=usubjid, o=adsl1.a48);

data adsl1.a49;
set adsl1.a48;
if cmiss(mdsfl) then MDSFL= "N"; 
run;

**********************************************************************************************************;

*MNTSDT	75	8	
MNTSDT IS EQUIVALENT TO TRTSDT.
;

data adsl1.a50;
set adsl1.a49;
MNTSDT = TRTSDT;
format mntsdt date9.;
run;

*********************************************************************************************************;
*SCRFLDTS	76	1	
*If the subject is rescreened (i.e. DM.SUBJID="MULTPLE") 
then concatenate all of the subject's screening dates 
from DS.DSSTDTC (converted to DATE9. format) where DS.VISITNUM = 10 together, separated by a comma.;

data scrfldts1(keep=usubjid);
set sdtm_lib.dm;
if subjid eq "MULTIPLE";
run;

data scrfldts2(keep=usubjid dsstdtc dsscat visitnum);
set sdtm_lib.ds;
run;
%left_join(l=scrfldts1, r= scrfldts2, b= usubjid, o=scrfldts3);

data scrfldts3a;
set scrfldts3;
where (dsscat= "SCREEN" and visitnum= 10);
run;


proc sort data=scrfldts3a nodupkey;
by usubjid dsstdtc;
run;

*using retain to concatenate based on usubjid;
*first converting to date9. format and using it as character;
data scrfldts4(drop=dsscat visitnum);
set scrfldts3a;
date1= input(dsstdtc, yymmdd10.);
format date1 date9.;
date2= put(date1, date9.);
run;

*now concatenating using retain function;
data scrfldts5;
set scrfldts4;
by usubjid;
length concat_date $ 50.;
retain concat_date ;
if first.usubjid then concat_date = date2;
else concat_date= catx(",", concat_date, date2);
run;

data scrfldts6(keep= usubjid scrfldts);
set scrfldts5;
by usubjid;
if last.usubjid;
rename concat_date = SCRFLDTS;
run;

%left_join(l=adsl1.a50, r=scrfldts6, b=usubjid, o=adsl1.a51);
***********************************************************************************************************;

*SCRFLSID	77	1	
*If the subject is rescreened (i.e. DM.SUBJID="MULTPLE")
 then concatenate all of the subject's SUBJIDs from SUPPDM.QVAL
 where SUPPDM.QNAM contains "SUBJID" together, separated by a comma.
;
data scrflsid1(keep=usubjid);
set sdtm_lib.dm;
if subjid eq "MULTIPLE";
run;

data scrflsid2;
set sdtm_lib.suppdm;
run;
%left_join(l=scrflsid1, r=scrflsid2, b=usubjid, o=scrflsid3);

data scrflsid4(keep=usubjid qval);
set scrflsid3;
where prxmatch("m/subjid/I", qnam);
run;

proc sort data=scrflsid4 nodupkey;
by usubjid qval;
run;

*using retain;
data scrflsid5(keep=usubjid scrflsid);
set scrflsid4;
by usubjid;
length SCRFLSID $30.;
retain SCRFLSID;
if first.usubjid then SCRFLSID = QVAL;
else SCRFLSID = catx(",", SCRFLSID, QVAL);
run;

data scrflsid6;
set scrflsid5;
by usubjid;
if last.usubjid;
run;

%left_join(l= adsl1.a51, r=scrflsid6, b=usubjid, o=adsl1.a52);

*********************************************************************************************************;
*SCRFLRS	78	1	;

* If the subject is rescreened (i.e. DM.SUBJID="MULTPLE") 
then concatenate all of the subject's reasons for failing screening from 
DS.DSDECOD where DS.VISITNUM=10 and DS.DSDECOD ne "COMPLETED" together,
 in double quotation marks and separated by a comma.;
 
data scrflrs1(keep=usubjid);
set sdtm_lib.dm;
if subjid eq "MULTIPLE";
run;

data scrflrs2(keep=usubjid dsdecod);
set sdtm_lib.ds;
if visitnum eq 10 and dsdecod ne "COMPLETED";
run;

%left_join(l=scrflrs1, r=scrflrs2, b=usubjid, o=scrflrs3);

proc sort data=scrflrs3 nodupkey;
by usubjid dsdecod;
run;

*adding quotation marks:
;
data scrflrs4;
set scrflrs3;
quotation= cats('"', dsdecod, '"');
run;

*using retain;
data scrflrs5;
set scrflrs4;
by usubjid;
retain SCRFLRS;
if first.usubjid then SCRFLRS = quotation;
else SCRFLRS= catx(",", SCRFLRS, quotation);
run;

data scrflrs6(keep= usubjid scrflrs);
set scrflrs5;
by usubjid;
if last.usubjid;
run;

%left_join(l=adsl1.a52, r= scrflrs6, b=usubjid, o=adsl1.a53);

***********************************************************************************************************;

*79	SCRFLST	79	1	
*Only populate for subjects who have been rescreened (i.e. DM.SUBJID="MULTPLE"). 
If the subject is rescreened once (i.e. SCRFLIDS contains two subject IDs) 
and completes their second screening then SCRFLST="Failed, Enrolled",
 else if the subject fails both screenings then SCRFLST="Failed, Failed",
 else if the subject is rescreened twice and passes their third screening
 (i.e. SCRFLIDS contains two subject IDs) then SCRFLST="Failed, Failed, Enrolled".;

data scrflids1(keep=usubjid);
 set sdtm_lib.dm;
 where subjid eq "MULTIPLE";
 run;

data scrflids2;
set sdtm_lib.suppdm;
run;

%left_join(l=scrflids1, r= scrflids2, b=usubjid, o=scrflids3)


************************************************************************************************************;

*WEIGHTBL	87	8	
SELECT LATEST RECORDS WHERE UPCASE(VSTESTCD) CONTAINS 'WEIGHT'
AND NON-NULL VSDTC VALUES ARE EITHER  BEFORE OR ON THE TREATMENT START DATE.
WEIGHTBL=VSSTRESN;

data weightbl1(keep=usubjid vstestcd vsstresn vsdtc vsdtc1 vsstresu);
set sdtm_lib.vs;
where vstestcd contains "WEIGHT";
vsdtc1= input(vsdtc, yymmdd10.);
format vsdtc1 date9.;
run;

data weightbl2(keep=usubjid trtsdt);
set adsl1.a53;
run;

data weightbl3;
merge weightbl1 weightbl2;
by usubjid;
if not(missing(cats(vsdtc)));
run;

data weightbl4(keep=usubjid weightbl WTUNIT);
set weightbl3;
if vsdtc1<=trtsdt;
rename vsstresn = WEIGHTBL;
rename vsstresu = WTUNIT;
run;

%left_join(l=adsl1.a53, r=weightbl4, b=usubjid, o=adsl1.a54);
**********************************************************************************************************;

*HEIGHTBL	85	8	
SELECT LATEST RECORDS WHERE UPCASE(VSTESTCD) 
CONTAINS 'HEIGHT' AND NON-NULL VSDTC VALUES ARE
 EITHER  BEFORE OR ON THE TREATMENT START DATE.  
 HEIGHTBL=VSSTRESN	
;
data heightbl1(keep=usubjid vstestcd vsstresn vsdtc vsdtc1 vsstresu);
set sdtm_lib.vs;
where vstestcd contains "HEIGHT";
vsdtc1= input(vsdtc, yymmdd10.);
format vsdtc1 date9.;
run;

data heightbl2(keep=usubjid trtsdt);
set adsl1.a53;
run;

data heightbl3;
merge heightbl1 heightbl2;
by usubjid;
if not(missing(cats(vsdtc)));
run;

data heightbl4(keep=usubjid heightbl htunit);
set heightbl3;
if vsdtc1<=trtsdt;
rename vsstresn = HEIGHTBL;
rename vsstresu = HTUNIT;
run;

%left_join(l=adsl1.a54, r=heightbl4, b=usubjid, o=adsl1.a55);
***************************************************************************************************;
*BMIBL	80	8	
BMIBL = WEIGHTBL/((HEIGHTBL/100)*(HEIGHTBL/100));

data adsl1.a56 ;
set adsl1.a55;
BMIBL = WEIGHTBL/((HEIGHTBL/100)*(HEIGHTBL/100));
run;
*****************************************************************************************************;

*BMIGR1N	81	8	
IF . < BMIBL < 30 THEN BMIGR1N=1, 
ELSE IF BMIBL >= 30 THEN BMIGR1N=2, 
OTHERWISE BLANK.	;

*BMIGR1	82	4	DECODE OF NUMERIC VARIABLE BMIGR1N;

*BMIUNIT = 'kg/m2' if bmibl=weightbl/((heightbl/100)*(heightbl/100)) is not Null.;

data adsl1.a57;
set adsl1.a56;
length BMIGR1 $ 4.;
if bmibl<30  and bmibl>. then do; BMIGR1N=1; BMIGR1 = "<30"; BMIUNIT= "kg/m2";  end;
else if bmibl>=30 then do; BMIGR1N=2; BMIGR1= ">=30";BMIUNIT= "kg/m2"; end;
run;

*******************************************************************************************************;

*88	HEPBST	88	8	
If subject has a pre-treatment record where 
CO.COVAL="HBV DNA DETECTED" then HEPBST="Positive".
 Else if subject has a pre-treatment record where
 LB.LBTESTCD in ("HBVDNA" "HBVDNAC" "HBVDNAL"): 
 if LB.LBSTRESN ne . or LB.LBORRES ne "<x" then HEPBST="Positive",
 else HEPBST="Negative". 
 Else if subject has a pre-treatment record where
 LB.LBTESTCD="HBSAGZ": if LB.LBSTRESC="REACTIVE" then HEPBST="Positive", 
 else if LB.LBSTRESC="NON-REACTIVE" then HEPBST="Negative".
;


*for first condition;
*If subject has a pre-treatment record where 
CO.COVAL="HBV DNA DETECTED" then HEPBST="Positive".;
data hep1;
set sdtm_lib.co;
where coval eq "HBV DNA DETECTED";
run;
* there are 0 rows so lets check 2nd condition;

*for 2nd condition;
*if subject has a pre-treatment record where
 LB.LBTESTCD in ("HBVDNA" "HBVDNAC" "HBVDNAL"): 
 if LB.LBSTRESN ne . or LB.LBORRES ne "<x" then HEPBST="Positive",
 else HEPBST="Negative".;

data hep2(keep=usubjid lbtestcd lbstresn lborres);
set sdtm_lib.lb;
if prxmatch("/HBVDNA|HBVDNAC|HBVDNAL/", lbtestcd);
run;
*there are 0 rows as well here..so lets try 3rd condition;

 
*for 3rd condition
LB.LBTESTCD="HBSAGZ": if LB.LBSTRESC="REACTIVE" then HEPBST="Positive", 
 else if LB.LBSTRESC="NON-REACTIVE" then HEPBST="Negative".
;


data hep3(keep= usubjid lbtestcd lbstresc);
set sdtm_lib.lb;
if lbtestcd eq "HBSAGZ";
run;
data hep4(keep=usubjid HEPBST);
set hep3;
if lbstresc eq "REACTIVE" then HEPBST = "Positive";
else if lbstresc eq "NON-REACTIVE" then HEPBST = "Negative";
run;

proc sort data=hep4 nodup;
by usubjid;
run;

%left_join(l=adsl1.a57, r=hep4, b=usubjid, o=adsl1.a58);

***********************************************************************************************************;

*HEPBSTCD	89	8	
IF HEPBST="NEGATIVE" THEN HEPBSTCD=0, 
ELSE IF HEPBST="POSITIVE" THEN HEPBSTCD=1.	;

data adsl1.a59;
set adsl1.a58;
if hepbst eq "Negative" then HEPBSTCD=0;
else if hepbst eq "Positive" then HEPBSTCD=1;
run;
*********************************************************************************************************;
*HEPCST	90	8	
If subject has a pre-treatment record where
 LB.LBTESTCD in ("HCVRNA" "HCVRNAL"):
 if LB.LBORRES ne "TARGET NOT DETECTED" or LB.LBSTRESN ne .
 then HEPCST="Positive", else HEPCST="Negative".
 Else if subject has a pre-treatment record where
 LB.LBTESTCD="HCVABZ": 
 if LB.LBSTRESC in ("REACTIVE" "BORDERLINE") then HEPCST="Positive", 
 else if LB.LBSTRESC="NON-REACTIVE" then HEPCST="Negative".
;

*testing 1st condiiton;
data hepc1;
set sdtm_lib.lb;
if prxmatch("/HCVRNA|HCVRNAL/", lbtestcd);
run;
data hepc1a;
set hepc1;
where (LBORRES ne "TARGET NOT DETECTED" or lbstresn is not missing);
run;


*there are 0 rows for first conditon so lets check the 2nd condiiton;
*LB.LBTESTCD="HCVABZ": 
 if LB.LBSTRESC in ("REACTIVE" "BORDERLINE") then HEPCST="Positive", 
 else if LB.LBSTRESC="NON-REACTIVE" then HEPCST="Negative".;
 
data hepc2(keep=usubjid lbtestcd lbstresc);
set sdtm_lib.lb;
if lbtestcd eq "HCVABZ";
run;

data hepc3;
set hepc2;
if lbstresc eq "REACTIVE" or lbstresc eq "BORDERLINE" then HEPCST= "Positive";
else if lbstresc eq "NON-REACTIVE" then HEPCST="Negative";
run;

proc sort data=hepc3 nodup;
by usubjid;
run;

%left_join(l=adsl1.a59, r=hepc3, b=usubjid, o=adsl1.a60);
************************************************************************************************************;
*HEPCSTCD	91	8	
IF HEPCST="NEGATIVE" THEN HEPCSTCD=0, ELSE IF HEPCST="POSITIVE" THEN HEPCSTCD=1.;


data adsl1.a61;
set adsl1.a60;
if hepcst eq "Negative" then HEPCSTCD = 0;
else if hepcst eq "Positive" then HEPCSTCD =1;
run;
**********************************************************************************************************;

*HEPBCST	92	7	
IF HEPBSTCD=1 AND HEPCSTCD=0 THEN HEPBCST="B ONLY", 
ELSE IF HEPBSTCD=0 AND HEPCSTCD=1 THEN HEPBCST="C ONLY",
 HEPBSTCD=1 AND HEPCSTCD=1 THEN HEPBCST="B AND C",
 ELSE IF HEPBSTCD=0 AND HEPCSTCD=0 THEN HEPBCST="NEITHER".	
;

data adsl1.a62;
set adsl1.a61;
length HEPBCST $ 8.;
if HEPBSTCD=1 AND HEPCSTCD=0 THEN HEPBCST="B ONLY";
ELSE IF HEPBSTCD=0 AND HEPCSTCD=1 THEN HEPBCST="C ONLY";
else if HEPBSTCD=1 AND HEPCSTCD=1 THEN HEPBCST="B AND C";
ELSE IF HEPBSTCD=0 AND HEPCSTCD=0 THEN HEPBCST="NEITHER";
run;
 
*93	HEPBCSCD	93	8
IF HEPBCST="B ONLY" THEN HEPBCSCD=1,
 ELSE IF HEPBCST="C ONLY" THEN HEPBCSCD=2, 
 ELSE IF HEPBCST="B AND C" THEN HEPBCSCD=3,
 ELSE IF HEPBCST="NEITHER" THEN HEPBCSCD=4.	;
 
data adsl1.a63;
set adsl1.a62;
IF HEPBCST="B ONLY" THEN HEPBCSCD=1;
 ELSE IF HEPBCST="C ONLY" THEN HEPBCSCD=2;
 ELSE IF HEPBCST="B AND C" THEN HEPBCSCD=3;
 ELSE IF HEPBCST="NEITHER" THEN HEPBCSCD=4	;
run;
********************************************************************************************************;

*LTARTSDT	94	8;
*Select medications from C1 where C1.C1CAT contains "ANTIRETROVIRAL" 
and TRTEDT < imputed C1 start date. If LTFUFL="Y" then LTARTSDT= imputed C1 start date.;
data c1(keep= usubjid c1cat c1stdtc);
set sdtm_lib.c1;
if prxmatch("m/ANTIRETROVIRAL/I", c1cat);
run;

*2012-12-23
*2012-12
*2012
*-----;

data c2(keep=usubjid trtedt ltfufl);
set adsl1.a63;
run;

data c3;
merge c1 c2;
by usubjid;
run;
data c4;
set c3;
if ltfufl eq "Y";
c_date= input(c1stdtc, yymmdd10.);
format c_date date9.;

run;

data c5;
set c4;
if c_date>trtedt;
run;


*no imputed dates in results containing ltfufl eq Y so....all ids should be blank;
data adsl1.a64;
set adsl1.a63;
LTARTSDT = .;
run;

******************************************************************************************;

*LSTINJDT	95	8	;
*Numeric date part of the latest of EX.EXSTDTC and EX.EXENDTC 
where EX.EXROUTE="INTRAMUSCULAR".;
data lst1(keep=usubjid exstdtc1 exendtc1 latest);
set sdtm_lib.ex;
where exroute eq "INTRAMUSCULAR";
exstdtc1 = input(strip(scan(exstdtc,1, "T")), yymmdd10.);
exendtc1=  input(strip(scan(exendtc,1, "T")), yymmdd10.);

if exstdtc1>exendtc1 then latest = exstdtc1;
else if exstdtc1<exendtc1 then latest = exendtc1;
else latest = exstdtc1;
format exstdtc1 exendtc1 latest date9.;
run;

proc sort data=lst1;
by usubjid latest;
run;

data lst2(keep=usubjid LSTINJDT);
set lst1;
by usubjid;
if last.usubjid;
rename latest =LSTINJDT;
run;
%left_join(l=adsl1.a64, r=lst2, b=usubjid, o=adsl1.a65 );
*********************************************************************************************************;

*LSTORLDT	96	8	;
*Numeric date part of the latest of EX.EXSTDT and EX.EXENDT 
where EX.EXROUTE="ORAL" or EX.EXTPT="ORAL DOSE". Set to TRTEDT for TRT01PN=2.;

data lst3(keep=usubjid exstdtc1 exendtc1 latest);
set sdtm_lib.ex;
where exroute eq "ORAL" or extpt eq "ORAL DOSE"; 
exstdtc1 = input(strip(scan(exstdtc,1, "T")), yymmdd10.);
exendtc1=  input(strip(scan(exendtc,1, "T")), yymmdd10.);

if exstdtc1>exendtc1 then latest = exstdtc1;
else if exstdtc1<exendtc1 then latest = exendtc1;
else latest = exstdtc1;
format exstdtc1 exendtc1 latest date9.;
run;

proc sort data=lst3;
by usubjid latest;
run;

data lst4(keep=usubjid LSTORLDT);
set lst3;
by usubjid;
if last.usubjid;
rename latest =LSTORLDT;
run;
%left_join(l=adsl1.a65, r=lst4, b=usubjid, o=adsl1.a66 );

data adsl1.a67;
set adsl1.a66;
if trt01pn eq 2 then LSTORLDT= TRTEDT;
run;
%adsl_check(v=lstorldt);
********************************************************************************************************;

*	MTH12SDT	97	8	
VALUE OF SVSTDTC WHERE VISIT='MONTH 12';

data mth12(keep=usubjid MTH12SDT);
set sdtm_lib.sv;
where visit eq 'MONTH 12';
MTH12SDT = input(svstdtc, yymmdd10.);
format MTH12SDT date9.;
run;

proc sort data=mth12 nodupkey;
by usubjid;
run; 

%left_join(l=adsl1.a67, r=mth12, b=usubjid, o=adsl1.a68);

*********************************************************************************************************;

*MTH26SDT	98	8	
VALUE OF SVSTDTC WHERE VISIT='MONTH 26';

data mth26(keep=usubjid MTH26SDT);
set sdtm_lib.sv;
where visit eq 'MONTH 26';
MTH26SDT = input(svstdtc, yymmdd10.);
format MTH26SDT date9.;
run;

proc sort data=mth26 nodupkey;
by usubjid;
run; 

%left_join(l=adsl1.a68, r=mth26, b=usubjid, o=adsl1.a69);

********************************************************************************************************;

*HIVRKFL	99	1	

IF SUBJECT HAS A RECORD WHERE Y8.Y8TESTCD="HIVRFKNW" THEN HIVRKFL="Y", ELSE HIVRKFL="N".;	
data hiv1(keep=usubjid HIVRKFL);
set sdtm_lib.y8;
where Y8TESTCD="HIVRFKNW" ;
HIVRKFL="Y";
run;
proc sort data=hiv1 nodupkey;
by usubjid;
run;
%left_join(l=adsl1.a69, r=hiv1, b=usubjid, o=adsl1.a70);

data adsl1.a71;
set adsl1.a70;
if cmiss(HIVRKFL) then HIVRKFL ="N";
run;

%adsl_check(v=hivrkfl);
data hivrk_check(keep=usubjid hivrkfl);
set adsl1.adsl_final_output;
run;

********************************************************************************************************;
*HIVRK	100	20

*Concatenate all values of Y8.Y8STRESC where Y8.Y8TESTCD="HIVRF", 
separated by a semi colon. Order the values based on Y8.Y8SEQ,
except for where Y8.Y8STRESC="OTHER", which should be kept last 
in the list of values.;

data y81(keep=usubjid HIVRK);
set sdtm_lib.y8;
length HIVRK $ 20.;
where Y8TESTCD="HIVRF";
rename y8stresc=HIVRK;
run;

proc sort data=y81 nodupkey dupout=y82;
by usubjid;
run;
*since there are no more than 1 values for each usubjid, we do not need to concatenate;
%left_join(l=adsl1.a71, r=y81, b=usubjid, o=adsl1.a72);

******************************************************************************************************;
*CD4BL	101	8	
The latest value of LB.LBSTRESN where LB.LBTESTCD="CD4" and LB.LBDTC is on or before TRTSDT.
 Note that pre-dose unscheduled visits are included.
;

data trts1(keep= usubjid trtsdt);
set adsl1.a72;
run;
data lbs1(keep=usubjid lbtestcd lbstresn lbdtc1);
set sdtm_lib.lb;
where lbtestcd eq "CD4";
lbdtc1 = input(lbdtc, yymmdd10.);
format lbdtc1 date9.;
run;

data lbs2;
merge trts1 lbs1;
by usubjid;
run;
data lbs3;
set lbs2;
if lbdtc1<=trtsdt;
run;

proc sort data=lbs3;
by usubjid descending lbdtc1;
run;
 
data lbs4(keep=usubjid CD4BL);
set lbs3;
by usubjid;
if first.usubjid;
rename lbstresn=CD4BL;
run;

%left_join(l=adsl1.a72, r=lbs4, b=usubjid, o=adsl1.a73);
**********************************************************************************************************;

*CD4BLG1N	103	8
IF . < CD4BL < 350 THEN CD4BLG1N=1, 
ELSE IF 350 =< CD4BL < 500 THEN CD4BLG1N=2, 
ELSE IF CD4BL >= 500 THEN CD4BLG1N=3.	
;

data adsl1.a74;
set adsl1.a73;
if cd4bl>. and cd4bl<350 THEN CD4BLG1N=1;
ELSE IF CD4BL>=350 and cd4bl<500 THEN CD4BLG1N=2;
ELSE IF CD4BL >= 500 THEN CD4BLG1N=3;
run;
**********************************************************************************************************;



*CDCBCATN	105	8	
*If subject has a record where CE.CECAT="HIV ASSOCIATED CONDITIONS" 
and CE.CESTDTC non-missing and CE.CESTDTC is on/before TRTSDT then CDCBCATN=3. 
Else if . < CD4BL < 200 then CDCBCATN=3, else if 200 =< CD4BL < 500 then CDCBCATN=2,
 else if CD4BL >= 500 then CDCBCATN=1.
 Else if CD4BL is missing then find the subjects latest record
 where LB.LBTESTCD="CD4LY" and LB.LBDTC is on/before TRTSDT,
 and if . < LB.LBSTRESN < 14 then CDCBCATN =3, 
 else if 14 =< LB.LBSTRESN < 26 then CDCBCATN =2,
 else if LB.LBSTRESN >= 26 then CDCBCATN=1. 
 Otherwise CDCBCATN is missing.
 Where CD4BL is the latest value of LB.LBSTRESN where 
 LB.LBTESTCD="CD4" and numeric date part of LB.LBDTC is on or before TRTSDT.
;


*trying first condition;
*If subject has a record where CE.CECAT="HIV ASSOCIATED CONDITIONS" 
and CE.CESTDTC non-missing and CE.CESTDTC is on/before TRTSDT then CDCBCATN=3. ;

data trtss(keep= usubjid trtsdt);
set adsl1.a74;
run;

data ce11(keep=usubjid cecat cestdtc1);
set sdtm_lib.ce;
cestdtc1= input(cestdtc, yymmdd10.);
format cestdtc1 date9.;
run;

%left_join(l=ce11, r=trtss, b=usubjid, o=ce12);

data ce13;
set ce12;
where (not(cmiss(CESTDTC1)) and CESTDTC1 <= TRTSDT);
run;

*no rows here so moving on to next condition;

 *if . < CD4BL < 200 then CDCBCATN=3, else if 200 =< CD4BL < 500 then CDCBCATN=2,
 else if CD4BL >= 500 then CDCBCATN=1.;

data adsl1.a75;
set adsl1.a74;
if cd4bl>. and cd4bl<200 then  CDCBCATN=3;
else if cd4bl>=200 and cd4bl<500 then CDCBCATN=2;
else if CD4BL >= 500 then CDCBCATN=1;
run;

*for missing ones;
 *Else if CD4BL is missing then find the subjects latest record
 where LB.LBTESTCD="CD4LY" and LB.LBDTC is on/before TRTSDT,
 and if . < LB.LBSTRESN < 14 then CDCBCATN =3, 
 else if 14 =< LB.LBSTRESN < 26 then CDCBCATN =2,
 else if LB.LBSTRESN >= 26 then CDCBCATN=1.; 

data miss_c(keep=usubjid trtsdt);
set adsl1.a75;
if cmiss(cd4bl);
run;

*since trtsdt is missing , cant compare for further results..hence putting it as a blank for 274.
%adsl_check(v=cdcbcatn);

*************************************************************************************************************;
*CDCBLCAT	104	8	
DECODE OF NUMERIC VARIABLE CDCBCATN;

proc format;
value cdcblcat
1 = "Stage I"
2= "Stage II"
3= "Stage III"
;
run;

data adsl1.a76;
set adsl1.a75;
CDCBLCAT = put(CDCBCATN, cdcblcat.);
run;

*HISDEPFL	106	1
If subject has a record where MH.MHTERM="DEPRESSION" and
 MH.MHOCCUR="Y" and MH.VISITNUM=10 and MH.MHSTRF="BEFORE"
 then HISDEPFL="Y", else HISDEPFL="N".	;
 
data mh1(keep=usubjid HISDEPFL);
set sdtm_lib.mh;
where mhterm eq "DEPRESSION" and MHOCCUR eq "Y" and VISITNUM eq 10 and MHSTRF eq "BEFORE";
HISDEPFL = "Y";
run;
proc sort data=mh1 nodupkey;
by usubjid;
run;
%left_join(l=adsl1.a76, r=mh1, b=usubjid, o=adsl1.a77);

data adsl1.a78;
set adsl1.a77;
if cmiss(HISDEPFL) then HISDEPFL ="N";
run;
***********************************************************************************************************;
*HISSUIFL	107	1	
If subject has a record where MH.MHTERM="SUICIDAL IDEATION"
 and MH.MHOCCUR="Y" and MH.VISITNUM=10 and MH.MHSTRF="BEFORE" 
 then HISSUIFL="Y", else HISSUIFL="N".	;
 data mh2(keep=usubjid HISSUIFL);
 set sdtm_lib.mh;
 where MHTERM eq "SUICIDAL IDEATION" and MHOCCUR eq "Y" and VISITNUM eq 10 and MHSTRF eq "BEFORE";
 HISSUIFL= "Y";
 run;
 %left_join(l=adsl1.a78, r=mh2, b=usubjid, o=adsl1.a79);

data adsl1.a80;
set adsl1.a79;
if cmiss(HISSUIFL) then HISSUIFL= "N";
run;

*************************************************************************************************************;

*HISANXFL	108	1	
If subject has a record where 
MH.MHTERM="ANXIETY" and MH.MHOCCUR="Y" and 
MH.VISITNUM=10 and MH.MHSTRF="BEFORE" then 
HISANXFL="Y", else HISANXFL="N".	;

data mh3(keep=usubjid HISANXFL);
set sdtm_lib.mh;
where 
MHTERM eq "ANXIETY" and MHOCCUR eq "Y" and 
VISITNUM eq 10 and MHSTRF eq "BEFORE";
HISANXFL= "Y";
run;

proc sort data=mh3 nodupkey;
by usubjid;
run;

%left_join(l=adsl1.a80, r=mh3, b=usubjid, o=adsl1.a81);
data adsl1.a82;
set adsl1.a81;
if cmiss(HISANXFL) then HISANXFL = "N";
run;
*************************************************************************************************************;
*HISANX	109	30	
If HISANXFL="Y" then HISANX="previous history of anxiety",
 else HISANX="no previous history of anxiety".	;
 
*HISSUI	110	40	
If HISSUIFL="Y" then HISSUI="previous history of suicidal ideation", 
else HISSUI="no previous history of suicidal ideation".	 ;


*HISDEP	111	33	
If HISDEPFL="Y" then HISDEP="previous history of depression",
 else HISDEP="no previous history of depression".	;
 
data adsl1.a83;
set adsl1.a82;
length HISANX $ 30.;
LENGTH HISSUI $ 40.;
LENGTH HISDEP $ 33.;
If HISANXFL="Y" then HISANX="previous history of anxiety";
else HISANX="no previous history of anxiety";
If HISSUIFL="Y" then HISSUI="previous history of suicidal ideation";
else HISSUI="no previous history of suicidal ideation";
If HISDEPFL="Y" then HISDEP="previous history of depression";
else HISDEP="no previous history of depression"	;
run;

************************************************************************************************************;
*ARRANGING ACCORDING TO THE ORDER OF THE VARIABLE;

data ADSL1.ORDER_VAR(keep=variable var_order);
	set nm.adsl_guide;
run;

PROC SORT DATA=ADSL1.ORDER_VAR;
BY VAR_ORDER;
RUN;

proc transpose data=adsl1.ORDER_VAR out=adsl1.FOR_ORDER(drop=_name_ 
		_label_);
	id variable;
run;

proc sql noprint;
	select name into: ADSL_ORDER separated by " " from dictionary.columns where 
		LIBNAME='ADSL1' AND MEMNAME='FOR_ORDER';
QUIT;

%put naam= &ADSL_ORDER.;

DATA ADSL1.ADSL_FINAL_OUTPUT;
RETAIN &ADSL_ORDER.;
SET ADSL1.A83;
RUN;
***********************************************************************************************************;

