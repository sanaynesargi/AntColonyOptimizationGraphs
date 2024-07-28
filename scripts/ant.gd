extends Sprite2D

var START
var PATH = []
var ALL_NODES = []
var ROUTE_LENGTH = 0

func weighted_random_index(weights):
	var all_zero = true
	for weight in weights:
		if weight != 0:
			all_zero = false
			break

	if all_zero:
		return randi() % len(weights)

	var total_weight = 0.0
	for weight in weights:
		total_weight += weight

	var cumulative_probs = []
	var cumulative_sum = 0.0
	for weight in weights:
		cumulative_sum += weight / total_weight
		cumulative_probs.append(cumulative_sum)

	var rnd = randf()
	for i in range(len(cumulative_probs)):
		if rnd < cumulative_probs[i]:
			return i

	return len(weights) - 1

func generate_possible_paths():
	var current_node = PATH[len(PATH) - 1]
	var possible_paths = []

	for j in ALL_NODES:
		if current_node == j or j in PATH:
			continue
		possible_paths.append([current_node, j])

	return possible_paths

func generate_path_probs(paths):
	var alpha = 1
	var beta = 10

	var desires = []
	var probs = []
	var sum = 0.001

	for path in paths:
		var i = path[0]
		var j = path[1]
		var dist = get_parent().DISTANCE_MATRIX[i][j]
		var phers = get_parent().PHEROMONE_MATRIX[i][j]

		var desire = (phers ** alpha) * ((1.0 / dist) ** beta)  # Adjusted desirability calculation
		desires.append(desire)
		sum += desire

	for d in desires:
		probs.append(d / sum)

	return probs

func _ready():
	var num_nodes = get_parent().NUM_NODES  
	for i in range(num_nodes):
		ALL_NODES.append(i)

func create_path():
	PATH = [START]
	ROUTE_LENGTH = 0

	while len(PATH) < len(ALL_NODES):
		var paths = generate_possible_paths()
		var path_probs = generate_path_probs(paths)
		var chosen_path_idx = weighted_random_index(path_probs)

		var chosen_path = paths[chosen_path_idx]
		var dist = get_parent().DISTANCE_MATRIX[chosen_path[0]][chosen_path[1]]

		PATH.append(chosen_path[1])
		ROUTE_LENGTH += dist

func compute_pheromones():
	var q_constant = get_parent().Q_CONSTANT
	var p_mult = get_parent().P_MULTIPLIER
	var pheromone_addition = (q_constant / ROUTE_LENGTH) * p_mult

	return pheromone_addition
