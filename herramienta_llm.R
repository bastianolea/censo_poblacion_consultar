# usar la función por medio de una IA

# cargar la función
source("consultar_censo.R")

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
      values = c("Total", "0 a 4", "5 a 9", "10 a 14", "15 a 19", "20 a 24", 
                 "25 a 29", "30 a 34", "35 a 39", "40 a 44", "45 a 49", "50 a 54", 
                 "55 a 59", "60 a 64", "65 a 69", "70 a 74", "75 a 79", "80 a 84", 
                 "85 o más"),
      description = "Grupos de edades para filtrar la población. Si se busca la población total, elegir 'Total'."
    ),
    sexo = type_enum(
      required = FALSE,
      values = c("Hombres", "Mujeres", "Total"),
      description = "Sexo para filtrar la población. Si se busca la población total, elegir 'Total'."
    ),
    territorio = type_string(
      required = FALSE,
      description = "Unidad territorial a filtrar si se elige un nivel distinto a 'País'. Corresponde al nombre de la región, provincia o comuna que se desea consultar"
    )
  )
)


# probar chat ----

# iniciar modelo
chat <- chat_anthropic(model = "claude-haiku-4-5")
# chat <- chat_ollama(model = "llama3.2")

# ver si responde bien sin herramienta
chat$chat("Cuál es la población de Curanilahue?")

# probar herramienta en chat ----
# entregarle herramienta
chat$register_tool(herramienta_censo)

# probar ahora que tiene la herramienta
chat$chat("Cuál es la población de Curanilahue?")

# probar otros casos más complejos
chat$chat("Cuál es la población femenina de Curanilahue?")

chat$chat("Cuál es la población masculina de Curanilahue mayor de 20 años?")

chat$chat("Cuál es la población masculina de Curanilahue mayor de 60 años?")
# tiene problemas con las sumas

# contrastar con datos
consultar_censo(nivel = "Comuna", 
                territorio = "Curanilahue")

consultar_censo(nivel = "Comuna", 
                sexo = "Mujeres",
                territorio = "Curanilahue")

consultar_censo(nivel = "Comuna", 
                sexo = "Hombres",
                edad = 18,
                territorio = "Curanilahue")


# crear otra herramienta pasa sumar valores, porque los modelos de lenguaje no saben sumar
sumar <- function(valores) {
  sum(valores)
}

herramienta_suma <- tool(
  sumar,
  description = "Suma varios valores numéricos",
  # explicar uso de argumentos
  arguments = list(
    valores = type_array(type_integer(),
                         description = "Cifras a sumar")
  )
)

# entregarle herramienta
chat$register_tool(herramienta_suma)

# probar
chat$chat("Cuál es la población masculina de Curanilahue mayor de 20 años?")





chat$chat("¿En qué comuna vive más gente: en Puente Alto o en Maipú?")