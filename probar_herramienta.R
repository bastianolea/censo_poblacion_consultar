# funciones necesarias
source("funciones.R")

# definir herramienta para el LLM
source("herramienta.R")

library(ellmer)

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
consultar_censo(nivel = "Comuna", territorio = "Curanilahue")

consultar_censo(nivel = "Comuna", sexo = "Mujeres", territorio = "Curanilahue")

consultar_censo(
  nivel = "Comuna",
  sexo = "Hombres",
  edad = 18,
  territorio = "Curanilahue"
)


# crear otra herramienta pasa sumar valores, porque los modelos de lenguaje no saben sumar
sumar <- function(valores) {
  sum(valores)
}

herramienta_suma <- tool(
  sumar,
  description = "Suma varios valores numéricos",
  # explicar uso de argumentos
  arguments = list(
    valores = type_array(type_integer(), description = "Cifras a sumar")
  )
)

# entregarle herramienta
chat$register_tool(herramienta_suma)

# probar
chat$chat("Cuál es la población masculina de Curanilahue mayor de 20 años?")


chat$chat("¿En qué comuna vive más gente: en Puente Alto o en Maipú?")
