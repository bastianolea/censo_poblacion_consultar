# a qué nivel (nacional, regional, provincial, comunal)
# qué sexos (hombre, mujer, total)
# qué edades ({grupos de edad}, total)


library(dplyr)
library(readxl)
library(janitor)
library(stringr)

# cargar ----
ruta_datos <- "datos/D1_Poblacion-censada-por-sexo-y-edad-en-grupos-quinquenales.xlsx"


datos_region_edad <- read_xlsx(ruta_datos,
                               sheet = 4)

datos_comuna_edad <- read_xlsx(ruta_datos,
                               sheet = 5)


# limpiar ----

region_edad <- datos_region_edad |> 
  row_to_names(3) |> 
  clean_names() |> 
  mutate(across(c(poblacion_censada, hombres, mujeres), as.numeric)) |> 
  rename(total = poblacion_censada) |> 
  filter_out(is.na(region)) |> 
  filter_out(region == "País") |> 
  mutate(nivel = "Región", .before = 1) |> 
  mutate(grupos_de_edad = recode_values(grupos_de_edad,
                                        "Total Región" ~ "Total",
                                        default = grupos_de_edad)) |> 
  select(-razon_hombre_mujer) |> 
  rename(edad = grupos_de_edad)

comuna_edad <- datos_comuna_edad |> 
  row_to_names(3) |> 
  clean_names() |> 
  mutate(across(c(poblacion_censada, hombres, mujeres), as.numeric)) |> 
  rename(total = poblacion_censada) |> 
  filter_out(region == "País") |> 
  mutate(nivel = "Comuna", .before = 1) |> 
  mutate(grupos_de_edad = recode_values(grupos_de_edad,
                                        "Total Comuna" ~ "Total",
                                        default = grupos_de_edad)) |> 
  select(-razon_hombre_mujer) |> 
  rename(edad = grupos_de_edad)

pais_edad <- datos_region_edad |> 
  row_to_names(3) |> 
  clean_names() |> 
  mutate(across(c(poblacion_censada, hombres, mujeres), as.numeric)) |> 
  rename(total = poblacion_censada) |> 
  filter_out(is.na(region)) |> 
  filter(region == "País") |> 
  mutate(nivel = "País", .before = 1) |> 
  mutate(grupos_de_edad = recode_values(grupos_de_edad,
                                        "Total País" ~ "Total",
                                        default = grupos_de_edad)) |> 
  select(-razon_hombre_mujer) |> 
  rename(edad = grupos_de_edad)


# calcular provincia ----

provincia_edad <- datos_comuna_edad |> 
  row_to_names(3) |> 
  clean_names() |> 
  mutate(across(c(poblacion_censada, hombres, mujeres), as.numeric)) |> 
  rename(total = poblacion_censada) |> 
  filter_out(region == "País") |> 
  mutate(grupos_de_edad = recode_values(grupos_de_edad,
                                        "Total Comuna" ~ "Total",
                                        default = grupos_de_edad)) |> 
  group_by(codigo_provincia, provincia, grupos_de_edad) |> 
  summarise(total = sum(total), hombres = sum(hombres), mujeres = sum(mujeres)) |> 
  ungroup() |> 
  mutate(nivel = "Provincia", .before = 1) |> 
  rename(edad = grupos_de_edad)


# pivotar sexo ----

region_edad_sexo <- region_edad |> 
  pivot_longer(cols = c(total, hombres, mujeres), 
               names_to = "sexo", 
               values_to = "poblacion",
               names_transform = str_to_title)

comuna_edad_sexo <- comuna_edad |> 
  pivot_longer(cols = c(total, hombres, mujeres), 
               names_to = "sexo", 
               values_to = "poblacion",
               names_transform = str_to_title)

pais_edad_sexo <- pais_edad |> 
  pivot_longer(cols = c(total, hombres, mujeres), 
               names_to = "sexo", 
               values_to = "poblacion",
               names_transform = str_to_title)

provincia_edad_sexo <- provincia_edad |> 
  pivot_longer(cols = c(total, hombres, mujeres), 
               names_to = "sexo", 
               values_to = "poblacion",
               names_transform = str_to_title)


# unir ----

censo <- bind_rows(
  comuna_edad_sexo,
  provincia_edad_sexo,
  region_edad_sexo,
  pais_edad_sexo,
  )


# guardar ----

library(readr)

write_rds(censo,
          "datos/censo.rds")
