FROM ubuntu:24.04

# 1. Instalar dependencias esenciales, Nginx y librerías de Godot
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    ca-certificates \
    libfontconfig1 \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# 2. Descargar y configurar Godot 4.3 estable Headless
ENV G_HOST=https://github.com
ENV G_PATH=/godotengine/godot/releases/download/4.3-stable
ENV G_FILE=Godot_v4.3-stable_linux.x86_64.zip

RUN curl -sL "${G_HOST}${G_PATH}/${G_FILE}" -o godot.zip \
    && unzip godot.zip \
    && mv Godot_v* /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm godot.zip

WORKDIR /app
COPY . /app

# 3. Configurar dinámicamente Nginx para Render
# El puerto público será el $PORT (10000). Redirigirá el WebSocket a Godot en el puerto 10005
RUN echo 'server { \
    listen 10000; \
    location / { \
        proxy_pass http://127.0.0.1:10005; \
        proxy_http_version 1.1; \
        proxy_set_header Upgrade $http_upgrade; \
        proxy_set_header Connection "Upgrade"; \
        proxy_set_header Host $host; \
        proxy_cache_bypass $http_upgrade; \
        # Responder OK directamente al Health Check si no es un WebSocket \
        if ($http_upgrade != "websocket") { \
            return 200 "OK"; \
        } \
    } \
}' > /etc/nginx/sites-available/default

# Forzar puerto expuesto de Render
ENV PORT=10000
EXPOSE 10000

# Forzamos a Godot a escuchar internamente en el puerto 10005 asignando la variable de entorno
ENV PORT_INTERNO=10005

# Ejecutar Nginx en segundo plano y Godot en primer plano
CMD service nginx start && godot --headless --path /app
