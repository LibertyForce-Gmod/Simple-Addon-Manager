--[[

SIMPLE ADDON MANAGER
by LibertyForce
http://steamcommunity.com/id/libertyforce/

--]]

local Version = "2.0.0" -- REQUIRES UPDATING VERSION.TXT

local VersionLatest
local VersionNotify = false
local WorkshopReady = false
local Addons
local SaveData
local InstallData
local TagList
local Menu = { }
local dir = "lf_addon_manager"
local savefile = dir .. "/addons.txt"
local ValidTypes = { "Gamemode", "Map", "Weapon", "Vehicle", "NPC", "Tool", "Effects", "Model", "Entity", "ServerContent" }

if not file.Exists( dir, "DATA" ) then file.CreateDir( dir ) end

if file.Exists( "lf_addon_manager.txt", "DATA" ) and not file.Exists( savefile, "DATA" ) then
	local data = util.JSONToTable( file.Read( "lf_addon_manager.txt", "DATA" ) )
	local convert = { }
	if istable( data ) then
		for k,v in pairs( data ) do
			convert[k] = { }
			convert[k].tags = v
		end
	end
	file.Write( savefile, util.TableToJSON( convert, true ) )
	convert = nil
end

local function Save()
	SaveData = { }
	for k, v in pairs( Addons ) do
		SaveData[ k ] = { }
		SaveData[ k ].tags = v.tags or nil
		SaveData[ k ].customname = v.customname or nil
	end
	file.Write( savefile, util.TableToJSON( SaveData, true ) )
	SaveData = nil
end

local function InitAddons()
	
	Addons = { }
	TagList = { }
	SaveData = { }
	
	if file.Exists( savefile, "DATA" ) then
		local data = util.JSONToTable( file.Read( savefile, "DATA" ) )
		if istable( data ) then
			for ID, v in pairs( data ) do
				SaveData[ID] = { }
				SaveData[ID].tags = v.tags
				SaveData[ID].customname = v.customname
			end
		end
	end
	
	InstallData = engine.GetAddons()
	for k, v in pairs( InstallData ) do
	
		local id
		local title
		if tonumber( v.wsid ) > 0 then
			id = tonumber( v.wsid )
			title = v.title
		else
			id = 0
			title = "*** Manually installed GMA files ***"
		end
		
		Addons[id] = {}
		Addons[id].title = title
		Addons[id].active = v.mounted
		
		local tbl = string.Split( v.tags, "," )
		if istable( tbl ) then
			local found
			for _, v in pairs( tbl ) do
				for _, cat in pairs ( ValidTypes ) do
					if v:lower() == cat:lower() then
						Addons[id].cat = cat
						found = true
					end
				end
				if found then break end
			end
			if not found then
				Addons[id].cat = "INVALID"
			end
		end
		
		
		Addons[id].tags = { }
		
		if istable( SaveData[id] ) then
			for k, v in pairs( SaveData[id].tags ) do
				table.insert( Addons[id].tags, tostring( v ) )
				if not table.HasValue( TagList, tostring( v ) ) then
					table.insert( TagList, tostring( v ) )
				end
			end
			table.sort( Addons[id].tags, function( a, b )
				local a = string.lower( a )
				local b = string.lower( b )
				return a < b;
			end )
			Addons[id].customname = SaveData[id].customname
		end
		
	end
	
	table.sort( TagList, function( a, b )
		local a = string.lower( a )
		local b = string.lower( b )
		return a < b;
	end )
	
	SaveData = nil
	
end

local function GetAddons()
	
	if not istable( Addons ) then
		InitAddons()
	end
	
	timer.Simple( 0.1, function()
		Save()
		Menu.Populate()
		Menu.PopulateTags()
	end )
	
end


local function PopupWindow( pw, ph )
	local f = vgui.Create( "DFrame" )
	local fw, fh = ScrW(), ScrH()
	local padw, padh = ( fw - pw ) / 2, ( fh - ph ) / 2
	f:SetSize( fw, fh )
	f:SetTitle( "" )
	f:SetDraggable( false )
	f:ShowCloseButton( false )
	f:Center()
	f:MakePopup()
	f:DockPadding( padw, padh, padw, padh )
	f.Paint = function( self, w, h )
		surface.SetDrawColor( 0, 0, 0, 255 )
		surface.DrawOutlinedRect( padw - 1, padh - 1, pw + 2, ph + 2 )
		surface.DrawOutlinedRect( padw - 2, padh - 2, pw + 4, ph + 4 )
		surface.SetDrawColor( 0, 0, 0, 200 )
		surface.DrawRect( 0, 0, w, h )
		return true
	end
	
	local p = f:Add( "DPanel" )
	p:DockPadding( 10, 10, 10, 10 )
	p:Dock( FILL )
	
	return f, p
end

local function PopupConfirm( pw, ph, b1_label, b2_label, text1, text2, header, b1_width, b2_width )
	local f, p = PopupWindow( pw, ph )
	
	local h
	if header then
		h = p:Add( "DLabel" )
		h:Dock( TOP )
		h:SetFont( "DermaLarge" )
		h:SetText( header )
		h:SetDark( true )
		h:SizeToContents()
	end
	local t1
	if text1 then
		t1 = p:Add( "DLabel" )
		t1:Dock( TOP )
		t1:SetFont( "Font_AddonTitle" )
		t1:SetText( text1 )
		t1:SetDark( true )
		t1:SizeToContents()
	end
	local t2
	if text2 then
		t2 = p:Add( "DLabel" )
		t2:Dock( TOP )
		t2:SetText( text2 )
		t2:SetDark( true )
		t2:SizeToContents()
	end
	
	local b1 = p:Add( "DButton" )
	local b2 = p:Add( "DButton" )
	
	b1:SetHeight( 20 )
	b1:Dock( LEFT )
	b1:DockMargin( 20, 20, 20, 0 )
	b1:SetWidth( b1_width or 100 )
	b1:SetText( b1_label )
	
	b2:SetHeight( 20 )
	b2:Dock( RIGHT )
	b2:DockMargin( 20, 20, 20, 0 )
	b2:SetWidth( b2_width or 120 )
	b2:SetText( b2_label )
	
	return f, b1, b2, t1, t2, h
end


function Menu.Setup()
	
	if not WorkshopReady then
		MsgC( Color( 255, 0, 0 ), "Error: Addons not initialized. Please wait for all downloads to finish.\n" )
		return
	end
	
	if IsValid( Menu.Frame ) then
		Menu.Frame:Close()
		return
	end
	
	if VersionNotify then
		
		VersionNotify = false
		
		local f, p = PopupWindow( 450, 158 )
		
		local t = p:Add( "DLabel" )
		t:Dock( TOP )
		t:SetFont( "DermaLarge" )
		t:SetText( "Update available!" )
		t:SetDark( true )
		t:SizeToContents()
		
		local t = p:Add( "DLabel" )
		t:Dock( TOP )
		t:SetText( "\nThere is an update to version "..VersionLatest.." available for Simple Addon Manager.\nTo get the latest version, please copy and paste the URL below to your browser:\n" )
		t:SetDark( true )
		t:SizeToContents()
		
		local t = p:Add( "RichText" )
		t:Dock( TOP )
		t:InsertColorChange( 0, 0, 0, 255 )
		t:AppendText( "https://github.com/LibertyForce-Gmod/Simple-Addon-Manager/releases/latest" )
		t:SetVerticalScrollbarEnabled( false )
		
		local b = p:Add( "DButton" )
		b:Dock( LEFT )
		b:DockMargin( 20, 10, 20, 0 )
		b:SetWidth( 180 )
		b:SetHeight( 20 )
		b:SetText( "Copy URL to clipboard" )
		b.DoClick = function() SetClipboardText( "https://github.com/LibertyForce-Gmod/Simple-Addon-Manager/releases/latest" ) end
		
		local b = p:Add( "DButton" )
		b:Dock( RIGHT )
		b:DockMargin( 20, 10, 20, 0 )
		b:SetWidth( 100 )
		b:SetHeight( 20 )
		b:SetText( "Close" )
		b.DoClick = function() f:Close() timer.Simple( 0, Menu.Setup ) end
		
		return
		
	end
	
	Menu.Frame = vgui.Create( "DFrame" )
	local fw, fh = 900, math.Round( ScrH() * 83 / 100, 0 )
	Menu.Frame:SetSize( fw, fh )
	Menu.Frame:SetTitle( "Simple Addon Manager - Version "..Version.." - Created by LibertyForce" )
	Menu.Frame:SetVisible( true )
	Menu.Frame:SetDraggable( true )
	Menu.Frame:SetScreenLock( false )
	Menu.Frame:ShowCloseButton( true )
	Menu.Frame:Center()
	Menu.Frame:MakePopup()
	Menu.Frame:SetKeyboardInputEnabled( true )
	
	Menu.Frame.btnMinim:SetVisible( false )
	Menu.Frame.btnMaxim:SetVisible( false )
	
	
	local AddonsReadable
	local Selected_Addons = { }
	local Selected_Tags = { }
	local Selected_TagFilter = { }
	local Selected_Cat
	local SortType = 1
	local color_normal = Color( 255, 255, 255, 255 )
	local color_selected = Color( 204, 232, 255, 255 )
	local last_selected = 1
	local last_selected_tag = 1
	
	
	local function TagCheckIfNeeded( tag )
		local inuse
		for id, v in pairs( Addons ) do
			if table.HasValue( v.tags, tag ) then
				inuse = true
				break
			end
		end
		if not inuse then
			table.RemoveByValue( TagList, tag )
			Selected_Tags[tag] = nil
			Selected_TagFilter[tag] = nil
			Menu.NoSelectedTags.Count()
		end
	end
	
	local function AddonToggleSelected( value )
		if #table.GetKeys( Selected_Addons ) < 1 then return end
		for id in pairs( Selected_Addons ) do
			steamworks.SetShouldMountAddon( id, value )
			Addons[id].active = value
		end
		steamworks.ApplyAddons()
		Menu.Populate()
	end
	
	local function AddonToggleAll( value )
		for id in pairs( Addons ) do
			steamworks.SetShouldMountAddon( id, value )
			Addons[id].active = value
		end
		steamworks.ApplyAddons()
		GetAddons()
	end
	
	local function AddonLikeSelected()
		
		if #table.GetKeys( Selected_Addons ) < 1 then return end
		local count = #table.GetKeys( Selected_Addons )
		local text1 = "Give a LIKE to ".. count .." selected addons?"
		local text2 = "\nThis can not be undone.\n\nThank you for supporting the addon creators."
		local b1_label = "Give LIKE"
		local b2_label = "Cancel"
		
		local f, b1, b2 = PopupConfirm( 350, 127, b1_label, b2_label, text1, text2 )
		
		b1.DoClick = function()
			for id in pairs( Selected_Addons ) do
				steamworks.Vote( id, true )
			end
			f:Close()
		end
		
		b2.DoClick = function() f:Close() end
		
	end
	
	local function AddonDeleteSelected()
		
		if #table.GetKeys( Selected_Addons ) < 1 then return end
		local count = #table.GetKeys( Selected_Addons )
		local header = "Warning! Uninstalling " .. count .. " addons"
		local text1 = "\nDo you want to uninstall ".. count .." selected addons?"
		local text2 = "\nThis can not be undone.\n\nIt is recommended to restart Garry's Mod after uninstalling addons."
		local b1_label = "Confirm to uninstall"
		local b2_label = "Cancel"
		
		local f, b1, b2, t1, t2, h = PopupConfirm( 450, 176, b1_label, b2_label, text1, text2, header )
		
		b1:SetEnabled( false )
		timer.Simple( 3, function() if IsValid( f ) then b1:SetEnabled( true ) end end )
		
		b1.DoClick = function()
			h:SetText( "Uninstalling..." )
			t1:SetText( "Please wait. This can take a while." )
			t2:SetText( "" )
			b1:SetEnabled( false )
			b2:SetEnabled( false )
			for id in pairs( Selected_Addons ) do
				Selected_Addons[id] = nil
				Addons[id] = nil
				steamworks.Unsubscribe( id )
			end
			timer.Simple( 0.5, function()
				steamworks.ApplyAddons()
				Selected_Addons = { }
				Selected_Tags = { }
				Selected_TagFilter = { }
				Selected_Cat = nil
				Menu.NoSelectedAddons.Count()
				Menu.NoSelectedTags.Count()
				Addons = nil
			end )
			timer.Simple( 3, function()
				GetAddons()
				f:Close()
			end )
		end
		
		b2.DoClick = function() f:Close() end
	
	end
	
	local function AddonToggleByTag( value )
		if #table.GetKeys( Selected_Tags ) < 1 then return end
		for tag in pairs( Selected_Tags ) do
			for id in pairs( Addons ) do
				if table.HasValue( Addons[id].tags, tag ) then
					steamworks.SetShouldMountAddon( id, value )
					Addons[id].active = value
				end
			end
		end
		steamworks.ApplyAddons()
		Menu.Populate()
	end
	
	local function AddonChangeTags( add, newtag )
		if ( not newtag and #table.GetKeys( Selected_Tags ) < 1 ) or newtag == "" then return end
		if #table.GetKeys( Selected_Addons ) < 1 then return end
		
		if newtag then
		
			for id in pairs( Selected_Addons ) do
				if not table.HasValue( Addons[id].tags, newtag ) then
					table.insert( Addons[id].tags, newtag )
					table.sort( Addons[id].tags, function( a, b )
						local a = string.lower( a )
						local b = string.lower( b )
						return a < b;
					end )
				end
			end
			
			if not table.HasValue( TagList, newtag ) then
				table.insert( TagList, newtag )
			end
			table.sort( TagList, function( a, b )
				local a = string.lower( a )
				local b = string.lower( b )
				return a < b;
			end )
			
		else
		
			for tag in pairs( Selected_Tags ) do
				for id in pairs( Selected_Addons ) do
					if add and not table.HasValue( Addons[id].tags, tag ) then
						table.insert( Addons[id].tags, tag )
						table.sort( Addons[id].tags, function( a, b )
							local a = string.lower( a )
							local b = string.lower( b )
							return a < b;
						end )
					elseif not add and table.HasValue( Addons[id].tags, tag ) then
						table.RemoveByValue( Addons[id].tags, tag )
					end
				end
				if not add then
					TagCheckIfNeeded( tag )
				end
			end
		
		end
		
		GetAddons()
	end
	
	local function AddonSetCustomname( id )
		local f, p = PopupWindow( 300, 95 )
		
		local t = p:Add( "DLabel" )
		t:Dock( TOP )
		t:DockMargin( 0, 0, 0, 10 )
		t:SetFont( "Font_AddonTitle" )
		t:SetText( "Enter new name:" )
		t:SetDark( true )
		t:SizeToContents()
		
		local TextEntry = p:Add( "DTextEntry" )
		TextEntry:Dock( TOP )
		TextEntry:DockMargin( 0, 0, 0, 10 )
		TextEntry:SetValue( Addons[id].customname or "" )
		local function Send()
			local name = TextEntry:GetValue()
			if name ~= "" and name ~= Addons[id].title then
				Addons[id].customname = name
				GetAddons()
			elseif Addons[id].customname then
				Addons[id].customname = nil
				GetAddons()
			end
			f:Close()
		end
		TextEntry.OnEnter = Send
		
		local b1 = p:Add( "DButton" )
		local b2 = p:Add( "DButton" )
		
		b1:Dock( LEFT )
		b1:SetWidth( 130 )
		b1:SetText( "OK" )
		b1.DoClick = Send
		
		b2:Dock( RIGHT )
		b2:SetWidth( 130 )
		b2:SetText( "Cancel" )
		b2.DoClick = function() Menu.Frame:SetVisible( true ) f:Close() end
	end
	
	local function AddonRemoveCustomnames()
		local text1 = "Remove ALL custom names?"
		local text2 = "\nThis can not be undone."
		local b1_label = "Remove all"
		local b2_label = "Cancel"
		
		local f, b1, b2 = PopupConfirm( 300, 101, b1_label, b2_label, text1, text2 )
		
		b1.DoClick = function()
			for k, v in pairs( Addons ) do
				v.customname = nil
			end
			GetAddons()
			f:Close()
		end
		
		b2.DoClick = function() f:Close() end
	end
	
	
	function Menu.Populate()
	
		Menu.Scroll:Clear()
		Menu.List = { }
		AddonsReadable = { }
		local AddonFilter = Menu.AddonFilter:GetValue() or nil
		
		local function IsCat( k, v )
			if Selected_Cat and Selected_Cat ~= v.cat then
				return false
			else
				return true
			end
		end
		
		local function IsTag( k, v )
			if #table.GetKeys( Selected_TagFilter ) > 0 then
				for _, tag in pairs( v.tags ) do
					if Selected_TagFilter[tag] then
						return true
					end
				end
				return false
			else
				return true
			end
		end
		
		local function IsFilter( k, v )
			if not AddonFilter or AddonFilter == "" then
				return true
			else
				local title = v.title
				if v.customname then title = v.customname .. "     { " .. title .. " }" end
				local tbl = string.Split( AddonFilter, " " )
				for _, substr in pairs( tbl ) do
					if not string.match( title:lower(), string.PatternSafe( substr:lower() ) ) then
						return false
					end
				end
				return true
			end
		end
		
		for k, v in pairs( Addons ) do
			if IsCat( k, v ) and IsTag( k, v ) and IsFilter( k, v ) then
				local enabled = ""
				if v.active then enabled = "✔" end
				local title = v.title
				if v.customname then title = v.customname .. "     { " .. title .. " }" end
				table.insert( AddonsReadable, { k, enabled, title, table.concat( v.tags, "; " ), v.cat } )
			end
		end
		
		table.sort( AddonsReadable, function( a, b )
			local a1, b1 = a[1], b[1]
			local a2, b2 = a[2], b[2]
			local a3, b3 = string.lower( a[3] ), string.lower( b[3] )
			local a4, b4 = string.lower( a[4] ), string.lower( b[4] )
			
			if SortType == 3 or SortType == 4 or SortType == 5 then -- Sort by Enabled
				if a2 ~= b2 then return a2 > b2; end
			end
			if SortType == 2 or SortType == 5 then -- Sort by Tags
				if a4 ~= b4 then return a4 < b4; end
			end
			if SortType == 1 or SortType == 2 or SortType == 4 or SortType == 5 then -- Sort by Name
				if a3 ~= b3 then return a3 < b3; end
			end
			return a1 < b1; -- Always sort by ID
		end )
		
		for k, v in pairs( AddonsReadable ) do
			
			local id = v[1]
			Menu.List[id] = { }
			
			Menu.List[id].panel = Menu.Scroll:Add( "DButton" )
			Menu.List[id].panel:Dock( TOP )
			Menu.List[id].panel:SetHeight( 35 )
			Menu.List[id].panel:DockMargin( 2, 0, 2, 4 )
			--Menu.List[id].panel:DockPadding( 3, 3, 3, 3 )
			Menu.List[id].panel:SetText( "" )
			Menu.List[id].panel.index = k
			
			Menu.List[id].panel.color = color_normal
			if Selected_Addons[id] then Menu.List[id].panel.color = color_selected end
			Menu.List[id].panel.Paint = function( self, w, h )
				draw.RoundedBox( 15, 0, 0, w, h, Menu.List[id].panel.color ) return true
			end
			
			Menu.List[id].panel.DoClick = function()
				if input.IsKeyDown( KEY_LSHIFT ) then
					local first = math.min( k, last_selected )
					local last = math.max( k, last_selected )
					local line_select = true
					if not Selected_Addons[id] then line_select = false end
					for index = first, last do
						local tbl = AddonsReadable[index]
						local line_id = tbl[1]
						if not line_select then
							Selected_Addons[line_id] = true
							Menu.List[line_id].panel.color = color_selected
						else
							Selected_Addons[line_id] = nil
							Menu.List[line_id].panel.color = color_normal
						end
					end
				else
					if not Selected_Addons[id] then
						Selected_Addons[id] = true
						Menu.List[id].panel.color = color_selected
					else
						Selected_Addons[id] = nil
						Menu.List[id].panel.color = color_normal
					end
					last_selected = k
				end
				Menu.NoSelectedAddons.Count()
			end
			
			Menu.List[id].panel.DoRightClick = function()
				local ContextMenu = Menu.List[id].panel:Add( "DMenu" )
				
				ContextMenu:AddOption( "Open Workshop", function()
					gui.OpenURL( "https://steamcommunity.com/sharedfiles/filedetails/?id=" .. tostring( id ) )
				end ):SetIcon( "icon16/world_go.png" )
				ContextMenu:AddOption( "Copy URL", function()
					SetClipboardText( "https://steamcommunity.com/sharedfiles/filedetails/?id=" .. tostring( id ) )
				end ):SetIcon( "icon16/page_link.png" )
				ContextMenu:AddOption( "Copy ID", function()
					SetClipboardText( tostring( id ) )
				end ):SetIcon( "icon16/script_code.png" )
				
				ContextMenu:AddSpacer()
				
				ContextMenu:AddOption( "Add custom name", function()
					AddonSetCustomname( id )
				end ):SetIcon( "icon16/textfield_add.png" )
				
				if Addons[id].customname then
					ContextMenu:AddOption( "Remove custom name", function()
						Addons[id].customname = nil
						GetAddons()
					end ):SetIcon( "icon16/textfield_delete.png" )
				end
				
				ContextMenu:Open()
			end
			
			Menu.List[id].checkbox = Menu.List[id].panel:Add( "DCheckBox" )
			Menu.List[id].checkbox:SetPos( 10, 10 )
			Menu.List[id].checkbox:SetChecked( Addons[id].active )
			Menu.List[id].checkbox.DoClick = function()
				local value = not Addons[id].active
				steamworks.SetShouldMountAddon( id, value )
				Addons[id].active = value
				steamworks.ApplyAddons()
				Menu.Populate()
			end
			
			Menu.List[id].name = Menu.List[id].panel:Add( "DLabel" )
			Menu.List[id].name:SetPos( 40, 3 )
			Menu.List[id].name:SetSize( 530, 16 )
			Menu.List[id].name:SetAutoStretchVertical( false )
			Menu.List[id].name:SetFont( "Font_AddonTitle" )
			Menu.List[id].name:SetText( v[3] )
			Menu.List[id].name:SetDark( true )
			Menu.List[id].name:SetWrap( false )
			
			Menu.List[id].idno = Menu.List[id].panel:Add( "DLabel" )
			Menu.List[id].idno:SetPos( 580, 3 )
			Menu.List[id].idno:SetSize( 80, 13 )
			Menu.List[id].idno:SetAutoStretchVertical( false )
			Menu.List[id].idno:SetText( v[1] )
			Menu.List[id].idno:SetDark( true )
			Menu.List[id].idno:SetWrap( false )
			
			Menu.List[id].tags = Menu.List[id].panel:Add( "DLabel" )
			Menu.List[id].tags:SetPos( 40, 20 )
			Menu.List[id].tags:SetSize( 530, 13 )
			Menu.List[id].tags:SetAutoStretchVertical( false )
			Menu.List[id].tags:SetText( v[4] )
			Menu.List[id].tags:SetDark( true )
			Menu.List[id].tags:SetWrap( false )
			
			Menu.List[id].cat = Menu.List[id].panel:Add( "DLabel" )
			Menu.List[id].cat:SetPos( 580, 20 )
			Menu.List[id].cat:SetSize( 80, 13 )
			Menu.List[id].cat:SetAutoStretchVertical( false )
			Menu.List[id].cat:SetText( v[5] )
			Menu.List[id].cat:SetDark( true )
			Menu.List[id].cat:SetWrap( false )
			
		end
		
	end
	
	function Menu.PopulateTags()
	
		Menu.RightScroll:Clear()
		Menu.RightList = { }
		
		for k, v in pairs( TagList ) do
			
			local id = v
			Menu.RightList[id] = { }
			
			Menu.RightList[id].panel = Menu.RightScroll:Add( "DButton" )
			Menu.RightList[id].panel:Dock( TOP )
			Menu.RightList[id].panel:SetHeight( 20 )
			Menu.RightList[id].panel:DockMargin( 2, 2, 2, 2 )
			Menu.RightList[id].panel:DockPadding( 3, 3, 3, 3 )
			Menu.RightList[id].panel:SetText( "" )
			Menu.RightList[id].panel.index = k
			
			Menu.RightList[id].panel.color = color_normal
			if Selected_Tags[id] then Menu.RightList[id].panel.color = color_selected end
			Menu.RightList[id].panel.Paint = function( self, w, h )
				draw.RoundedBox( 10, 0, 0, w, h, Menu.RightList[id].panel.color ) return true
			end
			
			Menu.RightList[id].panel.DoClick = function()
				if input.IsKeyDown( KEY_LSHIFT ) then
					local first = math.min( k, last_selected_tag )
					local last = math.max( k, last_selected_tag )
					local line_select = true
					if not Selected_Tags[id] then line_select = false end
					for index = first, last do
						local line_id = TagList[index]
						if not line_select then
							Selected_Tags[line_id] = true
							Menu.RightList[line_id].panel.color = color_selected
						else
							Selected_Tags[line_id] = nil
							Menu.RightList[line_id].panel.color = color_normal
						end
					end
				else
					if not Selected_Tags[id] then
						Selected_Tags[id] = true
						Menu.RightList[id].panel.color = color_selected
					else
						Selected_Tags[id] = nil
						Menu.RightList[id].panel.color = color_normal
					end
				end
				last_selected_tag = k
				Menu.NoSelectedTags.Count()
			end
			
			Menu.RightList[id].checkbox = Menu.RightList[id].panel:Add( "DCheckBox" )
			Menu.RightList[id].checkbox:SetPos( 5, 2 )
			Menu.RightList[id].checkbox:SetChecked( Selected_TagFilter[id] )
			
			Menu.RightList[id].checkbox.DoClick = function()
				if not Selected_TagFilter[id] then
					Selected_TagFilter[id] = true
					Menu.RightList[id].checkbox:SetValue( true )
				else
					Selected_TagFilter[id] = nil
					Menu.RightList[id].checkbox:SetValue( false )
				end
				Menu.Populate()
			end
			
			Menu.RightList[id].name = Menu.RightList[id].panel:Add( "DLabel" )
			Menu.RightList[id].name:SetPos( 25, 0 )
			Menu.RightList[id].name:SetSize( 135, 20 )
			Menu.RightList[id].name:SetAutoStretchVertical( false )
			Menu.RightList[id].name:SetText( id )
			Menu.RightList[id].name:SetDark( true )
			Menu.RightList[id].name:SetWrap( false )
			
		end
		
	end
	
	
	Menu.MainPanel = Menu.Frame:Add( "DPanel" )
	Menu.MainPanel:Dock( FILL )
	
	Menu.Top = Menu.MainPanel:Add( "DPanel" )
	Menu.Top:SetHeight( 60 )
	Menu.Top:DockPadding( 10, 10, 10, 10 )
	Menu.Top:Dock( TOP )
	Menu.Top:SetPaintBackground( false )
	
	Menu.Right = Menu.MainPanel:Add( "DPanel" )
	Menu.Right:SetWidth( 200 )
	Menu.Right:DockPadding( 10, 10, 10, 10 )
	Menu.Right:Dock( RIGHT )
	Menu.Right:SetPaintBackground( false )
	
	Menu.RightTop = Menu.Right:Add( "DPanel" )
	Menu.RightTop:SetHeight( 120 )
	--Menu.RightTop:DockPadding( 10, 10, 10, 10 )
	Menu.RightTop:Dock( TOP )
	Menu.RightTop:SetPaintBackground( false )
	
	Menu.RightScroll = Menu.Right:Add( "DScrollPanel" )
	Menu.RightScroll:Dock( FILL )
	
	Menu.Scroll = Menu.MainPanel:Add( "DScrollPanel" )
	Menu.Scroll:Dock( FILL )
	
	
	local row1, row2 = 5, 30
	local col1 = 10
	
	local b = Menu.Top:Add( "DButton" )
	b:SetPos( 10, row1 )
	b:SetSize( 130, 20 )
	b:SetText( "Undo Selection" )
	b.DoClick = function()
		Selected_Addons = { }
		last_selected = 1
		Menu.NoSelectedAddons.Count()
		Menu.Populate()
	end
	
	local b = Menu.Top:Add( "DButton" )
	b:SetPos( 10, row2 )
	b:SetSize( 60, 20 )
	b:SetText( "Select All" )
	b.DoClick = function()
		local DoSelect
		for k, v in pairs( AddonsReadable ) do
			if not Selected_Addons[v[1]] then
				DoSelect = true
				break
			end
		end
		if DoSelect then
			for k, v in pairs( AddonsReadable ) do
				Selected_Addons[v[1]] = true
			end
		else
			for k, v in pairs( AddonsReadable ) do
				Selected_Addons[v[1]] = nil
			end
		end
		last_selected = 1
		Menu.NoSelectedAddons.Count()
		Menu.Populate()
	end
	
	Menu.NoSelectedAddons = Menu.Top:Add( "DLabel" )
	function Menu.NoSelectedAddons.Count()
		local No = tostring( #table.GetKeys( Selected_Addons ) )
		Menu.NoSelectedAddons:SetText( No .. " selected" )
	end
	Menu.NoSelectedAddons:SetPos( 75, row2 )
	Menu.NoSelectedAddons:SetSize( 70, 20 )
	Menu.NoSelectedAddons:SetDark( true )
	Menu.NoSelectedAddons.Count()
	
	local c = Menu.Top:Add( "DComboBox" )
	c:SetPos( 150, row1 )
	c:SetSize( 150, 20 )
	c:SetSortItems( false )
	c:SetValue( "Sort by Name" )
	c:AddChoice( "Sort by Name" )
	c:AddChoice( "Sort by Tag -> Name" )
	c:AddChoice( "Sort by Enabled -> Name" )
	c:AddChoice( "Sort by Enabled -> Tag" )
	c:AddChoice( "Sort by ID" )
	c.OnSelect = function( panel, index, value )
		if index == 1 then SortType = 1
		elseif index == 2 then SortType = 2
		elseif index == 3 then SortType = 4
		elseif index == 4 then SortType = 5
		else SortType = 0 end
		Menu.Populate()
	end
	
	local c = Menu.Top:Add( "DComboBox" )
	c:SetPos( 310, row1 )
	c:SetSize( 150, 20 )
	c:SetSortItems( false )
	c:SetValue( "All Types" )
	c:AddChoice( "All Types" )
	for _, cat in pairs( ValidTypes ) do
		c:AddChoice( cat )
	end
	c:AddChoice( "Invalid category" )
	c.OnSelect = function( panel, index, value )
		if index == 1 then Selected_Cat = nil
		elseif value == "Invalid category" then Selected_Cat = "INVALID"
		else Selected_Cat = value end
		Menu.Populate()
	end
	
	local t = Menu.Top:Add( "DLabel" )
	t:SetPos( 155, row2 )
	t:SetSize( 40, 20 )
	t:SetText( "Search:" )
	t:SetDark( true )
	
	Menu.AddonFilter = Menu.Top:Add( "DTextEntry" )
	Menu.AddonFilter:SetPos( 200, row2 )
	Menu.AddonFilter:SetSize( 260, 20 )
	Menu.AddonFilter:SetUpdateOnType( true )
	Menu.AddonFilter.OnEnter = function() end
	Menu.AddonFilter.OnValueChange = function()
		if timer.Exists( "lf_addon_manager_filter_refresh" ) then
			timer.Start( "lf_addon_manager_filter_refresh" )
		else
			timer.Create( "lf_addon_manager_filter_refresh", 0.2, 1, Menu.Populate )
		end
	end
	
	local b = Menu.Top:Add( "DButton" )
	b:SetPos( 480, row1 )
	b:SetSize( 120, 20 )
	b:SetText( "Enable Selected" )
	b.DoClick = function() AddonToggleSelected( true ) end
	
	local b = Menu.Top:Add( "DButton" )
	b:SetPos( 480, row2 )
	b:SetSize( 120, 20 )
	b:SetText( "Disable Selected" )
	b.DoClick = function() AddonToggleSelected( false ) end
	
	local b = Menu.Top:Add( "DButton" )
	b:SetPos( 620, row1 )
	b:SetSize( 120, 20 )
	b:SetText( "Enable by Tag" )
	b.DoClick = function() AddonToggleByTag( true ) end
	
	local b = Menu.Top:Add( "DButton" )
	b:SetPos( 620, row2 )
	b:SetSize( 120, 20 )
	b:SetText( "Disable by Tag" )
	b.DoClick = function() AddonToggleByTag( false ) end
	
	local b = Menu.Top:Add( "DButton" )
	b:SetPos( 760, row2 )
	b:SetSize( 120, 20 )
	b:SetText( "More" )
	b:SetIsMenu( true ) -- Prevent Menu to autoclose (and therefore immediately reopen) if the button is clicked
	local ContextMenu
	b.DoClick = function()
		if IsValid( ContextMenu ) then CloseDermaMenus() return end -- Menu open = Menu gets closed, won't run unless SetIsMenu
		ContextMenu = Menu.MainPanel:Add( "DMenu" )
		ContextMenu:SetPos( 690, row2 + 20 )
		ContextMenu:AddOption( "Enable all", function() AddonToggleAll( true ) end ):SetIcon( "icon16/tick.png" )
		ContextMenu:AddOption( "Disable all", function() AddonToggleAll( false ) end ):SetIcon( "icon16/cross.png" )
		ContextMenu:AddSpacer():SetWide( 200 )
		ContextMenu:AddOption( "Uninstall Selected", AddonDeleteSelected ):SetIcon( "icon16/bin.png" )
		ContextMenu:AddOption( "Give LIKE to Selected", AddonLikeSelected ):SetIcon( "icon16/thumb_up.png" )
		ContextMenu:AddOption( "Remove all custom names", AddonRemoveCustomnames ):SetIcon( "icon16/textfield_delete.png" )
		ContextMenu.OnClose = function() print( "TEST" ) end
	end
	
	
	local TextEntry = Menu.RightTop:Add( "DTextEntry" )
	TextEntry:Dock( TOP )
	local function Send()
		AddonChangeTags( true, TextEntry:GetValue() )
	end
	TextEntry.OnEnter = Send
	
	local b = Menu.RightTop:Add( "DButton" )
	b:SetPos( 40, 30 )
	b:SetSize( 100, 20 )
	b:SetText( "Create new Tag" )
	b.DoClick = Send
	
	local b = Menu.RightTop:Add( "DButton" )
	b:SetPos( 0, 60 )
	b:SetSize( 85, 20 )
	b:SetText( "Add Tags" )
	b.DoClick = function() AddonChangeTags( true ) end
	
	local b = Menu.RightTop:Add( "DButton" )
	b:SetPos( 95, 60 )
	b:SetSize( 85, 20 )
	b:SetText( "Remove Tags" )
	b.DoClick = function() AddonChangeTags( false ) end
	
	local b = Menu.RightTop:Add( "DButton" )
	b:SetPos( 0, 90 )
	b:SetSize( 60, 20 )
	b:SetText( "Select All" )
	b.DoClick = function()
		if #TagList == #table.GetKeys( Selected_Tags ) then
			for k, v in pairs( TagList ) do
				Selected_Tags[v] = nil
			end
		else
			for k, v in pairs( TagList ) do
				Selected_Tags[v] = true
			end
		end
		last_selected_tag = 1
		Menu.NoSelectedTags.Count()
		Menu.PopulateTags()
	end
	
	Menu.NoSelectedTags = Menu.RightTop:Add( "DLabel" )
	function Menu.NoSelectedTags.Count()
		local No = tostring( #table.GetKeys( Selected_Tags ) )
		Menu.NoSelectedTags:SetText( No .. " Tags selected" )
	end
	Menu.NoSelectedTags:SetPos( 70, 90 )
	Menu.NoSelectedTags:SetSize( 110, 20 )
	Menu.NoSelectedTags:SetDark( true )
	Menu.NoSelectedTags.Count()
	
	Addons = nil
	GetAddons()
	
end


hook.Add( "WorkshopEnd", "lf_addon_manager_wshook", function()
	WorkshopReady = true
end )

http.Fetch( "https://raw.githubusercontent.com/LibertyForce-Gmod/Simple-Addon-Manager/master/VERSION.txt",
	function( body, len, headers, code )
		VersionLatest = body or Version
		if VersionLatest != Version then
			VersionNotify = true
			print( "Simple Addon Manager "..Version.." - Successfully loaded. UPDATE TO VERSION "..VersionLatest.." AVAILABLE: https://github.com/LibertyForce-Gmod/Simple-Addon-Manager/releases/latest" )
		else
			print( "Simple Addon Manager "..Version.." - Successfully loaded. You are using the latest version." )
		end
	end,
	function( reason )
		print( "Simple Addon Manager "..Version.." - Successfully loaded. Error: Could not check for updates. ["..reason.."]" )
	end
)

surface.CreateFont( "Font_AddonTitle", {
	font = "Roboto",
	extended = false,
	size = 16,
	weight = 1000,
	antialias = true,
} )

concommand.Add("addon_manager", Menu.Setup )
concommand.Add("addons", Menu.Setup )
