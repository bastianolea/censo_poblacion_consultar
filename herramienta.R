# usar la función por medio de una IA

# cargar la función
source("funciones.R")

censo <- cargar_censo()

library(ellmer)

# crear herramienta
herramienta_censo <- tool(
  consultar_censo,
  description = "Permite obtener la población según datos del Censo 2024 a nivel de país, región, provincia o comuna, y según grupos de edad y/o sexo",
  # explicar uso de argumentos
  arguments = list(
    nivel = type_enum(
      required = TRUE,
      values = c("País", "Región", "Provincia", "Comuna"),
      description = "Nivel de la información sobre población, desde País (el más general) a Comuna (el más específico)"
    ),
    edad = type_enum(
      required = FALSE,
      values = unique(censo$edad),
      description = "Grupos de edades para filtrar la población. Si se busca la población total, elegir 'Total'. Se puede consultar una edad exacta (por ejemplo, 18 o 33) y se interpretará como el grupo de edad que contiene dicho número."
    ),
    sexo = type_enum(
      required = FALSE,
      values = c("Hombres", "Mujeres", "Total"),
      description = "Sexo para filtrar la población. Si se busca la población total, elegir 'Total'."
    ),
    territorio = type_string(
      required = FALSE,
      description = "Unidad territorial a filtrar si se elige un nivel distinto a 'País'. Corresponde al nombre de la región, provincia o comuna que se desea consultar."
    )
  )
)
