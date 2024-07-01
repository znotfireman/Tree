--!strict
--!nolint LocalShadow

--[[
	Copyright (c) 2024 znotfireman

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to
	deal in the Software without restriction, including without limitation the
	rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
	sell copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
	IN THE SOFTWARE.
]]

export type Describer = (instance: Instance?) -> (boolean, string?)

--[=[
	Provides methods to create descriptions of Roblox instance trees, and use it
	to validate other instances.

	@class Tree
]=]
local Tree = {}

local class_describer_cache: { [string]: Describer } = {}
local is_a_describer_cache: { [string]: Describer } = {}

local function get_property(instance: Instance, property: string): any
	return (instance :: any)[property]
end

--[=[
	Constructs and returns a describer given a description of an instance tree.
	Call the returned describer to validate instances.

	@param description -- The description of the instance tree.
	@return function -- A describer of the instance tree. If failed, returns an error reason as the second return value.
]=]
function Tree.new(description: {
	class_name: string?,
	is_a: string?,

	properties: { [string]: any }?,
	children: { [string]: Describer }?,
	attributes: { [string]: any }?,
}): Describer
	local class_name = description.class_name
	local is_a = description.is_a

	local properties = description.properties
	local children = description.children
	local attributes = description.attributes

	return function(instance: Instance?): (boolean, string?)
		if not instance then
			return false, "Expected an instance, got nil"
		end
		if class_name and instance.ClassName ~= class_name then
			return false, `Expected instance of class "{class_name}", got "{instance.ClassName}"`
		end
		if is_a and not instance:IsA(is_a) then
			return false, `Expected instance which is a "{is_a}", got "{instance.ClassName}"`
		end
		if attributes then
			local instance_attributes = instance:GetAttributes()
			for attribute, expected_value in pairs(attributes) do
				local real_value = instance_attributes[attribute]
				if not real_value then
					return false, `Expected attribute named "{attribute}"`
				end
				local expected_type = typeof(expected_value)
				local real_type = typeof(real_value)
				if expected_type ~= real_type then
					return false, `Attribute "{attribute}" expects type "{expected_type}", got type "{real_type}"`
				end
				if expected_value ~= real_value then
					local expected_value = tostring(expected_value)
					local real_value = tostring(real_value)
					return false, `Expected attribute {attribute} to be {expected_value}, got {real_value}`
				end
			end
		end
		if properties then
			for property, expected_value in pairs(properties) do
				local ok, real_value = pcall(get_property, instance, property)
				if not ok then
					return false, `Expected instance of class "{instance.ClassName}" to have property "{property}"`
				end
				local expected_type = typeof(expected_value)
				local real_type = typeof(real_value)
				if expected_type ~= real_type then
					return false, `Property "{property}" expects type "{expected_type}", got type "{real_type}"`
				end
				if expected_value ~= real_value then
					local expected_value = tostring(expected_value)
					local real_value = tostring(real_value)
					return false, `Expected property {property} to be {expected_value}, got {real_value}`
				end
			end
		end
		if children then
			for child_name, describer in pairs(children) do
				local child = instance:FindFirstChild(child_name)
				local ok, reason = describer(child)
				if not ok then
					if not child then
						return false, `Cannot find child named "{child_name}" in instance`
					end
					return false, `Cannot match child named "{child_name}"; {reason}`
				end
			end
		end
		return true, nil
	end
end

--[=[
	Constructs and returns a new describer that validates instances of the exact
	class name.

	@param class_name string -- The class name to validate with.
	@return function -- A describer of the class name. If failed, returns an error reason as the second return value.
]=]
function Tree.class_of(class_name: string): Describer
	local describer = class_describer_cache[class_name]
	if describer then
		return describer
	end
	local function describer(instance: Instance?): (boolean, string?)
		if not instance then
			return false, "Expected an instance, got nil"
		end
		if class_name ~= instance.ClassName then
			return false, `Expected instance of class "{class_name}", got "{instance.ClassName}"`
		end
		return true, nil
	end
	class_describer_cache[class_name] = describer
	return describer
end

--[=[
	Constructs and returns a new describer that validates instances which
	inherits from the given class name.

	@param class_name string -- The class name to validate with.
	@return function -- A describer of the class name. If failed, returns an error reason as the second return value.
]=]
function Tree.which_is_a(class_name: string): Describer
	local describer = is_a_describer_cache[class_name]
	if describer then
		return describer
	end
	local function describer(instance: Instance?): (boolean, string?)
		if not instance then
			return false, "Expected an instance, got nil"
		end
		if not instance:IsA(class_name) then
			return false, `Expected instance which is a "{class_name}", got "{instance.ClassName}"`
		end
		return true, nil
	end
	is_a_describer_cache[class_name] = describer
	return describer
end

--[=[
	Constructs and returns a new describer which passes if the instance is nil
	or the inner describer passes.

	@param inner_describer Describer -- The inner describer to validate with.
	@return function -- An optional describer of the inner describer. If failed, returns an error reason as the second return value.
]=]
function Tree.optional(inner_describer: Describer): Describer
	return function(instance: Instance?): (boolean, string?)
		if not instance then
			return true, nil
		end
		return inner_describer(instance)
	end
end

table.freeze(Tree)
return Tree
