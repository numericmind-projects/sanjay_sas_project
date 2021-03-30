data xyz;
length col1 $10.;
input col1 $;
cards;
20.1
32
555
997.8645
11.234
26(1%)
123(39%)
1(1%)
7(100%)
;
run;




data xyz1;
length col1 $10.;
set xyz;
col1= left(compress(col1));
l_col1= length(col1);
max_l_col1= 10;
if index(col1, ".")>0 then points_b_d = length(scan(col1, 1, "."));
else if index(col1, "(")>0 then  points_b_d= length(scan(col1, 1, "("));
else points_b_d = length(col1);
space_to_add= 4-points_b_d-1;
run;



data xyz2;
set xyz1;
if space_to_add= 0 then alignment=  "" || col1;
if space_to_add =1 then alignment = " " || " " || col1;
if space_to_add =2 then alignment = " " || " " || " " || col1;
if space_to_add =3 then alignment = " "|| " " || " " || " " || col1;
run;

data xyz3;
set xyz2;
if index(col1, "(")>0 then brac_length = length(scan(alignment, 2, "()"));
run;


data xyz4;
set xyz3;
if brac_length=2 then alignment= scan(alignment, 1, "(" ) || " " || " " || " " || "(" || scan(alignment, 2, "(");

if brac_length=3 then alignment= scan(alignment, 1, "(" ) || " " || " " || "(" || scan(alignment, 2, "(");


if brac_length=4 then alignment= scan(alignment, 1, "(" ) || " " || "(" || scan(alignment, 2, "(");

run;









proc template;
   define style styles.mypdf;
      parent=styles.printer;
      style fonts /
           'BatchFixedFont' = ("Courier",10pt)
           'TitleFont2' = ("Courier",10pt)
           'TitleFont' = ("Courier",10pt)
           'StrongFont' = ("Courier",10pt)
           'EmphasisFont' = ("Courier",10pt)
           'FixedEmphasisFont' = ("Courier",10pt)
           'FixedStrongFont' = ("Courier",10pt)
           'FixedHeadingFont' = ("Courier",10pt)
           'FixedFont' = ("Courier",10pt)
           'headingEmphasisFont' = ("Courier",10pt)
           'headingFont' = ("Courier",10pt)
           'docFont' = ("Courier",10pt);
   end;
   define style styles.myrtf;
      parent=styles.rtf;
      style fonts /
           'BatchFixedFont' = ("Courier",10pt)
           'TitleFont2' = ("Courier",10pt)
           'TitleFont' = ("Courier",10pt)
           'StrongFont' = ("Courier",10pt)
           'EmphasisFont' = ("Courier",10pt)
           'FixedEmphasisFont' = ("Courier",10pt)
           'FixedStrongFont' = ("Courier",10pt)
           'FixedHeadingFont' = ("Courier",10pt)
           'FixedFont' = ("Courier",10pt)
           'headingEmphasisFont' = ("Courier",10pt)
           'headingFont' = ("Courier",10pt)
           'docFont' = ("Courier",10pt);
   end;
run;



/* PDF */
/* The PROC FORMAT code in this example places spaces behind the 
   digit selectors for the one and zero decimal formats. */    


ods pdf file='/folders/myfolders/team/office/sample.pdf' notoc style=styles.mypdf;



proc report data=xyz4 nowd style(column)=[just=l asis=on];
   column alignment;

run;

ods pdf close;















