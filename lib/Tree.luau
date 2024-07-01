--!strict
--!nolint LocalShadow

export type Describer = (instance: Instance?) -> (boolean, string?)

local Tree = {}

local function get_property(instance: Instance, property: string): any
	return (instance :: any)[property]
end

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

function Tree.of_class(class_name: string): Describer
	return function(instance: Instance?): (boolean, string?)
		if not instance then
			return false, "Expected an instance, got nil"
		end
		if class_name ~= instance.ClassName then
			return false, `Expected instance of class "{class_name}", got "{instance.ClassName}"`
		end
		return true, nil
	end
end

function Tree.which_is_a(class_name: string): Describer
	return function(instance: Instance?): (boolean, string?)
		if not instance then
			return false, "Expected an instance, got nil"
		end
		if not instance:IsA(class_name) then
			return false, `Expected instance which is a "{class_name}", got "{instance.ClassName}"`
		end
		return true, nil
	end
end

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
