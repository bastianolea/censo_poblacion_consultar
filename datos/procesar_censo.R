# intentar obtener datos desde base de datos de población del censo
# para tener datos de todas las edades
# pero vienen con anonimización así que no es mejor que resultados tabulados

library(dplyr)
library(arrow)
library(tidyr)

# censo_anterior <- readr::read_rds("censo.rds")

censo <- open_dataset("~/Documents/Datos/Censo/2024/personas_censo2024.parquet")

censo |>
  head() |>
  glimpse()

censo_comuna <- censo |>
  group_by(comuna, provincia, region, sexo, edad_quinquenal) |>
  summarize(poblacion = n()) |>
  ungroup() |>
  collect() |>
  mutate(nivel = "Comuna")

censo_provincia <- censo |>
  group_by(provincia, region, sexo, edad_quinquenal) |>
  summarize(poblacion = n()) |>
  ungroup() |>
  collect() |>
  mutate(nivel = "Provincia")

censo_region <- censo |>
  group_by(region, sexo, edad_quinquenal) |>
  summarize(poblacion = n()) |>
  ungroup() |>
  collect() |>
  mutate(nivel = "Región")

censo_pais <- censo |>
  group_by(sexo, edad_quinquenal) |>
  summarize(poblacion = n()) |>
  ungroup() |>
  collect() |>
  mutate(nivel = "País")

censo_pais |>
  group_by(edad_quinquenal) |>
  summarize(poblacion = sum(poblacion))

censo_unido <- bind_rows(
  censo_comuna,
  censo_provincia,
  censo_region,
  censo_pais,
)

censo_sexo_total <- censo_unido |>
  group_by(nivel, comuna, provincia, region, edad_quinquenal) |>
  summarize(poblacion = sum(poblacion)) |>
  ungroup() |>
  mutate(sexo = 99)

censo_edad_total <- censo_unido |>
  group_by(nivel, comuna, provincia, region, sexo) |>
  summarize(poblacion = sum(poblacion)) |>
  ungroup() |>
  mutate(edad_quinquenal = 99)

censo_sexo_edad_total <- censo_unido |>
  group_by(nivel, comuna, provincia, region) |>
  summarize(poblacion = sum(poblacion)) |>
  ungroup() |>
  mutate(edad_quinquenal = 99, sexo = 99)

censo_unido_totales <- bind_rows(
  censo_unido,
  censo_sexo_total,
  censo_edad_total,
  censo_sexo_edad_total
)

censo_unido_totales |> count(edad_quinquenal) |> arrange(edad_quinquenal)

censo_largo <- censo_unido_totales |>
  # poner nivel primero
  relocate(nivel, .before = comuna) |>
  # renombrar columnas
  rename_with(
    .cols = c(comuna, provincia, region),
    .fn = ~ paste("codigo", .x, sep = "_")
  ) |>
  # recodificar sexo
  mutate(
    sexo = recode_values(
      sexo,
      1 ~ "Hombres",
      2 ~ "Mujeres",
      99 ~ "Total"
    )
  ) |>
  # recodificar edad quinquenal
  mutate(
    edad = case_when(
      edad_quinquenal == 99 ~ "Total",
      edad_quinquenal < 85 ~ paste(
        edad_quinquenal,
        edad_quinquenal + 4,
        sep = "-"
      ),
      edad_quinquenal == 85 ~ paste(edad_quinquenal, "o más")
    )
  ) |>
  mutate(edad = forcats::fct_reorder(edad, edad_quinquenal)) |>
  select(-edad_quinquenal) |>
  relocate(poblacion, .after = last_col())

# pruebas
censo_largo |>
  filter(nivel == "Comuna") |>
  filter(codigo_comuna == 4303) |>
  filter(edad == "5-9")

censo_largo |>
  filter(nivel == "Provincia") |>
  filter(codigo_provincia == 43) |>
  filter(edad == "5-9")

censo_largo |>
  filter(nivel == "Provincia") |>
  filter(codigo_provincia == 43) |>
  filter(sexo == "Total")

censo_largo |>
  filter(nivel == "Región") |>
  filter(codigo_region == 4) |>
  filter(sexo == "Total")

censo_largo |>
  filter(nivel == "Región") |>
  filter(codigo_region == 4) |>
  filter(edad == "Total")

censo_largo |>
  filter(nivel == "País") |>
  filter(edad == "Total")

censo_largo |>
  filter(nivel == "País") |>
  filter(sexo == "Mujeres") |>
  arrange(edad)

censo_largo
# censo_original


codigos_territoriales <- readxl::read_xlsx(
  "datos/diccionario_variables_censo2024.xlsx",
  sheet = "codigos_territoriales"
) |>
  rename(codigo = 1, nivel = 2, nombre = 3)

codigos_regiones <- codigos_territoriales |>
  filter(nivel == "Región") |>
  select(codigo_region = codigo, region = nombre)

codigos_comunas <- codigos_territoriales |>
  filter(nivel == "Comuna") |>
  select(codigo_comuna = codigo, comuna = nombre)

codigos_provincias <- codigos_territoriales |>
  filter(nivel == "Provincia") |>
  select(codigo_provincia = codigo, provincia = nombre)

library(forcats)

censo <- censo_largo |>
  # adjuntar regiones
  left_join(codigos_regiones, by = join_by(codigo_region)) |>
  relocate(region, .after = codigo_region) |>
  mutate(region = fct_reorder(region, codigo_region, .na_rm = FALSE)) |>
  # adjuntar provincias
  left_join(codigos_provincias, by = join_by(codigo_provincia)) |>
  relocate(provincia, .after = codigo_provincia) |>
  mutate(
    provincia = fct_reorder(provincia, codigo_provincia, .na_rm = FALSE)
  ) |>
  # adjuntar comunas
  left_join(codigos_comunas, by = join_by(codigo_comuna)) |>
  relocate(comuna, .after = codigo_comuna) |>
  mutate(comuna = fct_reorder(comuna, codigo_comuna, .na_rm = FALSE)) |>
  # ordenar
  arrange(nivel, region, provincia, comuna, sexo, edad)

censo

readr::write_csv2(censo, "datos/censo_2024_largo.csv")
