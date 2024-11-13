# Este archivo de configuración es solo para pruebas
# Ordo
# Asegúrate de ajustar las configuraciones para el entorno de producción

use Mix.Config

config :pleroma, Pleroma.Repo,
  username: System.get_env("DB_USER"),
  password: System.get_env("DB_PASSWORD"),
  database: System.get_env("DB_NAME"),
  hostname: System.get_env("DB_URL"),
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :pleroma, :http,
  url: System.get_env("PLEROMA_URL"),
  port: 4000,
  protocol: "http"

config :pleroma, :secret_key_base, System.get_env("SECRET_KEY_BASE")
