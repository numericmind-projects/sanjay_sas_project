*aphase;

*pulling out variables  from adsl; 
/*  */
/* data aphase_adsl(keep=usubjid lstinjdt lstorldt mth12sdt trtsdt mntedt trt01an ltartsdt ltfufl lstinjdt_adj lstorldt_adj); */
/* set ad.adsl; */
/* lstinjdt_adj = lstinjdt+67; */
/* lstorldt_adj =lstorldt+1; */
/* format lstinjdt_adj lstorldt_adj date9.; */
/* run; */
/*  */
/* *for adxw, naming the adxw file as aphase_temp1; */
/*  */
/* data aphase_temp1; */
/* set ofc.adxw8_sh; */
/* run; */
/*  */
/* *merging adsl and our dataset; */
/* proc sort data=aphase_adsl nodup; */
/* by usubjid; */
/* run; */
/*  */
/* proc sort data=aphase_temp1 nodup; */
/* by usubjid; */
/* run; */
/*  */
/* data aphase_temp2; */
/* merge aphase_temp1(in=x) aphase_adsl(in=y); */
/* by usubjid; */
/* if x; */
/* run; */


*instructions::::

*if predecessors are not derived form ae dataset..and.if the usubjid containing predecessor's dataset has EPOCH column and no EGTPT column; 

*also we require adt as our study date which is should already be calculated in your dataset;
*to determine aphase condtions, we need to create 3 columns:
aphase_phase1--->to check for screening subjects
aphase_phase2--->to check for maintenance subjects
aphase_phase3--->to check for long term follow up subjects;

*The values for rows of these columns are set to Y if any of the following conditions are met;

*1st case:
If trtsdt and adt are not missing, then a bunch of conditions are applied;

*2nd case:
If trtsdt is missing and adt is not missing then corresponding rows in aphase_phase1 are set to "Y";

*3rd case:
If trt01an=2 i.e. arm's value is not q2m but dtg+rpv then aphase_phase3 is set to "" empty value.
since DTG + RPV arm subjects cannot enter long term follow up Phase;

*most of the conditions and values for aphase are derived from 1st case:

so
*1st case:
If trtsdt and adt are not missing, then following conditions are checked:
	1. if lstinjdt is not missing and lstorldt is not missing then in such cases,
		--->if adt>max(lstinjdt, lstorldt) then aphase_phase3= "Y"	
		
	[the above conditions apply for both trt01an values 1 and 2..i.e for q2m and dtg+rpv]
	2. if trt01an=2 ..meaning trt01a value is dtg+rpv:
		--->if mth12sdt is not missing then apply following:
					:if epoch is present in column of my domain[xw for example] but egtpt column is not present then:
							if adt>trtsdt and adt<=mth12sdt then aphase_phase2= "Y".
		---->if mth12sdt is missing: apply following:
					:if epoch is present in column of my domain[xw for example]but egtpt column is not present then:
							if adt>trtsdt then aphase_phase2= "Y".
	
	3. if trt01an=1..meaning trt01a value is q2m:
		---->if ltartsdt is not missing then apply following:
					:if epoch is present in column of my domain[xw for example]but egtpt column is not present then:
							if adt>trtsdt and adt<=ltartsdt then aphase_phase2= "Y".
	    
		---->if ltartsdt is missing then apply following:
					::if epoch is present in column of my domain[xw for example]but egtpt column is not present then:
							if adt>trtsdt then aphase_phase2= "Y".
	    
	4. :if epoch is present in column of my domain[xw for example]but egtpt column is not present then:
					: if adt<=trtsdt then aphase_phase1= "Y"


apply 2nd and 3rd case:
now

we have 3 extra cols aphase_phase1 aphase_phase2 and aphase_phase3 with Y values filled in some rows:
if the row has value aphase_phase1= "Y" then for that aphase= 'Screeening' and aphasen=1.
if the row has value aphase_phase2= "Y" then for that aphase= 'Maintenance' and aphasen=2.
if the row has value aphase_phase3= "Y" then for that aphase= 'Long term follow up' and aphasen=3.

**************************************************************************************************;



***************************************************************************************************;




*instructions::::

*if predecessors are not derived form ae dataset..and.if the usubjid containing predecessor's dataset has EPOCH column and no EGTPT column; 

*also we require adt as our study date which is should already be calculated in your dataset;
*to determine aphase condtions, we need to create 3 columns:
aphase_phase1--->to check for screening subjects
aphase_phase2--->to check for maintenance subjects
aphase_phase3--->to check for long term follow up subjects;

*The values for rows of these columns are set to Y if any of the following conditions are met;

*1st case:
If trtsdt and adt are not missing, then a bunch of conditions are applied;

*2nd case:
If trtsdt is missing and adt is not missing then corresponding rows in aphase_phase1 are set to "Y";

*3rd case:
If trt01an=2 i.e. arm's value is not q2m but dtg+rpv then aphase_phase3 is set to "" empty value.
since DTG + RPV arm subjects cannot enter long term follow up Phase;

*most of the conditions and values for aphase are derived from 1st case:

so
*1st case:
If trtsdt and adt are not missing, then following conditions are checked:
	1. if lstinjdt is not missing and lstorldt is not missing then in such cases,
		--->if adt>max(lstinjdt, lstorldt) then aphase_phase3= "Y"	
		
	[the above conditions apply for both trt01an values 1 and 2..i.e for q2m and dtg+rpv]
	2. if trt01an=2 ..meaning trt01a value is dtg+rpv:
		--->if mth12sdt is not missing then apply following:
					:if epoch is present in column of my domain[xw for example] but egtpt column is not present then:
						if epoch eq "TREATMENT" then:
							if adt>trtsdt and adt<=mth12sdt then aphase_phase2= "Y".
					:if epoch and egtpt both column are present in my domain dataset then:
						if epoch eq "TREATMENT" then:
							if (trtsdt<=adt and index(egtpt,'POST DOSE')) and adt<=mth12sdt then aphase_phase2= "Y".
		---->if mth12sdt is missing: apply following:
					:if epoch is present in column of my domain[xw for example]but egtpt column is not present then:
						if epoch eq "TREATMENT" then:
							if adt>trtsdt then aphase_phase2= "Y".
					:if epoch and egtpt both column are present in my domain dataset then:
						if epoch eq "TREATMENT" then:
							if (trtsdt<=adt and index(egtpt,'POST DOSE')) then aphase_phase2= "Y".
		
	3. if trt01an=1..meaning trt01a value is q2m:
		---->if ltartsdt is not missing then apply following:
					:if epoch is present in column of my domain[xw for example]but egtpt column is not present then:
						if epoch eq "TREATMENT" then:
							if adt>trtsdt and adt<=ltartsdt then aphase_phase2= "Y".
	    			:if epoch and egtpt both column are present in my domain dataset then:
	    				if epoch eq "TREATMENT" then:
							if (trtsdt<=adt and index(egtpt,'POST DOSE')) and adt<=ltartsdt then aphase_phase2= "Y"
		---->if ltartsdt is missing then apply following:
					::if epoch is present in column of my domain[xw for example]but egtpt column is not present then:
						if epoch eq "TREATMENT" then:
							if adt>trtsdt then aphase_phase2= "Y".
	    			::if epoch and egtpt both column are present in my domain dataset then:
						if epoch eq "TREATMENT" then:	
							if (trtsdt<=adt and index(egtpt,'POST DOSE')) then aphase_phase2= "Y"
		
	4. :if epoch is present in column of my domain[xw for example]but egtpt column is not present then:
					: if adt<=trtsdt then aphase_phase1= "Y"
	   :if epoch and egtpt both column are present in my domain dataset then:
	             :left this part...not comprehensible from macros:  
	   

apply 2nd and 3rd case:
now

we have 3 extra cols aphase_phase1 aphase_phase2 and aphase_phase3 with Y values filled in some rows:
if the row has value aphase_phase1= "Y" then for that aphase= 'Screeening' and aphasen=1.
if the row has value aphase_phase2= "Y" then for that aphase= 'Maintenance' and aphasen=2.
if the row has value aphase_phase3= "Y" then for that aphase= 'Long term follow up' and aphasen=3.

****************************************************************************************************;

*If predecessor containing usubjid is derived from ae dataset:

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
*if usubjid containing predecessors are derived from datasets other than ae then:

*also we require adt as our study date which is should already be calculated in your dataset;
*to determine aphase condtions, we need to create 3 columns:
aphase_phase1--->to check for screening subjects
aphase_phase2--->to check for maintenance subjects
aphase_phase3--->to check for long term follow up subjects;

*The values for rows of these columns are set to Y if any of the following conditions are met;

*1st case:
If trtsdt and adt are not missing, then a bunch of conditions are applied;

*2nd case:
If trtsdt is missing and adt is not missing then corresponding rows in aphase_phase1 are set to "Y";

*3rd case:
If trt01an=2 i.e. arm's value is not q2m but dtg+rpv then aphase_phase3 is set to "" i.e empty value.
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

