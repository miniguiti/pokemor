# Script local para desenvolvimento.
# Não fica em R/ para evitar execução durante install()/load_all().

# install.packages("remotes")
# remotes::install_github("miniguiti/r-pokemon")

devtools::document()
devtools::install()

# Após rodar, clique em Session > Restart Session