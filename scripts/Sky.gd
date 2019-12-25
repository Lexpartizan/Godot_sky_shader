extends Sprite

#udate uniforms

onready var global_v=get_tree().get_root().get_node("scene")

func _ready():
	pass

func _process(delta):
	self.material.set("shader_param/iTime",global_v.iTime)
	self.material.set("shader_param/iFrame",global_v.iFrame)

func cov_scb(value):
	self.material.set("shader_param/COVERAGE",float(value))

func absb_scb(value):
	self.material.set("shader_param/ABSORPTION",float(value))

func thick_scb(value):
	self.material.set("shader_param/THICKNESS",value)

func step_scb(value):
	self.material.set("shader_param/STEPS",value)


func _DAY_TIME_changed(value):
	self.material.set("shader_param/DAY_TIME",value)


func wind_strength(value):
	self.material.set("shader_param/wind_strength",value)
