prefabs = { "pondeel", "pondfish", "wetpouch" }

for i, prefab in ipairs(prefabs) do
    AddPrefabPostInit(prefab, function(inst)
        inst:DoTaskInTime(0, function(inst)
            inst:Show()
        end)
    end)
end
