#class_name GnumarusStaticDataImporterEditorImportPlugin
@tool
extends EditorImportPlugin

static var sinstance: EditorImportPlugin = null

var maddondir: String = get_script().resource_path.get_base_dir()
var meditorplugin: EditorPlugin = load(maddondir + "/EditorPlugin.gd").sinstance
var mimportertype: int = meditorplugin.ImporterType.default
var mconfig: Dictionary = {}


func _get_preset_name(ppreset_index: int) -> String:
	match ppreset_index:
		meditorplugin.Presets.DEFAULT:
			return "Gnumarus data importer"
		_:
			return 'Gnumarus data importer (Unknown presset "%s")' % ppreset_index


func _init(pconfig: Dictionary = {}) -> void:
	_print("_init()")
	sinstance = self
	mconfig = pconfig


func _notification(pwhat: int) -> void:
	if pwhat == NOTIFICATION_PREDELETE:
		_print("_notification(NOTIFICATION_PREDELETE)\n")
		sinstance = null


func _get_importer_name() -> String:
	return "GnumarusStaticDataImporter"


func _get_visible_name() -> String:
	return "Gnumaru's Static Data Importer"


func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(mconfig.extensions)


func _get_save_extension() -> String:
	return "tres"


func _get_resource_type() -> String:
	# just returnint 'Resource' is already enough, but you can also return a more specific native class name or a script class_name or, if the script does not define a class name, you can return a script resource path
	return "JSON"


func _get_preset_count() -> int:
	return meditorplugin.Presets.size()


func _get_priority() -> float:
	# just slightly above the default priority so that we get over the default csv import
	return mconfig.priority


func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
	#enum propertyhint
	#https://docs.godotengine.org/en/latest/classes/class_%40globalscope.html#enum-globalscope-propertyhint
	#flags PropertyUsageFlags
	#https://docs.godotengine.org/en/latest/classes/class_%40globalscope.html#enum-globalscope-propertyusageflags
	match preset_index:
		meditorplugin.Presets.DEFAULT:
			return [
				{
					name = meditorplugin.ImportOptions.preset_index,
					default_value =
					roundi(meditorplugin.get_option(meditorplugin.ImportOptions.preset_index, {}))
				},  # Presets.DEFAULT
				# importer type. there are currently two types: dummy, wich imports an empty resource regardless of the input file, and default that tries to interpret the input file but saves an empty resource in case of parsing error
				#import_method importer_type
				{
					name = meditorplugin.ImportOptions.import_method,
					default_value =
					roundi(meditorplugin.get_option(meditorplugin.ImportOptions.import_method, {})),  # ImporterType.default
					property_hint = PROPERTY_HINT_ENUM,
					hint_string =
					(
						"Do Not Import:%s,Standard:%s"
						% [meditorplugin.ImporterType.dummy, meditorplugin.ImporterType.default]
					)
				},
				# everything that can't be parsed natively by godot is converted to json or csv using python. if this is true do not delete the intermediate files after the import process
				{
					name = meditorplugin.ImportOptions.debug_keep_temporary_files,
					default_value =
					meditorplugin.get_option(
						meditorplugin.ImportOptions.debug_keep_temporary_files, {}
					)
				},  # false
				# if true, every string will be evaluated using str_to_var, otherwise it will remain as a common string
				# TODO change to enum
				{
					name = meditorplugin.ImportOptions.perform_str_to_var_on_srings,
					default_value =
					meditorplugin.get_option(
						meditorplugin.ImportOptions.perform_str_to_var_on_srings, {}
					)
				},  # true
				# if false tabular data (csv, tsv, ods, xlsx) will be imported as a two dimensional string array. if true, each sheet of the input file will be treated as 'database table', the first row will be treated as the column names and de next rows as the table rows. the final import will be a dictionary[string,array] where the keys are the table names and the values are the row arrays, and the content of the row arrays will be objects where the keys are the column names and the values are the column value for that row.
				{
					name = meditorplugin.ImportOptions.interpret_tabular_data_as_database,
					default_value =
					meditorplugin.get_option(
						meditorplugin.ImportOptions.interpret_tabular_data_as_database, {}
					)
				},  # true
				# if true, when interpret_tabular_data_as_database is also true, will try to extract multiple tables per sheet. each table will be separated by an empty newline, and the table name will precede the column names
				{
					name = meditorplugin.ImportOptions.multiple_tables_per_sheet,
					default_value =
					roundi(
						meditorplugin.get_option(
							meditorplugin.ImportOptions.multiple_tables_per_sheet, {}
						)
					),  # Never:0
					property_hint = PROPERTY_HINT_ENUM,
					hint_string = "Never:0,Single Sheet Files Only:1,Always:2"
				}
			]
		_:
			return []


func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	if option_name == "import_method":
		return true
	if option_name == "preset_index":
		return false
	#if options.get('import_method', ImporterType.dummy) == ImporterType.dummy:
	#return false

	return true


func _get_import_order() -> int:
	return 0


func _import(
	psource_file: String,
	psave_path: String,
	poptions: Dictionary,
	pplatform_variants: Array[String],
	pgen_files: Array[String]
) -> Error:
	_print("importing "+psource_file.get_file(), '\n\n\n')
	match meditorplugin.get_option(meditorplugin.ImportOptions.import_method, poptions):
		meditorplugin.ImporterType.default:
			return import_default(
				psource_file, psave_path, poptions, pplatform_variants, pgen_files
			)

	return import_dummy(psource_file, psave_path, poptions, pplatform_variants, pgen_files)


func import_dummy(
	psource_file: String,
	psave_path: String,
	poptions: Dictionary,
	pplatform_variants: Array[String],
	pgen_files: Array[String]
) -> Error:
	return save(null, psave_path, poptions, psource_file)


func import_default(
	psource_file: String,
	psave_path: String,
	poptions: Dictionary,
	pplatform_variants: Array[String],
	pgen_files: Array[String]
) -> Error:
	var vinputtmpfpath: String = extract_data(psource_file)
	var vdeletetempfiles: bool = not meditorplugin.get_option(
		meditorplugin.ImportOptions.debug_keep_temporary_files, poptions
	)

	var vparseddata: Variant
	if ".json" in vinputtmpfpath:
		var vjsonstr: String = FileAccess.get_file_as_string(vinputtmpfpath)
		var vjson: JSON = JSON.new()
		var verror: Error = vjson.parse(vjsonstr)

		if verror != OK:
			_print(
				(
					'Failed to parse json at line "%s" with message "%s". saving empty resource'
					% [vjson.get_error_line(), vjson.get_error_message()]
				)
			)
			save(null, psave_path, poptions, psource_file)
			return verror
		vparseddata = vjson.data

	else:  # mttsv
		vparseddata = Array()  #[], TYPE_PACKED_STRING_ARRAY, &'', null)
		var vdelim = "," if ".csv" in psource_file else "\t"
		var vfile: FileAccess = FileAccess.open(vinputtmpfpath, FileAccess.READ)

		while not vfile.eof_reached():
			var vrow = Array(vfile.get_csv_line(vdelim))
			var vsize = vrow.size()
			if vsize > 0 and vrow[vsize - 1].is_empty():
				vrow.pop_back()  # pra evitar que quaisquer tabs no final afetem a importacao
			vparseddata.push_back(vrow)

		if meditorplugin.get_option(
			meditorplugin.ImportOptions.interpret_tabular_data_as_database, poptions
		):
			var vdb: Dictionary = {}
			var vstate: int = 0
			var vcurtablename: String
			var vcurtablekeys: Array

			for irowidx in range(1, vparseddata.size()):  # start with 1 because 0 is the mandatory 'multitable' line
				if vstate == 0:  # expecting table name
					var vrow: Array = vparseddata[irowidx]
					if vrow.size() < 1 or (vrow.size() == 1 and vrow[0].is_empty()):
						vstate = 0
					else:
						vstate += 1
						vcurtablename = vparseddata[irowidx][0]
						vdb[vcurtablename] = []

				elif vstate == 1:  # expecting column names
					var vrow: Array = vparseddata[irowidx]
					if vrow.size() == 1 and vrow[0].is_empty():
						pass
					else:
						vstate += 1
						vcurtablekeys = vrow

				elif vstate == 2:  # expecting row data
					var vrow: Array = vparseddata[irowidx]
					if vrow.size() < 1 or (vrow.size() == 1 and vrow[0].is_empty()):
						vstate = 0
					else:
						var vdct: Dictionary = {}
						for ikeyidx in vcurtablekeys.size():
							if ikeyidx < vrow.size():
								vdct[vcurtablekeys[ikeyidx]] = vrow[ikeyidx]
							else:
								pass # this should not be possible
						vdb[vcurtablename].push_back(vdct)
			vparseddata = vdb

	if vdeletetempfiles and vinputtmpfpath != psource_file:
		# delete tmp file right after getting content
		OS.move_to_trash(vinputtmpfpath)
		if psource_file.ends_with(".odb"):
			OS.move_to_trash(psource_file + "_hsqldbdata")

	var verrorcode: int
	if meditorplugin.get_option(meditorplugin.ImportOptions.perform_str_to_var_on_srings, poptions):
		vparseddata = str_to_var_recursive(vparseddata)

	verrorcode = save(vparseddata, psave_path, poptions, psource_file)
	if verrorcode != OK:
		_print("Failed to save resource with error code %s " % verrorcode)

	return verrorcode


func str_to_var_recursive(pinput: Variant) -> Variant:
	if pinput is Array:
		for iidx: int in pinput.size():
			pinput[iidx] = str_to_var_recursive(pinput[iidx])
	elif pinput is Dictionary:
		for ikey: Variant in pinput:
			pinput[ikey] = str_to_var_recursive(pinput[ikey])
	elif pinput is String:
		# if it is not a string, try to interpret
		var v: Variant = str_to_var(pinput)
		if typeof(v) == TYPE_NIL and pinput.length() > 0:
			# if interpreting fails, use as string
			return pinput
		# else, if interpreting succeeds, use as interpreted
		return v

	#else, in any other case, return input as is
	return pinput


func extract_data(psource_file: String) -> String:
	var vextensiondir: String = (
		ProjectSettings.globalize_path(get_script().resource_path).get_base_dir() + "/"
	)

	if (
		psource_file.ends_with(".csv")
		or psource_file.ends_with(".tsv")
		or psource_file.ends_with(".json")
	):
		return psource_file

	else:
		var vhjsontojsonpypath: String = vextensiondir + "Extractor.py"
		var vhjsonglobalpath: String = ProjectSettings.globalize_path(psource_file)
		var vargs: PackedStringArray = PackedStringArray([vhjsontojsonpypath, vhjsonglobalpath])
		var vstdoutarr: Array = []
		var vexitcode: Error = OS.execute("python", vargs, vstdoutarr, true)

		if vexitcode != 0:
			_print(
				(
					"there was an error processing the file %s. The exit code is %s and the output is the following:\n\n========================================\n%s\n========================================\n\n"
					% [psource_file, vexitcode, vstdoutarr[0].replace("\\n", "\n")]
				)
			)
			return ""

		var vtmpfileglobalpath: String = vstdoutarr[0].strip_edges()
		return vtmpfileglobalpath

	# godot already parses json
	return psource_file


func save(pdata: Variant, psave_path: String, poptions: Dictionary, psource_file: String) -> Error:
	var vjson: JSON = JSON.new()
	vjson.data = pdata
	var vsavepath: String = psave_path + "." + _get_save_extension()
	if meditorplugin.get_option(
		meditorplugin.ImportOptions.debug_print_parsed_value_before_saving, poptions
	):
		var v = "=".repeat(50)
		print("\n%s\n%s\n%s\n" % [v, vjson.data, v])
	var verr: Error = ResourceSaver.save(vjson, vsavepath)
	if verr == OK:
		_print(psource_file.get_file()+" imported successfully")
		if (
			meditorplugin.get_option(
				meditorplugin.ImportOptions.debug_copy_saved_resource_alongside_temp_file, poptions
			)
		):
			DirAccess.copy_absolute(
				ProjectSettings.globalize_path(vsavepath),
				ProjectSettings.globalize_path(psource_file + ".tres.tmp")
			)
	else:
		_print("there was an error while saving the import results of "+psource_file.get_file())
	return verr


func _print(pafter: Variant, pbefore: Variant = "") -> void:
	print("%s- GnumarusStaticDataImporterEditorImportPlugin: %s" % [pbefore, pafter])
