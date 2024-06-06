#class_name GnumarusStaticDataImporterEditorPlugin
@tool
extends EditorPlugin

static var sinstance: EditorPlugin = null
var sconfig: Dictionary = {}

var mimport_plugins: Array[EditorImportPlugin] = []  #[EditorImportPlugin]
var minspector_plugins: Array[EditorInspectorPlugin] = []  #[EditorInspectorPlugin]
var msupportedextensionscache: Dictionary = {}
var maddondir: String = ""


func _init() -> void:
	_print("_init()", "\n")
	sinstance = self
	maddondir = get_script().resource_path.get_base_dir()


func _enter_tree() -> void:
	_print("_enter_tree()")
	sconfig = JSON.parse_string(FileAccess.get_file_as_string(maddondir + "/config.json"))
	build_supported_extensions_cache()

	mimport_plugins = []
	minspector_plugins = []

	if check_dependencies():
		_print("All dependencies where fullfilled. Import plugin can be used normally")
		var v = load(maddondir + "/EditorImportPlugin.gd").new(sconfig)
		mimport_plugins.push_back(v)
		add_import_plugin(v)

		var vusecustominspector: bool = sconfig.get("use_custom_json_data_inspector", true)
		if vusecustominspector:
			v = load(maddondir + "/EditorInspectorPlugin.gd").new(sconfig)
			minspector_plugins.push_back(v)
			add_inspector_plugin(v)

	else:
		_print(
			"One or more dependencies where not fullfilled. Plugin will remain disabled. Please refer to the previous error messages"
		)


func _exit_tree() -> void:
	_print("_exit_tree()")
	sinstance = null
	for i in mimport_plugins:
		if is_instance_valid(i):
			remove_import_plugin(i)
	for i in minspector_plugins:
		if is_instance_valid(i):
			remove_inspector_plugin(i)
	mimport_plugins = []
	minspector_plugins = []


func check_dependencies() -> bool:
	var vstdout: Variant = [""]
	var vexitcode: int

	var vdependsonpython: bool = is_any_type_handled(
		[
			"yaml",
			"toml",
			"hjson",
			"xml",
			"html",
			"htm",
			"graphml",
			"mscx",
			"musicxml",
			"xlsx",
			"ods",
			"odb",
			"sqlite",
			"sqlite3",
			"odb",
			"midi"
		]
	)
	var vdependsonjava: bool = is_any_type_handled(
		[
			"odb",
			"h2db",
			"data",  # hsqldb
		]
	)
	# "derby"

	var vispythonavailable: bool = (
		OS.execute("python", PackedStringArray(["--version"]), vstdout) == OK
	)
	var vpythonversionoutput: String = "\n".join(PackedStringArray(vstdout)).replace("\r\n", "\n")
	var vpythonis3: bool = "ython 3" in vpythonversionoutput
	var vispyyamlavailable: bool = (
		OS.execute("python", PackedStringArray(["-c", "import yaml"]), vstdout) == OK
	)
	var vispytomlavailable: bool = (
		OS.execute("python", PackedStringArray(["-c", "import toml"]), vstdout) == OK
	)
	var vispyhjsonavailable: bool = (
		OS.execute("python", PackedStringArray(["-c", "import hjson"]), vstdout) == OK
	)
	var visopenpyxlavailable: bool = (
		OS.execute("python", PackedStringArray(["-c", "import openpyxl"]), vstdout) == OK
	)
	var vispyexcelods3available: bool = (
		OS.execute("python", PackedStringArray(["-c", "import pyexcel_ods3"]), vstdout) == OK
	)

	var visjavaavailable: bool = OS.execute("java", PackedStringArray(["--version"]), vstdout) == OK

	if vdependsonpython:
		if not vispythonavailable:
			_print(
				"Python 3 was not found. This plugin needs python to extract the data from the ods file. Please install Python 3 and add it to the path variable."
			)
			return false

		if not vpythonis3:
			_print(
				(
					"Python version was different from 3. This plugin needs python to extract the data from the ods file. Please install Python 3 and add it to the path variable. the output of python --version was \n%s\n"
					% vpythonversionoutput
				)
			)
			return false

		if is_any_type_handled("yaml") and not vispyyamlavailable:
			_print(
				'The pip package "pyyaml" is not installed. It is needed to extract data from yaml files. please install it with the command "python -m pip install pyyaml"'
			)
			return false

		if is_any_type_handled("toml") and not vispytomlavailable:
			_print(
				'The pip package "toml" is not installed. It is needed to extract data from toml files. please install it with the command "python -m pip install toml"'
			)
			return false

		if is_any_type_handled("hjson") and not vispyhjsonavailable:
			_print(
				'The pip package "hjson" is not installed. It is needed to extract data from hjson files. please install it with the command "python -m pip install hjson"'
			)
			return false

		if is_any_type_handled("xlsx") and not visopenpyxlavailable:
			_print(
				'The pip package "openpyxl" is not installed. It is needed to extract data from the xlsx files. please install it with the command "python -m pip install openpyxl"'
			)
			return false

		if is_any_type_handled("ods") and not visopenpyxlavailable:
			_print(
				'The pip package "pyexcel-ods3" is not installed. It is needed to extract data from the ods files. please install it with the command "python -m pip install pyexcel-ods3"'
			)
			return false

	return true


func is_any_type_handled(pfileextensions) -> bool:
	assert(pfileextensions is Array or pfileextensions is String)

	if not sconfig.get("extensions", null) is Array:
		sconfig.extensions = []

	if not pfileextensions is Array:
		pfileextensions = [pfileextensions]

	for ifileextension: String in pfileextensions:
		if ifileextension in msupportedextensionscache:
			return true

	return false


func build_supported_extensions_cache() -> void:
	if not sconfig.get("extensions", null) is Array:
		sconfig.extensions = []
	for i in sconfig.extensions:
		if i is String:
			msupportedextensionscache[i] = i


func _print(pafter: Variant, pbefore: Variant = "") -> void:
	print("%s- GnumarusStaticDataImporterEditorPlugin: %s" % [pbefore, pafter])


func get_option(poptionname: String, poptionsdct: Dictionary, pdefault: Variant = null) -> Variant:
	if not sconfig.get("override_import_options", null) is Dictionary:
		sconfig.override_import_options = {}

	if poptionname in sconfig.override_import_options:
		# if there is a global option override, use
		return sconfig.override_import_options[poptionname]

	if poptionname in poptionsdct:
		# if the options dict has a value, use
		return poptionsdct[poptionname]

	if not sconfig.get("default_import_options", null) is Dictionary:
		sconfig.default_import_options = {}

	if poptionname in sconfig.default_import_options:
		# if the file does not have that import option, use the default from the config file
		return sconfig.default_import_options[poptionname]

	var vconsts: Dictionary = (ImportOptions as Variant as Script).get_script_constant_map()
	var voptionvalue = poptionname + "_value"
	if voptionvalue in vconsts:
		# at last, if there is no default import option, use the default option value from the constants
		return vconsts[voptionvalue]

	# there should always be a constant for the default options. if there is not, this is a bug that should be fixed (or the option name was misspelled)
	assert(
		false,
		'either there is a missing constant defined for the option "%s" OR the option "%s" is mispelled'
	)
	return pdefault


enum Presets { DEFAULT }

enum ImporterType {
	dummy = 0,
	default = 1,
}

enum MultiTableParsingBehavior {
	never = 0,
	single_sheet_files_only = 1,
	always = 2,
}


class ImportOptions:
	# default import options values
	const preset_index: String = "preset_index"
	const preset_index_value: Presets = Presets.DEFAULT

	const import_method: String = "import_method"
	const import_method_value: ImporterType = ImporterType.default

	const perform_str_to_var_on_srings: String = "perform_str_to_var_on_srings"
	const perform_str_to_var_on_srings_value: bool = true

	const interpret_tabular_data_as_database: String = "interpret_tabular_data_as_database"
	const interpret_tabular_data_as_database_value: bool = true

	const multiple_tables_per_sheet: String = "multiple_tables_per_sheet"
	const multiple_tables_per_sheet_value: int = 0

	const debug_keep_temporary_files: String = "debug_keep_temporary_files"
	const debug_keep_temporary_files_value: bool = true

	const debug_print_parsed_value_before_saving: String = "debug_print_parsed_value_before_saving"
	const debug_print_parsed_value_before_saving_value: bool = false

	const debug_copy_saved_resource_alongside_temp_file: String = "debug_copy_saved_resource_alongside_temp_file"
	const debug_copy_saved_resource_alongside_temp_file_value: bool = false

	const use_custom_json_data_inspector: String = "use_custom_json_data_inspector"
	const use_custom_json_data_inspector_value: bool = true
