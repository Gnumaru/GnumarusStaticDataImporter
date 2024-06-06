# Gnumaru's Static Data Importer

A Godot editor addon for importing data files like yaml, toml, xml, xlsx, ods, sqlite and others as static data

### **TL;DR**: Automatically import object data files (yaml, json and the like) as nested dictionaries and tabular data files (tsv, xlsx and the like) as a structure mimicking a database.

### **WARNING**: This add-on has system prerequisites and does not work without them, read the "Prerequisites" section for further details.

# Installation

- Download the addon from the editor integrated asset library
  - Or, instead of using the editor integrated asset library, download a bleeding edge zipfile from github at https://github.com/Gnumaru/GnumarusStaticDataImporter/archive/refs/heads/master.zip and extract the GnumarusStaticDataImporter folder into your project's "addons" directory
  - Or, if you like using git, clone the repository with "git clone https://github.com/Gnumaru/GnumarusStaticDataImporter.git" and copy the GnumarusStaticDataImporter folder into your project's "addons" directory
- Enable the addon in Project > Project Settings > Plugins > Gnumaru's Static Data Importer

# Supported file types

The complete list of supported file extensions are: json, hjson, yaml, toml, xml, html, htm, graphml, csv, tsv, xlsx, ods, odb, sqlite and sqlite3.

Since editor import plugins uses simple file extensions instead of segmented file extensions or trying to detect the file type, this add-on may use one ore more different extension (like "sqlite" and "sqlite3") to import the same file type (an sqlite 3 database file).

# General Usage

After installing and enabling the add-on, add a file of any of the supported file types to your project, and it will be automatically imported every time the file changes. All of them will be imported as a JSON resource for it allows to easily wrap any kind of data into a resource without creating helper scripts just for this purpose. The parsed data will be available in the "data" property of the json resource object, and it will generally be a nested dictionary structure for object data files like json or yaml, or a "Dictionary[String, Array[Dictionary[String, Variant]]]" for tabular data files like csv and xlsx.

To later use the imported file, use the load and preload functions, which will return a JSON Resource. As any resource saved under res://, this data is meant to be non persistant, so bear in mind that any changes made to the data will be lost as soon as the resource is unloaded, that is, when you close the game. You may, however, change the data and save it externally on "user://" or any other file path where the game has permissions to write to and later retrieve the altered data from there. But this add-on does not support writing data changes back to the original files.

Unfortunately due to an editor limitation (at least up to godot 4.2) it is not possible to inspect the contents of the parsed file in the inspector (the data property will wrongly show always as "null") but the import process creates temporary files that are just plaintext files and can be opened and inspected to view the imported data. For example, importing a "data.yaml" file will generate a temporary json file file named "data.yaml.json.tmp" and importing a "data.xlsx" file will create a temporary tsv file named "data.xlsx.mttsv.tmp". Both can be opened in any text editor. These temporary files are not deleted by default but you can automatically delete them while importing by setting the "keep temporary files" import option to false.

# Usage Highlights

There are two specially useful usage scenarios for this add-on: Importing yaml files containing nested heterogeneous data and importing strictly formatted xlsx containing database like data.

With yaml you are able to type much faster and create much more readable files than with json because you don't need to type: Quotes around strings; comas separating key-value pairs; square brackets on arrays; curly brackets on dictionaries. You could, for example, write very readable dialog data using yaml.

<pre>
- speech: hi!

- id: 2
  speech: Do you think I'm pretty?
  answers:

  - text: Of course!
    goto: 3

  - text: Nope!
    goto: 2

  - text: (run away!)
    quit: true

- id: 3
  speech: Thanks!
  quit: true
  answers:

  - text: You're welcome!
</pre>

Or a bit more compact, but still valid yaml:

<pre>
- speech: hi!

- id: 2
  speech: Do you think I'm pretty?
  answers:
  - {text: Of course!, goto: 3}
  - {text: Nope!, goto: 2}
  - {text: (run away!), quit: true}

- id: 3
  speech: thanks!
  quit: true
  answers: {text: You're welcome!}
</pre>

<br>

And with xlsx and ods you are able to easily write tabular data that would be too cumbersome to write in any plain text format, even csv. You can also leverage all the features of your spreadsheet editor to author your data the easiest way possible. For example, you could have an "enemies" table with the health, strength, experience and gold columns, and use functions to calculate experience and gold based on health and strength. You could also have a table "player" containing default player stats and calculate the enemies health and strength based on the player stats. This kind of flexibility would be impossible with csv or json. And as a bonus you can style the spreadsheet however you want, set colors, different font types and font sizes, change column width and row height, in order to have more readable data, and after importing you will have just plain data to work with.

# Prerequisites

This add-on has some system prerequisites depending on the file type you are going to import (you can disable the ones you don't want):

1) All types except json, csv and tsv require python 3.
1) yaml requires "pyyaml" pip package.
1) toml requires "toml" pip package.
1) hjson requires "hjson" pip package.
1) xlsx requires "openpyxl" pip package.
1) ods requires "pyexcel_ods3" pip package.
2) odb requires java >= 8 and the jdbc hsqldb driver (a .jar file). The driver is downloaded automatically. odb import is disabled by default, you have to enable it by editing the config.json file.

Upon activating the add-on it will check for every dependency according to the handled file types. If there is at least one dependency not satisfied, it will not register the import plugins. You can either install the dependencies or remove the file types you do not want the add-on to handle, editing the config.json file and removing supported file extensions in the "extensions" array.

# Imported Data Format

File types containing object data (json, hjson, yaml, toml, xml, html, graphml) are parsed into a nested dictionary structure. Xml style markup language files (html, xml, graphml) uses a dictionary similar to the json example below:

<pre>
{"tag": "my-xml-tag",
 "attributes": {"a": "1", "b": "2", "c": "3"},
 "children": [
    "raw text here",
    {"tag": "an-empty-tag", "attributes": {}, "children": []},
    "more raw text here"}
</pre>

File types containing tabular data (csv, tsv, xlsx, ods, odb, sqlite) are parsed either as a dictionary mapping sheet names to an array of dictionaries or optionally as two-dimensional string arrays. Sheet names are the spreadsheet names in xlsx/ods, the table names in sqlite/odb, an empty string in csv and tsv and embedded table names when using a multitable csv/tsv (read about multitable below).

When interpreting csv/tsv as a database, you can store multiple tables in the same file **IF**:

1) The first line contains only the string "multitable" without quotes followed by a newline
2) every table is preceded by a line containing only the table name
3) every table has two newlines separating each other

For example:

<pre>
multitable
person
id,name,age
1,alice,20
2,bob,30

friends_rel
id_person_from,id_person_to
1,2
2,1
</pre>

Parsing tabular data as a two-dimensional string array has no requisites, but parsing as a an array of dictionaries imposes several restrictions.

- You cannot have more columns in a record than the quantity of column names, the extra columns will be discarded.
- You cannot have more than one column with the same name, the parser does not try to be smart, only the last value for columns with identical names will be kept.
- The line break usage needs to be precise. Exactly one line break after each line and exactly two line breaks after each table (in case of multitable csv/tsv). The amount of line breaks at the end of the file doesn't matter.

For any file type, be it object data or tabular data, you can tell the importer to interpret every string using str_to_var by setting the "perform str to var" import option to true, so that if you have a string value like "Color(1,0,0,1)" it will be parsed as the actual "Color" variant for the color red, not a "String" variant containing the text "Color(1,0,0,1)"

# Configuration

Besides the import options for each imported file, this add-on is configurable using the config.json file. There you can change default import options or general add-on options like the import plugin priority. Please note that changing import plugin options like priority or the supported file extensions list only take effect after restarting godot (reloading the add-on should suffice, but I have already faced a scenario where it does not).

# Usage Examples

Godot makes it very easy to define custom resource scripts, create resource instances and edit them in the inspector. But there may be valid reasons for storing and consuming data in non resource files, specially common file types like json or file types that can be richly manipulated by other applications like xlsx and graphml. Some examples are:

- You just need a raw value for something. Then you can create a json file and write down your string/bool/number/null/array/dictionary there. In json any value is a valid root value, thus a text file containing just a quoted string is a valid json file and will be imported successfully.
- You need a uniform array or dictionaries with several items, each one a dictionary with two or more keys. Editing arrays and dictionaries in the inspector, specially dictionaries, can get quite tedious, specially for many items. If you're using a plain text file like json you can create a single item, copy and paste several times and quickly edit all of them.
- You need a non-uniform nested dictionary structure. Editing dictionaries in godot is cumbersome. Typing all the double quotes in json is a sore. So you can just use yaml, and it becomes quite easy to the eye and quick to the fingers to type a deeply nested structure.
- You need very structured data, like a database. Just use csv or xlsx and input all your data in a very organized way. If you use xlsx you can style your sheet however you want and just the data get exported to godot.
- You have strongly typed relational data that needs consistency. Then you can use an embedded database like sqlite or libreoffice's odb (which uses hsqldb under the hood) and have all the strong typing and ensured consistency that a relational database offer.
- You have dynamic data dependency and transformation, like the experience and gold calculation mentioned in the highlights section. Then you use xlsx/ods and make most of your data calculated over other data in the spreadsheet.

# Example Data

There is an Examples folder in the addon directory with several example files. You can play with them and check the import results for them. After you're done, you can just delete the entire Examples folder.

# Troubleshooting and Support

Under the hood this addon uses python or java to extract data from all files not natively supported by godot and convert and save all this data to temporary files containing plain json (for object data) or tsv (for tabular data). If the subprocess execution goes wrong the addon will print the error output to the console so you can see what went wrong. Even if the suprocess execution succeeds it may be that you could get unexpected results. If keep on the "keep temporary files" import option you can open the temporary file and see if the extracted data was not extracted and saved as it was meant to. Even if the temporary file seems right but the data doesn't, you can turn on the "debug print parsed value before saving" in order to print to the console the value that will be saved or turn on the "debug copy saved resource alongside temp file" import option. This will copy the saved resource file (the one that gets saved to .godot/import/) alongside the converted tmp file. For example, if you turn on all these debug options, besides printing the value to the console, while converting, for example, the SampleYaml.yaml file, you will get in the same directory a SampleYaml.yaml.json.tmp and a SampleYaml.yaml.tres.tmp. Opening this tres.tmp is the exact source of truth. If it contains your data, then the extraction was undoubtedly successfull. But in case of any errors, please, fill a bug report with sample data if something occurs to you.

I'm using this add-on in my own projects so you can expect me to update bug-fixes or improvements while I'm using it myself and stumble uppon problems or things I would like to improve. But please feel free to report bugs and feature requests.
