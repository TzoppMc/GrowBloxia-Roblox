--!nocheck
-- Normalizes user-entered asset values from AssetManifest.lua.

local AssetResolver = {}

function AssetResolver.toContentId(reference)
	if type(reference) ~= "string" then
		return nil
	end

	local value = string.gsub(reference, "%s+", "")
	if value == "" then
		return nil
	end

	if string.match(value, "^rbxassetid://") or string.match(value, "^rbxasset://") then
		return value
	end

	if string.match(value, "^%d+$") then
		return "rbxassetid://" .. value
	end

	-- Deliberately reject arbitrary URLs (including Google Drive links): Roblox
	-- runtime UI should use a published Roblox content ID instead.
	return nil
end

function AssetResolver.isConfigured(reference)
	return AssetResolver.toContentId(reference) ~= nil
end

return AssetResolver
