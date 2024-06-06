#class_name GnumarusStaticDataImporterEditorInspectorPlugin
extends EditorInspectorPlugin

var GnumarusStaticDataImporterJsonDataEditorPropertyScript: GDScript
var maddondir: String
var moptions: Dictionary = {}


func _init(poptions: Dictionary) -> void:
	_print("_init()")
	maddondir = get_script().resource_path.get_base_dir()
	GnumarusStaticDataImporterJsonDataEditorPropertyScript = load(
		maddondir + "/JsonDataEditorProperty.gd"
	)


func _can_handle(pobject: Object) -> bool:
	return pobject is JSON


func _parse_property(
	pobject: Object,
	ptype: Variant.Type,
	pname: String,
	phint_type: PropertyHint,
	phint_string: String,
	pusage_flags: int,
	pwide: bool
) -> bool:
	if not pobject is JSON or not pname == "data" or not ptype == TYPE_NIL:
		return false
	_print("_parse_property()")
	#print()
	#print(pobject.data)
	add_property_editor(pname, GnumarusStaticDataImporterJsonDataEditorPropertyScript.new())
	#print()
	return true


func _print(pafter: Variant, pbefore: Variant = "") -> void:
	print("%s- GnumarusStaticDataImporterEditorInspectorPlugin: %s" % [pbefore, pafter])
