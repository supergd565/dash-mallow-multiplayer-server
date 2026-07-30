FROM ubuntu:24.04

# 1. Instalar herramientas del sistema y dependencias de red
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    ca-certificates \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# 2. Configurar la descarga usando variables limpias independientes
ENV G_HOST=https://github.com
ENV G_PATH=/godotengine/godot/releases/download/4.3-stable
ENV G_FILE=Godot_v4.3-stable_linux.x86_64.zip

# 3. Descargar usando las variables estructuradas
RUN curl -sL "${G_HOST}${G_PATH}/${G_FILE}" -o godot.zip

# 4. Descomprimir e instalar el ejecutable
RUN unzip godot.zip \
    && mv Godot_v* /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm godot.zip

# 5. Establecer el directorio de trabajo y copiar tu proyecto
WORKDIR /app
COPY . /app

# 6. Configurar el puerto dinámico requerido por Render
ENV PORT=10000
EXPOSE 10000

# 7. Ejecutar Godot en segundo plano Y responder con HTTP 200 OK a Render
CMD godot --headless --path /app & \
    while true; do echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 2\r\n\r\nOK" | nc -l -p $PORT; done
