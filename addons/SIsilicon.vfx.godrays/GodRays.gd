tool
extends Spatial

var light : Light
export(float, 0, 2) var exposure := 0.5 setget set_exposure
export(float, EASE) var attenuation := 2.0 setget set_attenuation
export(float, 0, 2) var light_size := 0.5 setget set_light_size

var clouds : Texture setget set_clouds

var canvas : MeshInstance
var material := preload("GodRays.tres").duplicate() as ShaderMaterial

func _notification(what : int) -> void:
	if what == NOTIFICATION_PARENTED:
		if get_parent() is Light:
			light = get_parent()
	elif what == NOTIFICATION_UNPARENTED:
		light = null
		set_clouds(null)

func _ready() -> void:
	if get_child_count() > 0 and get_child(0).owner == null:
		remove_child(get_child(0))
	
	var mesh := QuadMesh.new()
	mesh.size = Vector2(2, 2)
	mesh.custom_aabb = AABB(Vector3(1,1,1) * -300000, Vector3(1,1,1) * 600000)
	
	canvas = MeshInstance.new()
	canvas.name = "GodRay"
	canvas.mesh = mesh
	canvas.material_override = material
	add_child(canvas)
	
	material.setup_local_to_scene()
	
	set_exposure(exposure)
	set_attenuation(attenuation)
	set_light_size(light_size)
	
	set_clouds(null)

func _process(delta : float) -> void:
	if not light:
		material.set_shader_param("light_type", 0)
		material.set_shader_param("light_pos", Vector3())
		return
	
	var is_directional := light is DirectionalLight
	
	material.set_shader_param("light_type", not is_directional)
	material.set_shader_param("light_color", light.light_color * light.light_energy)
	
	if is_directional:
		var direction := light.global_transform.basis.z
		material.set_shader_param("light_pos", direction)
		material.set_shader_param("size", light_size)
	else:
		var position := light.global_transform.origin
		material.set_shader_param("light_pos", position)
		material.set_shader_param("size", light_size * (light as OmniLight).omni_range)
	
	material.set_shader_param("num_samples", ProjectSettings.get_setting("rendering/quality/godrays/sample_number"))
	material.set_shader_param("use_pcf5", ProjectSettings.get_setting("rendering/quality/godrays/use_pcf5"))
	material.set_shader_param("dither", ProjectSettings.get_setting("rendering/quality/godrays/dither_amount"))

func set_exposure(value : float) -> void:
	exposure = value
	material.set_shader_param("exposure", exposure)
	if canvas:
		canvas.visible = exposure != 0

func set_attenuation(value : float) -> void:
	attenuation = value
	material.set_shader_param("attenuate", attenuation)
	if canvas:
		canvas.visible = attenuation != 0

func set_light_size(value : float) -> void:
	light_size = value
	if canvas:
		canvas.visible = light_size != 0

func set_clouds(value : Texture) -> void:
	clouds = value
	material.set_shader_param("clouds", value)
	material.set_shader_param("use_clouds", value != null)
