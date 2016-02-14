--[[

SIMPLE ADDON MANAGER
by LibertyForce
http://steamcommunity.com/id/libertyforce/

--]]

local Version = "1.0"

local Addons
local SaveData
local Tags
local Menu = { }

local function Save()
	for k, v in pairs( Addons ) do
		SaveData[k] = v.tag or nil
	end
	file.Write( "lf_addon_manager.txt", util.TableToJSON( SaveData, true ) )
end

local function GetAddons()
	
	Addons = { }
	Tags = { }
	if !istable( SaveData ) then SaveData = { } end
	
	if file.Exists( "lf_addon_manager.txt", "DATA" ) then
		data = util.JSONToTable( file.Read( "lf_addon_manager.txt", "DATA" ) )
		if istable( data ) then
			for k,v in pairs( data ) do
				SaveData[tostring(k)] = v
			end
		end
	end
	
	timer.Simple( 0.1, function()
	
		local installed = engine.GetAddons()
		table.SortByMember( installed, "title", true )
		for k, v in pairs( installed ) do
			local key
			if tonumber(v.wsid) > 0 then key = tostring(v.wsid) else key = "0" end
			Addons[key] = {}
			Addons[key].title = v.title
			Addons[key].active = v.mounted
			Addons[key].tag = { }
			if istable( SaveData[key] ) then
				for k, v in pairs( SaveData[key] ) do
					table.insert( Addons[key].tag, tostring(v) )
					if !table.HasValue( Tags, tostring(v) ) then
						table.insert( Tags, tostring(v) )
					end
				end
			end
		end
		
		Save()
		Menu.List.Populate()
		Menu.Tags.Populate()
	
	end )
	
end

function Menu.Setup()
	
	if IsValid( Menu.Frame ) then
		Menu.Frame:Close()
		return
	end
	
	Menu.Frame = vgui.Create( "DFrame" )
	local fw, fh = 900, 800
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
	
	Menu.List = Menu.Frame:Add( "DListView" )
	Menu.List:Dock( LEFT )
	Menu.List:SetWidth( 650 )
	Menu.List:DockMargin( 10, 10, 10, 10 )
	Menu.List:SetMultiSelect( true )
	Menu.List:AddColumn( "ID" ):SetFixedWidth( 80 )
	Menu.List:AddColumn( " " ):SetFixedWidth( 20 )
	Menu.List:AddColumn( "Name" )
	Menu.List:AddColumn( "Tags" )
	Menu.List.DoDoubleClick = function( _, _, line )
		gui.OpenURL( "http://steamcommunity.com/sharedfiles/filedetails/?id="..line:GetValue(1) )
	end
	
	function Menu.List.Populate()
		Menu.List:Clear()
		for k, v in pairs( Addons ) do
			local enabled = ""
			if v.active then enabled = "✔" end
			Menu.List:AddLine( k, enabled, v.title, table.concat( v.tag, "; " ) )
		end
		Menu.List:SortByColumn( 3 )
	end
	
	Menu.Right = Menu.Frame:Add( "DPanel" )
	Menu.Right:SetHeight( 110 )
	Menu.Right:DockMargin( 10, 10, 10, 10 )
	Menu.Right:DockPadding( 10, 10, 10, 10 )
	Menu.Right:Dock( TOP )
	
	local function AddonToggle( value )
		local sel = Menu.List:GetSelected()
		for k, v in pairs( sel ) do
			local id = tostring( v:GetValue(1) )
			steamworks.SetShouldMountAddon( id, value )
		end
		steamworks.ApplyAddons()
		GetAddons()
	end
	
	local b = Menu.Right:Add( "DButton" )
	b:Dock( TOP )
	b:DockMargin( 0, 0, 0, 10 )
	b:SetHeight( 40 )
	b:SetText( "Enable selected Addons" )
	b.DoClick = function() AddonToggle( true ) end
	
	local b = Menu.Right:Add( "DButton" )
	b:Dock( TOP )
	b:DockMargin( 0, 0, 0, 40 )
	b:SetHeight( 40 )
	b:SetText( "Disable selected Addons" )
	b.DoClick = function() AddonToggle( false ) end
	
	Menu.Right = Menu.Frame:Add( "DPanel" )
	Menu.Right:SetHeight( 90 )
	Menu.Right:DockMargin( 10, 10, 10, 10 )
	Menu.Right:DockPadding( 10, 10, 10, 10 )
	Menu.Right:Dock( TOP )
	
	local function AddonToggle( value )
		for k, v in pairs( Addons ) do
			steamworks.SetShouldMountAddon( k, value )
		end
		steamworks.ApplyAddons()
		GetAddons()
	end
	
	local b = Menu.Right:Add( "DButton" )
	b:Dock( TOP )
	b:DockMargin( 0, 0, 0, 10 )
	b:SetHeight( 30 )
	b:SetText( "Enable ALL Addons" )
	b.DoClick = function() AddonToggle( true ) end
	
	local b = Menu.Right:Add( "DButton" )
	b:Dock( TOP )
	b:DockMargin( 0, 0, 0, 40 )
	b:SetHeight( 30 )
	b:SetText( "Disable ALL Addons" )
	b.DoClick = function() AddonToggle( false ) end
	
	Menu.Right = Menu.Frame:Add( "DPanel" )
	Menu.Right:SetHeight( 287 )
	Menu.Right:DockMargin( 10, 10, 10, 10 )
	Menu.Right:DockPadding( 10, 10, 10, 10 )
	Menu.Right:Dock( TOP )
	
	Menu.Tags = Menu.Right:Add( "DComboBox" )
	Menu.Tags:Dock( TOP )
	Menu.Tags:DockMargin( 0, 0, 0, 20 )
	
	function Menu.Tags.Populate()
		Menu.Tags:Clear()
		for k, v in pairs( Tags ) do
			Menu.Tags:AddChoice( v )
		end
	end
	
	local function AddonToggle( value )
		if !Menu.Tags:GetSelected() then return end
		local cat = tostring( Menu.Tags:GetSelected() )
		for k, v in pairs( Addons ) do
			if table.HasValue( Addons[k].tag, cat ) then
				steamworks.SetShouldMountAddon( k, value )
			end
		end
		steamworks.ApplyAddons()
		GetAddons()
	end
	
	local function ChangeCat( cat, add )
		local sel = Menu.List:GetSelected()
		for k,v in pairs( sel ) do
			local id = tostring( v:GetValue(1) )
			if add and !table.HasValue( Addons[id].tag, cat ) then
				table.insert( Addons[id].tag, cat )
			elseif !add and table.HasValue( Addons[id].tag, cat ) then
				table.RemoveByValue( Addons[id].tag, cat )
			end
		end
		Save()
		GetAddons()
	end
	
	local b = Menu.Right:Add( "DButton" )
	b:Dock( TOP )
	b:DockMargin( 0, 0, 0, 10 )
	b:SetHeight( 30 )
	b:SetText( "Enable Addons with choosen tag" )
	b.DoClick = function() AddonToggle( true ) end
	
	local b = Menu.Right:Add( "DButton" )
	b:Dock( TOP )
	b:DockMargin( 0, 0, 0, 20 )
	b:SetHeight( 30 )
	b:SetText( "Disable Addons with choosen tag" )
	b.DoClick = function() AddonToggle( false ) end
	
	local b = Menu.Right:Add( "DButton" )
	b:Dock( TOP )
	b:DockMargin( 0, 0, 0, 10 )
	b:SetHeight( 25 )
	b:SetText( "Add tag to selected Addons" )
	b.DoClick = function()
		if !Menu.Tags:GetSelected() then return end
		local cat = tostring( Menu.Tags:GetSelected() )
		ChangeCat( cat, true )
	end
	
	local b = Menu.Right:Add( "DButton" )
	b:Dock( TOP )
	b:DockMargin( 0, 0, 0, 20 )
	b:SetHeight( 25 )
	b:SetText( "Remove tag from selected Addons" )
	b.DoClick = function()
		if !Menu.Tags:GetSelected() then return end
		local cat = tostring( Menu.Tags:GetSelected() )
		ChangeCat( cat, false )
	end
	
	local TextEntry = Menu.Right:Add( "DTextEntry" )
	TextEntry:Dock( TOP )
	TextEntry:DockMargin( 0, 0, 0, 10 )
	
	local b = Menu.Right:Add( "DButton" )
	b:Dock( TOP )
	b:DockMargin( 0, 0, 0, 40 )
	b:SetHeight( 25 )
	b:SetText( "Add new tag to selected Addons" )
	b.DoClick = function()
		local cat = tostring( TextEntry:GetValue() )
		if cat == "" then return end
		ChangeCat( cat, true )
	end
	
	Menu.Right = Menu.Frame:Add( "DPanel" )
	Menu.Right:SetHeight( 90 )
	Menu.Right:DockMargin( 10, 10, 10, 10 )
	Menu.Right:DockPadding( 10, 10, 10, 10 )
	Menu.Right:Dock( TOP )
	
	local b = Menu.Right:Add( "DButton" )
	b:Dock( TOP )
	b:DockMargin( 0, 0, 0, 20 )
	b:SetHeight( 30 )
	b:SetText( "Give LIKE to selected Addons" )
	b.DoClick = function()
		local Confirm = Menu.Right:Add( "DMenu" )
		Confirm:AddOption( "Cancel" ):SetIcon( "icon16/cancel.png" )
		Confirm:AddOption( "Confirm", function()
			local sel = Menu.List:GetSelected()
			for k, v in pairs( sel ) do
				local id = tostring( v:GetValue(1) )
				steamworks.Vote( id, true )
			end
		end ):SetIcon( "icon16/accept.png" )
		Confirm:Open()
	end
	
	local b = Menu.Right:Add( "DButton" )
	b:Dock( TOP )
	b:DockMargin( 0, 0, 0, 10 )
	b:SetHeight( 20 )
	b:SetText( "UNINSTALL selected Addons" )
	b.DoClick = function()
		local Confirm = Menu.Right:Add( "DMenu" )
		Confirm:AddOption( "Cancel" ):SetIcon( "icon16/cancel.png" )
		Confirm:AddOption( "Confirm", function()
			local sel = Menu.List:GetSelected()
			for k, v in pairs( sel ) do
				local id = tostring( v:GetValue(1) )
				steamworks.Unsubscribe( id )
			end
			steamworks.ApplyAddons()
			GetAddons()
		end ):SetIcon( "icon16/accept.png" )
		Confirm:Open()
	end
	
	Menu.Right = Menu.Frame:Add( "DPanel" )
	Menu.Right:SetHeight( 89 )
	Menu.Right:DockMargin( 10, 10, 10, 10 )
	Menu.Right:DockPadding( 10, 10, 10, 10 )
	Menu.Right:Dock( TOP )
	
	local t = Menu.Right:Add( "DLabel" )
	t:Dock( TOP )
	t:SetText( "You can double-click on an addon,\nto visit it's Workshop page." )
	t:SetDark( true )
	t:SizeToContents()
	
	local b = Menu.Right:Add( "DButton" )
	b:Dock( TOP )
	b:DockMargin( 0, 10, 0, 10 )
	b:SetHeight( 30 )
	b:SetText( "Created by LibertyForce\nClick here for my Workshop addons" )
	b.DoClick = function()
		gui.OpenURL( "http://steamcommunity.com/id/libertyforce/myworkshopfiles/?appid=4000" )
	end
	
	GetAddons()
	
end


concommand.Add("addon_manager", Menu.Setup )
concommand.Add("addons", Menu.Setup )
