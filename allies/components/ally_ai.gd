extends Node
class_name AllyAI

enum State { FOLLOWING, MOVING_TO_TARGET, ATTACKING, RETREATING }

var ally_ref
var current_state := State.FOLLOWING
var player_target
var enemy_target
var state_update_timer := 0.0
var state_update_interval := 0.1
var attack_delay_timer := 0.0
var attack_delay := 0.0
var retreat_timer := 0.0

var first_names = [
	"Aiden", "Luna", "Kai", "Mira", "Rowan", "Zara", "Finn", "Nova", "Ezra", "Lyra",
	"Orin", "Sage", "Rhea", "Jax", "Vera", "Theo", "Ivy", "Dax", "Nia", "Kian",
	"Tara", "Milo", "Suri", "Riven", "Elara", "Bryn", "Juno", "Vale", "Niko", "Sable",
	"Astra", "Corin", "Eira", "Lira", "Marek", "Nyx", "Oryn", "Pax", "Quill", "Rivena",
	"Soren", "Talon", "Vesper", "Wyn", "Xara", "Yara", "Zarek", "Aeliana", "Balen", "Cael",
	"Darian", "Elys", "Faelan", "Galen", "Halyn", "Isen", "Jarek", "Kael", "Lirael", "Mirael",
	"Neris", "Orin", "Pyria", "Quorin", "Rylin", "Sylas", "Tirian", "Uriel", "Vael", "Weylin",
	"Xyra", "Yalen", "Zyra", "Aeris", "Briar", "Caius", "Darian", "Elowen", "Fira", "Galen",
	"Hale", "Iria", "Jace", "Kira", "Lira", "Mira", "Nira", "Orin", "Pax", "Quin", "Ryn"
]
var last_names = [
	"Stormrider", "Dawnbringer", "Nightshade", "Ironwood", "Starfall", "Ashwalker", "Frostwind", "Shadowmere",
	"Brightblade", "Moonwhisper", "Stonehelm", "Swiftarrow", "Emberforge", "Mistvale", "Oakenshield", "Riversong",
	"Wolfbane", "Sunstrider", "Duskwalker", "Windrider", "Firebrand", "Silverleaf", "Darkwater", "Goldheart",
	"Hawthorne", "Stormwatch", "Ironfist", "Lightfoot", "Shadowfox", "Winterborn", "Amberfall", "Blackswan",
	"Cinderfell", "Duskwhisper", "Eaglecrest", "Flintlock", "Grimward", "Hollowbrook", "Ironvale", "Jadeblade",
	"Kingsley", "Larkspur", "Moonshadow", "Nightriver", "Oakheart", "Pinecrest", "Quickwater", "Ravencrest",
	"Stormvale", "Thornfield", "Umbermoor", "Valebrook", "Westwood", "Yewbranch", "Zephyrwind", "Ashenford",
	"Briarwood", "Cloudspire", "Dawnforge", "Ebonwood", "Frostvale", "Glimmerstone", "Hawkwing", "Ivoryspire",
	"Jasperfield", "Kestrel", "Lionshade", "Mistwood", "Northwind", "Oakenfield", "Pinevale", "Quicksilver",
	"Ridgewood", "Stonevale", "Thornbush", "Umberfield", "Violetmoor", "Willowisp", "Yarrow", "Zephyrfield"
]

func _ready():
	while first_names.size() < 1000:
		first_names.append("Name%d" % first_names.size())
	while last_names.size() < 1000:
		last_names.append("Surname%d" % last_names.size())

func generate_random_name() -> String:
	var first = first_names[randi() % first_names.size()]
	var last = last_names[randi() % last_names.size()]
	return first + " " + last

func setup(ally):
	ally_ref = ally
	if not ally_ref.has_meta("display_name"):
		var random_name = generate_random_name()
		ally_ref.set_meta("display_name", random_name)
		ally_ref.name = random_name

func set_player_target(player):
	player_target = player

func _process(delta):
	state_update_timer += delta
	if state_update_timer >= state_update_interval:
		_update_ai_state()
		state_update_timer = 0.0
	_execute_current_state(delta)

func _update_ai_state():
	if not player_target:
		return
	enemy_target = ally_ref.combat_component.find_nearest_enemy()
	var _previous_state = current_state
	if ally_ref.health_component.current_health < ally_ref.max_health * 0.25 and enemy_target:
		current_state = State.RETREATING
		retreat_timer = 1.0 + randf() * 1.5
		return
	if enemy_target:
		var distance_to_enemy = ally_ref.global_position.distance_to(enemy_target.global_position)
		if distance_to_enemy <= ally_ref.combat_component.attack_range:
			current_state = State.ATTACKING
		elif distance_to_enemy <= ally_ref.combat_component.detection_range:
			current_state = State.MOVING_TO_TARGET
		else:
			current_state = State.FOLLOWING
	else:
		current_state = State.FOLLOWING

func _execute_current_state(delta: float):
	match current_state:
		State.FOLLOWING:
			_handle_following(delta)
		State.MOVING_TO_TARGET:
			_handle_moving_to_target(delta)
		State.ATTACKING:
			_handle_attacking(delta)
		State.RETREATING:
			_handle_retreating(delta)

func _handle_following(delta: float):
	if not player_target:
		return
	var distance_to_player = ally_ref.global_position.distance_to(player_target.global_position)
	if distance_to_player > ally_ref.movement_component.follow_distance:
		ally_ref.movement_component.move_towards_target(player_target.global_position, delta)
	else:
		ally_ref.movement_component.orbit_around_player(player_target, delta)
	ally_ref.movement_component.apply_separation(delta)

func _handle_moving_to_target(delta: float):
	if not enemy_target:
		current_state = State.FOLLOWING
		return
	ally_ref.movement_component.strafe_around_target(enemy_target, delta)
	ally_ref.movement_component.apply_separation(delta)

func _handle_attacking(delta: float):
	if not enemy_target:
		current_state = State.FOLLOWING
		return
	if attack_delay_timer > 0:
		attack_delay_timer -= delta
		return
	if randf() < 0.1:
		attack_delay = 0.1 + randf() * 0.3
		attack_delay_timer = attack_delay
		return
	ally_ref.combat_component.attack_target(enemy_target)
	ally_ref.velocity.x = move_toward(ally_ref.velocity.x, 0, ally_ref.speed * 2 * delta)
	ally_ref.velocity.z = move_toward(ally_ref.velocity.z, 0, ally_ref.speed * 2 * delta)

func _handle_retreating(delta: float):
	if retreat_timer > 0:
		retreat_timer -= delta
		if enemy_target:
			ally_ref.movement_component.move_away_from_target(enemy_target.global_position, delta)
		return
	current_state = State.FOLLOWING

func command_move_to_position(position: Vector3):
	ally_ref.movement_component.move_towards_target(position, 0.1)
