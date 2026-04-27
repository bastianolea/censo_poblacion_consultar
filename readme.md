# Consultar Censo


Función para consultar la población de comunas, regiones, provincias o
país según resultados del Censo 2024.

Diseñada para registrarla como herramienta para LLMs y así hacer que la
IA pueda consultar datos de población censal.

Más información [en esta
publicación.](https://bastianolea.rbind.io/blog/herramientas_llm/)

## Instalación

Clona este repositorio, o descarga el script `consultar_censo.R` y el
archivo `censo.rds` en tu proyecto de R.

## Ejemplos de uso

Población a nivel nacional:

``` r
# cargar la función
source("consultar_censo.R")

consultar_censo()
```

    → datos a nivel país

    ℹ población censada: 18.480.432

    [1] 18480432

Población de una región:

``` r
consultar_censo(nivel = "Región", 
                territorio = "Maule")
```

    → datos a nivel región, Maule

    ℹ población censada: 1.123.008

    [1] 1123008

Población de una comuna:

``` r
consultar_censo(nivel = "Comuna", 
                territorio = "Curanilahue")
```

    → datos a nivel comuna, Curanilahue

    ℹ población censada: 31.119

    [1] 31119

Población por comuna y sexo:

``` r
consultar_censo(nivel = "Comuna", 
                sexo = "Mujeres",
                territorio = "Curanilahue")
```

    → datos a nivel comuna, Curanilahue

    → sexo: Mujeres

    ℹ población censada: 15.992

    [1] 15992

Población por comuna y edad

``` r
consultar_censo(nivel = "Comuna", 
                edad = "50 a 54",
                territorio = "Las Condes")
```

    → datos a nivel comuna, Las Condes

    → grupo de edad: 50 a 54

    ℹ población censada: 18.507

    [1] 18507

Población por comuna, sexo y edad

``` r
consultar_censo(nivel = "Comuna", 
                sexo = "Hombres",
                edad = "30", # interpreta el número como rango de edad
                territorio = "La Florida")
```

    ! la edad "30" fue interpretada como "30 a 34"

    → datos a nivel comuna, La Florida

    → grupo de edad: 30 a 34

    → sexo: Hombres

    ℹ población censada: 16.009

    [1] 16009

Población por provincia:

``` r
consultar_censo(nivel = "Provincia", 
                territorio = "Cordillera")
```

    → datos a nivel provincia, Cordillera

    ℹ población censada: 614.587

    [1] 614587

Ejemplos de la interpretación de edades en grupos de edad:

``` r
# interpreta edad
consultar_censo(nivel = "Comuna", 
                edad = 0,
                territorio = "Las Condes")
```

    ! la edad "0" fue interpretada como "0 a 4"

    → datos a nivel comuna, Las Condes

    → grupo de edad: 0 a 4

    ℹ población censada: 12.824

    [1] 12824

``` r
# interpreta edad
consultar_censo(nivel = "Comuna", 
                edad = 53,
                territorio = "Ñuñoa")
```

    ! la edad "53" fue interpretada como "50 a 54"

    → datos a nivel comuna, Ñuñoa

    → grupo de edad: 50 a 54

    ℹ población censada: 13.517

    [1] 13517

Más información [en esta
publicación.](https://bastianolea.rbind.io/blog/herramientas_llm/)

## Datos

- Población censada por sexo, según grupos de edad quinquenal, a nivel
  región, provincia y comuna.
