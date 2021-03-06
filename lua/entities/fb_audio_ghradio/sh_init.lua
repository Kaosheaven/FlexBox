AddCSLuaFile()

local function code()

-- Soundcloud code
--Taken from PlayX. Thanks PlayX team and Xerasin

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
			local author = dec["user"]
			--local tags = playxlib.ParseTags(dec["tag_list"])
			callback({
				["Duration"] = math.floor(tonumber(dec["duration"])/1000),
				["URL"] = dec["uri"],
				["URL2"] = uri,
				["Title"] = title,
				["Description"] = desc,
				["Tags"] = tags,
				["ViewerCount"] = viewerCount,
				["Author"] = author,
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
ENT.Version = "2.1"
ENT.Global = false

if CLIENT then
 
local ghfonts = {}

surface.CreateFont("GhRadio_ScreenFont",
	{
		font = "Roboto",
		size = 24,
		weight = 700,
		antialias = true,
		outline = false
	}
)

ghfonts.scrfont = "GhRadio_ScreenFont"

surface.CreateFont("GhRadio_ScreenFontSlight",
	{
		font = "Roboto",
		size = 20,
		weight = 500,
		antialias = true,
		outline = false
	}
)

ghfonts.scrfontssl = "GhRadio_ScreenFontSlight"

surface.CreateFont("GhRadio_VersionFont",
	{
		font = "Roboto",
		size = 18,
		weight = 700,
		antialias = true,
		outline = false
	}
)


ghfonts.verfont = "GhRadio_VersionFont"

surface.CreateFont("GhRadio_ScreenFontSmall",
	{
		font = "Roboto",
		size = 16,
		weight = 400,
		antialias = true,
		outline = false
	}
)

ghfonts.scrfontsm = "GhRadio_ScreenFontSmall"

surface.CreateFont("GhRadio_ScreenFontSmaller",
	{
		font = "Roboto",
		size = 12,
		weight = 300,
		antialias = true,
		outline = false
	}
)

ghfonts.scrfontxs = "GhRadio_ScreenFontSmaller"
 

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

if !url:find"http://" and !url:find"https://" then
	url = ("http://" .. url)
end
url = string.Trim(url," ")
self.URL = url


if SoundCloud.Detect(url) then

	
	SoundCloud.QueryMetadata(url,
		function(m)  

			local url
			local name = m.Title
			local author = m.Author

			if m.URL then url = m.URL .. "/stream?client_id=3775c0743f360c022a2fed672e33909d" else url = nil end

if url then
	self.SoundCloud = true
	self.SoundCloudTitle = name
	self.SoundCloudAuthor = author["username"]

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
			MsgC(Color(255,0,0),"[GhRadio]",Color(255,255,255)," Returned an error when trying to play the requested audio:\n",Color(255,0,0),error.."\n")
			end
	end)
else
	MsgC(Color(255,0,0),"[GhRadio]",Color(255,255,255)," SoundCloud failed to load properly??")
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
			MsgC(Color(255,0,0),"[GhRadio]",Color(255,255,255)," Returned an error when trying to play the requested audio:\n",Color(255,0,0),error.."\n")
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

function ENT:SetGlobal(bool)
	bool = tobool(bool)
	self.Global = bool
end
 
function ENT:SetLoop(bool)
	bool = tobool(bool)

	self.Loop = bool

end

function ENT:GetTexts()
	local function addzerotonumber(n)

		n = tonumber(n)
		if n == nil then n = 0 end
		if n < 10 then
			return "0" .. n
		else
			return tostring(n)
		end

	end



	local globalstation = globalstations[self:EntIndex()]
	if type(globalstation) != "IGModAudioChannel" then return "Not playing", "--:-- / --:--" end

	if !IsValid(globalstation) then
		return "Not playing", "--:-- / --:--"
	end
	if IsValid(globalstation) then
		local a = globalstation:GetState()
		local time = globalstation:GetTime()/globalstation:GetPlaybackRate()
		local length = globalstation:GetLength()/globalstation:GetPlaybackRate()
		local time_t = string.FormattedTime(time)
		local length_t = string.FormattedTime(length)
		local hideradio = false

		if length_t.h == 0 then
			time = tostring(addzerotonumber(time_t.m)) .. ":"
			.. tostring(addzerotonumber(time_t.s))
			if length >= 0 then
			length = tostring(addzerotonumber(length_t.m)) .. ":"
			.. tostring(addzerotonumber(length_t.s))
			else
				length = "??:??"
			end
		else
			time = tostring(addzerotonumber(time_t.h)) .. ":"
			.. tostring(addzerotonumber(time_t.m)).. ":"	
			.. tostring(addzerotonumber(time_t.s))	
			if length >= 0 then

			length = tostring(addzerotonumber(length_t.h)) .. ":" ..
			tostring(addzerotonumber(length_t.m)) .. ":"
			.. tostring(addzerotonumber(length_t.s))
			else
				time = "-audio stream-"
				length = ""
				hideradio = true
			end
		end		

		if a == GMOD_CHANNEL_STALLED then
			return "Buffering...", "--:-- / --:--"
		elseif a == GMOD_CHANNEL_STOPPED then
			return "Not playing", "--:-- / --:--"
		elseif a == GMOD_CHANNEL_PLAYING then
			return "Playing", (!hideradio and time
			.. " / "
			.. length or time)
		elseif a == GMOD_CHANNEL_PAUSED then
			return "Paused", (!hideradio and time
			.. " / "
			.. length or time)
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
		if globalstation:GetState() == GMOD_CHANNEL_STOPPED then self.SoundCloudTitle = "" end
		return self.SoundCloudTitle
	end

		if globalstation:GetLength() < 0 then
			FixedName = tostring(ll)
			FixedName = string.Replace( FixedName, "http://", "" )
FixedName = string.Replace( FixedName, "https://", "" )
			return FixedName
		end
	
		
		if globalstation:GetState() == GMOD_CHANNEL_STOPPED then
			return ""
		end
		if isstring(FixedName) then
		if FixedName:find(".fm") then 
			FixedName = string.TrimLeft(FixedName,"http://")
			FixedName = string.TrimLeft(FixedName,"https://")
			return FixedName end
		FixedName = string.Replace( FixedName, "_", " " )

		FixedName = string.Replace( FixedName, "%20", " " )
		FixedName = string.Replace( FixedName, "%28", "(" )
		FixedName = string.Replace( FixedName, "%29", ")" )
		FixedName = string.Replace( FixedName, "%5b", "[" )
		FixedName = string.Replace( FixedName, "%5d", "]" )
		FixedName = string.Replace( FixedName, "%26", "&" )


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
	
		FixedName = FixedName:gsub("(%l)(%w*)", function(a,b) 
				return string.upper(a)..b end)



		FixedName = string.Replace( FixedName, "Ytpmv", "YTPMV")
		FixedName = string.Replace( FixedName, "Ytp", "YTP")
		

		FixedName = string.sub( FixedName , 0 , NEnd - 1 )

		end
--  		FixedName = string.Trim(FixedName, ".mp3")
  	end
		return FixedName
end

function ENT:GetAuthor()


	local globalstation = globalstations[self:EntIndex()]




	if IsValid(globalstation) then

		if globalstation:GetState() == GMOD_CHANNEL_STOPPED 
			or globalstation:GetState() == GMOD_CHANNEL_STALLED
		then
			return ""
		end
else

	
	return ""

end

	local a = self.SoundCloudAuthor
	if a == nil then a = "" end
	return a

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
	local color_dim 
	color_dim = Color(0,0,0)
	local color_dimmer = Color(255,255,255,100)
	local fft = {}

	local function wave(e)

		return -math.abs(math.sin(CurTime()*(e/5)%16)*320)

	end

	local scrfont = ghfonts.scrfont
	local verfont = ghfonts.scrfont
	local scrfontsl = ghfonts.scrfontssl
	local scrfontsm = ghfonts.scrfontsm
	local scrfontxs = ghfonts.scrfontxs
	local verfont = ghfonts.verfont

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
			HSVToColor((RealTime()*100)%360,1,0.2)
		color_dimmer = Color(255,255,255,100)

		if globalstation:GetState() != GMOD_CHANNEL_PLAYING and globalstation:GetState() != GMOD_CHANNEL_PAUSED then
			color_dim = color_black
			color_dimmer = Color(255,255,255,100)
		end
		playproxy = math.sin(RealTime()*6%360)*6
		--playproxy2 = math.sin(RealTime()*12%360)*4

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

		color_dim = color_black
		globallevels[self:EntIndex()] =  {0,0}
		
	end



	
	
	local bouncey = -30
	local xorigin = textcenter-16-16-16
	local textcenter = textcenter+10
	local color_rainbow = HSVToColor((RealTime()*100)%360,1,1)
	local glevel = globallevels[self:EntIndex()]

	
	
	if color_dim != nil then  


		draw.RoundedBox(6,
			ee*3, off,
			552, 320,
			color_dim)

	else

		draw.RoundedBox(6,
			ee*3, off,
			552, 320,
			color_black)
	end


local a = true
if IsValid(globalstation) then
	if globalstation:GetState() == GMOD_CHANNEL_STOPPED then 
		a= true 
	else 
		a= false 
	end
end
if a then

		glevel = {wave(1),wave(2),wave(3),wave(4),wave(5),
		wave(6),wave(7),wave(8),wave(9),wave(10),wave(11),
		wave(12),wave(13),wave(14),wave(15),wave(16)}
		for i = 1, 15 do
		if glevel[i] == nil then break end
		if i == #glevel - 1 then continue end
		draw.RoundedBox(0,
			tonumber(xorigin*(-i/3)-18), bouncey,
			16, 			glevel[i],
			color_rainbow)

		end
		glevel = table.Reverse(glevel)

		for i = 1, (#glevel) do

		if glevel[i] == nil then break end
		if i == #glevel or i == #glevel - 1 then continue end
		draw.RoundedBox(0,
			tonumber(xorigin*(-i/3)-18) + xorigin*4.65, bouncey,
			16, 			glevel[i],
			color_rainbow)
		end


end


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
		texttop,scrfont,
		textcenter,textheight/2.5 - 4 + (16-draw.GetFontHeight(scrfont))+playproxy,color_white,TEXT_ALIGN_CENTER)
		draw.DrawText(
		textbottom,scrfont,
		textcenter,textheight/2.5+4+14+playproxy,color_white,TEXT_ALIGN_CENTER)
		
		draw.DrawText(
			"GhRadio v" .. self.Version,
			verfont,
			ee*3,off+320 - draw.GetFontHeight(verfont)+2,
			color_dimmer,TEXT_ALIGN_LEFT)

		local songname = self:GetSongName()
		local snl = #songname
		if snl < 30 then
			draw.DrawText(
			self:GetSongName(),
			scrfont,
			textcenter+playproxy2,off,color_white,TEXT_ALIGN_CENTER)
			draw.DrawText(
			self:GetAuthor(),
			scrfontsm,
			textcenter+playproxy2
			,off+draw.GetFontHeight(scrfont),color_white,TEXT_ALIGN_CENTER)
		elseif snl > 29 and snl < 48 then
			draw.DrawText(
			self:GetSongName(),
			scrfontsl,
			textcenter+playproxy2,off,color_white,TEXT_ALIGN_CENTER)
			draw.DrawText(
			self:GetAuthor(),
			scrfontsm,
			textcenter+playproxy2
			,off+draw.GetFontHeight(scrfontsl),color_white,TEXT_ALIGN_CENTER)
		elseif snl > 48 and snl < 60 then
			draw.DrawText(
			self:GetSongName(),
			scrfontsm,
			textcenter+playproxy2,off,color_white,TEXT_ALIGN_CENTER)
			draw.DrawText(
			self:GetAuthor(),
			scrfontxs,
			textcenter+playproxy2
			,off+draw.GetFontHeight(scrfontsm),color_white,TEXT_ALIGN_CENTER)
		else
			draw.DrawText(
			self:GetSongName(),
			scrfontxs,
			textcenter+playproxy2,off,color_white,TEXT_ALIGN_CENTER)
			draw.DrawText(
			self:GetAuthor(),
			scrfontxs,
			textcenter+playproxy2
			,off+draw.GetFontHeight(scrfontxs),color_white,TEXT_ALIGN_CENTER)			

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
		if !self.SoundCloud then self.SoundCloudAuthor = "" end

    	if IsValid(globalstation) then
    		if !self.Global then
    		globalstation:SetVolume(vol)
    	else
    		globalstation:SetVolume(volmult)
    		end
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

function ENT:SetGlobal(bool)
	bool = tobool(bool)

	for k,v in pairs(player.GetHumans()) do
			v:SendLua([[Entity(]] .. self:EntIndex() .. [[):SetGlobal(]] .. (bool and "1" or "0") .. [[)]])
	end	

end

function ENT:SetLoop(bool)
	bool = tobool(bool)

	for k,v in pairs(player.GetHumans()) do
			v:SendLua([[Entity(]] .. self:EntIndex() .. [[):SetLoop(]] .. (bool and "1" or "0") .. [[)]])
	end	

end

end
--easylua.EndEntity()



MsgC(Color(255,0,0),"[GhRadio] ",Color(255,255,255),"Ran code\n")

end

code()

if SERVER then
	hook.Add("PlayerInitialSpawn","_________",function(p)
		p:SendLua[[globalstations = {} globallevels = {}]]
		code()

end)
end