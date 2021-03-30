*For deriving aphase, 3 columns are created: aphase_phase1, aphase_phase2 and aphase_phase3.
aphase_phase1--->to check for screening subjects
aphase_phase2--->to check for maintenance subjects
aphase_phase3--->to check for long term follow up subjects;

*if the conditions below are met then each row of these corresponding columns are set to "Y".

****************************************************************************************************;

*If predecessor containing usubjid is derived from "ae" dataset then the following conditions
are applied:[astdt has to be calculated first i.e astdt is a derived/assigned variable]
get the required variables from adsl and your current dataset:

from adsl ::varibles required: trtsdt, trt01an, ltartsdt, lstinjdt, lstorldt, mth12sdt
from ae[ for example,creating dataset for adae]:: usubjid, aeseq, aerefid, aeacnoth, astdt[calculated by yourself]
merge them and apply the conditions below:


*if trtsdt, trt01an and astdt are not missing then:
	1. if trt01an=1 then:
			1a. if ltartsdt is not missing then:
					->if (trtsdt<=astdt and astdt<ltartsdt) 
						or (astdt=ltartsdt and aeacnoth eq "WITHDRAWN FROM STUDY") 
						then aphase_phase2="Y"
					->if (trtsdt<astdt and astdt>=ltartsdt)
						and not(astdt=ltartsdt and aeacnoth eq "WITHDRAWN FROM STUDY") 
						then aphase_phase3= "Y"
					->if lstinjdt and lstorldt are not missing then:
						if astdt>lstinjdt and astdt>lstorldt then aphase_phase3 = "Y"
			
			1b.	if ltartsdt is missing then:
					->if trtsdt<=astdt then aphase_phase2 = "Y".
	2.	if trt01an=2 then:
			2a.	if mth12sdt is not missing then:
					->if trtsdt<=astdt and astdt<=mth12sdt then aphase_phase2= "Y"
					->if trtsdt<astdt and astdt>=mth12sdt then aphase_phase3= "Y"
			2b.	 if mth12sdt is missing then:
					->if trtsdt<=astdt then aphase_phase2= "Y"
					
	3.	if astdt<trtsdt then aphase_phase1= "Y"
	
	
*if trtsdt, trt01an and astdt are missing then:
			aphase_phase1=""
			aphase_phase2=""
			aphase_phase3=""
***********************************************************************************************;
***********************************************************************************************;
***********************************************************************************************;



*if usubjid containing predecessors are derived from datasets other than "ae" then:

*also we require adt as our study date which is should already be calculated in your dataset;
*to determine aphase condtions, we need to create 3 columns:
aphase_phase1--->to check for screening subjects
aphase_phase2--->to check for maintenance subjects
aphase_phase3--->to check for long term follow up subjects;

*from adsl ::varibles required:usubjid, trtsdt, trt01an, ltartsdt, lstinjdt, lstorldt, mth12sdt
from xw or any other dataset other than ae
[ for example xw is taken for creating dataset for adxw]:: usubjid, xwseq(depends on dataset..could be egseq or any other seq),epoch(if present), egtpt(if present), adt/sdt[calculated by yourself]
merge them and apply the conditions below:



*The values for rows of these columns are set to Y if any of the following conditions are met;

*1st case:
If trtsdt and adt are not missing, then a bunch of conditions are applied;

*2nd case:
If trtsdt is missing and adt is not missing then  aphase_phase1= "Y";

*3rd case:
If trt01an=2 then aphase_phase3 ="" [i.e empty value.]
since DTG + RPV arm subjects cannot enter long term follow up Phase;

*most of the conditions and values for aphase are derived from 1st case:

so
*1st case:
If trtsdt and adt are not missing, then following conditions are checked:
	1. if lstinjdt is not missing and lstorldt is not missing then in such cases,
		--->if adt>max(lstinjdt, lstorldt) then aphase_phase3= "Y"	
		
	[the above conditions apply for both trt01an = 1 or 2]
	
	2. if trt01an=2 :
		--->if mth12sdt is not missing then apply following:
					:if epoch is present in column of my domain[xw for example] but egtpt column is not present then:
						
							if trtsdt<adt and adt<=mth12sdt then aphase_phase2= "Y".
					:if epoch and egtpt both column are present in my domain dataset then:
						
							if (trtsdt<=adt and index(egtpt,'POST DOSE')) or (trtsdt<adt and adt<=mth12sdt) then aphase_phase2= "Y".
		---->if mth12sdt is missing: apply following:
					:if epoch is present in column of my domain[xw for example]but egtpt column is not present then:
						
							if trtsdt<adt then aphase_phase2= "Y".
							
					:if epoch and egtpt both column are present in my domain dataset then:
						if epoch eq "TREATMENT" then:
							if (trtsdt<=adt and index(egtpt,'POST DOSE')) or (trtsdt<adt) then aphase_phase2= "Y".
		
	3. if trt01an=1..meaning trt01a value is q2m:
		---->if ltartsdt is not missing then apply following:
					:if epoch is present in column of my domain[xw for example]but egtpt column is not present then:
						
							if trtsdt<adt and adt<=ltartsdt then aphase_phase2= "Y".
	    			:if epoch and egtpt both column are present in my domain dataset then:
	    				
							if (trtsdt<=adt and index(egtpt,'POST DOSE'))or ( trtsdt<adt and adt<=ltartsdt) then aphase_phase2= "Y"
		---->if ltartsdt is missing then apply following:
					::if epoch is present in column of my domain[xw for example]but egtpt column is not present then:
						
							if trtsdt<adt then aphase_phase2= "Y".
	    			::if epoch and egtpt both column are present in my domain dataset then:
						
							if (trtsdt<=adt and index(egtpt,'POST DOSE')) or (trtsdt<adt ) then aphase_phase2= "Y"
		
	4. :if epoch is present in column of my domain[xw for example]but egtpt column is not present then:
					: if adt<=trtsdt then aphase_phase1= "Y"
	   :if epoch and egtpt both column are present in my domain dataset then:
	             	: if (trtsdt=adt and index(egtpt, "PRE DOSE")) or adt<trtsdt then aphase_phase1= "Y"
	   

apply 2nd and 3rd case:
now

we have 3 extra cols aphase_phase1 aphase_phase2 and aphase_phase3 with Y values filled in some rows:
if the row has value aphase_phase1= "Y" then for that aphase= 'Screeening' and aphasen=1.
if the row has value aphase_phase2= "Y" then for that aphase= 'Maintenance' and aphasen=2.
if the row has value aphase_phase3= "Y" then for that aphase= 'Long term follow up' and aphasen=3.

****************************************************************************************************;


*In most of the cases, if aphase_phase1= "Y" then aphase_phase2 and aphase_phase3 are empty.However,
if aphase_phase2= "Y" and aphase_phase3= "Y" in the same row then 
APHASE= "Maintenance" and we need to add an extra row for the same usubjid
with value APHASE= 'Long term follow up'...i.e the row is duplicated with both of the APHASE values:
i.e. Maintenance and Long term follow up.
AND FOR such duplicated values, DTYPE column= "Phantom".
 
