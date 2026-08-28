extends ProgressBar

var tween: Tween

var active: bool = false:
	set(new_val):
		if new_val == active: return
		
		if new_val and value > step: # guarding for not being visible		
			active = true
			if(!$ScrollTexture.visible):
				$ScrollTexture.show()
				
			# if currently been tweened, cancel it
			if (tween): 
				tween.kill()
				tween = null
			tween = create_tween()\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_QUAD)
			
			# tween to 1
			tween.tween_method(
				func(x): $ScrollTexture.material.set_shader_parameter("active", x),
				$ScrollTexture.material.get_shader_parameter("active"),
				1.0, 0.1
			)
			#tween.tween_method(
				#func(x): $ScrollTexture.material.set_shader_parameter("scroll_speed", x),
				#$ScrollTexture.material.get_shader_parameter("scroll_speed"),
				#50.0, 0.1
			#)
			
		else:
			active = false
			
			# if currently been tweened, cancel it
			if (tween): 
				tween.kill()
				tween = null
			tween = create_tween()\
			.set_ease(Tween.EASE_IN)\
			.set_trans(Tween.TRANS_QUAD)
			
			# tween to 1
			tween.tween_method(
				func(x): $ScrollTexture.material.set_shader_parameter("active", x),
				$ScrollTexture.material.get_shader_parameter("active"),
				0.0, 0.2
			)
			#tween.tween_method(
				#func(x): $ScrollTexture.material.set_shader_parameter("scroll_speed", x),
				#$ScrollTexture.material.get_shader_parameter("scroll_speed"),
				#0.0, 0.1
			#)

func _ready() -> void:
	value = 0.0
	$ScrollTexture.hide()
