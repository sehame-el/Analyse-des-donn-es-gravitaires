/*
Libname in "C:\Users\maserati\Documents\SAS\projet";
Proc print data = in.final(obs=10); Run;
*/

DM "clear log:clear output";

Libname in "C:\Users\maserati\Documents\SAS\projet";



/*******************************************************
 *****          Récupération des données           *****
 *******************************************************/

%macro ouverture; 
	%do i = 1998 %to 2002; 
		Data donnees&i;
			Infile "C:\Users\maserati\Documents\SAS\projet\BACI_HS96_Y&i._V202401b.csv" dlm = ',' firstobs = 2;
			Input t i j k $ v q;
		Run;
	%end; 
%mend; 

%ouverture; Run;

/*
Proc print data = donnees1998 (obs=5); Run;
Proc contents data = donnees1998; Run;

Proc print data = donnees2002 (obs=5); Run;
Proc contents data = donnees20002; Run; 
*/




/*******************************************************
 *****       Concatenation des tables BACI         *****
 *******************************************************/


Data donnees; Set donnees1998; 
Run;

%macro concatenation; 
	%do i = 1999 %to 2002; 
		Proc sort data = donnees; 
			By t; 
		Run;

		Proc sort data = donnees&i;
			By t; 
		Run; 

		Data donnees; Set donnees donnees&i;
			By t;
		Run;
	%end;
%mend;

%concatenation; Run; 

Data in.donnees; Set donnees; Run;



/* 
Proc print data = donnees (obs=5); Run;
Proc contents data = donnees; Run; 
*/



/*******************************************************
 *****   Ouverture des tables PIB POP et distance  *****
 *******************************************************/

Data table;
    Infile "C:\Users\maserati\Documents\SAS\projet\gdp.csv" dlm=',' ;
    Input country $ indicator $ v1960-v2027;
Run;

Data table1; Set table; 
	Keep country indicator v1996-v2012;
	If _N_ = 1 then delete;
Run;

Proc sort data = table1; 
	By country indicator; 
Run;

Proc transpose data = table1 out = table2;
    By country indicator;          
    Var v1996-v2012; 
Run;

/*
Proc print data = table2(obs=5); Run;
Proc contents data = table2; Run;
*/


/***********PIB***********/

Data PIB_i; Set table2(rename = (country = isoname_i COL1 = PIB_i )); 
		t = input(substr(_name_,2,5), 8.);
	If indicator ="GDP-PPP";
	Keep t isoname_i PIB_i;
Run;

Data PIB_j; Set table2(rename = (country = isoname_j COL1= PIB_j )); 
		t = input(substr(_name_,2,5), 8.);
	If indicator = "GDP-PPP";
	Keep t isoname_j PIB_j;
Run;


Proc sql;
    Create table PIB as
    Select 
        PIB_i.t as t, 
        PIB_i.isoname_i, 
        PIB_i.PIB_i, 
        PIB_j.isoname_j, 
        PIB_j.PIB_j
    From PIB_i, PIB_j
    Where PIB_i.t = PIB_j.t;
Quit;

Data in.PIB; Set PIB; run;


/***********POP***********/

Data POP_i; Set table2(rename = (country = isoname_i COL1 = POP_i )); 
		t = input(substr(_name_,2,5), 8.);
	If indicator ="POP";
	Keep t isoname_i POP_i;
Run;

Data POP_j; Set table2(rename = (country = isoname_j COL1 = POP_j )); 
		t =input(substr(_name_,2,5), 8.);
	If indicator = "POP";
	Keep t isoname_j POP_j;
Run;


Proc sql;
    Create table POP as
    Select 
        POP_i.t as t, 
        POP_i.isoname_i, 
        POP_i.POP_i, 
        POP_j.isoname_j, 
        POP_j.POP_j
    From POP_i, POP_j
    Where POP_i.t = POP_j.t;
Quit;

Data in.POP; Set POP; run;



/*********Distance********/

Proc import out = distance
	Datafile = "C:\Users\maserati\Documents\SAS\projet\dist_cepii.xls"
	Dbms = xls replace;
Run;

Data distance; Set distance(keep = iso_o iso_d dist);
	Rename iso_o = isoname_i iso_d =isoname_j; 
Run;

Data in.distance; Set distance; run;

/*
Proc print data = PIB(obs=5); Run;
Proc contents data = PIB; Run; 

Proc print data = POP(obs=5); Run;
Proc contents data = POP; Run;

Proc print data = distance (obs=5); Run;
Proc contents data = distance; Run;
*/


/*******************************************************
 *****            Importation de isoo              *****
 *******************************************************/

Proc import datafile ="C:\Users\maserati\Documents\SAS\projet\country_codes_V202401b.csv"
    Out = isoo
    Dbms = csv replace;
    Delimiter = ',';
    Getnames = yes;
Run;


Data iso_i; Set isoo(keep = country_code country_iso3);  
	Rename country_code = i; 
	Rename country_iso3 = isoname_i; 
Run; 

Data iso_j; Set isoo(keep = country_code country_iso3);
	Rename country_code = j; 
	Rename country_iso3 = isoname_j; 
Run; 


Proc sql;
    Create table iso as
    Select 
        iso_i.isoname_i, 
        iso_i.i, 
        iso_j.isoname_j, 
       	iso_j.j
    From iso_i, iso_j;
Quit;

Data iso; Set iso; 
	Format i j isoname_i isoname_j ; 
Run;

Data in.iso; Set iso; run;

/*
Proc print data = iso(obs=100); Run;
Proc contents data = iso; Run;
*/



/*******************************************************
 *****           Importation de secteur            *****
 *******************************************************/

Proc import out = secteur0
	Datafile = "C:\Users\maserati\Documents\SAS\projet\HS1996 to SITC3.xls"
	Dbms = xls replace;
	Sheet = "Conversion Table";
	Range = "Conversion Table$D:E";
Run;

Data secteur; Set secteur0; 
	If D = "" and E = "" then delete; 
	If D = "HS96" and E = "S3" then delete;
	Rename D = k;
		s = substr(E,1,2);
	Drop E;
Run;

Data in.secteur; Set secteur; run;

/*
Proc print data = secteur(obs=100); Run;
Proc contents data = secteur; Run;
*/



/*******************************************************
 ***On merge donnees et secteur pour calculer le PUMP***
 *******************************************************/

Proc sort data = donnees; 
	By k; 
Run;

Proc sort data = secteur;
	By k; 
Run; 

Data temp0; Merge donnees(in = a) secteur;
	If a;
	By k;
Run;


Proc sql; 
	Create table tempp as select *, q/sum(q) as poids
	From temp0
	Group by i, j,s,t;
Quit;

Proc sql; 
	Create table table as select*, 
		sum(v/q*poids) as pump
	From tempp
	Group by i,j,s,t; 
Run;

Data in.table; Set table; Run; 

/*
Proc contents data = table; Run;
Proc print data = in.table(obs=5); Run;
*/


/*******************************************************
 ****   On merge donnees avec PIB POP et distance   ****
 *******************************************************/

Proc sort data = table; 
	By i j; 
Run;

Proc sort data = iso;
	By i j; 
Run;

Data temp2; merge table(in = a) iso; 
	If a;
	By i j;
Run;


Proc sort data = temp2; 
	By t isoname_i isoname_j; 
Run; 

Proc sort data = PIB; 
	By t isoname_i isoname_j; 
Run; 

Proc sort data = POP; 
	By t isoname_i isoname_j; 
Run; 

Data temp3; Merge temp2(in = a) PIB POP; 
	If a;
	By t isoname_i isoname_j; 
Run;


Proc sort data = temp3; 
	By isoname_i isoname_j; 
Run;

Proc sort data = distance; 
	By isoname_i isoname_j; 
Run;

Data temp4; Merge temp3 (in = a) distance;
	If a; 
	By isoname_i isoname_j; 
Run;

Data in.temp4; Set temp4; run;

/*
Proc contents data = temp4; Run;
Proc print data = temp4(obs=5); Run;
*/



/*******************************************************
 ****       On garde que les pays de l'OCDE         ****
 *******************************************************/

Proc import out = ocdee
	Datafile = "C:\Users\maserati\Documents\SAS\projet\iso_alpha3_ocde.xlsx"
	Dbms = xlsx replace;
Run;


Data ocde_i; Set ocdee(keep = ISO_Alpha_3_ocde);  
	Rename ISO_Alpha_3_ocde=isoname_i; 
Run; 

Data ocde_j; Set ocdee(keep = ISO_Alpha_3_ocde);
	Rename ISO_Alpha_3_ocde =isoname_j; 
Run; 

Proc sql;
    Create table ocde as
    Select 
        ocde_i.isoname_i, 
        ocde_j.isoname_j 
    From ocde_i, ocde_j;
Quit;

Data in.ocde; Set ocde; Run;


Proc sort data = temp4; 
	By isoname_i isoname_j; 
Run;

Proc sort data = ocde; 
	By isoname_i isoname_j; 
Run; 

Data fin; Merge temp4(in = a) ocde(in = b); 
	By isoname_i isoname_j; 
	If a and b; 
Run; 

Proc sort data = fin ; 
	By t i j s; 
Run;


Data fin2; Set fin; 
	if cmiss(of _all_) = 0;
Run;

Data in.fin2; Set fin2; Run;

/*
Proc contents data = fin2; Run;
Proc print data = fin2(obs=5); Run;
*/

/*******************************************************
 ****     Mise en ordre, voici la table final       ****
 *******************************************************/

Proc sql;
    Create table final as
    Select t, i, isoname_i, j, isoname_j, s, k, v, q, poids, pump, PIB_i, PIB_j, POP_i, POP_j, dist
    From fin2;
Quit;

Data in.final; Set final; Run;


/*******************************************************
 ****             Ajout des indicatrices            ****
 *******************************************************/

%let pays = DEU-AUT-BEL-CAN-DNK-ESP-USA-FRA-GRC-IRL-ISL-LUX-NOR-NLD-PRT-GBR-
			SWE-CHE-TUR-ITA-JPN-FIN-AUS-NZL-MEX-CZE-KOR-HUN-POL-SVK-CHL-EST- 
			ISR-SVN-LVA-LTU-COL-CRI;


Data indicatrices; Set in.final; Run; 


%macro indicatrices_p;
	%do a = 1 %to 38;
	%let b = %scan(&pays, &a);
		Data indicatrices; Set indicatrices;
			If isoname_i = "&b." then &b._i = 1; else &b._i = 0;
			If isoname_j = "&b." then &b._j = 1; else &b._j = 0;
		Run;
	%end;  

%mend;

%indicatrices_p;

Data in.indicatrices; Set indicatrices; Run;
Data indicatrices1; Set indicatrices; Run; 


%macro indicatrices_t;
	%do i = 1998 %to 2002;
		Data indicatrices1; Set indicatrices1;
			If t = &i then DUM_&i. = 1; else DUM_&i. = 0;
		Run;
	%end;  

%mend;

%indicatrices_t; 

data in.indicatrices1; set indicatrices1; run;
data etude; set indicatrices1; 
data in.etude; set etude; run;

/*
Libname in "C:\Users\maserati\Documents\SAS\projet";
Proc print data = in.etude (obs=50); Run;
Proc contents data = in.etude; Run;
*/




/*************************************STAT DESCRIPTIVES ET REGRESSION*****************************************************/

/*
Libname in "C:\Users\maserati\Documents\SAS\projet";
Data etudee; Set in.etude; Run;
Proc print data = etudee (obs=500); Run;
Proc contents data = etudee; Run;
*/

Data etude; Set etudee;
	log_q = log(q);
	log_pump = log(pump);
	log_PIB_i = log(PIB_i);
	log_PIB_j = log(PIB_j);
	log_POP_i = log(POP_i);
	log_POP_j = log(POP_j);
	log_dist = log(dist);
	drop CAN_i CAN_j DUM_2000;
Run;



/*Balance commerciale*/

Proc means data = etude1 n sum mean maxdec = 2;
    Class isoname_i;
    Var q;
    Output out = temp1 (drop = _type_ _freq_)
        sum = exportations;
Run;

Proc means data = etude1 n sum mean maxdec = 2;
    Class isoname_j;
    Var q;
    Output out = temp2 (drop = _type_ _freq_)
        sum = importations;
Run;

Proc sql;
    Create table BC as
    Select a.isoname_i as isoname, a.exportations, b.importations, exportations-importations as bc   
    From temp1 as a
    Inner join temp2 as b
    On a.isoname_i = b.isoname_j;
Quit;

Ods rtf file = "C:\Users\maserati\Documents\SAS\projet\bc.rtf" style = science;
Proc sgplot data = bc;
    Vbar isoname / response = bc stat = sum;
    Xaxis label = "Pays";
    Yaxis label = "Balance Commerciale" values = (-1231022817 to 1517719117 by 137437097) valueattrs = (size = 8);
    Title "Histogramme des Balances Commerciales par Pays";
Run;
Ods rtf close;


/*Partenaires de la France*/

Proc sql;
    Create table france_partners as
    Select 
        case 
            when isoname_i = "FRA" then isoname_j
            when isoname_j = "FRA" then isoname_i
        end as partner,
        sum(q) as total_q
    From etude
    Where isoname_i = "FRA" or isoname_j = "FRA"
    Group by partner
    Order by total_q desc;
Quit;

Ods rtf file = "C:\Users\maserati\Documents\SAS\projet\france.rtf" style = science;
Proc sgplot data = france_partners;
    Vbar partner / response=total_q;
	Xaxis label = "Pays";
    Yaxis label = "Total des échanges en volume";
    Title "Les partenaires commerciaux de la France";
Run;
Ods rtf close;

/**/


%let var = q pump PIB_i PIB_j POP_i POP_j dist;
%let log_var = log_q log_pump log_PIB_i log_PIB_j log_POP_i log_POP_j log_dist;


Ods rtf file = "C:\Users\maserati\Documents\SAS\projet\stat_des.rtf" style = science;
		Proc means data = etude mean median min max std; 
			Var &var.;
			Output out = stat(drop = _TYPE_ _FREQ_);
			title "Statistiques descriptives des variables";
		Run;
Ods rtf close;


Ods rtf file = "C:\Users\maserati\Documents\SAS\projet\correlation.rtf" style = science;
		Proc corr data = etude cov outp = corr; 
			Var &log_var.;
			title "Tableau de corrélation entre les variables"; 
		Run;
Ods rtf close;


%macro densite;
%do a = 1 %to 7;
	%let b = %scan(&var.,&a.);
Ods rtf file = "C:\Users\maserati\Documents\SAS\projet\densite&b..rtf" style = science;
	Proc kde data = etude;
		Univar &b. / plots =Density;
		Title "Courbe de densité pour la variable &b.";
	Run;
Ods rtf close;
	%end;
%mend;

%densite;


Ods rtf file = "C:\Users\maserati\Documents\SAS\projet\densitelogq.rtf" style = science;
	Proc kde data = etude;
		Univar log_q / plots = Density;
		Title "Courbe de densité pour la variable log_q";
	Run;
Ods rtf close;



/*******************************************************************************************************************/

Ods excel file = "C:\Users\maserati\Documents\SAS\projet\regression.xlsx" style = science;
Proc reg data = etude plots=none;
   Model log_q= AUS_i AUS_j AUT_i AUT_j BEL_i BEL_j CHE_i CHE_j CHL_i CHL_j COL_i COL_j 
CRI_i CRI_j CZE_i CZE_j DEU_i DEU_j DNK_i DNK_j DUM_1998 DUM_1999 DUM_2001 DUM_2002 
ESP_i ESP_j EST_i EST_j FIN_i FIN_j FRA_i FRA_j GBR_i GBR_j GRC_i GRC_j HUN_i HUN_j 
IRL_i IRL_j ISL_i ISL_j ISR_i ISR_j ITA_i ITA_j JPN_i JPN_j KOR_i KOR_j LTU_i LTU_j 
LUX_i LUX_j LVA_i LVA_j MEX_i MEX_j NLD_i NLD_j NOR_i NOR_j NZL_i NZL_j POL_i POL_j 
SVK_i SVK_j SVN_i SVN_j SWE_i SWE_j TUR_i TUR_j USA_i USA_j
log_PIB_i log_PIB_j log_POP_i log_POP_j log_dist log_pump;
   Run;
Quit;
Ods excel close;

