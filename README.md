# Tree
The evergreen way to describe Roblox instance trees and validate instances with.

# Why Tree?

In game development, particularly Roblox, it's crucial to verify that incoming
instances adheres to a specific structure. For instance, in genres like
JToH-esque towers and flood escape, kits must conform to a set structure to
function correctly. For example, games like Tria.OS allows playtesting of
user-created maps, but only if they comply with the expected structure.

Tree aims to simplify this by allowing you to declaratively describe an instance
tree, returning a describer function to check instances against.

It's better if you see it in practice:

```lua
-- Without Tree
local function validate(instance: Instance): boolean
    local client_objects = instance:FindFirstChild("ClientObjectScripts")
    local obby = instance:FindFirstChild("Obby")
    local frame = instance:FindFirstChild("Frame")

    return instance.ClassName == "Folder"
        and client_objects
        and client_objects.ClassName == "Folder"
        and obby
        and obby.ClassName == "Folder"
        and frame
        and frame.ClassName == "Model"
end

-- With Tree
local validate = Tree.describe {
    class_name = "Folder",
    children = {
        ClientObjectScripts = Tree.class_of("Folder"),
        Obby = Tree.class_of("Folder"),
        Frame = Tree.class_of("Model")
    }
}

-- Tree provides a helpful error message if the description fails
local ok, reason = validate(data.TowerObj)
if not ok then
    return warn("Failed to get tower;", reason)
else
    return print("Got tower!")
end
```

# Installation
