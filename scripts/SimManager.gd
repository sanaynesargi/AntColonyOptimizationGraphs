extends Node


@export var NUM_NODES := 5
@export var NODE_RADIUS := 100
@export var NODE_OFFSET := 150
@export var MAX_T_STEPS := 500

@export var NUM_ANTS := NUM_NODES
@export var PHEROMONE_EVAPORATION := 0.5
@export var Q_CONSTANT := 4
@export var P_MULTIPLIER := 1


@onready var dist_label = $MinDist


var S_WIDTH := 1920
var S_HEIGHT := 1080
var S_LEFT = S_WIDTH / 2.0 * -1.0
var S_BOTTOM = S_HEIGHT / 2.0 * -1
var S_RIGHT = -S_LEFT
var S_TOP = -S_BOTTOM

var T_STEP = 0

var ADJ_MATRIX = [] # computational representation

var DISTANCE_MATRIX = []
var PHEROMONE_MATRIX = []

# graphical representation
var NODES = []
var EDGES = {}
var ANTS = []

var GNode = load("res://scenes/g_node.tscn")
var GEdge = load("res://scenes/g_edge.tscn")
var Ant = load("res://scenes/ant.tscn")


func generate_node_coords(used_coords):
    var not_found = true

    while not_found:
        var x = randf_range(S_LEFT + NODE_RADIUS, S_RIGHT - NODE_RADIUS)
        var y = randf_range(S_BOTTOM + NODE_RADIUS, S_TOP - NODE_RADIUS)
        var box_l = (NODE_RADIUS * 2) + NODE_OFFSET

        var valid = true
        for coord in used_coords:
            if abs(x - coord[0]) < box_l and abs(y - coord[1]) < box_l:
                valid = false
                break

        if valid:
            return Vector2(x, y)


# get distance using 2d distance of pixel values
func get_distance(i, j):
    var pos1 = NODES[i].position
    var pos2 = NODES[j].position

    return pos1.distance_to(pos2)


# since tuples are not mutable, convert to strings for indexing
func convert_to_key(i, j):
    return str(i) + str(j)


func convert_from_key(key):
    var char1 = key[0]
    var char2 = key[1]

    return [int(char1), int(char2)]


func create_distance_list():
    # optimization -> dst[i][j] is the same as dst[j][i]

    for i in range(NUM_NODES):
        for j in range(NUM_NODES):
            if i == j:
                DISTANCE_MATRIX[i][j] = 0
                continue

            var dst = get_distance(i, j)
            DISTANCE_MATRIX[i][j] = dst
            DISTANCE_MATRIX[j][i] = dst


func create_ants():
    # create ants
    for i in range(NUM_ANTS):
        var instance = Ant.instantiate()
        add_child(instance)
        ANTS.append(instance)


func delete_ants():
    for ant in ANTS:
        ant.queue_free()
    ANTS = []


# Called when the node enters the scene tree for the first time.
func _ready():
    get_window().size = Vector2i(S_WIDTH, S_HEIGHT)

    var coords = []

    # create the empty adj_matrix
    for i in range(NUM_NODES):
        ADJ_MATRIX.append([])
        DISTANCE_MATRIX.append([])
        PHEROMONE_MATRIX.append([])
        for j in range(NUM_NODES):
            ADJ_MATRIX[i].append(0)
            DISTANCE_MATRIX[i].append(0)
            PHEROMONE_MATRIX[i].append(0.5)            

    # create nodes
    for i in range(NUM_NODES):
        var instance = GNode.instantiate()
        var coord = generate_node_coords(coords)
        coords.append(coord)

        instance.ID = i
        instance.RADIUS = NODE_RADIUS
        instance.position = coord

        NODES.append(instance)
        add_child(instance)

    create_distance_list()

    # create edges
    for i in range(NUM_NODES):
        for j in range(NUM_NODES):
            if i == j:
                continue

            var k = convert_to_key(i, j)
            if k in EDGES:
                continue

            var node1 = NODES[i]
            var node2 = NODES[j]

            var pos1 = node1.position
            var pos2 = node2.position

            var instance = GEdge.instantiate()

            instance.POS1 = pos1
            instance.POS2 = pos2
            instance.EDGE_ID = k
            instance.THICKNESS = -1
            instance.visible = false

            add_child(instance)

            EDGES[k] = instance


func evaporate_pheromones():
    for i in range(NUM_NODES):
        for j in range(NUM_NODES):
            PHEROMONE_MATRIX[i][j] *= (1 - PHEROMONE_EVAPORATION)
            PHEROMONE_MATRIX[i][j] = max(PHEROMONE_MATRIX[i][j], 0.05) # Ensure pheromones do not drop below a threshold


func generate_path_pairs(path):
    var pairs = []
    for i in range(len(path) - 1):
        pairs.append([path[i], path[i + 1]])
    return pairs


func add_ant_pheromones():
    for ant in ANTS:
        var ant_path = ant.PATH
        var ant_pheromones = ant.compute_pheromones()

        for path in generate_path_pairs(ant_path):
            var i = path[0]
            var j = path[1]
            PHEROMONE_MATRIX[i][j] += ant_pheromones


func update_graphics_pheromones():
    var max_pheromone = 0.0

    # Find the maximum pheromone level
    for i in range(NUM_NODES):
        for j in range(NUM_NODES):
            if i != j:
                max_pheromone = max(max_pheromone, PHEROMONE_MATRIX[i][j])

    # Update the thickness of the edges with logarithmic scaling
    for i in range(NUM_NODES):
        for j in range(NUM_NODES):
            if i == j:
                continue

            var str_key = convert_to_key(i, j)
            var pheromone_level = PHEROMONE_MATRIX[i][j]

            # Logarithmic scaling to magnify differences
            if max_pheromone > 0:
                var normalized_pheromone = pheromone_level / max_pheromone
                var thickness = log(1 + 9 * normalized_pheromone) * 5  # Scale to [0, 10]

                EDGES[str_key].visible = true
                EDGES[str_key].THICKNESS = thickness
            else:
                EDGES[str_key].visible = false
                EDGES[str_key].THICKNESS = 0



func update_graphics_best_found():
    # Clear all edges visibility and thickness
    for i in range(NUM_NODES):
        for j in range(NUM_NODES):
            if i == j:
                continue

            var str_key = convert_to_key(i, j)
            EDGES[str_key].visible = false
            EDGES[str_key].THICKNESS = 0

    var visited = []
    var path = []
    var dist = 0

    # Start from the first node
    var current_node = 0
    path.append(current_node)
    visited.append(current_node)

    while len(path) < NUM_NODES:
        var max_pheromone = -1.0
        var next_node = -1

        # Find the next node with the maximum pheromone that hasn't been visited
        for j in range(NUM_NODES):
            if j in visited or current_node == j:
                continue

            if PHEROMONE_MATRIX[current_node][j] > max_pheromone:
                max_pheromone = PHEROMONE_MATRIX[current_node][j]
                next_node = j

        if next_node == -1:
            break

        var str_key = convert_to_key(current_node, next_node)
        var d = get_distance(current_node, next_node)
        EDGES[str_key].visible = true
        EDGES[str_key].THICKNESS = 5

        current_node = next_node
        path.append(current_node)
        visited.append(current_node)

        dist += d

    # Complete the path by connecting the last node to the start node if necessary
    if len(path) == NUM_NODES:
        var str_key = convert_to_key(current_node, path[0])
        EDGES[str_key].visible = true
        EDGES[str_key].THICKNESS = 5
        dist += get_distance(current_node, path[0])

    dist_label.text = "Min Dist: " + str(int(dist))



# Called every frame. 'delta' is the elapsed time since the previous frame
func _process(_delta):

    if T_STEP == MAX_T_STEPS:
        return

    create_ants()

    var start = 0
    for ant in ANTS:
        ant.START = start % NUM_NODES
        ant.create_path()
        start += 1

    evaporate_pheromones()
    add_ant_pheromones()
    update_graphics_best_found()

    T_STEP += 1

    delete_ants()
