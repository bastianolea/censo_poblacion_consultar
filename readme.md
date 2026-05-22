# Consultar Censo


Función para consultar la población de comunas, regiones, provincias o
país según resultados del Censo 2024.

Diseñada para registrarla como herramienta para LLMs y así hacer que la
IA pueda consultar datos de población censal.

Más información [en esta
publicación.](https://bastianolea.rbind.io/blog/herramientas_llm/)

## Archivos

- `funciones.R` contiene la función `consultar_censo()`, así como otras
  funciones necesarias para su funcionamiento.
- `probar.R` muestra ejemplos de uso de `consultar_censo()` y prueba los
  errores de la misma.
- `herramienta.R` define el uso de la función `consultar_censo()` para
  que los modelos de lenguaje puedan usarla.
- `probar_herramienta.R` muestra ejemplos del uso de la función por
  medio de un chat de IA.

## Datos

- `datos/censo_2024_largo.csv` resultados del Censo 2024 en formato
  largo, por edad y sexo, calculados directamente de la base de datos
  oficial (`personas_censo2024.parquet`) en el script
  `datos/procesar_censo.R` (opcional)

## Ejemplos de uso

Población a nivel nacional:

``` r
# cargar la función
source("funciones.R")

censo <- cargar_censo()
```

    ℹ Using "','" as decimal and "'.'" as grouping mark. Use `read_delim()` for more control.

``` r
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
                edad = "50-54",
                territorio = "Las Condes")
```

    → datos a nivel comuna, Las Condes

    → grupo de edad: 50-54

    ℹ población censada: 18.507

    [1] 18507

Población por comuna, sexo y edad

``` r
consultar_censo(nivel = "Comuna", 
                sexo = "Hombres",
                edad = "30", # interpreta el número como rango de edad
                territorio = "La Florida")
```

    Loading required package: purrr

    Loading required package: stringr

    ! edad "30" interpretada como "30-34"

    → datos a nivel comuna, La Florida

    → grupo de edad: 30-34

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

    ! edad "0" interpretada como "0-4"

    → datos a nivel comuna, Las Condes

    → grupo de edad: 0-4

    ℹ población censada: 12.824

    [1] 12824

``` r
# interpreta edad
consultar_censo(nivel = "Comuna", 
                edad = 53,
                territorio = "Ñuñoa")
```

    ! edad "53" interpretada como "50-54"

    → datos a nivel comuna, Ñuñoa

    → grupo de edad: 50-54

    ℹ población censada: 13.517

    [1] 13517

Más información [en esta
publicación.](https://bastianolea.rbind.io/blog/herramientas_llm/)

## Datos

- Población censada por sexo, según grupos de edad quinquenal, a nivel
  región, provincia y comuna.
