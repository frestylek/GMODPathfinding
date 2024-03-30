AddCSLuaFile()
if SERVER then
util.AddNetworkString( "fresdroidon" )
end
ENT.Type = "anim"
ENT.Editable		= false
ENT.PrintName		= "Droid smart" 
ENT.Spawnable 		= true
ENT.AdminSpawnable 	= false
ENT.Category = "[fStands] Dron"

function ENT:Initialize()
	self.last = CurTime()
		
		if SERVER then
			self:SetPos(self:GetPos() + Vector(0,0,100))
		self.on = false
		self.wep = {}
		self:SetHealth(100) 
		self:SetModel("models/fenixshiro/model/roomba.mdl")
		self:SetModelScale(1,0)
		local min, max = self:GetModelBounds()
		min = Vector(min.x,min.y,min.z)
		self:PhysicsInitBox( min*1.1, max*1.1 )
		self:PhysWake()
		self:SetSolid(SOLID_VPHYSICS)
		local phys = self:GetPhysicsObject()
		if phys then
			phys:EnableDrag(true)	
			phys:SetMass(1000)
			phys:SetMaterial("Metal")
		end
		self:SetUseType( SIMPLE_USE )
		
	end
end
function ENT:Draw()	
	self:DrawModel()
end

local goal2 = Vector(0,0,-150) -- Ustaw pozycję docelową drona
local desired_angles = Angle(0, 0, 0)
local speed = 10
local speedz = 10
local acceleration = 0.01
local maxSpeed = 3
local off = false


ENT.GOING = 0
ENT.GOING2 = 0

function ENT:Update(txt,val)
	self:SetNWVector(txt,val)
end

-- Define grid parameters
local gridSize = 200
local grid = {}
local cellSize = 50

-- Sample IsObstacleAt function (replace with your own logic)
function IsObstacleAt(x, y,self)
	local point = {x = x - gridSize/2,y = y - gridSize/2}
	point = {x = point.x*cellSize,y = point.y*cellSize}
	point = {x = point.x  + (self.startpath.x),y = point.y + (self.startpath.y)}
	local pos = Vector(point.x,point.y,self.startpath.z)
    local mins = Vector(-25, -25, 0)
    local maxs = Vector( 25,  25, 0) -- Załóżmy, że interesuje nas sprawdzenie przeszkód w płaszczyźnie poziomej

    local trace = util.TraceHull({
        start = pos,
        endpos = pos,
        mins = mins,
        maxs = maxs,
        mask = MASK_SOLID,
        filter = self
    })
		print(trace.Hit)
    return trace.Hit
end

-- A* Algorithm using trace lines
function AStar(start, goal,self)
    local openSet = {start}
    local cameFrom = {}
    local gScore = {}
    local fScore = {}

    -- Initialize scores
    for x = 1, gridSize do
        gScore[x] = {}
        fScore[x] = {}
        for y = 1, gridSize do
            gScore[x][y] = math.huge
            fScore[x][y] = math.huge
        end
    end

    gScore[start.x][start.y] = 0
    fScore[start.x][start.y] = Heuristic(start, goal)

    while #openSet > 0 do
        -- Find the cell with the lowest fScore in the open set
        local current = openSet[1]
        for _, cell in ipairs(openSet) do
            if fScore[cell.x][cell.y] < fScore[current.x][current.y] then
                current = cell
            end
        end

        if current.x == goal.x and current.y == goal.y then
            return ReconstructPath(cameFrom, current)
        end

        table.RemoveByValue(openSet, current)

        local neighbors = GetWalkableNeighbors(current,self)
        for _, neighbor in ipairs(neighbors) do
            local tentativeGScore = gScore[current.x][current.y] + Distance(current, neighbor)

            if tentativeGScore < gScore[neighbor.x][neighbor.y] then
                cameFrom[neighbor] = current
                gScore[neighbor.x][neighbor.y] = tentativeGScore
                fScore[neighbor.x][neighbor.y] = tentativeGScore + Heuristic(neighbor, goal)

                if not InSet(openSet, neighbor) then
                    table.insert(openSet, neighbor)
                end
            end
        end
    end

    return nil -- No path found
end

-- Heuristic function (Euclidean distance)
function Heuristic(a, b)
    return math.sqrt((b.x - a.x)^2 + (b.y - a.y)^2)
end

-- Distance function (Euclidean distance)
function Distance(a, b)
    return math.sqrt((b.x - a.x)^2 + (b.y - a.y)^2)
end

-- Check if a cell is in the set
function InSet(set, cell)
    for _, c in ipairs(set) do
        if c.x == cell.x and c.y == cell.y then
            return true
        end
    end
    return false
end

-- Get walkable neighbors
function GetWalkableNeighbors(current,self)
    local neighbors = {}

    -- Define offsets for neighboring cells
    local offsets = {
        {0, 1},   -- Up
        {0, -1},  -- Down
        {1, 0},   -- Right
        {-1, 0}   -- Left
    }

    for _, offset in ipairs(offsets) do
        local newX = current.x + offset[1]
        local newY = current.y + offset[2]

        -- Check if the neighbor is within bounds and not obstructed
        if newX >= 1 and newX <= gridSize and newY >= 1 and newY <= gridSize and not IsObstacleAt(newX, newY,self) then
            table.insert(neighbors, {x = newX, y = newY})
        end
    end

    return neighbors
end

-- Reconstruct path
function ReconstructPath(cameFrom, current)
    local totalPath = {current}

    while cameFrom[current] do
        current = cameFrom[current]
        table.insert(totalPath, 1, current)
    end

    return totalPath
end

function ENT:Pathg()
		-- Example usage

		self.startpath = self:GetPos()
	local rel = self.goal - self.startpath

	rel.x,rel.y = math.Round(rel.x)/cellSize,math.Round(rel.y)/cellSize
	rel.x,rel.y = rel.x + gridSize/2,rel.y + gridSize/2
	rel.x,rel.y = math.Round(rel.x),math.Round(rel.y)
	print(rel.x,rel.y)
	local start = {x = math.Round(gridSize/2), y = math.Round(gridSize/2)}
	local goal = {x = rel.x, y = rel.y}
	
	local path = AStar(start, goal,self)

	if path then
		
		for _, point in ipairs(path) do



			point = {x = point.x - gridSize/2,y = point.y - gridSize/2}
			point = {x = point.x*cellSize,y = point.y*cellSize}
			point = {x = point.x  + (self.startpath.x),y = point.y + (self.startpath.y)}
			
			print(string.format("Move to: (%d, %d)", point.x, point.y))
			
			path[_] = point
			-- Implement your movement logic here
		end
		self.path = path
	else
		print("No path found")
	end
end



function ENT:NewGoal()
	if self.GOING2 == 1 then return end
	
	self.goal = self:GetPos() + VectorRand(-400,400)
	self.goal.z = self:GetPos().z
	self.path = {}
	self:Pathg()
	self:Update("goal",self.goal)
end
function ENT:NewGoal2()
	if self.GOING2 == 1 then return end
	self.goal = self:GetPos() + self:GetRight() * math.random(300,400)
	self.goal.z = self:GetPos().z
	self.path = {}
	self:Pathg()
	self:Update("goal",self.goal)
end

function ENT:limit(phys)
	return self.GOING2 == 1
end

function ENT:Ground(phys)
	local tr = util.TraceLine( {
		start = self:GetPos() + self:GetForward() * 20 + Vector(0,0,10),
		endpos = self:GetPos() + self:GetForward() * 20 + Vector(0,0,-10000),
		filter = self
	} )	
	local trroot = util.TraceLine( {
		start = self:GetPos() + Vector(0,0,10),
		endpos = self:GetPos() + Vector(0,0,-10000),
		filter = self
	} )	
	local tr2 = util.TraceLine( {
		start = self:GetPos() + self:GetForward() * -10 + Vector(0,0,10),
		endpos = self:GetPos() + self:GetForward() * -10 + Vector(0,0,-10000),
		filter = self
	} )
	if self:GetPos():Distance(trroot.HitPos) > 10 then
		self:SetPos(self:GetPos() + Vector(0,0,(-50 * engine.TickInterval())))
	end
	self:SetAngles((tr.HitPos - tr2.HitPos):Angle())
end

function ENT:forward(phys)
	self.GOING = 1
	if self:limit(phys) then return end
	self:SetPos(self:GetPos() + self:GetForward() * (50 * engine.TickInterval()))
end
function ENT:back(phys)
	self.GOING = 0
	if self:limit(phys) then return end
	self:SetPos(self:GetPos() + self:GetForward() * (-50 * engine.TickInterval()))
end

function ENT:Brake()

end

function rotateCW(init, target)
    local clockwise = (target - init + 360) % 360 <= 180
	if ((target - init + 360) % 360 > 355 or (target - init + 360) % 360 < 5) == true then
		return false
	end
    return clockwise and 0 or 1
end

-- Example usage
local initAngle = 350
local targetAngle = 5

function ENT:left(phys)
	local ang = self:GetAngles()
	ang:RotateAroundAxis(self:GetUp(),(50 * engine.TickInterval()))
	self:SetAngles(ang)
end
function ENT:right(phys)
	local ang = self:GetAngles()
	ang:RotateAroundAxis(self:GetUp(),(-50 * engine.TickInterval()))
	self:SetAngles(ang)
end

function ENT:TURN(phys)
	local pos1 = self:GetPos()
	local pos2 = self.goal2
	desired_angles = (pos2 - pos1):Angle()
	desired_angles:Normalize()

		local ang = self:GetAngles().y
		txt = rotateCW(ang, desired_angles.y)
		if txt ~= false then
			self.GOING2 = 1
			if txt == self.GOING then
				self:right()
			else
				self:left()
			end
		else
			self.GOING2 = 0
		end
end

hook.Add("DrawOverlay","debug",function()
	local ent = ents.FindByClass("droid2")[1]
	if !IsValid(ent) then return end
	if ent:GetNWVector("goal",nil) ~= nil then
		local pos =  ent:GetNWVector("goal",nil):ToScreen()
		surface.SetDrawColor(Color(255,0,0))
		surface.DrawRect(-10 + pos.x,-10 + pos.y,20,20)
	end
	if ent:GetNWVector("path",nil) ~= nil then
		local pos =  ent:GetNWVector("path",nil):ToScreen()
		surface.SetDrawColor(Color(106,255,0))
		surface.DrawRect(-10 + pos.x,-10 + pos.y,20,20)
	end
end)

ENT.stuck = 0
ENT.stuckt = CurTime() - 50
ENT.isstuck = false
ENT.laststuck = Vector(0,0,0)

function ENT:main(phys)
	local pos1 = self:GetPos()
	self:Ground(phys)
	if self.path == nil then
		self:NewGoal2()
	end
	if self.path == nil or #self.path == 0 then self:NewGoal2() return end
	local pos2 = Vector(0,0,0)
	for k,v in ipairs(self.path) do
		if v == "done" then continue end
		local pos = Vector(v.x,v.y,self.startpath.z)
		if pos:Distance(self:GetPos()) < cellSize/2 then
			self.path[k] = "done"
			continue
		end
		self.goal2 = pos
		self:Update("path",self.goal2)
		break
	end
	if !self.isstuck then
			--self:DropToFloor()
			self:Ground(phys)
			self:TURN(phys)
			local tr = util.TraceHull( {
				start = self:GetPos() + Vector(0,0,10),
				min = Vector(-10,-10,0),
				max = Vector(10,10,1),
				endpos = self:GetPos() + self:GetForward() * 51 + Vector(0,0,10),
				filter = self
			} )

			if tr.HitPos:Distance(self:GetPos()) < 25 and tr.HitNormal.z *360 < 70 then
				self:Brake()
			else
				self:forward(phys)
			end

	else
		self:Ground(phys)
		if CurTime() - self.stuckt < 3 then
			self:TURN(phys)
			self:back(phys)
		else
			self.stuck = 0
			self.isstuck = false
		end
	end
	
	if self:GetPos():Distance(self.laststuck) < 0.2 then
		self.stuck = self.stuck + 1
	end
	self.laststuck = self:GetPos()
	if self.stuck > 500 then
		self.stuck = 0
		self.isstuck = true 
		self.stuckt = CurTime()
	end

end

function ENT:Think()
	if CLIENT then return end
	if self.path == nil then
		self:NewGoal()
	end

	local phys = self:GetPhysicsObject()

	if phys then
		if self.goal:Distance(self:GetPos()) < 100 then 
			self:Brake()
			self:NewGoal()
		else
			self:main(phys)
		end
		


	end

    self:NextThink(CurTime())

    return true
end

function ENT:OnTakeDamage( dmginfo )
	if self:Health() > 0 then
		self:SetHealth(self:Health() - dmginfo:GetDamage())
	end
end

function ENT:OnRemove()

end



