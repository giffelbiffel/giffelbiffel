-- Maskine.server.luau
-- Fase 1: Lav ÉN grå kasse (en "maskine"), der bliver sat på baseplaten,
-- når spillet starter. Ikke andet endnu. Vi bygger videre senere.

local maskine = Instance.new("Part")        -- 1. Lav en ny kasse
maskine.Name = "Maskine"                     -- 2. Giv den navnet "Maskine"
maskine.Size = Vector3.new(4, 4, 4)          -- 3. Gør den 4x4x4 stor
maskine.Position = Vector3.new(0, 2, 0)      -- 4. Placér den midt på baseplaten
maskine.Anchored = true                      -- 5. Lås den fast, så den ikke falder
maskine.BrickColor = BrickColor.new("Medium stone grey")  -- 6. Gør den grå
maskine.Parent = workspace                   -- 7. Sæt den ind i spillet

print("Maskinen er placeret på baseplaten!")  -- 8. Skriv en besked i Output
