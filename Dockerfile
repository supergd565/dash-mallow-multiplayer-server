FROM ubuntu:24.04

# 1. Instalar herramientas del sistema y dependencias de red básicas
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    ca-certificates \
    libfontconfig1 \
    && rm -rf /var/lib/apt/lists/*

# 2. Descargar, descomprimir y configurar Godot 4.3 estable de consola
ENV G_HOST=https://github.com
ENV G_PATH=/godotengine/godot/releases/download/4.3-stable
ENV G_FILE=Godot_v4.3-stable_linux.x86_64.zip

RUN curl -sL "${G_HOST}${G_PATH}/${G_FILE}" -o godot.zip \
    && unzip godot.zip \
    && mv Godot_v* /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm godot.zip

# 3. Establecer el directorio de trabajo y copiar tu proyecto
WORKDIR /app
COPY . /app

# Puerto dinámico oficial requerido por Render
ENV PORT=10000
EXPOSE 10000

# Arrancamos Godot pasándole el control directo
CMD ["godot", "--headless", "--path", "/app"]
