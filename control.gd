extends Control

var peer = WebSocketMultiplayerPeer.new()

# Diccionarios lógicos de salas virtuales
var salas = {}
var jugadores_en_sala = {}

func _ready():
	# Forzamos a Godot a escuchar en el puerto público asignado por Render (10000)
	var port = OS.get_environment("PORT")
	if port == "":
		port = "10000"
	var port_int = port.to_int()
	
	print("Iniciando Servidor Central unificado en puerto: ", port_int)
	
	var error = peer.create_server(port_int)
	if error != OK:
		print("Error crítico al crear el servidor unificado: ", error)
		return
		
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	print("Servidor listo. Escuchando jugadores y pings de Render en el mismo canal.")

func _on_player_disconnected(id):
	print("Jugador desconectado: ", id)
	if jugadores_en_sala.has(id):
		var codigo_sala = jugadores_en_sala[id]
		salas[codigo_sala].erase(id)
		jugadores_en_sala.erase(id)
		
		notificar_salida_sala(codigo_sala, id)
		
		if salas[codigo_sala].size() == 0:
			salas.erase(codigo_sala)

# --- LLAMADAS REMOTAS (RPCs) ---

@rpc("any_peer", "call_local", "reliable")
func unirse_a_sala(codigo_sala: String):
	var id_remoto = multiplayer.get_remote_sender_id()
	
	if not salas.has(codigo_sala):
		salas[codigo_sala] = []
		
	salas[codigo_sala].append(id_remoto)
	jugadores_en_sala[id_remoto] = codigo_sala
	print("Jugador ", id_remoto, " entró a la sala: ", codigo_sala)

@rpc("any_peer", "call_local", "unreliable")
func actualizar_datos_jugador(posicion: Vector2, animacion: String):
	var id_remoto = multiplayer.get_remote_sender_id()
	
	if jugadores_en_sala.has(id_remoto):
		var codigo_sala = jugadores_en_sala[id_remoto]
		
		for miembro_id in salas[codigo_sala]:
			if miembro_id != id_remoto:
				recibir_datos_de_otro_jugador.rpc_id(miembro_id, id_remoto, posicion, animacion)

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
