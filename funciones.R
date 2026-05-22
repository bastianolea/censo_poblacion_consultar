library(dplyr) |> suppressPackageStartupMessages()
library(readr)
library(cli)

# datos requeridos
cargar_censo <- function() {
  read_csv2("datos/censo_2024_tidy.csv", show_col_types = FALSE)
}


redactar_edades <- function(edades) {
  glue::glue_collapse(paste0('"', edades, '"'), sep = ", ", last = " y ")
}


#' genera una tabla con todas las categorías de edad y las edades que les pertenecen
tabla_edades <- function(edades) {
  require(purrr)
  require(stringr)

  map(
    edades,
    ~ {
      # .x <- edades[4]
      # .x <- edades[18]
      inicial <- str_extract(.x, "^\\d+")
      final <- str_extract(.x, "\\d+$")

      # si es el 85
      if (is.na(final)) {
        final <- 100
      }

      # si es el total
      if (is.na(inicial)) {
        return(NULL)
      }

      numeros <- inicial:final

      tibble(valor = .x, edad_intermedia = numeros)
    }
  ) |>
    list_rbind()
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
    # si la categoría de edad corresponde con una de las posibles, entregarla
    return(edad)

    # pero si la edad elegida no es exactamente una de las válidas
  } else if (!edad %in% edades) {
    # edad <- 2
    # edad <- 50
    # edad <- 0

    # buscar en tabla de edades posibles
    edad_buscar <- tabla_edades(edades) |>
      filter(edad_intermedia == edad)

    # si se encuentra entre las edades, entregar
    if (nrow(edad_buscar) > 0) {
      edad_encontrada <- edad_buscar |>
        slice(1) |>
        pull(valor)

      cli_alert_warning(
        'edad "{edad}" interpretada como "{edad_encontrada}"'
      )

      return(edad_encontrada)

      # si no se encontró
    } else {
      cli_abort(
        "edad incorrecta, las edades posibles son: {redactar_edades(edades)}"
      )
    }
  }
}

# interpretar_edades("46", edades)

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
  territorio = NA
) {
  # censo <- cargar_censo()
  # revisar si están los datos
  if (!exists("censo")) {
    cli_abort("no se encontraron datos del censo!")
  }

  # revisar si nivel es válido
  if (!nivel %in% c("País", "Región", "Provincia", "Comuna")) {
    cli_abort(
      'valor incorrecto en nivel, los valores válidos son: "País", "Región", "Provincia" o "Comuna".'
    )
  }

  # revisar si la edad es válida
  if (edad != "Total") {
    unique(censo$edad)
    # vector con edades posibles
    edades <- censo$edad |> unique()

    edad <- interpretar_edades(edad, edades)
  }

  # revisar si el sexo es válido
  if (!sexo %in% c("Hombres", "Mujeres", "Total")) {
    cli_abort(
      'sexo incorrecto, los valores posibles son: "Hombres", "Mujeres" o "Total".'
    )
  }

  # filtrar datos según argumentos; si no se define se deja total
  filtrado <- censo |>
    filter(
      .data$nivel == .env$nivel,
      .data$edad == .env$edad,
      .data$sexo == .env$sexo
    )

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
    cli_abort(
      "edad incorrecta, las edades posibles son: {redactar_edades(edades)}"
    )
  }

  # error si no hay resultados
  if (nrow(filtrado) == 0) {
    cli_abort("no se encontraron resultados; por favor revise los argumentos")
  }

  # extraer valor
  poblacion <- filtrado |> pull(poblacion)

  # mensaje con resultado
  cli_alert_info(
    "población censada: {scales::label_comma(big.mark = '.', decimal.mark = ',')(poblacion)}"
  )

  return(poblacion)
}
