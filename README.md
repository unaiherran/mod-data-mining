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

## Analisis de la variable objetivo


Si hacemos un estudio de frecuencias de la variable objetivo (peso del bebe al nacer) vemos que no es una variable de clase sino una numérica y continua.

```
proc freq data=bwg;
	tables weight;
run;
```

Con lo que analizamos la media, así como la gráfica y los test estadisticos para demostrar la normalidad.

```
proc means data=bwg;
	var weight;
run;
```

![proc_means](https://raw.githubusercontent.com/unaiherran/mod-data-mining/master/img/01_proc_means.png)

Vemos que tenemos 50000 observaciones con 10 variables.

```
/*  NOTE: There were 50000 observations read from the data set SASHELP.BWEIGHT.
 NOTE: The data set WORK.BWG has 50000 observations and 10 variables. 
 
 Analysis Variable : Weight Infant Birth Weight
	N	Media	Desv. est.	Mínimo	Máximo
50000	3370.76	566.3850556	240.00	6350.00
 */;
```

```
proc gchart data=bwg;
 vbar weight;
run;

/*Analisis Normalidad de la variable objetivo*/;
proc univariate data=bwg normal plot;
 var weight;
 HISTOGRAM /NORMAL(COLOR=MAROON W=4) CFILL = BLUE CFRAME = LIGR;
 INSET MEAN STD /CFILL=BLANK FORMAT=5.2;
run;
```
![univariate](https://raw.githubusercontent.com/unaiherran/mod-data-mining/master/img/02_univariate.png)


## Data Cooking:

### Duplicados
Empezamos con 50000 observaciones y 10 variables. Podriamos eliminar duplicados con:

```
proc sort data=bwg out=B dupout=C nodupkey; By _all_ ; run;
```
Pero considero que no son datos duplicados, sino dos observaciones distintas de eventos distintos con exactamente los mismos valores en todas las variables.

### Logica previa en los datos

La variable MomSmoke es 0 si la madre no fuma y 1 si lo hace. Además tenemos la variable numero de cigarrilos al dia. Antes de nada hacemos una comprobacion básica de si hay error en los datos y se ha indicado que una mujer fuma pero luego toma 0 cigarrillos al día o al contrario, la observacion dice que no fuma pero luego consume mas de 0 cigarrilos al día:

```data bwgDummy (keep = alerta);
 set bwg;
	if cigsperDay = 0 and MomSmoke = 1 then alerta=1;
	else
	if cigsperDay> 0 and MomSmoke = 0 then alerta=2;
	else alerta=0;
run;

proc freq data=bwgDummy;
run;
```

La simple lógica nos dice que estas variables tienen que estar relacionadas, pero aun así realizamos un estudio de correlación entre ambas:
```
proc corr data=bwg;
 var MomSmoke cigsperday;
run;
```

![Corr_Cigs_Smoke](https://raw.githubusercontent.com/unaiherran/mod-data-mining/master/img/03_corr.png)

Podemos eliminar una de las dos del conjunto de datos a estudiar. Ya que `CigsPerDay`da más datos que `MomSmoke`, eliminamos MomSmoke.

Además, la variable MomAge está referida a 25 años, para que el estudio sea más sencillo se cambia la variable a su valor real

```
data bwgC (drop = momAge momSmoke);
 set bwg;
 realMomAge = momAge + 25;
run;
```


### Estudio de variables independientes tablas de frecuencia, TTest:

Con:
```
ods graphics on;

proc ttest data=bwgc;
   var _numeric_;
run;

ods graphics off;

```
realizamos un TTest de todas las variables numericas ( [PDF con resultados de TTest](https://raw.githubusercontent.com/unaiherran/mod-data-mining/master/img/04_TTest.pdf) ) 

Paso a estudiar cada variable:


#### Black Mother
```
proc freq data=bwgc;
	table black;
run;
```


|  Black    | Frecuencia  | Porcentaje | Frecuencia acumulada |	Porcentaje acumulado |
|-----------|-------------|------------|----------------------|----------------------|
|0	    |41858        |	83.72  |	41858         | 	83.72        |
|1	    |8142	  |16.28       |	50000         |	    100.00           |

No faltan valores (no hay missings) y se puede usar para el modelo. Es una variable categorica, y no puede ser ajustada a una normal.

#### Mother is married

```
proc freq data=bwgc;
	table married;
run;
```

|Married|	Frecuencia|Porcentaje|Frecuencia acumulada|Porcentaje acumulado|
|---|-------------|------------|----------------------|----------------------|
|0|	14369|	28.74|	14369|	28.74|
|1|	35631|	71.26|	50000|	100.00|

Este caso es similar al anterior. Es una variable dicotomica.


#### Baby Boy

```
proc freq data=bwgc;
	table boy;
run;
```

|Boy|	Frecuencia|Porcentaje|Frecuencia acumulada|	Porcentaje acumulado|
|---|-------------|------------|----------------------|----------------------|
|0  |    24208    |	48.42  |	24208         |	48.42                |
|1  |    25792    |	51.58  |	50000         |	100.00               |

No hay ningun missing, es una variable dicotomica y al 50% aprox.


#### Cigarretes per day

```
proc freq data=bwgc;
	table CigsPerDay;
	run;
```

|CigsPerDay|	Frecuencia|	Porcentaje|	Frecuencia acumulada|	Porcentaje acumulado|
|---|-------------|------------|----------------------|----------------------|
|0|	43467|	86.93|	43467|	86.93|
|1|	206|	0.41|	43673|	87.35|
|2|	309|	0.62|	43982|	87.96|
|3|	387|	0.77|	44369|	88.74|
|...|....   |...    |...       |...   |
|50|	4|	0.01|	49998|	100.00|
|60|	2|	0.00|	50000|	100.00|

De nuevo no faltan valores, pero vemos que el casi el 87% de las observaciones son de no fumadoras, y sólo el 13% restante es de fumadoras. Lo podemos usar para el modelo, pero al ser tan pocos no sé seguro cuanto puede afectar al mismo. Por sentido comun el hecho de que fume la madre debería afectar al peso del bebe, pero hay que estudiarlo.

#### Mother Weight Gain

```
proc freq data=bwgc;
	table MomAge;
	run;
```

|MomWtGain|	Frecuencia|	Porcentaje|	Frecuencia acumulada|	Porcentaje acumulado|
|---|-------------|------------|----------------------|----------------------|
|-30|	598|	1.20|	598|	1.20|
|-29|	56|	0.11|	654|	1.31|
|...|....   |...    |...       |...   |
|64|	1|	0.00|	49977|	99.95|
|66|	1|	0.00|	49978|	99.96|
|68|	22|	0.04|	50000|	100.00|

No faltan ningun valor, lo podemos usar para el modelo. Pero presenta una distribución extraña, habiendo muchos más valores concentrados en multiplos de 5. Probablemente sea un error a la toma de los datos en el sentido de que se han redondeado. Por ello voy a generar otro conjunto de datos con los valores en grupos de 5 libras y realizaré el estudio con ambos modelos.

#### Mom Prenatal Visit
```
proc freq data=bwg;
	table Visit;
run;
```

|Visit|	Frecuencia|	Porcentaje|	Frecuencia acumulada|	Porcentaje acumulado|
|---|-------------|------------|----------------------|----------------------|
|0|	403|	0.81|	403|	0.81|
|1|	6339|	12.68|	6742|	13.48|
|2|	1114|	2.23|	7856|	15.71|
|3|	42144|	84.29|	50000|	100.00|

No faltan valores y se puede usar para el modelo. Es una variable con 4 categorias distintas.


#### Mother's Education Level

```
proc freq data=bwg;
	table MomEdLevel;
run;
```


|MomEdLevel |Frecuencia	|Porcentaje |Frecuencia acumulada|Porcentaje acumulado|
|-----------|-----------|-----------|--------------------|--------------------|
|0          |	17449   |      34.90|	     	    17449|		 34.90|
|1	    |	12129   |      24.26|		    29578|		 59.16|
|2	    |	12449   |      24.90|		    42027|		 84.05|
|3	    |	7973    |      15.95|               50000|		100.00|


No faltan valores y se puede usar para el modelo. Es una variable con 4 categorias distintas.




#### Mothers age

```
proc freq data=bwg;
	table MomAge;
	run;
```

|MomAge|Frecuencia|	Porcentaje|	Frecuencia acumulada|	Porcentaje acumulado|
|---|-------------|------------|----------------------|----------------------|
|16|	1824|	3.65|	1824	|3.65 |
|17|	2420|	4.84|	4244	|8.49|
|18|	2588|	5.18|	6832	|13.66|
|19|	2521|	5.04|	9353	|18.71|
|20|	2590|	5.18|	11943	|23.89|
|...|....   |...    |...       |...   |
|42|	44|	0.09|	49974|	99.95|
|43|	26|	0.05|	50000|	100.00|

No faltan ningun valor, lo podemos usar para el modelo. La distribución no es normal en su cola de ascenso, se aproxima bastante en su cola de descenso. Hay que tener en cuenta que la edad fertil de la mujer es muy dependiente de su biologia, y aunque en edades tempranas es más probable que se quede embarazada (si no pone medios en contra), mientras que según pasa el tiempo influyen otros valores.





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



