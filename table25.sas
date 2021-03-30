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
**************************************************************************************************************;


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

*******************************************************************;
*******************************************************************;

*for any medication;
data adc1_any1;
set adc1_filter1;
adecodn= 0;
run;
proc sort data=adc1_any1 nodupkey out=adc1_any2;
by usubjid;
run;

proc freq data=adc1_any2;
tables adecodn*trt01pn/ out=adc1_any3(drop=percent);
run;

data dummy2;
do trt01pn=1 to 3;
	do adecodn=0 to 0;
	output;
	end;
end;
run;

data adc1_any4;
merge adc1_any3 dummy2;
if count eq . then count =0;
run;


proc transpose data=adc1_any4 prefix=trt out=adc1_any5;
by adecodn;
var count;
id trt01pn;
run;
***************stacking***************************;
data adc1_freq4a;
set adc1_any5 adc1_freq4;
run;

************************************************************************************************************;

data adc1_freq5(drop= _name_ _label_);
set adc1_freq4a;
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

proc transpose data=adc1_full3 prefix=trt1 out=adc1_full4 ;
var ttl;
id trt01pn;
run;

data adc1_full5;
set adc1_full4;
do i=1 to 7;
output;
end;
run;

data adc1_freq6(drop= _name_ i);
merge adc1_freq5 adc1_full5;
run;

*using arrays for calc;
data adc1_freq7;
set adc1_freq6;
array x [3] trt1 trt2 trt3;
array y [3] trt11 trt12 trt13 ;
array percent[3];
do i=1 to dim(x);
 percent[i] =round((x[i]/y[i])*100, 1);
end;
drop i;
run;

data adc1_freq8;
set adc1_freq7;
array percent[3];
array trt[3];
array trt_final[3] $;
do i=1 to dim(percent);
	
	if percent[i] ne 0 then trt_final[i] =cats( put(trt[i], best.) , "(" ,  put(percent[i], best.) , "%)");
	else  trt_final[i] = cats(put(trt[i], best.));
end;
drop i;
run;

data adc1_freq9;
merge adc1_freq2(keep=adecod adecodn) adc1_freq8;
by adecodn;
if adecodn=0 then adecod= 'Any medications';
if adecodn=0 then grp='a';
else grp='b';
run;

proc sort data=adc1_freq9 out=adc1_freq10;
by descending percent3;
run;


*macro for decimal alignment;
%macro decimal_alignment(dataset=, column=, final_name=);
%let und= _1;
%let und2= x;

data final_table2x1;
set &dataset;
if index(&column, ".")>0 then points_b_d = length(scan(&column, 1, "."));
else if index(&column, "(")>0 then  points_b_d= length(scan(&column, 1, "("));
else points_b_d = length(&column);
space_to_add= 4-points_b_d-1;
run;



data final_table2x2;
set final_table2x1;
if space_to_add= 0 then &column&und=  "" || &column;
if space_to_add =1 then  &column&und = " " || " " || &column;
if space_to_add =2 then  &column&und = " " || " " || " " || &column;
if space_to_add =3 then  &column&und = " "|| " " || " " || " " || &column;
run;


data final_table2x3;
set final_table2x2;
if index(&column, "(")>0 then brac_length = length(scan(&column&und, 2, "()"));
run;


data &final_name(drop=brac_length space_to_add points_b_d &column&und &column);
set final_table2x3;
if brac_length=2 then &column&und2= scan(&column&und, 1, "(" ) || " " || " " || " " || "(" || scan(&column&und, 2, "(");

else if brac_length=3 then &column&und2= scan(&column&und, 1, "(" ) || " " || " " || "(" || scan(&column&und, 2, "(");


else if brac_length=4 then &column&und2= scan(&column&und, 1, "(" ) || " " || "(" || scan(&column&und, 2, "(");
else &column&und2=&column&und;

run;
%mend;


**********************************************************************************************************;





data adc1_freq11(keep=adecod trt_final1-trt_final3 grp);
set adc1_freq10;
run;




%decimal_alignment(dataset=adc1_freq11, column=trt_final1, final_name= adc1_freq12);
%decimal_alignment(dataset=adc1_freq12, column=trt_final2, final_name= adc1_freq13);

%decimal_alignment(dataset=adc1_freq13, column=trt_final3, final_name= adc1_freq14);
















options papersize='LETTER' orientation=landscape topmargin = '3.61cm' bottommargin = '3.61cm' 
        leftmargin = '2.54cm' rightmargin = '2.54cm' nodate nonumber missing=' ';



%** Create template for TLFs **;
proc template;  
  %** Courier 9pt **;
  
   define style styles.mypdf;
   	  style(report)={just=center rules=none frame=void cellspacing=0 
			cellheight=0.1in} style(lines)=header{background=white asis=on 
			font_size=10pt font_face="Courier New" font_weight=medium just=left 
			cellheight=0.1in} style(header)=header{just=l background=white 
			font_size=10pt font_face="Courier New" font_weight=medium 
			borderbottomstyle=dashed borderbottomwidth=0.5px borderbottomcolor=gray} 
			style(column)=header{just=left background=white font_size=10pt 
			font_face="Courier New" font_weight=medium asis=on cellheight=0.1in} 
			style={outputwidth=100%};
			
      parent=styles.printer;
      replace fonts /  
      	  'TitleFont2' = ("Courier",10pt )         
          'TitleFont' = ("Courier",10pt )          
          'FootnoteFont' = ("Courier",10pt )       
          'StrongFont' = ("Courier",10pt )         
          'EmphasisFont' = ("Courier",10pt )
          'FixedEmphasisFont' = ("Courier",10pt )
          'FixedStrongFont' = ("Courier",10pt)
          'FixedHeadingFont' = ("Courier",10pt)
          'BatchFixedFont' = ("Courier",10pt )
          'FixedFont' = ("Courier",10pt )
          'headingEmphasisFont' = ("Courier",10pt )
          'headingFont' = ("Courier",10pt )        
          'docFont' = ("Courier",10pt );
	     replace document from container	/	
          asis = on
          protectspecialchars=off;
        replace SystemFooter from TitlesAndFooters /
          asis = on
          protectspecialchars = on
          font= Fonts('FootnoteFont');         
	     replace systemtitle from titlesandfooters/
          asis = on
          protectspecialchars=off;   
	     replace body from document	/	
		    asis = on; 
        replace color_list
          "Colors used in the default style" /
          'link'= blue
          'bgH'= white
          'fg' = black
          'bg' = white;         
        replace Table from output /
          Background=_UNDEF_                                                
          cellpadding = 0pt   
          Rules=groups
          Frame=hsides;
        style Header from Header /
          Background=_undef_;
        style Rowheader from Rowheader /
          Background=_undef_;
        replace pageno from titlesandfooters/
          Foreground=white;
   end;

   define style styles.ods_9pt;
        parent=styles.rtf;
        replace fonts/
          'TitleFont2' = ("Courier New",9pt )         
          'TitleFont' = ("Courier New",9pt )          
          'FootnoteFont' = ("Courier New",9pt )       
          'StrongFont' = ("Courier New",9pt )         
          'EmphasisFont' = ("Courier New",9pt )
          'FixedEmphasisFont' = ("Courier New",9pt )
          'FixedStrongFont' = ("Courier New",9pt)
          'FixedHeadingFont' = ("Courier New",9pt)
          'BatchFixedFont' = ("Courier New",9pt )
          'FixedFont' = ("Courier New",9pt )
          'headingEmphasisFont' = ("Courier New",9pt )
          'headingFont' = ("Courier New",9pt )        
          'docFont' = ("Courier New",9pt );
	     replace document from container	/	
          asis = on
          protectspecialchars=off;
        replace SystemFooter from TitlesAndFooters /
          asis = on
          protectspecialchars = on
          font= Fonts('FootnoteFont');         
	     replace systemtitle from titlesandfooters/
          asis = on
          protectspecialchars=off;   
	     replace body from document	/	
		    asis = on; 
        replace color_list
          "Colors used in the default style" /
          'link'= blue
          'bgH'= white
          'fg' = black
          'bg' = white;         
        replace Table from output /
          Background=_UNDEF_                                                
          cellpadding = 0pt   
          Rules=groups
          Frame=hsides;
        style Header from Header /
          Background=_undef_;
        style Rowheader from Rowheader /
          Background=_undef_;
        replace pageno from titlesandfooters/
          Foreground=white;
   end;
run;

ods noresults escapechar = "^";
ods listing close;
ods pdf file='/folders/myfolders/team/office/sample.pdf' notoc style=styles.mypdf ;
/* ods pdf file="/folders/myfolders/team/office/sample1.pdf" style=styles.ods_9pt */
	

title1 j= l font= 'Courier' "Protocol: 209035 POLAR" j=r 'Page ^{thispage} of ^{lastpage}';
title2 j= l font= 'Courier' "Population: Intent-to-Treat Exposed";
title3 j= c font= 'Courier' "Table 1.25";
title4 j= c font= 'Courier' "Summary of Lipid Modifying Agent Use at Baseline";
footnote j=l "/folders/myfolders/team/office/table25.sas";



/* proc report data=final_table2_total4 nowd style(column)=[just=l asis=on]; */
proc report nowd data=adc1_freq14 style(column)=[just=l asis=on] split='$' missing;
columns grp adecod trt_final1x trt_final2x trt_final3x;




/* define pg / order order=internal noprint; */
/*  */
define grp / order order=internal noprint;
/*  */
/* define inner / order order=internal noprint; */
/*  */
define adecod / 'Ingredients' display style(header)=[just=l]  
              style(column)=[asis=on just=l cellwidth=44%];
/*  */
define trt_final1x / "Q2M$(N=90)" display style(header)=[just=l] 
             style(column)=[just=l cellwidth=15%];

define trt_final2x / "DTG+RPV$(N=7)" display style(header)=[just=l]
             style(column)=[just=l cellwidth=15%];

define trt_final3x / "Total$(N=97)" display style(header)=[just=l]
              style(column)=[just=l cellwidth=15%];
/*  */
/*  */
/* break after pg/page; */
/*  */
/*  */
/*  */
/*  */
/*  */
/*  */
compute before grp / style=[asis=on just=l];
	line ' ';
endcomp;


run;

ods listing;
ods pdf close;



















