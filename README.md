<img
    src="./gh-assets/wordmark-dark.svg#gh-dark-mode-only"
    alt="Tree"
    width="250">
<img
    src="./gh-assets/wordmark-light.svg#gh-light-mode-only"
    alt="Tree"
    width="250">

The evergreen way to describe Roblox instance trees and validate instances with.

# Why Tree?

In game development, particularly Roblox, it's crucial to verify that incoming
instances adheres to a specific structure. For instance, in genres like
JToH-esque towers and flood escape, kits must conform to a set structure to
function correctly. For example, games like Tria.OS allows playtesting of
user-created maps, but only if they comply with a given structure.

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

## Install via Roblox

Tree can be installed as a Roblox model. Simply grab the latest release from
[the release page.](https://github.com/znotfireman/Tree/releases)

## Install via Wally

Tree can be installed through [Wally](https://wally.run/), simply append this to
your `wally.toml` file:

```toml
[dependencies]
tree = "znotfireman/tree@0.1.0"
```

## Install via Source

Tree is distribued as a single module. Thus, you can install it by obtaining
[its source code](https://raw.githubusercontent.com/znotfireman/Tree/main/lib/Tree.luau)
to a new `Tree.luau` file.

# API

```lua
type Describer = (Instance: instance?) -> (boolean, string?)
```

A function that, given an instance, validates that it matches an instance tree
description. Returns if the instance matches the description, and an error
message if it fails.

```lua
function Tree.new(description: {
    class_name: string?,
    is_a: string?,

    properties: { [string]: any }?,
    children: { [string]: Describer }?,
    attributes: { [string]: any }?,
}): Describer
```

Constructs and returns a new describer given an instance description:

- If `class_name` is specified, validates that the class name of the instance
  exactly matches the given class name. Internally compares both class names.
- If `is_a` is specified, validates that the instance inherits from the given
  class name. Internally calls `:IsA()` with the given class name.
- If `properties` is specified, every property provided will be checked against
  the instance with the expected value.
- If `children` is specified, every child provided will have its describer
  checked with the instance's real child.
- If `attributes` is specified, every attribute provided will be checked against
  the instance with the expected value.

```lua
function Tree.class_of(class_name: string): Describer
```

Constructs and returns a new describer that matches an instance which is the
exact provided class name.

```lua
function Tree.which_is_a(class_name: string): Describer
```

Constructs and returns a new describer that matches an instance which inherits
from the provided class name.

```lua
function Tree.optional(inner_describer: Describer): Describer
```

Constructs and returns a new describer that allows `nil` instances. If such an
instance exists, it is ran through the provided inner describer.

# License

MIT License

Copyright (c) 2024 znotfireman

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
