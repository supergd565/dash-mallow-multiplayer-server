FROM ubuntu:24.04

# 1. Instalar herramientas del sistema y dependencias de red
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    ca-certificates \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# 2. Definir versiones de Godot (Ajusta la versión si usas otra diferente a la 4.3)
ARG GODOT_VERSION=4.3
ARG RELEASE=stable
ARG GODOT_URL=https://github.com{GODOT_VERSION}-${RELEASE}/Godot_v${GODOT_VERSION}-${RELEASE}_linux.x86_64.zip

# 3. Descargar, descomprimir y configurar Godot de consola
RUN curl -sL ${GODOT_URL} -o godot.zip \
    && unzip godot.zip \
    && mv Godot_v* /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm godot.zip

# 4. Establecer el directorio de trabajo y copiar tu proyecto
WORKDIR /app
COPY . /app

# 5. Configurar el puerto dinámico requerido por Render
ENV PORT=10000
EXPOSE 10000

# 6. Ejecutar Godot en segundo plano Y responder con HTTP 200 OK a Render para evitar bloqueos
CMD godot --headless --path /app & \
    while true; do echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 2\r\n\r\nOK" | nc -l -p $PORT; done
