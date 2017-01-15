--[[
This file is part of toml. It is subject to the licence terms in the COPYRIGHT file found in the top-level directory of this distribution and at https://raw.githubusercontent.com/pallene-modules/toml/master/COPYRIGHT. No part of toml, including this file, may be copied, modified, propagated, or distributed except according to the terms contained in the COPYRIGHT file.
Copyright © 2015 The developers of toml. See the COPYRIGHT file in the top-level directory of this distribution and at https://raw.githubusercontent.com/pallene-modules/toml/master/COPYRIGHT.
]]--


local halimede = require('halimede')
local toml = require('toml')
local TOML = toml.TOML
local assert = halimede.assert
local Node = halimede.moduleclass('Node')
local FileHandleStream = halimede.io.FileHandleStream


module.static.parseFromStringPathOrStandardIn = function(stringPathOrHyphen, description, strict)
	assert.parameterTypeIsString('stringPathOrHyphen', stringPathOrHyphen)
	assert.parameterTypeIsString('description', description)
	assert.parameterTypeIsBoolean('strict', true)
	
	local tomlString = FileHandleStream.readEitherStandardInOrFileContentsIntoString(stringPathOrHyphen, description)
	return Node.parseFromString(tomlString, strict)
end

module.static.parseFromString = function(tomlString, strict)
	assert.parameterTypeIsString('tomlString', tomlString)
	assert.parameterTypeIsBoolean('strict', strict)
	
	return Node:new(TOML.parse(tomlString, {strict = strict}), '')
end

function module:initialize(tomlTable, parentPath)
	assert.parameterTypeIsTable('tomlTable', tomlTable)
	assert.parameterTypeIsString('parentPath', parentPath)
	
	self.tomlTable = tomlTable
	self.parentPath = parentPath
end

function module:_concatenateNameWithParentPath(name)
	if self.parentPath == '' then
		return name
	else
		return self.parentPath .. '.' .. name
	end
end

function module:stringOrDefault(name, commandLineOptionNameOrFilePathString, default)
	assert.parameterTypeIsString('name', name)
	assert.parameterTypeIsString('commandLineOptionNameOrFilePathString', commandLineOptionNameOrFilePathString)
	assert.parameterTypeIsString('default', default)
	
	local value = self.tomlTable[name]
	if value == nil then
		return default
	end
	if type(value) ~= 'string' then
		exception.throw("'%s' does not contain a %s string", commandLineOptionNameOrFilePathString, self:_concatenateNameWithParentPath(name))
	end
end

function module:table(name, commandLineOptionNameOrFilePathString)
	assert.parameterTypeIsString('name', name)
	assert.parameterTypeIsString('commandLineOptionNameOrFilePathString', commandLineOptionNameOrFilePathString)
	
	local table = self.tomlTable[name]
	
	if table == nil then
		exception.throw("'%s' does not contain a %s definition", commandLineOptionNameOrFilePathString, self:_concatenateNameWithParentPath(name))
	end
	
	if type(table) ~= 'table' then
		exception.throw("'%s' does not contain a %s definition as a table", commandLineOptionNameOrFilePathString, self:_concatenateNameWithParentPath(name))
	end
	
	return table
end

function module:node(name, commandLineOptionNameOrFilePathString)
	local table = self:table(name, commandLineOptionNameOrFilePathString)
	
	return Node:new(table, self:_concatenateNameWithParentPath(name))
end

function module:tableOfStringsOrEmptyIfMissing(name, commandLineOptionNameOrFilePathString)
	assert.parameterTypeIsString('name', name)
	assert.parameterTypeIsString('commandLineOptionNameOrFilePathString', commandLineOptionNameOrFilePathString)
	
	if self.tomlTable[name] == nil then
		return {}
	else
		return self:tableOfStrings(name, commandLineOptionNameOrFilePathString)
	end
end

function module:tableOfStrings(name, commandLineOptionNameOrFilePathString)
	local table = self:table(name, commandLineOptionNameOrFilePathString)
	
	local tableLength = #table
	local counter = 0
	for index, entry in ipairs(table) do
		if type(entry) ~= 'string' then
			exception.throw("'%s' %s entry index (one-based) %s is not a string", commandLineOptionNameOrFilePathString, self:_concatenateNameWithParentPath(name), index)
		end
		counter = counter + 1
	end
	if counter ~= tableLength then
		exception.throw("'%s' %s does not contain an array of strings", commandLineOptionNameOrFilePathString, self:_concatenateNameWithParentPath(name))
	end
	
	return table
end

