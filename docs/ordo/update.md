¡Bienvenido a la comunidad Ordo! 🚀

## Instrucciones de actualización

Para actualizar Ordo (el backend), entra al servidor y ejecuta los siguientes comandos:

```sh
sudo -Hu pleroma bash
cd /opt/pleroma

git pull origin main

asdf install

mix deps.get
MIX_ENV=prod mix ecto.migrate

exit
systemctl restart pleroma
```