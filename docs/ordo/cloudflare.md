
# Configuración de Certbot con Cloudflare para Generación de Certificados SSL

## 1. Crear el API Token en Cloudflare

Antes de continuar, crea un **API Token** en Cloudflare para que Certbot pueda gestionar los registros DNS para validar tu dominio.

1. Inicia sesión en **Cloudflare**.
2. En **My Profile**, selecciona **API Tokens**.
3. Haz clic en **Create Token** y selecciona **Edit DNS**.
4. Guarda el **API Token** generado.

## 2. Instalar Certbot y el Plugin DNS de Cloudflare

En tu servidor, instala **Certbot** y el plugin de **Cloudflare**:

```bash
sudo apt update
sudo apt install certbot python3-certbot-dns-cloudflare
```

## 3. Configurar el archivo `cloudflare.ini`

1. Crea el archivo `cloudflare.ini` para almacenar el API Token:

```bash
sudo nano /etc/letsencrypt/cloudflare.ini
```

2. Añade la siguiente línea al archivo:

```ini
dns_cloudflare_api_token = tu_api_token_aqui
```

3. Establece los permisos adecuados para el archivo:

```bash
sudo chmod 600 /etc/letsencrypt/cloudflare.ini
```

## 4. Generar el Certificado con Certbot

Usa el siguiente comando para generar el certificado SSL:

```bash
sudo certbot certonly --dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini -d tu-dominio -d www.tu-dominio --dns-cloudflare-propagation-seconds 60
```

Este comando utilizará el plugin de Cloudflare para la validación del dominio y generar los certificados.

## Vuelve a la [instalacion de Ordo](https://docs.fedired.com/ordo/install.html#_4-b-nginx)

## 5. Configuración de Renovación Automática

Añade un cron job para renovar el certificado automáticamente:

```bash
sudo crontab -e
```

Añade la siguiente línea para ejecutar la renovación cada día a las 2:30 AM:

```bash
30 2 * * * certbot renew --quiet
```

Este cron job renovará el certificado y mantendrá tu sitio siempre protegido con HTTPS.

## Resumen de Archivos y Configuraciones:

1. **cloudflare.ini**: Contiene el API Token de Cloudflare.
   - Ubicación: `/etc/letsencrypt/cloudflare.ini`

2. **Tarea Cron**: Renovación automática de certificados.
   - Comando en crontab: `30 2 * * * certbot renew --quiet`