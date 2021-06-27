local fdir_to_right = {
	{  1,  0 },
	{  0, -1 },
	{ -1,  0 },
	{  0,  1 }
}

--digilines compatibility

local rules_alldir = {
	{x =  0, y =  0, z = -1},  -- borrowed from lightstones
	{x =  1, y =  0, z =  0},
	{x = -1, y =  0, z =  0},
	{x =  0, y =  0, z =  1},
	{x =  1, y =  1, z =  0},
	{x =  1, y = -1, z =  0},
	{x = -1, y =  1, z =  0},
	{x = -1, y = -1, z =  0},
	{x =  0, y =  1, z =  1},
	{x =  0, y = -1, z =  1},
	{x =  0, y =  1, z = -1},
	{x =  0, y = -1, z = -1},
	{x =  0, y = -1, z =  0},
}

function streetlights.rightclick_pointed_thing(pos, placer, itemstack, pointed_thing)
	local node = minetest.get_node_or_nil(pos)
	if not node then return false end
	local def = minetest.registered_nodes[node.name]
	if not def or not def.on_rightclick then return false end
	return def.on_rightclick(pos, node, placer, itemstack, pointed_thing) or itemstack
end

function streetlights.check_and_place(itemstack, placer, pointed_thing, def)

	local pole                = def.pole
	local light               = def.light
	local param2              = def.param2
	local height              = def.height or 5
	local has_top             = (def.has_top ~= false)
	local needs_digiline_wire = def.needs_digiline_wire
	local distributor_node    = def.distributor_node

	local controls = placer:get_player_control()
	if not placer then return end
	local playername = placer:get_player_name()

	local player_name = placer:get_player_name()
	local fdir = minetest.dir_to_facedir(placer:get_look_dir())

	local pos1 = minetest.get_pointed_thing_position(pointed_thing)
	local node1 = minetest.get_node(pos1)
	if not node1 or node1.name == "ignore" then return end
	local def1 = minetest.registered_items[node1.name]

	if (def1 and def1.buildable_to) then
		pos1.y = pos1.y-1
	end

	local rc = streetlights.rightclick_pointed_thing(pos1, placer, itemstack, pointed_thing)
	if rc then return rc end

	if not minetest.check_player_privs(placer, "streetlight") then
		minetest.chat_send_player(playername, "*** You don't have permission to use a streetlight spawner.")
		return
	end

	local node1 = minetest.get_node(pos1)

	local node2, node3, node4
	local def1 = minetest.registered_items[node1.name]
	local def2, def3, def4

	local pos2, pos3, pos4
	for i = 1, height do
		pos2 = { x=pos1.x, y = pos1.y+i, z=pos1.z }
		node2 = minetest.get_node(pos2)
		def2 = minetest.registered_items[node2.name]
		if minetest.is_protected(pos2, player_name) or not (def2 and def2.buildable_to) then return end
	end

	pos3 = { x = pos1.x+fdir_to_right[fdir+1][1], y = pos1.y+height, z = pos1.z+fdir_to_right[fdir+1][2] }
	node3 = minetest.get_node(pos3)
	def3 = minetest.registered_items[node3.name]
	if minetest.is_protected(pos3, player_name) or not (def3 and def3.buildable_to) then return end

	if has_top then
		pos4 = { x = pos1.x+fdir_to_right[fdir+1][1], y = pos1.y+height-1, z = pos1.z+fdir_to_right[fdir+1][2] }
		node4 = minetest.get_node(pos4)
		def4 = minetest.registered_items[node4.name]
		if minetest.is_protected(pos4, player_name) or not (def4 and def4.buildable_to) then return end
	end

	local pos0 = { x = pos1.x, y = pos1.y-1, z = pos1.z }

	if controls.sneak and minetest.is_protected(pos1, player_name) then return end
	if distributor_node and minetest.is_protected(pos0, player_name) then return end

	if not creative.is_enabled_for(player_name) then
		local inv = placer:get_inventory()
		if not inv:contains_item("main", pole.." 6") then
			minetest.chat_send_player(playername, "*** You don't have enough "..pole.." in your inventory!")
			return
		end

		if not inv:contains_item("main", light) then
			minetest.chat_send_player(playername, "*** You don't have any "..light.." in your inventory!")
			return
		end

		if needs_digiline_wire and not inv:contains_item("main", digiline_wire_node.." 6") then
			minetest.chat_send_player(playername, "*** You don't have enough Digiline wires in your inventory!")
			return
		end

		if controls.sneak then
			if not inv:contains_item("main", streetlights.concrete) then
				minetest.chat_send_player(playername, "*** You don't have any concrete in your inventory!")
				return
			else
				inv:remove_item("main", streetlights.concrete)
			end
		end

		if distributor_node and needs_digiline_wire then
			if not inv:contains_item("main", distributor_node) then
				minetest.chat_send_player(playername, "*** You don't have any "..distributor_node.." in your inventory!")
				return
			else
				inv:remove_item("main", distributor_node)
			end
		end

		inv:remove_item("main", pole.." 6")
		inv:remove_item("main", light)

		if needs_digiline_wire then
			inv:remove_item("main", digiline_wire_node.." 6")
		end

	end

	if controls.sneak then
		minetest.set_node(pos1, { name = streetlights.concrete })
	end

	local pole2 = pole
	if needs_digiline_wire then
		pole2 = pole.."_digilines"
	end

	for i = 1, height do
		pos2 = {x=pos1.x, y = pos1.y+i, z=pos1.z}
		minetest.set_node(pos2, {name = pole2 })
	end

	if has_top then
		minetest.set_node(pos3, { name = pole2 })
		minetest.set_node(pos4, { name = light, param2 = param2 })
	else
		minetest.set_node(pos3, { name = light, param2 = param2 })
	end

	if needs_digiline_wire and ilights.player_channels[playername] then
		minetest.get_meta(pos4):set_string("channel", ilights.player_channels[playername])
	end

	if distributor_node and needs_digiline_wire then
		minetest.set_node(pos0, { name = distributor_node })
		digilines.update_autoconnect(pos0)
	end

end

minetest.register_privilege("streetlight", {
	description = "Allows using streetlight spawners",
	give_to_singleplayer = true
})
