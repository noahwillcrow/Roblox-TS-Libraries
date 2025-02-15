-- Compiled with https://roblox-ts.github.io v0.2.14
-- August 11, 2019, 4:44 AM Central Daylight Time

local TS = _G[script];
local exports = {};
local validateTree;
function validateTree(object, tree, violators)
	if not (tree["$className"] ~= nil) or object:IsA(tree["$className"]) or violators then
		local whitelistedKeys = {
			["$className"] = true;
		};
		local _0 = object:GetChildren();
		for _1 = 1, #_0 do
			local child = _0[_1];
			local childName = child.Name;
			if childName ~= "$className" then
				local className = tree[childName];
				local _2;
				if (typeof(className) == "string") then
					_2 = child:IsA(className);
				else
					_2 = className and validateTree(child, className, violators);
				end;
				if _2 then
					whitelistedKeys[childName] = true;
				end;
			end;
		end;
		local matches = true;
		for value in pairs(tree) do
			if not (whitelistedKeys[value] ~= nil) then
				if violators then
					local fullName = object:GetFullName();
					violators[#violators + 1] = fullName .. "." .. tostring(value);
					matches = false;
				else
					return false;
				end;
			end;
		end;
		return matches;
	else
		return false;
	end;
end;
local yieldForTree = TS.async(function(object, tree)
	if validateTree(object, tree) then
		return object;
	else
		return TS.await(TS.Promise.new(function(resolve, reject)
			local resolved = false;
			local connections = {};
			local updateTreeForDescendant = function()
				if not resolved and validateTree(object, tree) then
					resolved = true;
					for _0 = 1, #connections do
						local connection = connections[_0];
						connection:Disconnect();
					end;
					resolve(object);
				end;
			end;
			local processDescendant = function(descendant)
				connections[#connections + 1] = descendant:GetPropertyChangedSignal("Name"):Connect(updateTreeForDescendant);
			end;
			local _0 = object:GetDescendants();
			for _1 = 1, #_0 do
				local descendant = _0[_1];
				processDescendant(descendant);
			end;
			connections[#connections + 1] = object.DescendantAdded:Connect(function(descendant)
				processDescendant(descendant);
				updateTreeForDescendant();
			end);
			delay(5, function()
				if not resolved then
					local violators = {};
					if validateTree(object, tree, violators) then
						resolved = true;
						for _2 = 1, #connections do
							local connection = connections[_2];
							connection:Disconnect();
						end;
						resolve(object);
					else
						warn("[yieldForTree] Infinite yield possible. Waiting for: " .. table.concat(violators, ", "));
					end;
				end;
			end);
		end));
	end;
end);
exports.validateTree = validateTree;
exports.yieldForTree = yieldForTree;
return exports;
