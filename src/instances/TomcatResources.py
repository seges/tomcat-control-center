import xml.etree.ElementTree as ET
from xml.etree import ElementTree
from os.path import sep
import csv
import os
import os.path
import sys
import shutil

# instance and name must be the first two items
resource_keys = { "db": [ "instance", "name", "initialSize", "maxActive", "maxIdle", "minIdle", "defaultAutoCommit", "driverClassName", "fairQueue", "jmxEnabled", "logAbandoned", "maxWait", "minEvictableIdleTimeMillis", "username", "password", "removeAbandoned", "removeAbandonedTimeout", "testOnBorrow", "testOnReturn", "testWhileIdle", "timeBetweenEvictionRunsMillis", "type", "url", "useEquals", "validationQuery", "factory", "jdbcInterceptors" ], "mail": [ "instance", "name", "mail.smtp.auth","mail.smtp.host","mail.smtp.port","mail.smtp.user","mail.user","username","mail.smtp.password","mail.password", "password","mail.smtp.socketFactory.class","mail.smtp.starttls.enable", "factory" ], "rmi": [ "instance", "name", "port", "factory" ], "env": [ "instance", "name", "value" ], "connector": [ "instance", "shutdown", "http" ] }

resource_types = { "db": ["javax.sql.DataSource", "javax.sql.XADataSource"], "mail" : ["javax.mail.Session"], "rmi" : ["java.rmi.registry.Registry"], "mq": ["com.sun.messaging.Queue"], "env": ["java.lang.String"] }

# "attrs" contains static, additional attributes to the tag
resource_tags = { "db" : {"tag": "Resource", "attrs": {"auth": "Container"}}, "mail": {"tag": "Resource", "attrs": {"auth": "Container"}}, "rmi": {"tag": "Resource", "attrs": {"auth": "Container"}}, "mq": {"tag": "Resource", "attrs": {"auth": "Container"}}, "env": {"tag": "Environment"} }

class CommentedTreeBuilder(ElementTree.TreeBuilder):
	def comment(self, data):
		self.start(ElementTree.Comment, {})
		self.data(data)
		self.end(ElementTree.Comment)

def walk_instances(resource_type = "db", mode = None):
	print("Resource type is " + resource_type)
	if resource_type is not None and resource_type.startswith("env"):
		tag = "Environment"
	else:
		tag = "Resource"

	if mode == "update":
		csvFile = open("resources-" + resource_type + ".csv", "rb")
		reader = csv.reader(csvFile)

		result = {}
		
		oldInst = None
		first = True
		for row in reader:
			print("row = " + str(row))
			if first:
				first = False
				continue
			if len(row) != len(resource_keys[resource_type]):
				print("incomplete row ( " + str(len(row)) + " vs " + str(len(resource_keys[resource_type])) + " ) " + str(row))
				continue
			inst = row[0]
			if oldInst is None:
				oldInst = inst
				items = {}

			if oldInst != inst:
				print("writing " + oldInst + " with " + str(items))
				result[oldInst] = items
				items = {}
	
			item = {}
			i = 0

			for key in resource_keys[resource_type]:
				# start after the name
				if i >= 2:
					item[key] = row[i]
				i += 1
			
			#if oldInst == inst:
			items[row[1]] = item
			oldInst = inst

		print("last writing " + str(oldInst) + " with " + str(items))
		result[oldInst] = items

		#return
		print("result = " + str(result))
		execute_fn = update_tomcat_pool
		create_fn = create_tomcat_pool
	else:
		csvFile = open("resources-" + resource_type + ".csv", "wb")
		result = csv.writer(csvFile)
		result.writerow(resource_keys[resource_type])
		execute_fn = parse_tomcat_pool

	resource_keys[resource_type].pop(0)

	instances = os.listdir(".")

	for instance in instances:
		modified = False

		serverFile = check_config_presence(instance)
		if serverFile == "":
			continue
	
		print("processing " + instance)
		tree = ET.parse(serverFile, parser=ElementTree.XMLParser(target=CommentedTreeBuilder()))
		root = tree.getroot()
		globalNamingResource = root.find("GlobalNamingResources")

		for resource in globalNamingResource.findall(tag):
			#print("found resource " + str(resource))
			type = resource.get("type")
			if type is not None:
				possible = resource_types[resource_type]
				#if type == "javax.sql.DataSource" or type == "javax.sql.XADataSource":
				if type in possible:
					modified = execute_fn(resource_type, instance, result, resource)
			else:
				print(str(resource))

		if mode == "update" and create_fn is not None:
			resource_type_type = resource_types[resource_type][0]
			create_fn(resource_type_type, resource_tags[resource_type], instance, result, globalNamingResource)
			modified = True

		if mode == "update" and modified:
			update(tree, instance, serverFile)

def create_tomcat_pool(resource_type_type, resource_tag, instance, result, globalNamingResource):
	print("yet unprocessed resources: " + str(result))
	# resources not present - these need to be inserted
	resources = result[instance]

	for name, resource_attrs in resources.items():
		attrs = { "name" : name }
		if "attrs" in resource_tag:
			attrs.update(resource_tag["attrs"])
		attrs.update(resource_attrs)

		print("creating " + str(resource_tag["tag"]) + " with: " + str(attrs))
		ET.SubElement(globalNamingResource, resource_tag["tag"], attrs)	
			

def update(tree, instance, serverFile):
	# for test purposes
	#tree.write(instance + "-server.xml")
	# for real replacement of server.xml
	tree.write(serverFile + ".new")
	shutil.move(serverFile, serverFile + ".bak")
	shutil.move(serverFile + ".new", serverFile)

def parse_tomcat_pool(resource_type, instance, result, resource):
	item = [instance]
	for key in resource_keys[resource_type]:
		item.append(resource.get(key))
	result.writerow(item)

def update_tomcat_pool(resource_type, instance, result, resource):
	if instance not in result:
		print("No " + instance + " instance entry")
		return False
	items = result[instance]
	name = resource.get("name")
	datasource = items[name]
	if datasource is None:
		print("There is no such datasource " + name)
		return False
	
	modified = False
	for key in resource_keys[resource_type]:
		if key == "name":
			continue
		value = datasource[key]
		if value is None or value == "":
			print("There is no such value for key " + key + " in " + name)
			continue
		print("Setting resource " + key + " = " + value)
		resource.set(key, value)
		modified = True

	if modified:
		del items[name]
	
	return modified

def check_config_presence(instance):
	if not os.path.isdir(instance):
		return ""
	serverFile = instance + sep + "conf" + sep + "server.xml"

	if not os.path.isfile(serverFile):
		print(serverFile + " is not file")
		return ""

	return serverFile


def walk_connectors(resource_type = "connector", mode = None):
	if mode == "update":
		csvFile = open("resources-" + resource_type + ".csv", "rb")
		reader = csv.reader(csvFile)

		result = {}
		
		oldInst = None
		first = True
		for row in reader:
			print("row = " + str(row))
			if first:
				first = False
				continue
			if len(row) != len(resource_keys[resource_type]):
				print("incomplete row " + str(row))
				continue
			inst = row[0]
			if oldInst is None:
				oldInst = inst
				items = {}

			if oldInst != inst:
				print("writing " + oldInst + " with " + str(items))
				result[oldInst] = items
				items = {}
	
			i = 0

			for key in resource_keys[resource_type]:
				# start after the instance
				if i >= 1:
					items[key] = row[i]
				i += 1
			
			#if oldInst == inst:
			oldInst = inst

		print("last writing " + oldInst + " with " + str(items))
		result[oldInst] = items

		#print("result = " + str(result))
		#return
		prepare_fn = prepare_update_connector
		execute_fn = update_connector
	else:
		csvFile = open("resources-" + resource_type + ".csv", "wb")
		result = csv.writer(csvFile)
		result.writerow(resource_keys[resource_type])
		prepare_fn = prepare_read_connector
		execute_fn = read_connector

	resource_keys[resource_type].pop(0)

	instances = os.listdir(".")

	for instance in instances:
		modified = False

		serverFile = check_config_presence(instance)
		if serverFile == "":
			continue
		
		print("processing " + instance)
		tree = ET.parse(serverFile, parser=ElementTree.XMLParser(target=CommentedTreeBuilder()))
		root = tree.getroot()
		service = root.find("Service")

		item = []
		prepare_fn(root, instance, result, item)

		for resource in service.findall("Connector"):
			protocol = resource.get("protocol")
			#print("protocol", protocol)
			if protocol == "HTTP/1.1":
				modified = execute_fn(resource, result, instance, item)

		if mode == "update" and modified:
			update(tree, instance, serverFile)

def prepare_update_connector(root, instance, result, item):
	root.set("port", result[instance]["shutdown"])

def prepare_read_connector(root, instance, result, item):
	item.append(instance)
	item.append(root.get("port"))

def read_connector(resource, result, instance, item):				
	item.append(resource.get("port"))
	result.writerow(item)
	return False

def update_connector(resource, result, instance, item):
	resource.set("port", result[instance]["http"])
	return True

if __name__ == '__main__':
	#print dirname(sys.argv[0])
	args = sys.argv[1:]
	if len(args) == 1:
		if args[0] == "connector":
			walk_connectors(args[0])
		else:
			walk_instances(args[0])
	elif len(args) == 2:
		if args[0] == "connector":
			walk_connectors(args[0], args[1])
		else:
			walk_instances(args[0], args[1])
	else:
		walk_instances()

