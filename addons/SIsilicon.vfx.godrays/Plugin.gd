tool
extends EditorPlugin

const GodRays = preload("GodRays.gd")

var project_settings := "rendering/quality/godrays/"

func _enter_tree() -> void:
	name = "GodRaysPlugin"
	
	add_custom_type("GodRays", "Spatial", GodRays, preload("GodRays.svg"))
	
	create_project_setting(project_settings+"sample_number", 50, TYPE_INT, "The amount of samples used in godrays postprocessing.")
	create_project_setting(project_settings+"use_pcf5", false, TYPE_BOOL, "Whether to smooth out the blocking artifacts with more depth samples.")
	create_project_setting(project_settings+"dither_amount", 1.0, TYPE_REAL, "The amount of noise to add to the godrays.")
	
	print("GodRaysPlugin has been activated.")

func _exit_tree() -> void:
	remove_custom_type("GodRays")
	print("GodRaysPlugin has been deactivated.")

func create_project_setting(setting : String, default, type : int, hint : String) -> void:
	if not ProjectSettings.has_setting(setting):
		ProjectSettings.set_setting(setting, default)
		ProjectSettings.add_property_info({
			name = setting,
			type = type,
			hint = PROPERTY_HINT_NONE,
			hint_string = hint
		})
