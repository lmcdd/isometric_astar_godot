extends Node2D

const BOUND_COLOR = Color(1, 1, 1)
const POINT_COLOR = Color(1, 1, 0.5)
const PATH_COLOR = Color(1, 0, 0)

var SIZE_MAP  # Generate
var TILE_SIZE  # in _ready()

# Tiles in TileSet
enum tileID {FIELD, GRASS, ROAD, WATHER}
var passable_tiles = [tileID.ROAD]

### AStar variables ###
var points = PoolVector2Array()
var bonds = []
var start_pos
var end_pos
var astar = AStar.new()

# Get TileMap
onready var tmap = $'terra'

# directions for the search of adjacent points
var dirs = [	
				# For without offset
				[	Vector2(-1, 1),	Vector2(0, 1),	Vector2(1, 1), 
					Vector2(-1, 0),					Vector2(1, 0), 
					Vector2(-1,-1),	Vector2(0, -1),	Vector2(1, -1)
				],
				
				# For Y offset
				# For X % 2 == 0
				[					Vector2(0, 1),
					Vector2(-1, 0),					Vector2(1, 0), 
					Vector2(-1,-1),	Vector2(0, -1),	Vector2(1, -1)
				],
				# For X % 2 == 1
				[	Vector2(-1, 1),	Vector2(0, 1),	Vector2(1, 1),
					Vector2(-1, 0),					Vector2(1, 0), 
									Vector2(0, -1),
				],
				# For X offset
				# For Y % 2 == 0	
				[	Vector2(-1, 1),	Vector2(0, 1),	 
					Vector2(-1, 0),					Vector2(1, 0), 
					Vector2(-1,-1),	Vector2(0, -1),	
				],
				# For Y % 2 == 1
				[					Vector2(0, 1),	Vector2(1, 1), 
					Vector2(-1, 0),					Vector2(1, 0), 
									Vector2(0, -1),	Vector2(1, -1)
				],
				
			]

func target_controller():
	# Start position
	if Input.is_action_just_pressed('LBM'):
		var coord = tmap.world_to_map(get_global_mouse_position()) + Vector2(1,-1) 	# Mouse pos in tile map
		print (coord)
		var global_coord = get_centre(coord)						# Global mouse pos in tile map
		if tmap.get_cell(coord.x, coord.y) in passable_tiles: #tileID.GRASS:
			start_pos = astar.get_closest_point(Vector3(global_coord.x, global_coord.y, 0))
		update()
	# End position
	if Input.is_action_just_pressed('RBM'):
		var coord = tmap.world_to_map(get_global_mouse_position()) + Vector2(1,-1)	
		var global_coord = get_global_mouse_position()
		if tmap.get_cell(coord.x, coord.y) in passable_tiles: #tileID.GRASS:
			end_pos = astar.get_closest_point(Vector3(global_coord.x, global_coord.y, 0))
		update()

func _process(delta):
	target_controller()

# To obtain the center of the tile		
func get_centre(mpos, tilesize = TILE_SIZE):
	return Vector2(tmap.map_to_world(mpos) + Vector2(-tilesize.x, tilesize.y / 2)) 
	
func get_centre2(pos, tilesize = TILE_SIZE):
	return Vector2(pos + Vector2(-tilesize.x, tilesize.y / 2)) 

# Adding points to draw in the _draw()
func set_point(index, x, y, a = astar):
	var c = get_centre(Vector2(x,y))
	points.append(c) # To obtain the center of the tile	
	a.add_point(index, Vector3(c.x, c.y, 0)) # Additing point without Z coord

# Adding bonds to draw in the _draw()
func set_bound(p1, p2):
	bonds.append( [get_centre(p1), get_centre(p2)] )

# Create point
func create_points(tilemap, tiles = [tileID.GRASS]):
	# Additing points in AStar class
	var i = 0	# ID
	for cx in range(SIZE_MAP.x):
		for cy in range(SIZE_MAP.y):
			#var l = Label.new()
			#l.text = '(' + str(cx) + ',' + str(cy) + ')'
			#l.rect_position = tmap.map_to_world( Vector2(cx,cy) )
			#add_child(l)
			if tilemap.get_cell(cx, cy) in tiles:
				i += 1
				set_point(i, cx, cy)

	# Additing bonds in AStar class
	for cx in range(SIZE_MAP.x):
		# The choice of directions
		var ddirs
		if tmap.cell_half_offset == tmap.HALF_OFFSET_Y:
			if cx % 2 == 0:
				ddirs = dirs[1]

			elif cx % 2 == 1:
				ddirs = dirs[2]

		else:
			ddirs = dirs[0]

		for cy in range(SIZE_MAP.y):
			# The choice of directions
			if tmap.cell_half_offset == tmap.HALF_OFFSET_X:
				if cy % 2 == 0:
					ddirs = dirs[3]
				elif cy % 2 == 1:
					ddirs = dirs[4]
			else:
				ddirs = dirs[0]


			if tilemap.get_cell(cx, cy) in tiles:
				var t = Vector2(cx, cy)		# Tile position to Vector2
				for d in ddirs:				# The sorting out of directions
					var td = t + d 			# Tile position + direction
					# Check out negative limits
					if not( td.x in [SIZE_MAP.x, -1] or td.y in [SIZE_MAP.y, -1] ):
						if tilemap.get_cell(td.x, td.y) in tiles:
							# To obtain the center of the tile	 
							var tc = get_centre(t)
							var tdc = get_centre(td)
							# Connecting the points
							astar.connect_points(astar.get_closest_point(Vector3(tc.x, tc.y, 0)), astar.get_closest_point(Vector3(tdc.x, tdc.y, 0)))
							# Additing bounds in array for _draw()
							set_bound(t, td)				
	update()

func init_path():
	# Constants
	SIZE_MAP = tmap.get_used_rect().size
	TILE_SIZE = tmap.cell_size

	create_points(tmap, passable_tiles)
	
func draw_path():
	# Draw bonds
	for t in bonds:
		draw_line(t[0], t[1], BOUND_COLOR)
		
	# Draw points
	for p in points:
		draw_circle(p, 9, POINT_COLOR)

	# If there are start and end points
	if start_pos != null and end_pos != null:
		var last_pos = null
		# Drawing bonds the path
		for j in astar.get_id_path(start_pos, end_pos):
			var point_pos = astar.get_point_position(j)
			if last_pos != null:
				draw_line(last_pos, Vector2(point_pos.x, point_pos.y), BOUND_COLOR, 4, true)
				draw_line(last_pos, Vector2(point_pos.x, point_pos.y), PATH_COLOR, 2)
			last_pos = Vector2(point_pos.x, point_pos.y)
		# Drawing points the path
		for j in astar.get_id_path(start_pos, end_pos):
			var point_pos = astar.get_point_position(j)
			draw_circle(Vector2(point_pos.x, point_pos.y), 6, PATH_COLOR)

func _draw():
	draw_path()
			
func _ready():
	init_path()				
