extends Control

var peer = WebSocketMultiplayerPeer.new()

# Diccionario de salas. Estructura: 
# { "CODIGO_SALA": [id_jugador1, id_jugador2, ...], ... }
var salas = {}

# Diccionario inverso para saber rápido en qué sala está un jugador:
# { id_jugador: "CODIGO_SALA", ... }
var jugadores_en_sala = {}

func _ready():
	# CORRECCIÓN: Leemos PORT_INTERNO (10005) para no colisionar con el puerto 10000 de Nginx
	var port = OS.get_environment("PORT_INTERNO")
	if port == "":
		port = "10005" # Puerto local de respaldo por defecto
	var port_int = port.to_int()
	
	print("Iniciando servidor en puerto interno: ", port_int)
	var error = peer.create_server(port_int)
	if error != OK:
		print("Error al crear el servidor: ", error)
		return
		
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	print("Servidor escuchando exitosamente detrás de Nginx.")

# Registrar cuando un jugador se desconecta para limpiarlo de la sala
func _on_player_disconnected(id):
	print("Jugador desconectado: ", id)
	if jugadores_en_sala.has(id):
		var codigo_sala = jugadores_en_sala[id]
		salas[codigo_sala].erase(id)
		jugadores_en_sala.erase(id)
		
		# Notificar al resto de la sala que este jugador se fue
		notificar_salida_sala(codigo_sala, id)
		
		# Borrar sala si se queda vacía
		if salas[codigo_sala].size() == 0:
			salas.erase(codigo_sala)

# --- LLAMADAS REMOTAS (RPCs) ---

# El cliente llama a esto primero para meterse en una sala
@rpc("any_peer", "call_local", "reliable")
func unirse_a_sala(codigo_sala: String):
	var id_remoto = multiplayer.get_remote_sender_id()
	
	# Si la sala no existe, la creamos
	if not salas.has(codigo_sala):
		salas[codigo_sala] = []
		
	# Añadir jugador a las listas
	salas[codigo_sala].append(id_remoto)
	jugadores_en_sala[id_remoto] = codigo_sala
	print("Jugador ", id_remoto, " se unió a la sala: ", codigo_sala)

# El cliente envía su posición y animación constantemente aquí
@rpc("any_peer", "call_local", "unreliable")
func actualizar_datos_jugador(posicion: Vector2, animacion: String):
	var id_remoto = multiplayer.get_remote_sender_id()
	
	# Verificar que el jugador realmente está en una sala registrada
	if jugadores_en_sala.has(id_remoto):
		var codigo_sala = jugadores_en_sala[id_remoto]
		
		# Reenviar el paquete SOLO a los miembros de esta sala
		for miembro_id in salas[codigo_sala]:
			if miembro_id != id_remoto: # No enviárselo a sí mismo
				# Ejecuta la función en el cliente remoto correspondiente
				recibir_datos_de_otro_jugador.rpc_id(miembro_id, id_remoto, posicion, animacion)

# Funciones puente obligatorias (para que Godot registre los nombres de RPC)
@rpc("any_peer")
func recibir_datos_de_otro_jugador(_id_origen: int, _posicion: Vector2, _animacion: String):
	pass

func notificar_salida_sala(codigo_sala: String, id_eliminado: int):
	if salas.has(codigo_sala):
		for miembro_id in salas[codigo_sala]:
			eliminar_jugador_remoto.rpc_id(miembro_id, id_eliminado)

@rpc("any_peer")
func eliminar_jugador_remoto(_id_eliminado: int):
	pass
