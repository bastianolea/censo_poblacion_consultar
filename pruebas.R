# para probar la función

source("funciones.R")


censo <- cargar_censo()

# pruebas ----
consultar_censo()

consultar_censo(nivel = "Región", territorio = "Maule")

consultar_censo(nivel = "Comuna", territorio = "Curanilahue")

consultar_censo(nivel = "Comuna", sexo = "Mujeres", territorio = "Curanilahue")

consultar_censo(nivel = "Comuna", edad = "50-54", territorio = "Las Condes")

consultar_censo(nivel = "Provincia", territorio = "Cordillera")

# interpreta edad
consultar_censo(nivel = "Comuna", edad = 0, territorio = "Las Condes")

# interpreta edad
consultar_censo(nivel = "Comuna", edad = 53, territorio = "Ñuñoa")


# probar errores ----
# error
consultar_censo(territorio = "Curanilahue")

# error
consultar_censo(nivel = "Región", territorio = "Ojigins")

# error
consultar_censo(nivel = "Región")

# error
consultar_censo(
  nivel = "Comuna",
  sexo = "Chiquillas",
  territorio = "Curanilahue"
)

# error
consultar_censo(nivel = "Comuna", sexo = "Mujeres", territorio = "Biobío")

# error
consultar_censo(nivel = "com", edad = "50 a 54", territorio = "Las Condes")

# error
consultar_censo(nivel = "com")
