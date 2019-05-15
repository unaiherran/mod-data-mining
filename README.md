# Práctica Modulo Data Mining
## KC BD 3

El modelo de los datos es el siguiente:

```
  Variables independientes:
  
  Black      -> Black Mother 		-> Madre de color (1 si, 0 no)
  Boy        -> Baby Boy 		-> Bebé (1 niño, 0 niña)
  CigsPerDay -> Cigarettes Per Day 	-> Número de Cigarrillos por día
  Married    -> Married Mother 		-> Madre casada (1 si, 0 no)
  MomAge     -> Mother's Age 		-> Edad de la madre (equivale el 0 a tener 25 años)
  MomEdLevel -> Mother's Education 	-> Level Nivel de educación de la madre (de 0 a 3, siendo 0 nada)
  MomSmoke   -> Smoking Mother 	 	-> Madre fumadora (1 si, 0 no)
  MomWtGain  -> Mother's Preg Wght Gain -> Embarazo de la madre pérdida/aumento de peso
  Visit      -> Prenatal Visit 		-> Visita prenatal (de 0 a 3, siendo el 0 ninguna visita) 
  
  Variable dependiente u Objetivo:
  weight     -> Baby Weight		-> Peso del Bebe
 
```

## Carga de datos

Para cargar los datos se pueden usar tanto los datos de suminsitrados por la practica como los de la libreria sashelp.bweight, ya que son los mismos.

```
data bwg;
  set sashelp.bweight;
run;
```

# Analisis de la variable objetivo


Si hacemos un estudio de frecuencias de la variable objetivo (peso del bebe al nacer) vemos que hay no es una variable de clase sino una numeríca
```
proc freq data=bwg;
	tables weight;
run;
```

Con lo que analizamos la media, así como la gráfica u los test estadisticos para demostrar la normalidad.

´´´
proc means data=bwg;
	var weight;
run;
´´´

´´´
proc gchart data=bwg;
 vbar weight;
run;
´´´

/*  NOTE: There were 50000 observations read from the data set SASHELP.BWEIGHT.
 NOTE: The data set WORK.BWG has 50000 observations and 10 variables. 
 
 Analysis Variable : Weight Infant Birth Weight
	N	Media	Desv. est.	Mínimo	Máximo
50000	3370.76	566.3850556	240.00	6350.00
 */;

´´´
/*Analisis Normalidad de la variable objetivo*/;
proc univariate data=bwg normal plot;
 var weight;
 HISTOGRAM /NORMAL(COLOR=MAROON W=4) CFILL = BLUE CFRAME = LIGR;
 INSET MEAN STD /CFILL=BLANK FORMAT=5.2;
run;
´´´


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

/* Del analisis univariate de CigsPerDay podemos considerar la variable CigsPerDay más como una variable categorica, en la que haremos grupos 
 para las distintas cantidades de cigarrilos. 
  */;


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


proc corr data=bwg;
run;
/* No hay ninguna variable correlada */;



/* 
 * Variables dependientes:
 * MomAge     -> Mother's Age 			 -> Edad de la madre (equivale el 0 a tener 25 años)
 * MomEdLevel -> Mother's Education 	 -> Level Nivel de educación de la madre (de 0 a 3, siendo 0 nada)
 * 
 * 
*/;

/* Transformaciones y agrupaciones */

data bwgDummy (drop = CigsPerDay momAge i alerta alerta2);
 set bwg;

 /***************************/
 /*Variable objetivo*/
 /***************************/

 /*Weight */

 /***************************/
 /*Variable de clasificacion*/
 /***************************/
 /* Black */
 /* Boy */
 /* Married */
 /* MomSmoke */
 /* MomWtGain */
 /* Visit */


 realMomAge = momAge + 25;
 if cigsperDay = 0 then cigs = 0;
	else if cigsPerDay <10 then cigs = 1;
	else if cigsPerDay <20 then cigs = 2;
	else if cigsPerDay <30 then cigs = 3;
	else cigs=4 ;

	

 *Bucle que sustituye los missings por ceros;
 array vars(*) _numeric_;
 do i=1 to dim(vars);
   if vars[i]=. then vars[i]=0;
 end;

/* Para comprobar que no hay algun error basisco en la entrada de datos, es decir que no hay nadie que diga que no fuma y si que tiene cigarrillos */;
if cigsperDay = 0 and MomSmoke = 1 then alerta=1;
if cigsperDay> 0 and MomSmoke = 0 then alerta2=1;
run;

data bwgDummy2 (drop = momAge );
 set bwg;

 realMomAge = momAge + 25;
run;






proc glmselect data=bwgdummy2 plots=all seed=12345;
  partition fraction(validate=0.2);
  class black boy married momsmoke  momedlevel; 
  model weight = realMomAge Visit cigsperday
  / selection=stepwise(select=aic choose=validate) details=all stats=all;
run;




proc glmselect data=bwgDummy2 plots=all seed=12345;
  partition fraction(validate=0.2);
  class black boy married momsmoke cigs momedlevel; 
  model weight = realMomAge Visit  
  / selection=stepwise(select=aic choose=validate) details=all stats=all;
run;



