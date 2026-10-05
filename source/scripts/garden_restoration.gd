extends RefCounted
## Presentation uses existing repair IDs; it never alters or resets saved progress.
const ZONES=[Vector4(.04,.015,.37,.36),Vector4(.29,.73,.37,.27),Vector4(.385,.32,.285,.33),Vector4(.625,.045,.37,.415),Vector4(.005,.39,.405,.465),Vector4(.68,.445,.32,.555)]
const REPAIR_IDS=[0,0,1,2,3,4]

static func weights(garden: Dictionary) -> PackedFloat32Array:
	var result:=PackedFloat32Array()
	for id in REPAIR_IDS:
		var completed:=false
		for saved_id in garden.get("repairs",[]):
			if int(saved_id)==id: completed=true; break
		result.append(1.0 if completed else 0.0)
	return result

static func apply(material: ShaderMaterial, garden: Dictionary) -> void:
	material.set_shader_parameter("zones",PackedVector4Array(ZONES))
	material.set_shader_parameter("restorations",weights(garden))
	material.set_shader_parameter("complete",1.0 if garden.get("repairs",[]).size()==5 else 0.0)
