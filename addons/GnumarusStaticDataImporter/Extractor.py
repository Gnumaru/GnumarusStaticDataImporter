# converts several file types into json (for object data) or multitable tsv (for tabular data)
import json
import csv
import sys
import os


def processOdb(vInPath):
	import zipfile
	# vInPath = r'T:\sync\gdrive\ezrasLegacy\v4\g\godot\addons\GnumarusStaticDataImporter\Examples\SampleOdb.odb' # DELETEME
	vDirPath = vInPath+'_hsqldbdata'
	try:
		os.mkdir(vDirPath)
	except:
		pass
	vDbAbsPath = f'{vDirPath}/db'
	vOdb = zipfile.ZipFile(vInPath, 'r')
	for i in ['backup', 'data', 'log', 'properties', 'script']:
		try:
			vData = vOdb.read(f'database/{i}')
		except:
			continue
		with open(f'{vDbAbsPath}.{i}', 'wb') as vFile:
			vFile.write(vData)
	pass
	scriptDirAbsPath = os.path.dirname(__file__)
	jarName = 'hsqldb'
	jarVersion = '1.8.0.10'
	jarVersionedName = f'{jarName}-{jarVersion}.jar'
	hsqlJarAbsPath = f'{scriptDirAbsPath}/{jarVersionedName}'
	if not os.path.isfile(hsqlJarAbsPath):
		from urllib.request import urlretrieve
		url = (f'https://repo1.maven.org/maven2/org/hsqldb/hsqldb/{jarVersion}/{jarVersionedName}')
		urlretrieve(url, hsqlJarAbsPath)
	# os.system(f'java -classpath {hsqlJarAbsPath} {scriptDirAbsPath}/Extractor.java {vInPath}')

	os.chdir(scriptDirAbsPath)
	os.system(f'javac -encoding utf-8 {scriptDirAbsPath}/Extractor.java')
	os.system(f'java -classpath "{hsqlJarAbsPath};." Extractor {vInPath}')
	# java -cp .\hsqldb-1.8.0.10.jar .\Extractor.java .\Examples\SampleOdb.odb_hsqldbdata\db
	# import shutil
	# shutil.rmtree(vInPath)
	# print(vInPath+'.mttsv.tmp')


def main():
	# return processOdb(r'T:\sync\gdrive\ezrasLegacy\v4\g\godot\addons\GnumarusStaticDataImporter\Examples\SampleOdb.odb')
	vInPath = None

	if len(sys.argv) > 0:
		vInPath = sys.argv[1]

	if vInPath == None:
		return

	if not os.path.exists(vInPath):
		return

	if vInPath.endswith('.xml') or vInPath.endswith('.html') or vInPath.endswith('.htm') or vInPath.endswith('.graphml'):
		processXml(vInPath)

	elif vInPath.endswith('.yaml'):
		processYaml(vInPath)

	elif vInPath.endswith('.toml'):
		processToml(vInPath)

	elif vInPath.endswith('.hjson'):
		processHjson(vInPath)

	elif vInPath.endswith('.ods'):
		processOds(vInPath)

	elif vInPath.endswith('.xlsx'):
		processXlsx(vInPath)

	elif vInPath.endswith('.sqlite') or vInPath.endswith('.sqlite3'):
		processSqlite(vInPath)

	elif vInPath.endswith('.odb'):
		processOdb(vInPath)


def processSqlite(vInPath):
	import sqlite3
	vCon = sqlite3.connect(vInPath)
	vCur = vCon.cursor()
	vTableNames = [i[0] for i in vCur.execute('select name from sqlite_master')] # get table names
	vColumns = {}
	vOutPath=vInPath+'.mttsv.tmp'
	with open(vOutPath, 'wt', newline='', encoding='utf-8') as vFile:
		vFile.writelines(['multitable\n'])
		for iTableName in vTableNames:
			vFile.writelines([iTableName+'\n'])
			vCsvWriter = csv.writer(vFile, delimiter='\t', quoting=csv.QUOTE_MINIMAL)
			vCsvWriter.writerow([i[1] for i in vCur.execute(f'pragma table_info({iTableName})')])
			for iRow in vCur.execute(f'select * from {iTableName}'):
				vCsvWriter.writerow(iRow)
			vFile.write('\n')
	print(vOutPath)


def processXlsx(vInPath):
	import openpyxl # python -m pip install openpyxl # pip3 install openpyxl
	vWorkBook = openpyxl.load_workbook(vInPath, data_only=True) # data_only=True permite avaliar o valor das celulas com formula ao inves de retornar a string da formula
	vOutPath=vInPath+'.mttsv.tmp'
	with open(vOutPath, 'wt', newline='', encoding='utf-8') as vFile:
		vFile.writelines(['multitable\n'])
		for iSheetName in vWorkBook.sheetnames:
			vFile.writelines([iSheetName+'\n'])
			vSheet = vWorkBook[iSheetName]
			vCsvWriter = csv.writer(vFile, delimiter='\t', quoting=csv.QUOTE_MINIMAL)
			for iRow in vSheet.rows:
				vCsvWriter.writerow([iCell.value for iCell in iRow])
			vFile.writelines(['\n']) # ensure to write a final newline to separate tables
	print(vOutPath)


def processOds(vInPath):
	import pyexcel_ods3 # python -m pip install pyexcel-ods3 # pip3 install pyexcel-ods3
	vWorkBook = pyexcel_ods3.get_data(vInPath)
	vOutPath=vInPath+'.mttsv.tmp'
	with open(vOutPath, 'wt', newline='', encoding='utf-8') as vFile:
		vFile.writelines(['multitable\n'])
		for iSheetName in vWorkBook:
			vFile.writelines([iSheetName+'\n'])
			vSheet = vWorkBook[iSheetName]
			vCsvWriter = csv.writer(vFile, delimiter='\t', quoting=csv.QUOTE_MINIMAL) # uses QUOTE_MINIMAL to ensure that quotes are only used when the string contains the quoting character
			for iRow in vSheet:
				vCsvWriter.writerow(iRow)
			vFile.writelines(['\n']) # ensure to write a final newline to separate tables
	print(vOutPath)


def processHjson(vInPath):
	import hjson # python -m pip install hjson # pip3 install hjson
	vOutPath=vInPath+'.json.tmp'
	with open(vInPath, 'rt', encoding='utf-8') as ihjsonFile:
		vhjsonData = hjson.load(ihjsonFile)
		with open(vOutPath, 'wt', encoding='utf-8') as iJsonFile:
			json.dump(vhjsonData, iJsonFile, ensure_ascii=False, indent=1)
	print(vOutPath)


def processToml(vInPath):
	import toml # python -m pip install toml # pip3 install toml
	vOutPath=vInPath+'.json.tmp'
	with open(vInPath, 'rt', encoding='utf-8') as iTomlFile:
		vTomlData = toml.load(iTomlFile)
		with open(vOutPath, 'wt', encoding='utf-8') as iJsonFile:
			json.dump(vTomlData, iJsonFile, ensure_ascii=False, indent=1)
	print(vOutPath)


def processYaml(vInPath):
	import yaml # python -m pip install pyyaml # pip3 install pyyaml
	vOutPath=vInPath+'.json.tmp'
	with open(vInPath, 'rt', encoding='utf-8') as iYamlFile:
		vYamlData = yaml.load(iYamlFile, Loader=yaml.FullLoader)
		with open(vOutPath, 'wt', encoding='utf-8') as iJsonFile:
			json.dump(vYamlData, iJsonFile, ensure_ascii=False, indent=1)
	print(vOutPath)


def processXml(vInPath):
	import xml.dom.minidom # built into python, no pip package needed
	vOutPath=vInPath+'.json.tmp'
	with open(vInPath, 'rt', encoding='utf-8') as ixmlFile:
		vdom = xml.dom.minidom.parse(ixmlFile)
		vxmlData = domNodeToDictRecursive(vdom.documentElement)
		with open(vOutPath, 'wt', encoding='utf-8') as iJsonFile:
			json.dump(vxmlData, iJsonFile, ensure_ascii=False, indent=1)
	print(vOutPath)


def domNodeToDictRecursive(pElement):
	if not hasattr(pElement, 'tagName'):
		return pElement.data
	vdict = {}
	vdict['tag'] = pElement.tagName
	vdict['attributes'] = {}
	for iattribname in pElement.attributes.keys():
		vdict['attributes'][iattribname] = pElement.attributes[iattribname].firstChild.data
	vdict['children'] = []
	for ichild in pElement.childNodes:
		vdict['children'].append(domNodeToDictRecursive(ichild))
	if len(vdict['children']) < 1:
		del vdict['children']
	return vdict


if __name__ == '__main__':
	main()
