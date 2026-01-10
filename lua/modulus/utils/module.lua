local Package = {}

local _setmetatable = setmetatable
local _table_concat = table.concat

setfenv(1, Package)


local PackageOps = {}

function PackageOps:GetUniqueID() return self.info.uid end
function PackageOps:GetAuthors() return self.info.authors end
function PackageOps:GetDescription() return self.info.description end
function PackageOps:GetDependencies() return self.info.dependencies end
function PackageOps:GetPath() return self.info.path end

function PackageOps:IsActive() return self.active end
function PackageOps:Deactivate(reason)
    self.active = false
    self.reasons = self.reasons and _table_concat(self.reasons, reason) or { reason }
end


function FromModuleInfo(moduleInfo, loaded)
    local init = {
        info = moduleInfo,
        active = true,
        loaded = loaded or false
    }

    return _setmetatable( init, { __index = PackageOps })
end


return Package
