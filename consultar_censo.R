# función que permite consultar datos de población del Censo 
# en distintos niveles (país, región, provincia, comuna) y 
# opcionalmente desagregadas por sexo y grupos de edad.

library(dplyr)
library(readr)
library(cli)

# datos requeridos
censo <- read_rds("censo.rds")


# funciones ----

redactar_edades <- function(edades) {
  glue::glue_collapse(paste0('"', edades, '"'), sep = ", ", last = " y ")
}


#' Interpretar cifra como grupos de edad del Censo
#' 
#' @description
#' Se le entrega un texto correspondiente a una edad o grupo de edad, y éste se interpreta para entregar la categoría de edad válida de la base de resultados del Censo
#'
#' @param edad La edad que entrega el/la usuario/a, puede ser numérico o caracter.
#' @param edades Vector de categorías de edad posibles, proveniente del Censo.
#'
#' @return Caracter que corresponde a uno de los grupos de edad válidos del Censo.
#' @export
interpretar_edades <- function(edad, edades) {
  
  if (edad %in% edades) {
    return(edad)
    
    # pero si la edad elegida no es exactamente una de las válidas
  } else if (!edad %in% edades) {
    # edad <- 534
    # edad <- 2
    
    # buscar número dentro de las edades válidas
    edad_buscar <- stringr::str_detect(edades, as.character(edad))
    
    # si el número aparece entre las edades, listo
    if (any(edad_buscar) & length(edad_buscar) == 1) {
      
      # elegir edad que coincide entre edades válidas
      edad_encontrada <- edades[which(edad_buscar)]
      
      if (is.na(edad_redondeada)) {
        cli_abort("error al buscar edad") 
      }
      
    } else {
      # pero si no aparece el número entre las edades válidas, redondear
      
      # # redondear edad hacia la decena
      # edad_redondeada <- round(as.numeric(edad), -1)
      # redondear edad 5 hacia abajo
      base <- 5
      edad_redondeada <- base*floor(as.numeric(edad)/base)
      
      # si no se puede redondear, error
      if (is.na(edad_redondeada)) {
        cli_abort("edad incorrecta, las edades posibles son: {redactar_edades(edades)}") 
      }
      
      # buscar número dentro de las edades válidas
      edad_posicion <- stringr::str_detect(edades, as.character(edad_redondeada)) |> which()
      # entrega la posición entre las edades válidas
      
      # si no coincide con ninguna
      if (length(edad_posicion) == 0) {
        cli_abort("edad incorrecta, las edades posibles son: {redactar_edades(edades)}") 
      }
      
      # filtrar edades válidas con la posición
      edad_encontrada <- edades[edad_posicion[1]]
    }
    
    # avisar resultado
    if (!is.na(edad_encontrada)) {
      cli_alert_warning('la edad "{edad}" fue interpretada como "{edad_encontrada}"') 
    } else {
      cli_abort("error al interpretar edad, las edades posibles son: {redactar_edades(edades)}") 
    }
    
    return(edad_encontrada)
  }
}


#' Consulta datos del censo
#' 
#' @description
#' Permite consultar datos de población del Censo en distintos niveles y desagregaciones.
#' 
#'
#' @param nivel nivel geográfico del dato a consultar: "País", "Región", "Provincia", "Comuna".
#' @param edad grupo etario a filtrar. Si no una categoría válida, se intenta interpretar el número entregado a una de las categorías posibles. "Total" para todos los grupos.
#' @param sexo Sexo a filtrar: "Hombres", "Mujeres" o "Total".
#' @param territorio Unidad territorial que debe definirse si se elige un nivel distinto a "País". Corresponde al nombre de la región, provincia o comuna que se desea consultar
#'
#' @return Un sólo valor numérico con la población solicitada
#' @export
consultar_censo <- function(
    nivel = "País",
    edad = "Total",
    sexo = "Total",
    territorio = NA) {
  
  # revisar si están los datos
  if (!exists("censo")) {
    cli_abort("no se encontraron datos del censo!")
  }
  
  # revisar si nivel es válido 
  if (!nivel %in% c("País", "Región", "Provincia", "Comuna")) {
    cli_abort('valor incorrecto en nivel, los valores válidos son: "País", "Región", "Provincia" o "Comuna".')
  }
  
  # revisar si la edad es válida
  if (edad != "Total") {
    
    # vector con edades posibles
    edades <- c("Total", "0 a 4", "5 a 9", "10 a 14", "15 a 19", "20 a 24", 
                "25 a 29", "30 a 34", "35 a 39", "40 a 44", "45 a 49", "50 a 54", 
                "55 a 59", "60 a 64", "65 a 69", "70 a 74", "75 a 79", "80 a 84", 
                "85 o más") # edades <- censo |> distinct(edad) |> na.omit() |> pull()
    
    edad <- interpretar_edades(edad, edades)
  }
  
  # revisar si el sexo es válido
  if (!sexo %in% c("Hombres", "Mujeres", "Total")) {
    cli_abort('sexo incorrecto, los valores posibles son: "Hombres", "Mujeres" o "Total".') 
  }
  
  # filtrar datos según argumentos; si no se define se deja total
  filtrado <- censo |> 
    filter(
      .data$nivel == .env$nivel,
      .data$edad == .env$edad,
      .data$sexo == .env$sexo)
  
  # avisos
  # avisar el nivel
  if (nivel == "País") {
    cli_alert("datos a nivel {tolower(nivel)}")
  } else {
    cli_alert("datos a nivel {tolower(nivel)}, {territorio}")
  }
  
  # avisar si se define una edad 
  if (edad != "Total") {
    cli_alert("grupo de edad: {edad}")
  }
  
  # avisar si se define un sexo
  if (sexo != "Total") {
    cli_alert("sexo: {sexo}")
  }
  
  # error si se determina un nivel pero no se especifica el territorio
  if (nivel != "País" & is.na(territorio)) {
    
    cli_abort("se determinó un nivel pero no se especificó el territorio")
  }
  
  # filtrar territorio
  # si se determina un nivel y un territorio, filtrar la columna correspondiente
  if (nivel != "País" & !is.na(territorio)) {
    
    columna <- janitor::make_clean_names(nivel)
    
    filtrado <- filtrado |> 
      filter(.data[[columna]] == territorio)
  }
  
  # errores
  # error si se determina un territorio pero no un nivel
  if (nivel == "País" & !is.na(territorio)) {
    
    cli_abort("se especificó un territorio pero no su nivel") 
  }
  
  # error si se determina una edad pero no se encuentra
  if (edad != "Total" & nrow(filtrado) == 0) {
    cli_abort("edad incorrecta, las edades posibles son: {redactar_edades(edades)}") 
  }
  
  # error si no hay resultados
  if (nrow(filtrado) == 0) {
    
    cli_abort("no se encontraron resultados; por favor revise los argumentos") 
  }
  
  # extraer valor
  poblacion <- filtrado |> pull(poblacion)
  
  # mensaje con resultado
  cli_alert_info("población censada: {scales::label_comma(big.mark = '.', decimal.mark = ',')(poblacion)}")
  
  return(poblacion)
}


