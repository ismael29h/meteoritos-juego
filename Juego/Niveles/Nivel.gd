extends Node2D

class_name Nivel

export var explosion:PackedScene = null
export var meteorito:PackedScene = null
export var explosion_meteorito:PackedScene = null
export var sector_meteoritos:PackedScene = null
export var tiempo_transicion_camara:float = 2

onready var contenedor_proyectiles:Node
onready var contenedor_meteoritos:Node
onready var contenedor_explosiones:Node
onready var contenedor_sector_meteoritos:Node
onready var camara_nivel:Camera2D = $CameraNivel
onready var camara_player:Camera2D = $Player/CameraPlayer

var meteoritos_totales:int = 0


func _ready() -> void:
	conectar_seniales()
	crear_contenedores()


func conectar_seniales() -> void:
	Eventos.connect("disparo", self, "_on_disparo")
	Eventos.connect("nave_destruida", self, "_on_nave_destruida")
	Eventos.connect("lluvia_meteoritos", self, "_on_spawn_meteoritos")
	Eventos.connect("destruccion_meteorito", self, "_on_meteorito_destruido")
	Eventos.connect("nave_en_sector_peligro", self, "_on_nave_en_sector_peligro")

func crear_contenedores() -> void:
	contenedor_proyectiles = Node.new()
	contenedor_proyectiles.name = "ProyectilesDisparados"
	add_child(contenedor_proyectiles)
	
	contenedor_meteoritos = Node.new()
	contenedor_meteoritos.name = "ContenedorMeteoritos"
	add_child(contenedor_meteoritos)
	
	contenedor_explosiones = Node.new()
	contenedor_explosiones.name = "ContenedorExplosiones"
	add_child(contenedor_explosiones)

	contenedor_sector_meteoritos = Node.new()
	contenedor_sector_meteoritos.name = "ContenedorSectorMeteoritos"
	add_child(contenedor_sector_meteoritos)


func crear_sector_meteoritos(centro_camara:Vector2, numero_peligros:int) -> void:
	meteoritos_totales = numero_peligros
	var nuevo_sector_meteoritos:SectorMeteoritos = sector_meteoritos.instance()
	nuevo_sector_meteoritos.crear(centro_camara, numero_peligros)
	camara_nivel.global_position = centro_camara
	#camara_nivel.current = true
	contenedor_sector_meteoritos.add_child(nuevo_sector_meteoritos)
	transicion_camaras(
		camara_player.global_position,
		camara_nivel.global_position,
		camara_nivel
	)


func meteoritos_restantes() -> void:
	meteoritos_totales -= 1
	print(meteoritos_totales)
	if meteoritos_totales == 0:
		contenedor_sector_meteoritos.get_child(0).queue_free()
		#transicion_camaras(
		#	camara_nivel.global_position,
		#	camara_player.global_position,
		#	camara_player
		#)
		# Decidí resolver el bug de cámara de esta manera, sigue siendo brusco...
		# ... intentando disimularlo con la animación de spawn
		camara_nivel.current = false
		$Player/AnimationPlayer.play("spawn")
		camara_player.current = true

func transicion_camaras(desde:Vector2, hasta:Vector2, camara_actual:Camera2D) -> void:
	$TweenCamara.interpolate_property(
		camara_actual,
		"global_position",
		desde,
		hasta,
		tiempo_transicion_camara,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN_OUT
	)
	camara_actual.current = true
	$TweenCamara.start()
	
	
func _on_disparo(proyectil:Proyectil) -> void:
	contenedor_proyectiles.add_child(proyectil)


func _on_nave_destruida(posicion:Vector2, explosiones:int) -> void:
	for i in range(explosiones):	
		var nueva_explosion:Node2D = explosion.instance()
		nueva_explosion.global_position = posicion
		contenedor_explosiones.add_child(nueva_explosion)
		yield(get_tree().create_timer(0.17), "timeout")


func _on_spawn_meteoritos(pos_spawn:Vector2, dir_meteorito:Vector2, volumen:float) -> void:
	var nuevo_meteorito:Meteorito = meteorito.instance()
	nuevo_meteorito.crear(
		pos_spawn,
		dir_meteorito,
		volumen
	)
	contenedor_meteoritos.add_child(nuevo_meteorito)


func _on_meteorito_destruido(pos:Vector2) -> void:
	var nueva_explosion:ExplosionMeteorito = explosion_meteorito.instance()
	nueva_explosion.global_position = pos
	contenedor_explosiones.add_child(nueva_explosion)
	
	meteoritos_restantes()


func _on_nave_en_sector_peligro(centro_cam:Vector2, tipo_peligro:String, num_peligros:int) -> void:
	if tipo_peligro == "Meteorito":
		crear_sector_meteoritos(centro_cam, num_peligros)
	elif tipo_peligro == "Enemigo":
		pass


