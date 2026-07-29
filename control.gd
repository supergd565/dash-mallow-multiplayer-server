extends Control

var peer = WebSocketMultiplayerPeer.new()

func _ready():
	var port = OS.get_environment("PORT")
	if port == "":
		port = "10000"
	var port_int = port.to_int()
	print("Iniciando servidor de WebSockets en el puerto: ", port_int)
	var error = peer.create_server(port_int)
	if error != OK:
		print("Error al crear el servidor: ", error)
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_player_connected)
	print("Servidor escuchando exitosamente.")

func _on_player_connected(id):
	print("Jugador conectado con ID: ", id)
