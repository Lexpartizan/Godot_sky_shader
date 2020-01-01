extends Sprite

#udate uniforms

onready var global_v=get_tree().get_root().get_node("scene")

func _ready():
	pass

func _process(delta):
	self.material.set("shader_param/iTime",global_v.iTime)

func cov_scb(value):
	self.material.set("shader_param/COVERAGE",float(value))

func absb_scb(value):
	self.material.set("shader_param/ABSORPTION",float(value))

func thick_scb(value):
	self.material.set("shader_param/THICKNESS",value)

func step_scb(value):
	self.material.set("shader_param/STEPS",value)
	print (value)

func _DAY_TIME_changed(value):
	var day_time: Vector2 = Vector2()
	day_time.x = floor(value/0.0835) #Период дня
	day_time.y = fmod(value,0.0835)*12.0; #Время в периоде в диапазоне от 0 до 1.
	var phi: float =0.0;
	phi = ((day_time.x-1.0) *30.0+day_time.y *30.0)*0.0174533
	var sun_pos: Vector3=Vector3(0.0,-1.0,0.0).rotated(Vector3(1.0,0.0,0.0),phi)
	var moon_pos: Vector3=Vector3(0.0,1.0,0.0).rotated(Vector3(1.0,0.0,0.0),phi)
	var temp: float =0.0
	print (day_time)
	if (day_time.x == 0.0 or day_time.x == 1.0 or day_time.x == 2.0 or day_time.x == 11.0):
		temp = 0.0 #ночь
	if (day_time.x == 3.0):
		temp = 1.0 #от ночи к рассвету
	if (day_time.x == 4.0):
		temp = 2.0 #от рассвета к дню
	if (day_time.x == 5.0 or day_time.x == 6.0 or day_time.x == 7.0 or day_time.x == 8.0):
		temp = 3.0 #день
	if (day_time.x == 9.0):
		temp = 4.0 #от дня к закату
	if (day_time.x == 10.0):
		temp = 5.0 #от заката к ночи
	day_time.x = temp;
	self.material.set("shader_param/DAY_TIME",day_time)
	self.material.set("shader_param/SUN_POS",sun_pos)
	self.material.set("shader_param/MOON_POS",moon_pos)
	


func wind_strength(value):
	var wind: Vector3 = Vector3(1.0,0.0,1.0).normalized()*value;
	self.material.set("shader_param/WIND",wind)


func _on_Button_button_down():
	var lighting_pos: Vector3 = Vector3(1.0,1.0,1.0).normalized();
	self.material.set("shader_param/LIGHTTING_POS",lighting_pos);
	self.material.set("shader_param/LIGHTING_STRIKE",true);


func _on_Button_button_up():
	self.material.set("shader_param/LIGHTING_STRIKE",false);
