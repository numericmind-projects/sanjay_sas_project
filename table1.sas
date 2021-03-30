data adc1_full1;
set ad.adc1;
run;

data adc1_filter1(keep=usubjid adecod trt01p trt01pn);
set ad.adc1;
where lpdblfl eq "Y" and lpdmpfl ne "";
run;


proc freq data=adc1_filter1;
tables adecod*trt01pn /nopercent out=adc1_freq1(drop=percent);
run;

data adc1_freq2;
set adc1_freq1;
retain adecodn 0;
adecodn = adecodn+1;
run;

data dummy;
do trt01pn=1 to 3;
	do adecodn=1 to 6;
		output;
	end;

end;

data adc1_freq3;
merge adc1_freq1 dummy;
if cmiss(count) then count=0;
run;

proc sort data=adc1_freq3;
by adecodn;
run;

proc transpose data=adc1_freq3 prefix=trt out=adc1_freq4;
by adecodn;
var count;
id trt01pn;
run;

data adc1_freq5(drop= _name_ _label_);
set adc1_freq4;
trt3= trt1+trt2;
run;


*for percentage;
proc sort data=adc1_full1(keep=usubjid trt01p trt01pn) nodupkey;
by usubjid trt01pn;
run;

data adc1_full2;
set adc1_full1;
output;
trt01p='total';
trt01pn=3;
output;
run;

proc sort data=adc1_full2;
by trt01pn;
run;

data adc1_full3(keep=trt01pn ttl);
set adc1_full2;
by trt01pn;
retain ttl;
if first.trt01pn then ttl=1;
else ttl=ttl+1;
if last.trt01pn;
run;


*merge for percent calc;
data adc1

