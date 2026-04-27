# a qué nivel (nacional, regional, provincial, comunal)
# qué sexos (hombre, mujer, total)
# qué edades ({grupos de edad}, total)

library(dplyr)
library(readr)
library(cli)

censo <- read_rds("datos/censo.rds")

censo |> distinct(edad)



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
    edad_buscar <- str_detect(edades, as.character(edad))
    
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
      edad_posicion <- str_detect(edades, as.character(edad_redondeada)) |> which()
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
      cli_warn('la edad "{edad}" fue interpretada como "{edad_encontrada}"') 
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
#' @param sexo Sexo a filtrar: "Hombre", "Mujer" o "Total".
#'
#' @return Un sólo valor numérico con la población solicitada
#' @export
consultar_censo <- function(
    nivel = "País",
    edad = "Total",
    sexo = "Total",
    territorio = NA) {
  
  # revisar niveles 
  if (!nivel %in% c("País", "Región", "Provincia", "Comuna")) {
    cli_abort('valor incorrecto en nivel, los valores válidos son: "País", "Región", "Provincia" o "Comuna".')
  }
    
  # revisar si la edad es válida
  if (edad != "Total") {
    
    # vector con edades posibles
    edades <- censo |> distinct(edad) |> na.omit() |> pull()
    
    # edad <- "50 a 54"
    edad <- interpretar_edades(edad, edades)
  }
  
  # revisar si el sexo es válido
  if (sexo != "Total") {
    sexos <- censo |> distinct(sexo) |> na.omit() |> pull()
    
    # revisar si es válido
    if (!sexo %in% sexos) {
      sexos <- paste0('"', sexos, '"')
      sexos_redactado <- glue::glue_collapse(sexos, sep = ", ", last = " y ")
      cli_abort("sexo incorrecto, los valores posibles son: {sexos_redactado}") 
    }
  }
  
  # browser()
  # filtrar datos según argumentos; si no se define se deja total
  filtrado <- censo |> 
    filter(.data$nivel == .env$nivel,
           .data$edad == .env$edad,
           .data$sexo == .env$sexo)
  
  # si sólo es a nivel país
  if (nivel == "País") {
    cli_alert("datos a nivel {tolower(nivel)}")
  }
  
  # si se determina un nivel pero no se especifica el territorio, se entrega la tabla pero con warning
  if (nivel != "País" & is.na(territorio)) {
    
    cli_abort("se determinó un nivel pero no se especificó el territorio")
  }
  
  # si se determina un nivel y un territorio, filtrar la columna correspondiente
  if (nivel != "País" & !is.na(territorio)) {
    
    cli_alert("datos a nivel {tolower(nivel)}, {territorio}")
    
    columna <- janitor::make_clean_names(nivel)
    
    filtrado <- filtrado |> 
      filter(.data[[columna]] == territorio)
  }
  
  # avisar si se define una edad 
  if (edad != "Total") {
    cli_alert("grupo de edad: {edad}")
  }
  
  # avisar si se define un sexo
  if (sexo != "Total") {
    cli_alert("sexo: {sexo}")
  }
  
  # error si se determina un territorio pero no un nivel
  if (nivel == "País" & !is.na(territorio)) {
    
    cli_abort("se especificó un territorio pero no su nivel") 
  }
  
  # si se determina una edad pero no se encuentra, avisar 
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


# pruebas ----
consultar_censo()

consultar_censo(nivel = "Región", 
                territorio = "Maule")

consultar_censo(nivel = "Comuna", 
                territorio = "Curanilahue")

consultar_censo(nivel = "Comuna", 
                sexo = "Mujeres",
                territorio = "Curanilahue")

consultar_censo(nivel = "Comuna", 
                edad = "50 a 54",
                territorio = "Las Condes")

consultar_censo(nivel = "Provincia", 
                territorio = "Cordillera")

# interpreta edad
consultar_censo(nivel = "Comuna", 
                edad = 0,
                territorio = "Las Condes")

# error
consultar_censo(territorio = "Curanilahue")

# error
consultar_censo(nivel = "Región", 
                territorio = "Ojigins")

# error
consultar_censo(nivel = "Región")

# error
consultar_censo(nivel = "Comuna", 
                sexo = "Chiquillas",
                territorio = "Curanilahue")

# error
consultar_censo(nivel = "Comuna", 
                sexo = "Mujeres",
                territorio = "Biobío")

# error 
consultar_censo(nivel = "com", 
                edad = "50 a 54",
                territorio = "Las Condes")
