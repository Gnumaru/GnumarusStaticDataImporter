#class_name GnumarusStaticDataImporterJsonDataEditorProperty
extends EditorProperty

var mjsontextlbl: Label = Label.new()
var mupdatebtn: Button = Button.new()
var mshouldupdate: bool = false


func _init() -> void:
	add_child(mupdatebtn)
	add_focusable(mupdatebtn)
	mupdatebtn.pressed.connect(update_btn_pressed)
	mupdatebtn.text = "Update view"

	add_child(mjsontextlbl)
	set_bottom_editor(mjsontextlbl)
	update_btn_pressed.call_deferred()


func update_btn_pressed() -> void:
	mjsontextlbl.text = JSON.stringify(get_edited_object()[get_edited_property()], " ")
