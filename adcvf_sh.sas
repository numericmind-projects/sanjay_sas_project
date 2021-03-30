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
%macro adcvf_check(v=);
data adcvf_check1(keep=usubjid &v);
set ad.adcvf;
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
data ofc.adcvf_guide(keep= dataset variable var_order length derivation source_var origin);
set nm.adam_guide;
where dataset eq "adcvf";
run;
*************************************************************************************************;



*Included only records where 
LB.LBSPEC='SERUM OR PLASMA' and LB.LBMETHOD='POLYMERASE CHAIN REACTION' 
and LB.LBTESTCD in ('HIV1RNA' 'HIV1RNAL') from LB dataset.;

data ofc.lb;
set sd.lb;
where lbspec eq 'SERUM OR PLASMA' and
LBMETHOD eq 'POLYMERASE CHAIN REACTION' and LBTESTCD in ('HIV1RNA', 'HIV1RNAL');
run;

%pred_usubj1(meta_source=/folders/myfolders/team/adam/ADAM_Metadata_Reviewer_Aid_28APR2020.xlsm ,
dataset=adcvf, pull_from=lb, library=ofc, output_name=ofc.adcvf1_sh);
%pred_other1(prev_file=ofc.adcvf1_sh, dataset=adcvf,  pull_from=adsl, library=ad, output_name=ofc.adcvf2_sh);

*not resolved:

parcat1
trtp
trtpn
trta
trtan
;


*resolving unresolved variables ;
data ofc.adcvf3_sh;
set ofc.adcvf2_sh;
TRTP= TRT01P;
TRTPN= TRT01PN;
TRTA= TRT01A;
TRTAN=TRT01AN;
RUN;

*PARCAT1
LB.LBCAT;
DATA PARCAT1(KEEP=USUBJID LBCAT);
SET OFC.LB;
RUN;

%left_join(l=ofc.adcvf3_sh, r=parcat1, b=usubjid, o=ofc.adcvf4_sh);
************************************************************************************************;



