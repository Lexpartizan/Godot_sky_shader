extends SpringArm

const ZOOM_MIN = 0.2
const ZOOM_MAX = 10
const MIN_ROT_Y = -89
const MAX_ROT_Y = 45

var mouse_relative: Vector2 = Vector2()
var zoom_step: float
var sens_x: float
var sens_y: float


func _input(event):
	if event is InputEventMouseMotion:
		mouse_relative += event.relative
	elif event.is_action_pressed("camera_zoom_in"):
		zoom_camera(1)
	elif event.is_action_pressed("camera_zoom_out"):
		zoom_camera(-1)

func _physics_process(delta):
	if mouse_relative != Vector2.ZERO:
		rotate_camera(Vector2(mouse_relative.y * delta * sens_x, mouse_relative.x * delta * sens_y))
		mouse_relative = Vector2()

func zoom_camera(direction):
	
	if direction > 0 and self.spring_length <= ZOOM_MIN:
		self.spring_length = ZOOM_MIN
	elif direction < 0 and self.spring_length >= ZOOM_MAX:
		self.spring_length = ZOOM_MAX
	else:
		self.spring_length -= direction * zoom_step

func rotate_camera(offset):
	self.rotation.y -= offset.y
	
	if self.rotation.y > PI:
		self.rotation.y -= PI*2
	elif self.rotation.y < -PI:
		self.rotation.y += PI*2
	
	if offset.x <= 0 and self.rotation_degrees.x >= MAX_ROT_Y:
		return
	if offset.x >= 0 and self.rotation_degrees.x <= MIN_ROT_Y:
		return
	
	self.rotation.x -= offset.x
