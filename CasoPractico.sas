
/* 
 * Variables dependientes:
 * 
 * Black      -> Black Mother 			 -> Madre de color (1 si, 0 no)
 * Boy        -> Baby Boy 				 -> Bebé (1 niño, 0 niña)
 * CigsPerDay -> Cigarettes Per Day 	 -> Número de Cigarrillos por día
 * Married    -> Married Mother 		 -> Madre casada (1 si, 0 no)
 * MomAge     -> Mother's Age 			 -> Edad de la madre (equivale el 0 a tener 25 años)
 * MomEdLevel -> Mother's Education 	 -> Level Nivel de educación de la madre (de 0 a 3, siendo 0 nada)
 * MomSmoke   -> Smoking Mother 	 	 -> Madre fumadora (1 si, 0 no)
 * MomWtGain  -> Mother's Preg Wght Gain -> Embarazo de la madre pérdida/aumento de peso
 * Visit      -> Prenatal Visit 		 -> Visita prenatal (de 0 a 3, siendo el 0 ninguna visita) 
 * 
 * Variable Objetivo:
 * weight 	  -> Baby Weight			 -> Peso del Bebe
 * 
*/;



data bwg;
  set sashelp.bweight;
run;

/* Analisis de objetivo */;

proc freq data=bwg;
	tables weight;
run;

/* Es una variable númerica, con lo que tenemos que aplicar modelos GLM */

proc means data=bwg;
	var weight;
run;

proc gchart data=bwg;
 vbar weight;
run;

/*  NOTE: There were 50000 observations read from the data set SASHELP.BWEIGHT.
 NOTE: The data set WORK.BWG has 50000 observations and 10 variables. 
 
 Analysis Variable : Weight Infant Birth Weight
	N	Media	Desv. est.	Mínimo	Máximo
50000	3370.76	566.3850556	240.00	6350.00
 */;

/*Analisis Normalidad de la variable objetivo*/;
proc univariate data=bwg normal plot;
 var weight;
 HISTOGRAM /NORMAL(COLOR=MAROON W=4) CFILL = BLUE CFRAME = LIGR;
 INSET MEAN STD /CFILL=BLANK FORMAT=5.2;
run;


/*Limpieza de datos*/;

/*Podriamos eliminar duplicados */;
proc sort data=bwg out=B dupout=C nodupkey; By _all_ ; run;
/* Pero considero que no son datos duplicados, sino dos observaciones distintas con exactamente los mismos valores en todas las variables */;


/* Para comprobar que no hay algun error basisco en la entrada de datos, es decir que no hay nadie que diga que no fuma y si que tiene cigarrillos */;
data bwgDummy (keep = alerta);
 set bwg;
 	if cigsperDay = 0 and MomSmoke = 1 then alerta=1;
	else
	if cigsperDay> 0 and MomSmoke = 0 then alerta=2;
	else alerta=0;
run;

proc freq data=bwgDummy;
run;
/*alerta	Frecuencia	Porcentaje	Frecuencia acumulada	Porcentaje acumulado
	0			50000	100.00			50000				100.00*/;



proc corr data=bwg;
 var MomSmoke cigsperday;
run;


/* Data Cooking:
*  -------------
*  Empezamos con 50000 observaciones y 10 variables:

 
 * Categoricas
 * -----------
 * Black
 * Boy
 * Married
 * MomEdLevel
 * MomSmoke
 * Visit
 * 
 * Numericas
 * ---------
 * MomAge
 * CigsPerDay
 * MomWtGain
*/;


proc means data=bwg;
var MomAge CigsPerDay Momwtgain;
run;

proc univariate data=bwg normal plot;
	var MomAge CigsPerDay MomWtGain;
run;

/* Variables de clase */


proc freq data=bwg;
	table black;
run;

proc freq data=bwg;
	table boy;
run;

proc freq data=bwg;
	table married;
run;

proc freq data=bwg;
	table MomEdLevel;
run;

proc freq data=bwg;
	table MomSmoke;
run;

proc freq data=bwg;
	table Visit;
run;

/* No hay variables sin observaciones, con lo no es necesario descartar nada */;

proc freq data=bwg;
	table MomAge;
	run;
	

proc freq data=bwg;
	table CigsPerDay;
	run;

proc freq data=bwg;
	table MomWtGain;
	run;

/* Una vez estudiado todas las variables independientes pasamos a generar el dataset que usamos para generar el modelo */
/* Mom Age esta centrado en 25 años, con lo que sumamos 25 */;


data bwgC (drop = momAge momSmoke);
 set bwg;
 realMomAge = momAge + 25;
run;

/* No hay variables sin observaciones, con lo no es necesario descartar nada */;




ods graphics on;

proc ttest data=bwgc;
   var _numeric_;
run;

ods graphics off;



/* 
 * ----------------------
 * Estudio de correlación
 * ----------------------
*/;

proc corr data=bwg;
run;
/* No hay ninguna variable correlada */;


/* Generamos un modelo nuevo con las ganancia de peso agrupadas */;

data bwgW (drop = MomwtGain);
 set bwgC;
 pesoAgrupado = momWtGain - mod(momWtGain,5);
run;

proc univariate data=bwgW normal plot;
	var pesoAgrupado;
run;



/*
 * --------------------------------------------------------------------------------------
 * A partir de este momento tenemos dos datasets limpios a priori bwgC y bwgW, el primero 
 * con la edad de la madre corregido y el segundo con la ganancia de peso agrupada en 
 * cada 5 kilos para evitar los errores en la toma de datos.
 * 
 * COn estos datasets vamos a intentar generar un modelo
 */;



/* Generamos un modelo básico para bwgC  e incluimos todas las variables y todas las 
intercacciones posibles*/;

proc glmselect data=bwgC;
 class Black Boy Married MomEdLevel Visit;
 model weight = Black Boy Married MomEdLevel Visit RealMomAge CigsPerDay MomWtGain
 				Black*Boy Black*Married Black*MomEdLevel Black*Visit Black*RealMomAge Black*CigsPerDay Black*MomWtGain
 				Boy*Married Boy*MomEdLevel Boy*Visit Boy*RealMomAge Boy*CigsPerDay Boy*MomWtGain
 				Married*MomEdLevel Married*Visit Married*RealMomAge Married*CigsPerDay Married*MomWtGain
 				MomEdLevel*Visit MomEdLevel*RealMomAge MomEdLevel*CigsPerDay MomEdLevel*MomWtGain
 				Visit*RealMomAge Visit*CigsPerDay Visit*MomWtGain
 				CigsPerDay*MomWtGain
 				

       /selection=stepwise; 
run;



/* Modelo elegido */;
/*Intercept Boy MomEdLevel Black*Married realMomAge*Black CigsPerDay*Boy MomWtGain*Boy MomWtGain*Visit /*/;

/*Una vez elegido el modelo lo vamos mejorando */

proc glm data=bwgC;
 class Black Boy Married MomEdLevel Visit;
 model weight = Boy MomEdLevel Black*Married realMomAge*Black CigsPerDay*Boy MomWtGain*Boy MomWtGain*Visit /solution e;
run;

/* Vemos que no hay ninguna  variable con un P valor superior a 0.0001 en el error tipo III y damos el modelo por válido
   R^2 = 0.105719*/;


/* Repetimos el analisis modificando ligeramente las observaciones debido al extraño comportamiento de la variable MomWtGain*/;
/* Otro modelo con la ganancia de peso de la madre agrupada */;






proc glmselect data=bwgW;
 class Black Boy Married MomEdLevel Visit;
 model weight = Black Boy Married MomEdLevel Visit RealMomAge CigsPerDay PesoAgrupado
 				Black*Boy Black*Married Black*MomEdLevel Black*Visit Black*RealMomAge Black*CigsPerDay Black*PesoAgrupado
 				Boy*Married Boy*MomEdLevel Boy*Visit Boy*RealMomAge Boy*CigsPerDay Boy*PesoAgrupado
 				Married*MomEdLevel Married*Visit Married*RealMomAge Married*CigsPerDay Married*PesoAgrupado
 				MomEdLevel*Visit MomEdLevel*RealMomAge MomEdLevel*CigsPerDay MomEdLevel*PesoAgrupado
 				Visit*RealMomAge Visit*CigsPerDay Visit*PesoAgrupado
 				CigsPerDay*PesoAgrupado
 				

       /selection=stepwise; 
run;

/* Intercept Boy MomEdLevel Black*Married realMomAge*Black CigsPerDay*Boy pesoAgrupado*Boy pesoAgrupado*Visit */;

proc glm data=bwgW;
 class Black Boy Married MomEdLevel Visit;
 model weight = Boy MomEdLevel Black*Married realMomAge*Black CigsPerDay*Boy pesoAgrupado*Boy pesoAgrupado*Visit /solution e;
run;
/* Vemos que no hay ninguna  variable con un P valor superior a 0.0001 en el error tipo III y damos el modelo por válido,
  R^2 = 0.104320 */;

/* Vemos que no hay ninguna diferencia entre ambos modelos (MomWtGain agrupadas y sin agrupar) Ligerame*/



/* Visit no lo consideramos como variable de clase y repetimos*/

proc glmselect data=bwgC;
 class Black Boy Married MomEdLevel;
 model weight = Black Boy Married MomEdLevel Visit RealMomAge CigsPerDay MomWtGain
 				Black*Boy Black*Married Black*MomEdLevel Black*Visit Black*RealMomAge Black*CigsPerDay Black*MomWtGain
 				Boy*Married Boy*MomEdLevel Boy*Visit Boy*RealMomAge Boy*CigsPerDay Boy*MomWtGain
 				Married*MomEdLevel Married*Visit Married*RealMomAge Married*CigsPerDay Married*MomWtGain
 				MomEdLevel*Visit MomEdLevel*RealMomAge MomEdLevel*CigsPerDay MomEdLevel*MomWtGain
 				Visit*RealMomAge Visit*CigsPerDay Visit*MomWtGain
 				CigsPerDay*MomWtGain
 				

       /selection=stepwise; 
run;



/* Boy MomEdLevel Black*Married realMomAge*Black CigsPerDay*Boy MomWtGain*Boy Visit*CigsPerDay */;

proc glm data=bwgC;
 class Black Boy Married MomEdLevel;
 model weight = Boy MomEdLevel Black*Married realMomAge*Black CigsPerDay*Boy MomWtGain*Boy Visit*CigsPerDay /solution e;
run;
/* Vemos que no hay ninguna  variable con un P valor superior a 0.0001 en el error tipo III y damos el modelo por válido,
  R^2 = 0.104842 */;

proc glmselect data=bwgW;
 class Black Boy Married MomEdLevel;
 model weight = Black Boy Married MomEdLevel Visit RealMomAge CigsPerDay PesoAgrupado
 				Black*Boy Black*Married Black*MomEdLevel Black*Visit Black*RealMomAge Black*CigsPerDay Black*PesoAgrupado
 				Boy*Married Boy*MomEdLevel Boy*Visit Boy*RealMomAge Boy*CigsPerDay Boy*PesoAgrupado
 				Married*MomEdLevel Married*Visit Married*RealMomAge Married*CigsPerDay Married*PesoAgrupado
 				MomEdLevel*Visit MomEdLevel*RealMomAge MomEdLevel*CigsPerDay MomEdLevel*PesoAgrupado
 				Visit*RealMomAge Visit*CigsPerDay Visit*PesoAgrupado
 				CigsPerDay*PesoAgrupado
 				

       /selection=stepwise; 
run;

/* 	Intercept Boy MomEdLevel Black*Married realMomAge*Black CigsPerDay*Boy pesoAgrupado*Boy Visit*CigsPerDay */;

proc glm data=bwgW;
 class Black Boy Married MomEdLevel;
 model weight = Boy MomEdLevel Black*Married realMomAge*Black CigsPerDay*Boy pesoAgrupado*Boy Visit*CigsPerDay /solution e;
run;

/* Vemos que no hay ninguna  variable con un P valor superior a 0.0001 en el error tipo III y damos el modelo por válido,
  R^2 = 0.103479 */;


/* De todos los modelos realizados el que mayor R^2 da es con la ganancia de peso de la madre desagrupado 
 y considerando visit como variable de clase */ 










/* Una vez hecho un modelo básico, vamos a hacer simulaciones con distintas seeds para ver si se puede mejorar */;

%let libMSV = '/home/u38083750/unaiherran/Practica1/Output/resultados01.txt';


/* Macros:

Creamos cuatro macros distintas, basadas en los modelos que hemos calculado previamente, una con la consideracion de 
Visit como variable de clase o no, y otra con la ganancia del peso de la madre agrupada o no

*/;





/*Macro Sin Agrupar MomWTGain y Visit class*/;
%macro macroSV (semi_ini, semi_fin, metodo);

%do semilla=&semi_ini. %to &semi_fin.;
	ods graphics on;
	ods output   SelectionSummary=modelos;
	ods output   SelectedEffects=efectos;
	ods output   Glmselect.SelectedModel.FitStatistics=ajuste;
	
	proc glmselect data=bwgC plots=all seed=&semilla;
		  partition fraction(validate=0.2);
		  class Black Boy Married MomEdLevel Visit; 
		  model weight = Black Boy Married MomEdLevel Visit RealMomAge CigsPerDay MomWtGain
		  				Black*Married realMomAge*Black CigsPerDay*Boy MomWtGain*Boy MomWtGain*Visit
		 		 
	  / selection=&metodo.(select=aic choose=validate) details=all stats=all;
	run;
	
	ods graphics off;   
	ods html close;   
	
	data union; i=12; set efectos; set ajuste point=i; run; *observación 12 ASEval;
	
	data  _null_;
		semilla=&semilla; 
		metodo=&metodo.;
	file &libMSV mod;
	set union;put effects "," nvalue1 "," semilla ", &metodo., SV";run;

	proc sql; drop table modelos,efectos,ajuste,union; quit;
%end;

%mend;




/*Macro Agrupar MomWTGain y Visit class*/;
%macro macroAV (semi_ini, semi_fin, metodo);

%do semilla=&semi_ini. %to &semi_fin.;
	ods graphics on;
	ods output   SelectionSummary=modelos;
	ods output   SelectedEffects=efectos;
	ods output   Glmselect.SelectedModel.FitStatistics=ajuste;
	
	proc glmselect data=bwgW plots=all seed=&semilla;
		  partition fraction(validate=0.2);
		  class Black Boy Married MomEdLevel Visit; 
		  model weight = Black Boy Married MomEdLevel Visit RealMomAge CigsPerDay PesoAgrupado
		  				Black*Married realMomAge*Black CigsPerDay*Boy pesoAgrupado*Boy Visit*CigsPerDay
		 		 
	  / selection=&metodo.(select=aic choose=validate) details=all stats=all;
	run;
	
	ods graphics off;   
	ods html close;   
	
	data union; i=12; set efectos; set ajuste point=i; run; *observación 12 ASEval;
	
	data  _null_;
		semilla=&semilla; 
		metodo=&metodo.;
	file &libMSV mod;
	set union;put effects "," nvalue1 "," semilla ", &metodo., AV";run;

	proc sql; drop table modelos,efectos,ajuste,union; quit;
%end;

%mend;


/*Macro Sin Agrupar MomWTGain*/;
%macro macroS (semi_ini, semi_fin, metodo);

%do semilla=&semi_ini. %to &semi_fin.;
	ods graphics on;
	ods output   SelectionSummary=modelos;
	ods output   SelectedEffects=efectos;
	ods output   Glmselect.SelectedModel.FitStatistics=ajuste;
	
	proc glmselect data=bwgC plots=all seed=&semilla;
		  partition fraction(validate=0.3);
		  class Black Boy Married MomEdLevel; 
		  model weight = Black Boy Married MomEdLevel Visit RealMomAge CigsPerDay MomWtGain
		  				Black*Married realMomAge*Black CigsPerDay*Boy MomWtGain*Boy MomWtGain*Visit
		 		 
	  / selection=&metodo.(select=aic choose=validate) details=all stats=all;
	run;
	
	ods graphics off;   
	ods html close;   
	
	data union; i=12; set efectos; set ajuste point=i; run; *observación 12 ASEval;
	
	data  _null_;
		semilla=&semilla; 
		metodo=&metodo.;
	file &libMSV mod;
	set union;put effects "," nvalue1 "," semilla ", &metodo., S";run;

	proc sql; drop table modelos,efectos,ajuste,union; quit;
%end;

%mend;




/*Macro Agrupar MomWTGain y Visit class*/;
%macro macroA (semi_ini, semi_fin, metodo);

%do semilla=&semi_ini. %to &semi_fin.;
	ods graphics on;
	ods output   SelectionSummary=modelos;
	ods output   SelectedEffects=efectos;
	ods output   Glmselect.SelectedModel.FitStatistics=ajuste;
	
	proc glmselect data=bwgW plots=all seed=&semilla;
		  partition fraction(validate=0.3);
		  class Black Boy Married MomEdLevel; 
		  model weight = Black Boy Married MomEdLevel Visit RealMomAge CigsPerDay PesoAgrupado
		  				Black*Married realMomAge*Black CigsPerDay*Boy pesoAgrupado*Boy Visit*CigsPerDay
		 		 
	  / selection=&metodo.(select=aic choose=validate) details=all stats=all;
	run;
	
	ods graphics off;   
	ods html close;   
	
	data union; i=12; set efectos; set ajuste point=i; run; *observación 12 ASEval;
	
	data  _null_;
		semilla=&semilla; 
		metodo=&metodo.;
	file &libMSV mod;
	set union;put effects "," nvalue1 "," semilla ",&metodo.,A";run;

	proc sql; drop table modelos,efectos,ajuste,union; quit;
%end;

%mend;

/* Ejecutamos las macros */;


%macroSV (12300,12350, stepwise);
%macroS (12300,12350, stepwise);
%macroAV (12300,12350, stepwise);
%macroA (12300,12350, stepwise);
%macroSV (12300,12350,, Backward);
%macroS (12300,12350, Backward);
%macroAV (12300,12350, Backward);
%macroA (12300,12350, Backward);
%macroSV (12300,12350, Forward);
%macroS (12300,12350, Forward);
%macroAV (12300,12350, Forward);
%macroA (12300,12350, Forward);




proc import datafile = '/home/u38083750/unaiherran/Practica1/Output/resultados01.txt'
 out = resultado
 dbms = dlm
 replace;
 delimiter = ',';
 getnames = no;
run;


data resultado_clean;
 set resultado; 
 rename           VAR1 = modelo
                          var2 = ASEEval
                          var3 = semilla
                          var4 = metodo
                          var5 = dataset;
run;

proc sort data=resultado_clean; by modelo;

proc freq data=resultado_clean;

/* El modelo mas frecuente (101 veces) es:
 Intercept Boy MomEdLevel Black*Married realMomAge*Black CigsPerDay*Boy MomWtGain*Boy
 Pero los valores de ASEVAL son muy altos 275810 - 298125
 */;
 
 
 proc univariate data=bwgC normal plot;
 var weight;
 HISTOGRAM /NORMAL(COLOR=MAROON W=4) CFILL = BLUE CFRAME = LIGR;
 INSET MEAN STD /CFILL=BLANK FORMAT=5.2;
run;

/* Outliers para weight 1% 1559 y 4605 
  Los eliminamos

*/;

 
data bwgCnO;
   set bwgC;
   if weight <= 1559 or weight >= 4605 then delete;
run;
 
 proc univariate data=bwgCno normal plot;
 var weight;
 HISTOGRAM /NORMAL(COLOR=MAROON W=4) CFILL = BLUE CFRAME = LIGR;
 INSET MEAN STD /CFILL=BLANK FORMAT=5.2;
run;

data bwgWnO;
   set bwgW;
   if weight <= 1559 or weight >= 4605 then delete;
run;


%let lib2 = '/home/u38083750/unaiherran/Practica1/Output/resultados02.txt';



/*Macro Visit class*/;
%macro macroVnO (semi_ini, semi_fin, metodo);

%do semilla=&semi_ini. %to &semi_fin.;
	ods graphics on;
	ods output   SelectionSummary=modelos;
	ods output   SelectedEffects=efectos;
	ods output   Glmselect.SelectedModel.FitStatistics=ajuste;
	
	proc glmselect data=bwgCno plots=all seed=&semilla;
		  partition fraction(validate=0.2);
		  class Black Boy Married MomEdLevel Visit; 
		  model weight = Black Boy Married MomEdLevel Visit RealMomAge CigsPerDay MomWtGain
		  				Black*Boy Black*Married Black*MomEdLevel Black*Visit Black*RealMomAge Black*CigsPerDay Black*MomWtGain
 				Boy*Married Boy*MomEdLevel Boy*Visit Boy*RealMomAge Boy*CigsPerDay Boy*MomWtGain
 				Married*MomEdLevel Married*Visit Married*RealMomAge Married*CigsPerDay Married*MomWtGain
 				MomEdLevel*Visit MomEdLevel*RealMomAge MomEdLevel*CigsPerDay MomEdLevel*MomWtGain
 				Visit*RealMomAge Visit*CigsPerDay Visit*MomWtGain
 				CigsPerDay*MomWtGain
		  				
	 		 
	  / selection=&metodo.(select=aic choose=validate) details=all stats=all;
	run;
	
	ods graphics off;   
	ods html close;   
	
	data union; i=12; set efectos; set ajuste point=i; run; *observación 12 ASEval;
	
	data  _null_;
		semilla=&semilla; 
		metodo=&metodo.;
	file &lib2 mod;
	set union;put effects "," nvalue1 "," semilla ", &metodo., SV";run;

	proc sql; drop table modelos,efectos,ajuste,union; quit;
%end;

%mend;





/*Macro Agrupar MomWTGain y Visit class*/;
%macro macroAVnO (semi_ini, semi_fin, metodo);

%do semilla=&semi_ini. %to &semi_fin.;
	ods graphics on;
	ods output   SelectionSummary=modelos;
	ods output   SelectedEffects=efectos;
	ods output   Glmselect.SelectedModel.FitStatistics=ajuste;
	
	proc glmselect data=bwgWno plots=all seed=&semilla;
		  partition fraction(validate=0.2);
		  class Black Boy Married MomEdLevel Visit; 
		  model weight = Black Boy Married MomEdLevel Visit RealMomAge CigsPerDay PesoAgrupado
		  		Black*Boy Black*Married Black*MomEdLevel Black*Visit Black*RealMomAge Black*CigsPerDay Black*PesoAgrupado
 				Boy*Married Boy*MomEdLevel Boy*Visit Boy*RealMomAge Boy*CigsPerDay Boy*PesoAgrupado
 				Married*MomEdLevel Married*Visit Married*RealMomAge Married*CigsPerDay Married*PesoAgrupado
 				MomEdLevel*Visit MomEdLevel*RealMomAge MomEdLevel*CigsPerDay MomEdLevel*PesoAgrupado
 				Visit*RealMomAge Visit*CigsPerDay Visit*PesoAgrupado
 				CigsPerDay*PesoAgrupado
 				
	  / selection=&metodo.(select=aic choose=validate) details=all stats=all;
	run;
	
	ods graphics off;   
	ods html close;   
	
	data union; i=12; set efectos; set ajuste point=i; run; *observación 12 ASEval;
	
	data  _null_;
		semilla=&semilla; 
		metodo=&metodo.;
	file &lib2 mod;
	set union;put effects "," nvalue1 "," semilla ", &metodo., AV";run;

	proc sql; drop table modelos,efectos,ajuste,union; quit;
%end;

%mend;


/*Macro Sin Agrupar MomWTGain*/;
%macro macroSnO (semi_ini, semi_fin, metodo);

%do semilla=&semi_ini. %to &semi_fin.;
	ods graphics on;
	ods output   SelectionSummary=modelos;
	ods output   SelectedEffects=efectos;
	ods output   Glmselect.SelectedModel.FitStatistics=ajuste;
	
	proc glmselect data=bwgCno plots=all seed=&semilla;
		  partition fraction(validate=0.3);
		  class Black Boy Married MomEdLevel; 
		  model weight = Black Boy Married MomEdLevel Visit RealMomAge CigsPerDay MomWtGain
		  				Black*Boy Black*Married Black*MomEdLevel Black*Visit Black*RealMomAge Black*CigsPerDay Black*MomWtGain
 				Boy*Married Boy*MomEdLevel Boy*Visit Boy*RealMomAge Boy*CigsPerDay Boy*MomWtGain
 				Married*MomEdLevel Married*Visit Married*RealMomAge Married*CigsPerDay Married*MomWtGain
 				MomEdLevel*Visit MomEdLevel*RealMomAge MomEdLevel*CigsPerDay MomEdLevel*MomWtGain
 				Visit*RealMomAge Visit*CigsPerDay Visit*MomWtGain
 				CigsPerDay*MomWtGain
 				
 				 
	  / selection=&metodo.(select=aic choose=validate) details=all stats=all;
	run;
	
	ods graphics off;   
	ods html close;   
	
	data union; i=12; set efectos; set ajuste point=i; run; *observación 12 ASEval;
	
	data  _null_;
		semilla=&semilla; 
		metodo=&metodo.;
	file &lib2 mod;
	set union;put effects "," nvalue1 "," semilla ", &metodo., S";run;

	proc sql; drop table modelos,efectos,ajuste,union; quit;
%end;

%mend;




/*Macro Agrupar MomWTGain y Visit class*/;
%macro macroAnO (semi_ini, semi_fin, metodo);

%do semilla=&semi_ini. %to &semi_fin.;
	ods graphics on;
	ods output   SelectionSummary=modelos;
	ods output   SelectedEffects=efectos;
	ods output   Glmselect.SelectedModel.FitStatistics=ajuste;
	
	proc glmselect data=bwgWno plots=all seed=&semilla;
		  partition fraction(validate=0.3);
		  class Black Boy Married MomEdLevel; 
		  model weight = Black Boy Married MomEdLevel Visit RealMomAge CigsPerDay PesoAgrupado
		  				Black*Boy Black*Married Black*MomEdLevel Black*Visit Black*RealMomAge Black*CigsPerDay Black*PesoAgrupado
 				Boy*Married Boy*MomEdLevel Boy*Visit Boy*RealMomAge Boy*CigsPerDay Boy*PesoAgrupado
 				Married*MomEdLevel Married*Visit Married*RealMomAge Married*CigsPerDay Married*PesoAgrupado
 				MomEdLevel*Visit MomEdLevel*RealMomAge MomEdLevel*CigsPerDay MomEdLevel*PesoAgrupado
 				Visit*RealMomAge Visit*CigsPerDay Visit*PesoAgrupado
 				CigsPerDay*PesoAgrupado
		  				
		  			
	  / selection=&metodo.(select=aic choose=validate) details=all stats=all;
	run;
	
	ods graphics off;   
	ods html close;   
	
	data union; i=12; set efectos; set ajuste point=i; run; *observación 12 ASEval;
	
	data  _null_;
		semilla=&semilla; 
		metodo=&metodo.;
	file &lib2 mod;
	set union;put effects "," nvalue1 "," semilla ",&metodo.,A";run;

	proc sql; drop table modelos,efectos,ajuste,union; quit;
%end;

%mend;

%macroSVno (12300,12350, stepwise);
%macroSno (12300,12350, stepwise);
%macroAVno (12300,12350, stepwise);
%macroAno (12300,12350, stepwise);
%macroSVno (12300,12350,, Backward);
%macroSno (12300,12350, Backward);
%macroAVno (12300,12350, Backward);
%macroAno (12300,12350, Backward);
%macroSVno (12300,12350, Forward);
%macroSno (12300,12350, Forward);
%macroAVno (12300,12350, Forward);
%macroAno (12300,12350, Forward);


/* Estudiamos los resultados */;

proc import datafile = '/home/u38083750/unaiherran/Practica1/Output/resultados02.txt'
 out = resultado
 dbms = dlm
 replace;
 delimiter = ',';
 getnames = no;
run;


data resultado_clean;
 set resultado; 
 rename           VAR1 = modelo
                          var2 = ASEEval
                          var3 = semilla
                          var4 = metodo
                          var5 = dataset;
run;

proc sort data=resultado_clean; by modelo;
run;


proc freq data=resultado_clean; run;

/*
 * Modelos con más repeciones:

Intercept Black Boy Married MomEdLevel Visit realMomAge CigsPerDay 
pesoAgrupado Black*Boy Black*Married realMomAge*Black CigsPerDay*Black 
pesoAgrupado*Black Boy*Married Boy*Visit realMomAge*Boy CigsPerDay*Boy 
pesoAgrupado*Boy Married

Intercept Black*MomEdLevel realMomAge*Black Boy*Married CigsPerDay*Boy 
MomWtGain*Boy CigsPerDay*Married MomWtGain*MomEdLevel Visit*CigsPerDay


Intercept Black*MomEdLevel realMomAge*Black Boy*Married CigsPerDay*Boy 
pesoAgrupado*Boy CigsPerDay*Married realMomAg*MomEdLevel pesoAgrup*MomEdLevel 
Visit*CigsPerDay

Intercept Visit Black*MomEdLevel realMomAge*Black CigsPerDay*Black Boy*Married 
CigsPerDay*Boy MomWtGain*Boy realMomAge*Married CigsPerDay*Married realMomAg*MomEdLevel 
MomWtGain*MomEdLevel CigsPerDay*Visit MomWtGain*Visit

ASE 217588-232091

 * 
 */;

/*Estudiamos cada uno de los modelos */;
proc glm data=bwgWno;
 class Black Boy Married MomEdLevel;
 model weight = Black Boy Married MomEdLevel Visit realMomAge CigsPerDay 
pesoAgrupado Black*Boy Black*Married realMomAge*Black CigsPerDay*Black 
pesoAgrupado*Black Boy*Married Boy*Visit realMomAge*Boy CigsPerDay*Boy 
pesoAgrupado*Boy Married  /solution e;
run;

/*quitamos las interacciones con P valor alto */
proc glm data=bwgWno;
 class Black Boy Married MomEdLevel Visit;
 model weight = Black Boy Married MomEdLevel realMomAge CigsPerDay 
pesoAgrupado realMomAge*Black  
 CigsPerDay*Boy 
pesoAgrupado*Boy Married  /solution e;
run;
/*0.095851*/;





proc glm data=bwgCnO;
 class Black Boy Married MomEdLevel;
 model weight = Black*MomEdLevel realMomAge*Black Boy*Married CigsPerDay*Boy 
MomWtGain*Boy CigsPerDay*Married MomWtGain*MomEdLevel Visit*CigsPerDay /solution e;
run;
/* 0.098127*/;






proc glm data=bwgWno;
 class Black Boy Married MomEdLevel;
 model weight = Black*MomEdLevel realMomAge*Black Boy*Married CigsPerDay*Boy 
pesoAgrupado*Boy CigsPerDay*Married realMomAge*MomEdLevel pesoAgrupado*MomEdLevel Visit*CigsPerDay /solution e;
run;

proc glm data=bwgWno;
 class Black Boy Married MomEdLevel;
 model weight = Black*MomEdLevel realMomAge*Black Boy*Married CigsPerDay*Boy 
pesoAgrupado*Boy CigsPerDay*Married pesoAgrupado*MomEdLevel Visit*CigsPerDay /solution e;
run;

/* 0.096577 */;





proc glm data=bwgCnO;
 class Black Boy Married MomEdLevel;
 model weight = Visit Black*MomEdLevel realMomAge*Black CigsPerDay*Black Boy*Married 
CigsPerDay*Boy MomWtGain*Boy realMomAge*Married CigsPerDay*Married realMomAge*MomEdLevel 
MomWtGain*MomEdLevel CigsPerDay*Visit MomWtGain*Visit /solution e;
run;

proc glm data=bwgCnO;
 class Black Boy Married MomEdLevel;
 model weight =  Black*MomEdLevel realMomAge*Black  Boy*Married 
CigsPerDay*Boy MomWtGain*Boy CigsPerDay*Married realMomAge*MomEdLevel 
 CigsPerDay*Visit  /solution e;
run;
/* 0.098088 */;



/* Modelo con menor ASEVAL*/;

proc glmselect data=bwgCno plots=all seed=12307;
		  partition fraction(validate=0.2);
		  class Black Boy Married MomEdLevel Visit; 
		  model weight =  Visit Black*MomEdLevel realMomAge*Black CigsPerDay*Black Boy*Married CigsPerDay*Boy MomWtGain*Boy 
		  realMomAge*Married CigsPerDay*Married realMomAge*MomEdLevel MomWtGain*MomEdLevel CigsPerDay*Visit MomWtGain*Visit 
		 		 
	  / selection=forward(select=aic choose=validate) details=all stats=all;
	run;
/*217588 */;

proc glm data=bwgCno;
		  class Black Boy Married MomEdLevel Visit; 
		  model weight =  Visit Black*MomEdLevel realMomAge*Black CigsPerDay*Black Boy*Married CigsPerDay*Boy MomWtGain*Boy 
		  realMomAge*Married CigsPerDay*Married realMomAge*MomEdLevel MomWtGain*MomEdLevel CigsPerDay*Visit MomWtGain*Visit 
		  / solution e;
		  run;

proc glm data=bwgCno;
		  class Black Boy Married MomEdLevel Visit; 
		  model weight =  Visit Black*MomEdLevel realMomAge*Black Boy*Married CigsPerDay*Boy MomWtGain*Boy 
		   CigsPerDay*Married realMomAge*MomEdLevel MomWtGain*Visit 
		  / solution e;
		  run;		  
		  
		 /* 0.098710 */

proc glmselect data=bwgCno plots=all seed=12307;
		  partition fraction(validate=0.2);
		  class Black Boy Married MomEdLevel Visit; 
		  model weight =  Visit Black*MomEdLevel realMomAge*Black Boy*Married CigsPerDay*Boy MomWtGain*Boy 
		   CigsPerDay*Married realMomAge*MomEdLevel MomWtGain*Visit
		 		 
	  / selection=forward(select=aic choose=validate) details=all stats=all;
	run;		  
		  /* 217280 */
		 
		 
		 
		 
		 /* Grabamos la libreria para usarlo en el DataMiner */;
		 
data lib_prac.bweight_cooked;
   set bwgCno;
run;
		 
data lib_prac.bweightW_cooked;
   set bwgWno;
run;		 
 