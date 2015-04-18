AddCSLuaFile()

-- Soundcloud code
local SoundCloud = {}

function SoundCloud.Detect(uri, useJW)
    local m = playxlib.FindMatch(uri:gsub("%?.*$", ""), {
        "^http[s]?://soundcloud.com/(.+)/(.+)$",
		"^http[s]?://www.soundcloud.com/(.+)/(.+)$",
		"^http[s]?://api.soundcloud.com/tracks/(%d)+",
    })
	if(m) then
		if m[1] and m[2] then
			return "http://soundcloud.com/"..m[1].."/"..m[2]
		elseif(m[1]) then
			return "http://api.soundcloud.com/tracks/"..m[1]
		end
	else
		return
	end
end

function SoundCloud.GetPlayer(uri, useJW)
	local url = uri
	return {
		["Handler"] = "SoundCloud",
		["URI"] = url,
		["ResumeSupported"] = true,
		["LowFramerate"] = false,
		["QueryMetadata"] = function(callback, failCallback)
			SoundCloud.QueryMetadata(uri, callback, failCallback)
		end,
		["HandlerArgs"] = {
			["VolumeMul"] = 0.1,
		},
	}
end

function SoundCloud.QueryMetadata(uri, callback, failCallback)
    local url = "http://api.soundcloud.com/resolve.json?url="..uri.."&client_id=3775c0743f360c022a2fed672e33909d"

    http.Fetch(url,function(content,size)
		local dec = util.JSONToTable(content)
		if content == NULL or not dec then
			if failCallback then failCallback("Failed to get Metadata") end
			return
		end
		if(dec and dec["title"] ~= nil) then
			local title = dec["title"]
			local desc = dec["description"]
			local viewerCount = dec["playback_count"]
			--local tags = playxlib.ParseTags(dec["tag_list"])
			callback({
				["Duration"] = math.floor(tonumber(dec["duration"])/1000),
				["URL"] = dec["uri"],
				["URL2"] = uri,
				["Title"] = title,
				["Description"] = desc,
				["Tags"] = tags,
				["ViewerCount"] = viewerCount,
			})
		end
	end)
end

--End soundcloud code

--easylua.StartEntity("fb_audio_ghradio")

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.Category = "Audio"
ENT.PrintName		= "GhRadio"
ENT.Author			= "Ghost"
ENT.Contact			= "Don't"
ENT.Purpose			= "Exemplar material"
ENT.Instructions	= "Use with care. Always handle with gloves."
ENT.Model = "models/props/cs_office/tv_plasma.mdl"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Value = 10
ENT.URL = ""
ENT.Range = 1500
ENT.Volume = .7
ENT.Levels = {0,0}
ENT.Loop = false
ENT.StartingURL = nil
ENT.Version = "2"

if CLIENT then
 
surface.CreateFont("GhRadio_ScreenFont",
	{
		font = "Roboto",
		size = 24,
		weight = 700,
		antialias = true,
		outline = false
	}
)

surface.CreateFont("GhRadio_ScreenFontSlight",
	{
		font = "Roboto",
		size = 20,
		weight = 700,
		antialias = true,
		outline = false
	}
)

surface.CreateFont("GhRadio_ScreenFontSmall",
	{
		font = "Roboto",
		size = 16,
		weight = 100,
		antialias = true,
		outline = false
	}
)


surface.CreateFont("GhRadio_ScreenFontSmaller",
	{
		font = "Roboto",
		size = 12,
		weight = 100,
		antialias = true,
		outline = false
	}
)
 

function ENT:SetRange(range)
	range = tonumber(range)
	if range == nil then return end
	self.Range = range
end

function ENT:SetVolume(vol)
	vol = tonumber(vol)
	if vol == nil then vol = 0 end
	self.Volume = vol
end


function ENT:Play(url)
if !globalstations then globalstations = {} 
else
	self:Stop()
end

self.URL = url

if SoundCloud.Detect(url) then

	
	SoundCloud.QueryMetadata(url,
		function(m)  

			local url
			local name = m.Title
			print(m.URL)

			if m.URL then url = m.URL .. "/stream?client_id=3775c0743f360c022a2fed672e33909d" else url = nil end

if url then
	self.SoundCloud = true
	self.SoundCloudTitle = name
sound.PlayURL(url,
		"noblock",
		function(station,_,error)
			if IsValid(station) then

				station:SetVolume(self.Volume)
				if self.Loop then station:EnableLooping(true) end
				station:Play()
				
				globalstations[self:EntIndex()] = station	
			end
			if error != nil then
			print(error)
			end
	end)
else
	print"SoundCloud failed D:"
end
	end)	
return
end
self.SoundCloud = false
sound.PlayURL(url,
		"noblock",
		function(station,_,error)
			if IsValid(station) then

				station:SetVolume(self.Volume)
				if self.Loop then station:EnableLooping(true) end
				station:Play()
				
				globalstations[self:EntIndex()] = station	
			end
			if error != nil then
			print(error)
			end
	end)

end

function ENT:Pause()
	local globalstation = globalstations[self:EntIndex()]
	if IsValid(globalstation) then
		if globalstation:GetState() != GMOD_CHANNEL_PAUSED then
		globalstation:Pause()
		end
	end
	
end

function ENT:Unpause()
	local globalstation = globalstations[self:EntIndex()]
	if IsValid(globalstation) then
		if globalstation:GetState() == GMOD_CHANNEL_PAUSED then
			globalstation:Play()
		end		
	end
	
end

function ENT:Stop()
	local globalstation = globalstations[self:EntIndex()]
	if IsValid(globalstation) then
		globalstation:Stop()
		globalstation = nil
	end	
	
end
 
function ENT:SetLoop(bool)
	bool = tobool(bool)

	self.Loop = bool

end

function ENT:GetTexts()

	local globalstation = globalstations[self:EntIndex()]
	if type(globalstation) != "IGModAudioChannel" then return "Not playing", "--:-- / --:--" end
	if !IsValid(globalstation) then
		return "Not playing", "--:-- / --:--"
	end
	if IsValid(globalstation) then
		local a = globalstation:GetState()
		if a == GMOD_CHANNEL_STALLED then
			return "Buffering...", "--:-- / --:--"
		elseif a == GMOD_CHANNEL_STOPPED then
			return "Not playing", "--:-- / --:--"
		elseif a == GMOD_CHANNEL_PLAYING then
			return "Playing", string.ToMinutesSeconds(math.Round(globalstation:GetTime()/globalstation:GetPlaybackRate())) 
			.. " / "
			.. string.ToMinutesSeconds(math.Round(globalstation:GetLength()/globalstation:GetPlaybackRate()))
		elseif a == GMOD_CHANNEL_PAUSED then
			return "Paused", string.ToMinutesSeconds(math.Round(globalstation:GetTime()/globalstation:GetPlaybackRate())) 
			.. " / "
			.. string.ToMinutesSeconds(math.Round(globalstation:GetLength()/globalstation:GetPlaybackRate()))
		end
			
	end	
end

function ENT:GetSongName(  ) --stolen x3

	local FixedName = ""

	local globalstation = globalstations[self:EntIndex()]


	if IsValid(globalstation) then
		local ll = globalstation:GetFileName()
	if !self.SoundCloud then
		FixedName = tostring( ll )
	else
		return self.SoundCloudTitle
	end
	
		
		if globalstation:GetState() == GMOD_CHANNEL_STOPPED then
			return ""
		end
		if isstring(FixedName) then

		FixedName = string.Replace( FixedName, "_", " " )

		FixedName = string.Replace( FixedName, "%20", " " )
		FixedName = string.Replace( FixedName, "%28", "(" )
		FixedName = string.Replace( FixedName, "%29", ")" )
		FixedName = string.Replace( FixedName, "%5b", "[" )
		FixedName = string.Replace( FixedName, "%5d", "]" )


		FixedName = string.GetFileFromFilename( FixedName )

		FixedName = string.JavascriptSafe( FixedName )

		
		NEnd = string.find( FixedName , "%.[mp3|Mp3|mP3|MP3]" )
		if NEnd == nil then
		NEnd = string.find( FixedName , "%.[ogg|Ogg|oGg|ogG|OGg|oGG|OGG]" )
		end
		if NEnd == nil then
		NEnd = string.find( FixedName , "%.[wav|Wav|wAv|waV|WAv|wAV|WAV]" )
		end
		if NEnd == nil then
		NEnd = string.find( FixedName , "%.[m4a|M4a|m4A|M4A]")
		end
		if NEnd == nil then
		NEnd = string.find( FixedName ,"%.[mp4|Mp4|mP4|MP4]" )
		end

		if NEnd == nil then
		NEnd = #FixedName
		end
	
		FixedName = FixedName:gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
		FixedName = string.Replace( FixedName, "Ytpmv", "YTPMV")
		FixedName = string.Replace( FixedName, "Ytp", "YTP")


		FixedName = string.sub( FixedName , 0 , NEnd - 1 )

		end
--  		FixedName = string.Trim(FixedName, ".mp3")
  	end
		return FixedName
end



--[[---------------------------------------------------------
   Name: Draw
   Purpose: Draw the model in-game.
   Remember, the things you render first will be underneath!
---------------------------------------------------------]]
function ENT:Draw()
      -- We want to override rendering, so don't call baseclass.
                                  -- Use this when you need to add to the rendering.
    self:DrawModel()       -- Draw the model.

	local pos = self:GetPos()
	local ang = self:GetAngles()
	local texttop,textbottom = self:GetTexts()
	local curfont = "GhRadio_ScreenFont"
	local color_dim
	local fft = {}

	ang:RotateAroundAxis(ang:Right(),90)
	ang:RotateAroundAxis(ang:Forward(),180)
	ang:RotateAroundAxis(ang:Up(),-90)
	
	cam.Start3D2D(pos+ang:Up()*9.15,ang,0.15)
		local off = -350
		local textheight = -500
		local ee = -92
		local textcenter = ee / 8
		local playproxy = 0
		local playproxy2 = 0
		local e,f = 0,0
		if !globalstations then return end
		local globalstation = globalstations[self:EntIndex()]
		if IsValid(globalstation) then

		color_dim =
			HSVToColor((RealTime()*100)%360,1,0.4)
		if globalstation:GetState() != GMOD_CHANNEL_PLAYING and globalstation:GetState() != GMOD_CHANNEL_PAUSED then
			color_dim = color_black
		end
		playproxy = math.sin(RealTime()*6%360)*6
		playproxy2 = math.sin(RealTime()*12%360)*4

		if globalstation:GetState() != GMOD_CHANNEL_PLAYING then
			playproxy = 0
			playproxy2 = 0
		end


		local moff = -off
		globalstation:FFT(fft,FFT_256)
		
		local xx = {}
		for i = 1, #fft, 8 do
			table.insert(xx,4+(moff*2.5*fft[i]/1.15))
		end
		globallevels[self:EntIndex()] = xx
		e,f = globalstation:GetLevel()
		e,f = e*2,f*2
	else

		color_dim = black
		globallevels[self:EntIndex()] =  {0,0}
		
	end



	
	
	local bouncey = -30
	local xorigin = textcenter-16-16-16
	local textcenter = textcenter+10
	local color_rainbow = HSVToColor((RealTime()*100)%360,1,1)
	local glevel = globallevels[self:EntIndex()]

	
	if !color_dim then color_dim = Color(0,0,0) end

		draw.RoundedBox(6,
			ee*3, off,
			552, 320,
			color_dim)


		for i = 1, (#glevel) do
		if glevel[i] == nil then break end
		if i == #glevel then continue end
		draw.RoundedBox(0,
			tonumber(xorigin*(i/3)), bouncey,
			16, 
			math.Clamp(
			tonumber(-glevel[i]*e),
			-310,0)
			,
			color_rainbow)
		end
		for i = (#glevel), 1, -1 do

		if glevel[i] == nil then break end
		if i == #glevel or i == #glevel - 1 then continue end
		draw.RoundedBox(0,
			tonumber(xorigin*(-i/3)-18), bouncey,
			16, 			math.Clamp(
			tonumber(-glevel[i]*f),
			-310,0),
			color_rainbow)
		end


		
		draw.DrawText(
		texttop,curfont,
		textcenter,textheight/2.5 - 4 + (16-draw.GetFontHeight(curfont))+playproxy,color_white,TEXT_ALIGN_CENTER)
		draw.DrawText(
		textbottom,"GhRadio_ScreenFont",
		textcenter,textheight/2.5+4+14+playproxy,color_white,TEXT_ALIGN_CENTER)
		
		draw.DrawText(
			"GhRadio v" .. self.Version,
			"GhRadio_ScreenFontSmall",
			ee*3,off,color_white,TEXT_ALIGN_LEFT)

		local songname = self:GetSongName()
		local snl = #songname
		if snl < 30 then
			draw.DrawText(
			self:GetSongName(),
			"GhRadio_ScreenFont",
			textcenter+playproxy2,off,color_white,TEXT_ALIGN_CENTER)
		elseif snl > 29 and snl < 48 then
			draw.DrawText(
			self:GetSongName(),
			"GhRadio_ScreenFontSlight",
			textcenter+playproxy2,off,color_white,TEXT_ALIGN_CENTER)
		elseif snl > 48 and snl < 60 then
			draw.DrawText(
			self:GetSongName(),
			"GhRadio_ScreenFontSmall",
			textcenter+playproxy2,off,color_white,TEXT_ALIGN_CENTER)
		else
			draw.DrawText(
			self:GetSongName(),
			"GhRadio_ScreenFontSmaller",
			textcenter+playproxy2,off,color_white,TEXT_ALIGN_CENTER)			

		end


	cam.End3D2D()


end

end


function ENT:Initialize()
	
	
 	if CLIENT then 
 	
 	if globalstations then
 		for k,v in pairs(globalstations) do
 			if IsValid(v) then v:Stop() v = nil end
		end
	end
	globalstations = {}
	
 	if globallevels then
 		for k,v in pairs(globallevels) do
 			v = nil 
		end
		
		
	end
	globallevels = {}	
	if self.StartingURL then
		local lel = tostring(self.StartingURL)
		timer.Simple(1,function() 
			self:Play(lel) 
			self.StartingURL = nil
		end)
	end

 elseif SERVER then

	self:SetModel( self.Model )
	self:SetModelScale(1.5)
	self:PhysicsInit( SOLID_OBB )      -- Make us work with physics,
	self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
	self:SetSolid( SOLID_OBB )         -- Toolbox
 	
        local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
	
	
end
	
	
end
 
if SERVER then
 
function ENT:Use( activator, caller )

    return
end
 
end
function ENT:Think()
	if SERVER then
    if IsValid(self) then
    	self:SetModel(self.Model)
    end
    elseif CLIENT then
    	if !globalstations then return end
    	local globalstation = globalstations[self:EntIndex()]
    	local range = self.Range
    	local volmult = tonumber(self.Volume)
    	if volmult == nil then volmult = 0 end
    	local vol = math.Clamp((range-self:GetPos():Distance(LocalPlayer():GetPos()))/range,0,1)*math.Clamp(volmult,0,1)
	

    	if IsValid(globalstation) then
    		globalstation:SetVolume(vol)
    		globalstation:EnableLooping(self.Loop)

		end


		
	end
 
end
if SERVER then

function ENT:Play(url)
	
	for k,v in pairs(player.GetHumans()) do
			v:SendLua([[Entity(]] .. self:EntIndex() .. [[):Play("]] .. url .. [[")]])
	end
	
end
function ENT:Stop()
	
	for k,v in pairs(player.GetHumans()) do
			v:SendLua([[Entity(]] .. self:EntIndex() .. [[):Stop()]])
	end
	
end
function ENT:Pause()
	
	for k,v in pairs(player.GetHumans()) do
			v:SendLua([[Entity(]] .. self:EntIndex() .. [[):Pause()]])
	end
	
end
function ENT:Unpause()
	
	for k,v in pairs(player.GetHumans()) do
			v:SendLua([[Entity(]] .. self:EntIndex() .. [[):Unpause()]])
	end
	
end
function ENT:SetRange(range)
	for k,v in pairs(player.GetHumans()) do
			v:SendLua([[Entity(]] .. self:EntIndex() .. [[):SetRange(]] .. tonumber(range) .. [[)]])
	end
end

function ENT:OnRemove()
	for k,v in pairs(player.GetHumans()) do
			v:SendLua([[if IsValid(globalstations]] .. "[" .. self:EntIndex() .. "]" .. [[)then globalstations]] .. "[" .. self:EntIndex() .. "]" .. [[:Stop()end]])
	end	
end

function ENT:SetLoop(bool)
	bool = tobool(bool)

	for k,v in pairs(player.GetHumans()) do
			v:SendLua([[Entity(]] .. self:EntIndex() .. [[):SetLoop(]] .. (bool and "1" or "0") .. [[)]])
	end	

end

end
easylua.EndEntity()