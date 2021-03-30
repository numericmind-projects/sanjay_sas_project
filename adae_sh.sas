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
%macro adae_check(v=);
data adae_check(keep=usubjid &v);
set ad.adae;
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
data ofc.adae_guide(keep= dataset variable var_order length derivation source_var origin);
set nm.adam_guide;
where dataset eq "adae";
run;
*************************************************************************************************;

%pred_usubj1(meta_source=/folders/myfolders/team/adam/ADAM_Metadata_Reviewer_Aid_28APR2020.xlsm,
 dataset=adae, pull_from=ae, library=sd, output_name=ofc.adae1_sh);

%pred_other1(prev_file=ofc.adae1_sh, dataset=adae,  pull_from=adsl, library=ad, output_name=ofc.adae2_sh);

*not resolved:
TRTP
TRTPN
TRTA
TRTAN

**************************************************************************************************;
*ASTDT;
data ofc.adae3_sh(keep=usubjid aeseq aerefid astdt);
set ofc.adae2_sh(keep=usubjid aeseq aerefid aestdtc trtsdt);
date_length= length(aestdtc);
if date_length eq 10 then ASTDTC_pre = aestdtc;
if date_length eq 7 then do;ASTDTC_pre= cats(aestdtc, "-01");partial_date= "Y";end;
/* if date_length ne 10; */
ASTDTC_pre1= input(ASTDTC_pre, yymmdd10.);

if partial_date eq 'Y' and trtsdt>astdtc_pre1 then ASTDT = trtsdt;
/* else if partial date eq "Y" and trtsdt<astdtc_pre1 then astdt = astdtc_pre1; */
else astdt= astdtc_pre1;
format astdtc_pre1 astdt date9.;
run;

/* ASTDT = input(aestdtc, yymmdd10.); */
/* format astdt date9.; */
run;

data aphase_adsl(keep=usubjid lstinjdt lstorldt mth12sdt trtsdt mntedt trt01an ltartsdt ltfufl); *lstinjdt_adj lstorldt_adj);
set ad.adsl;
/* lstinjdt_adj = lstinjdt+67; */
/* lstorldt_adj =lstorldt+1; */
/* format lstinjdt_adj lstorldt_adj date9.; */
run;

data aeac;
set sd.ae(keep=usubjid aeseq aerefid aeacnoth);
run;

%left_join(l=ofc.adae3_sh, r= aeac, b=usubjid aeseq aerefid, o=aeac2);
%left_join(l=aeac2, r=aphase_adsl,b=usubjid, o=ofc.adae_aphase);


data a_c;
set ofc.adae_aphase;
if usubjid eq "116482.000151";
run;



 **************************************************************************************;
 
 %adae_check(v=aphase);
data sd_check;
set sd.ae(keep=usubjid aeacnoth);
if aeacnoth eq 'WITHDRAWN FROM STUDY';
run;
****************************************************************************************;

data tab1;
input a $ b c;
cards;
p 1 1
p 2 3
. 3 4
r 1 1
p . 1
p . .
. . .
;
run;

%let aeacnoth = 1;
%macro xyz;
data tab2;
set tab1;
if b eq 1 and
 %if &aeacnoth then d= "Y";
/* %if &aeacnoth %then %do; d= "Y";%end; */
/*  %if &aeacnoth %then d="Y"; does not work */
run;
%mend;

%xyz;
