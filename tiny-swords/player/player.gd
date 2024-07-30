class_name Player
extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var sword_area: Area2D = $SwordArea
@onready var hitbox_area: Area2D = $HitboxArea
@onready var health_progress_bar: ProgressBar = $HealthProgressBar

@export_category("Movement")
@export var speed: float = 3
@export_category("Sword")
@export var sword_damage: int = 2
@export_category("Life")
@export var health: int = 50
@export var max_health: int = 50
@export var death_prefab: PackedScene
@export_category("Ritual")
@export var ritual_damage: float = 1
@export var ritual_interval: float =  30
@export var ritual_scene: PackedScene

var inputVector: Vector2 = Vector2(0,0)
var is_running: bool = false
var is_attacking: bool = false
var wasRunning: bool
var attack_cooldown: float = 0.0
var hitbox_cooldown: float = 0.0
var ritual_cooldown: float = 0.0

signal meat_collected(value: int)

func _ready():
	GameManager.player = self

func _process(delta) -> void:
	GameManager.player_position = position
	
	read_input()	
	play_idle_animation()
	update_attack_cooldown(delta)
	update_htbox_detection(delta)
	update_ritual(delta)
	
	health_progress_bar.max_value = max_health
	health_progress_bar.value = health
	
	if !is_attacking:
		rotate_sprite() 
	
	if Input.is_action_just_pressed("attack"):
		attack()
	
	#if Input.is_action_just_pressed("move_up"):
		#if is_running:
			#animation_player.play("idle")
			#is_running = false
		#else:
			#animation_player.play("run")
			#is_running = true
			
func _physics_process(delta):
	var speeedMultiplier: float = 100
	if !is_attacking:
		speeedMultiplier = 10
	var targetVelocity = inputVector * speed * 100
	velocity = lerp(velocity, targetVelocity, 0.2)
	move_and_slide()
	
func read_input() -> void:
	inputVector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	wasRunning= is_running
	is_running = not inputVector.is_zero_approx()
	
	#Apagar deadzone do input vector
	var deadzone = 0.15
	if abs(inputVector.x) <= 0.15:
		inputVector.x = 0.0
	if abs(inputVector.y) <= 0.15:
		inputVector. y= 0.0
	
func play_idle_animation() -> void:
	if !is_attacking:
		if wasRunning != is_running:
			if is_running:
				animation_player.play("run")
			else:
				animation_player.play("idle")

func rotate_sprite() -> void:
	if inputVector.x > 0:
		sprite.flip_h = false
	elif inputVector.x < 0:
		sprite.flip_h = true
	

func attack() -> void:
	if is_attacking:
		return
	animation_player.play("attack_side_1")
	is_attacking = true
	attack_cooldown = 0.6
	
func deal_damage_to_enemies() -> void:
	var bodies = sword_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			var enemy: Enemy = body
			var direction_to_enemy: Vector2 = (enemy.position - position).normalized()
			var attack_direction: Vector2
			if sprite.flip_h:
				attack_direction = Vector2.LEFT
			else :
				attack_direction = Vector2.RIGHT
			var dot_product = direction_to_enemy.dot(attack_direction)
			
			if dot_product >= 0.3:
				enemy.damage(sword_damage)
	
func update_attack_cooldown(delta: float) -> void:
	if is_attacking:
		velocity.x = 0
		velocity.y = 0
		attack_cooldown -= delta
		if attack_cooldown <= 0.0:
			is_attacking = false
			is_running = false
			animation_player.play("idle")

func damage (amount: int) -> void:
	if health <= 0: return
	health -= amount
	print("Player recebeu dano de: ", amount, " e tem : ", health, " de vida.")
	
	modulate = Color.RED
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	
	if health <= 0:
		die()
	
func die() -> void:
	if death_prefab:
		var death_object = death_prefab.instantiate()
		death_object.position = position
		get_parent().add_child(death_object)
		print("Player morreu")
		queue_free()
		
func update_htbox_detection(delta: float) -> void:
	hitbox_cooldown -= delta
	if hitbox_cooldown > 0: return
	
	hitbox_cooldown = 0.5
	
	var bodies = hitbox_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			var enemy = body
			var damage_amount = 1
			damage(damage_amount)
			
func heal(amount: int) -> int:
	health += amount
	if health > max_health:
		health = max_health
	print("Player recebeu cura de ", amount, " sua vida atual é  ", health)
	return health
		
	
func update_ritual(delta: float) -> void:
	ritual_cooldown -= delta
	if ritual_cooldown > 0: return
	ritual_cooldown = ritual_interval
	
	var ritual = ritual_scene.instantiate()
	ritual.damage_amount = ritual_damage
	add_child(ritual)
