shared.SkipLoadCheck = true
if IsTwiceRunning and not shared.SkipLoadCheck then
    return;
end
pcall(function() getgenv().IsTwiceRunning = true end);
if not game:IsLoaded() then game.Loaded:Wait() end; warn("Meow, game loaded.", shared.SkipLoadCheck);

local Fluent, SaveManager, InterfaceManager = 
loadstring(game:HttpGet("https://gist.githubusercontent.com/seria000/4ce60ba116cb52855f282a7f50b1866b/raw/63b3e6b94cf3d50c015465f895d5466041c91ac1/Fluent.lua"))(),
loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))(),
loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Second, Module = {}, {};
Module.__index = Module;
Second.__index = Second;

function missing(t, f, fallback) : any?
    if type(f) == t then return f end
    return fallback
end

cloneref = missing("function", cloneref, function(...) return ... end)
hookfunction = missing("function", hookfunction)
replicatesignal = missing("function", replicatesignal)
firesignal = missing("function", firesignal)
newcclosure = missing("function", newcclosure)
checkcaller = missing("function", checkcaller, function() return false end);
getnamecallmethod = missing("function", getnamecallmethod or get_namecall_method)
hookmetamethod = missing("function", hookmetamethod)

local Players = cloneref(game:GetService("Players"));
local RunService = cloneref(game:GetService("RunService"));
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait();
local PlayerGui = LocalPlayer:FindFirstChildWhichIsA("PlayerGui");

local ReplicatedStorage, VirtualUser, GuiService =
cloneref(game:GetService("ReplicatedStorage")),
cloneref(game:GetService("VirtualUser")),
cloneref(game:GetService("GuiService"));

local Heartbeat, Stepped, RenderStepped, PreSimulation =
RunService.Heartbeat, RunService.Stepped, RunService.RenderStepped, RunService.PreSimulation;
local placeId, gameId = game.PlaceId, game.GameId;
local VirtualInputManager = Instance.new("VirtualInputManager");
local httprequest = 
(syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request;

local RepitationThread
= loadstring(game:HttpGet("https://gist.githubusercontent.com/Seria000/ea277c117164f82fb40016246ba6a9ad/raw/eb0502cf8ad85b70a7b24e92227f37e717eb8111/RepitationThread.luau"))();

while not LocalPlayer do
	wait()
	LocalPlayer = Players.LocalPlayer
end

shared.isDebug = true;
local debugprint, debugwarn; do
	local p,w = print,warn
	debugprint = function(... : any?)
		return shared.isDebug and p("[DEBUG]", ...)
	end
	debugwarn = function(... : any?)
		return shared.isDebug and w("[DEBUG]", ...)
	end
end
local setconfig = function(k : string, v : any, t : table | nil) : ValueBase?
    getgenv()[k] = getgenv()[k] or v
    if type(t) == "table" then
        t[k] = t[k] or v
        -- table.insert(t, k, v) -- t: table, pos: number, value: any
    end
    return getgenv()[k]
end
local Notify = function(Content : string | any?)
	xpcall(function()
		Fluent:Notify({
			Title = "SeriaUwU",
			Content = Content,
			Duration = 5
		})
	end, debugprint)
end

function Module.getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end
function Module.getHumanoid()
    local Char = Module.getCharacter();
    return Char:FindFirstChild("Humanoid") or Char:FindFirstChildWhichIsA("Humanoid")
end
function Module.getStateHumanoid()
	local Humanoid = Module.getHumanoid();
	return Humanoid and Humanoid:GetState()
end
local previousStates = {} :: {[Enum.HumanoidStateType] : boolean}
function Module.SetState(ToDisable : Enum.HumanoidStateType, Value : boolean)
	local Humanoid = Module.getHumanoid();
	if not Humanoid then return end;

	if previousStates[ToDisable] == nil then
		previousStates[ToDisable] = Humanoid:GetStateEnabled(ToDisable)
	end

	Humanoid:SetStateEnabled(ToDisable, Value)
end
function Module:UndoSetState()
	local Humanoid = Module.getHumanoid();
	if not Humanoid then return end

	--// prevent empty table. skiped
	if next(previousStates) == nil then return end;

	for i, v in pairs(previousStates) do
		previousStates[i] = nil
		Humanoid:SetStateEnabled(i, v)
	end
end
function Module.getRoot(Root : BasePart) --// fix some logic 2PM 12/5/2025
	local Character = Module.getCharacter()

    if not Root then return Character:WaitForChild("HumanoidRootPart", 5) end;
    local rootPart = Root:FindFirstChild("HumanoidRootPart", true) or Root:FindFirstChild("Torso", true) or Root:FindFirstChild("UpperTorso", true);
	if not rootPart then return end

    return rootPart
end
function Module.Teleport(Target : Vector3 | CFrame | PVInstance) : boolean --// @centerepic
	local Pivot: CFrame;

	if typeof(Target) == "CFrame" then
		Pivot = Target;
	elseif typeof(Target) == "Vector3" then
		Pivot = CFrame.new(Target);
	elseif typeof(Target) == "PVInstance" then
		Pivot = Target:GetPivot();
	elseif typeof(Target) == "BasePart" then
		Pivot = Target:GetPivot();
	elseif typeof(Target) == "Model" then
		Pivot = Target:GetPivot();
	end

	local Character = Module.getCharacter();
	if Character then
		Character:PivotTo(Pivot);
		return true
	end

	return false
end

local Settings = {}; 
Settings.__index = Settings;
setconfig("AutoLevel", false, Settings)
setconfig("Noclip", false, Settings)

setconfig("tempConnect", {})

local function CollectThread(Thread : RBXScriptConnection | thread)
    if shared.isDebug then;debugprint("Collected New Threads", Thread);end
    table.insert(tempConnect, Thread)
end

local Main = setmetatable(Second, Module);
setconfig("Controller", pcall(RepitationThread.new()));

function Main:getPlayerLevels()
	return LocalPlayer.Info.Level.Value :: ValueBase
end
function Main:getQuestFromCurrentLevel()
	local Levels = Main:getPlayerLevels();
	local Quests = workspace["Main"]["NPCs"]["Quests"] :: Folder;
	local Center = workspace["Main"]["Characters"] :: Folder;
	local SpawnLocation = workspace["Spawn Location"] :: Folder;

	if Levels >= 1 and Levels < 50 then
		return {
			["Isle"] = Center["Windmill Village"] :: Model,
			["Mobs"] = "Bandit",
			["Quest"] = Quests["1"] * CFrame.new(0, 3, 0) :: Model,
			["CFrame"] = SpawnLocation["1"].CFrame,
			["Index"] = 5,
		}
	elseif Levels >= 50 and Levels < 150 then
		return {
			["Isle"] = Center["Windmill Village"] :: Model,
			["Mobs"] = "Bandit Leader",
			["Quest"] = Quests["2"] * CFrame.new(0, 3, 0) :: Model,
			["CFrame"] = SpawnLocation["1"].CFrame,
			["Index"] = 1,
		}
	elseif Levels >= 150 and Levels < 250 then
		return {
			["Isle"] = Center["Whispering Jungle"] :: Model,
			["Mobs"] = "Skeleton",
			["Quest"] = Quests["3"] * CFrame.new(0, 3, 0) :: Model,
			["CFrame"] = SpawnLocation["2"].CFrame,
			["Index"] = 5,
		}
	elseif Levels >= 250 and Levels < 350 then
		return {
			["Isle"] = Center["Whispering Jungle"] :: Model,
			["Mobs"] = "Pirate Skeleton",
			["Quest"] = Quests["4"] * CFrame.new(0, 3, 0) :: Model,
			["CFrame"] = SpawnLocation["2"].CFrame,
			["Index"] = 1,
		}
	end
end
function Main:AutoQuest()
	local QuestPath = LocalPlayer["Quest"] :: Folder;
	local QuestData = Main:getQuestFromCurrentLevel();
	local Teleport = Main.Teleport()
	local HasQuest = QuestPath.Toggle.Value :: ValueBase
	if not QuestData then return end

	if HasQuest then
		local Title = QuestPath["Title"].Value :: string
		local Target = QuestPath["Target"].Value :: ValueBase
		local spitted = string.split(Title, " ")[2] :: string
		if Target == QuestData["Index"] and tostring(spitted) == QuestData["Mobs"] then
			return true
		else
			local HUD = PlayerGui["HUD"] :: ScreenGui
			local Bar = HUD:FindFirstChild("Bar") :: Frame
			if Bar then
				local List = Bar:FindFirstChild("List") :: Frame
				local Quest = List:FindFirstChild("Quest") :: Frame
				if Quest then
					local Bar2 = Quest:FindFirstChild("Bar") :: Frame
					local Cancel = Bar2:FindFirstChild("Cancel") :: Frame
					if Cancel then
						if replicatesignal then --// firesignal not work and getconnections not work too
							replicatesignal(Cancel.Button.MouseButton1Click)
						else
							repeat Heartbeat:Wait()
								GuiService.SelectedObject = Cancel.Button
								if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(Quest) then
									VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
									VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
								end
								RunService.Heartbeat:Wait()
							until not Cancel:IsDescendantOf(Quest)
							GuiService.SelectedObject = nil
						end
					end
				end
			end
		end
	elseif not HasQuest then
		repeat Heartbeat:Wait()
			Teleport(QuestData["CFrame"])
		until ((QuestData["CFrame"].Position - Module.getRoot().Position.Magnitude) <= 5 or not Settings.AutoLevel)
		while HasQuest do task.wait()
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
		end
	end
end

local Window = Fluent:CreateWindow({
    Title = "Rogue Piece | Alpha",
    SubTitle = "By Seria",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false, 
    Theme = "Darker",
    Transparency = false,
    MinimizeKey = Enum.KeyCode.RightShift,
})
local Tabs = {
	Main = Window:AddTab({ Title = "Main", Icon = "component" }),
	Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}
local TabMain = Tabs.Main:AddSection("Main") do
	local AutoFarmLv = TabMain:AddToggle("AutoFarm", {Title = "Auto Level", Default = false })
    AutoFarmLv:OnChanged(function(v)
		Settings.AutoLevel = v
    end)
end

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("SerializedProject")
SaveManager:SetFolder("SerializedProject/Configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)
Fluent:Notify({
    Title = "Fluent",
    Content = "The script has been loaded.",
    Duration = 8
})
SaveManager:LoadAutoloadConfig()

spawn(function()
	local Features = {}
	Features[1] = CollectThread(Controller:newThread(nil, function()
		local Quests = Main:AutoQuest()
		if not Quests then
			Quests()
		elseif Quests then
			print("Already has quest.")
		end
	end))
end)
-- background stuff
local function GenerateRandomString(range1 : number, range2 : number)
	local characters = "abcdefghijklmnopABCDEFGHIJKLMNOP" -- qrstuvwxyzQRSTUVWXYZ are excluded cuz less common lmao
	local name = ""

	for i = 1, math.random(range1, range2) do
		local randint = math.random(#characters)
		name = name .. string.sub(characters, randint, randint)
	end

	return name
end
setconfig("VeloName", GenerateRandomString(7, 15));
spawn(function()
	CollectThread(Stepped:Connect(function() --// btw, this is not tested if fps dropping or not
		pcall(function()
			if Settings.AutoLevel :: boolean?
			then
				local Character = Module.getCharacter();
				local Root = Module.getRoot(Character);
				local Humanoid = Module.getHumanoid();
				local getStateHumanoid = Module.getStateHumanoid();
				local IsHumSitting = ((getStateHumanoid == Enum.HumanoidStateType.Seated) or Humanoid.Sit == true);

				Module.SetState(Enum.HumanoidStateType.Seated, false);
				Module.SetState(Enum.HumanoidStateType.FallingDown, false);
				Humanoid:ChangeState(Enum.HumanoidStateType.StrafingNoPhysics);

				if not IsHumSitting then
					if Root and not Root:FindFirstChild(VeloName) then
						local Velo = Instance.new("BodyVelocity", Root)
                        Velo["Name"] = VeloName
                        Velo["MaxForce"] = Vector3.new(9e9, 9e9, 9e9)
                        Velo["Velocity"] = Vector3.new(Vector3.zero * 0)
					end
				else
					Humanoid.Sit = true
				end
			else
				local Character = Module.getCharacter();
				local Root = Module.getRoot(Character);
				local Humanoid = Module.getHumanoid();
				local vel = Root:FindFirstChild(VeloName)

				if vel then vel:Destroy() end
				if Module.getStateHumanoid() ~= Enum.HumanoidStateType.None then
					Humanoid:ChangeState(Enum.HumanoidStateType.None);
				end
				Module:UndoSetState()
			end
		end)
	end))
end)
local toUndo = {} --// for noclip
spawn(function()
    CollectThread(Stepped:Connect(function()
        local Char = Module.getCharacter()
		if not Char then return end

        if Settings.Noclip then
			for i,v in pairs(Char:GetChildren()) do
				if v:IsA("BasePart") and v.CanCollide then
					v.CanCollide = false
					toUndo[v] = true
				end
			end
		else
			for i,v in pairs(toUndo) do
				toUndo[i] = nil
				i.CanCollide = true
			end
		end
    end))
end)
spawn(function()
    if getconnections then
        for _,v in getconnections(LocalPlayer.Idled) do
            v:Disable()
        end
    else
        CollectThread(LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end))
    end
end)
spawn(function() --// for instant prompt
	pcall(function()
		for _,v in pairs(workspace.Main.NPCs.Quests:GetDescendants()) do
			if v:IsA("ProximityPrompt") and v.HoldDuration ~= 0 then
				if not v.Enabled then 
					v.Enabled = true 
				end
				v.HoldDuration = 0
			end
		end
	end)
end)
task.spawn(function()
    local v1, v2 = pcall(identifyexecutor)
    if v1 and v2 then
        if string.find(string.lower(v2), "xeno|solara|jjsploit|zorara") then
            LocalPlayer:Kick("Please use something else")
            return
        end
    end
end)
