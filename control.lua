
function write_map_line(line)
   -- just add another line. Creates file if needed
   game.write_file("ASCII-map.txt", line .. "\n", true)
	 --game.print(line) -- echo it to the console
end

function orecount (elem, what)
  if elem == what then 
		if orecheck[what]== nil then orecheck[what] = 1
							              else orecheck[what] = orecheck[what] + 1
		end
	end
end

function dump_map(cmd)
  if cmd.parameter==nil then cmdpar = " " else cmdpar = cmd.parameter end
	log("dump_map para:"..cmdpar.." Tick:"..cmd.tick) --debug
	-- get player, the ground surface and other common details
	local world = game.get_surface("nauvis")
	local player = world.find_entities_filtered { name="character" } -- assumes SINGLE PLAYER
	local radars = world.find_entities_filtered { name="radar" }
	local myforce = player[1].force
	-- First: scan and count chunks and outer bounding box
	local CC = 0
	local LX,HX, LY, HY = 0,0,0,0
	for chunk in world.get_chunks() do
		--[=[ write_map_line(chunk.area.left_top.x .. ":" .. chunk.area.left_top.y .. "|"
									 .. chunk.area.right_bottom.x .. ":" .. chunk.area.right_bottom.y .. "="
									 .. chunk.x .. "," .. chunk.y
									 )  ]=]
		if myforce.is_chunk_charted("nauvis", {chunk.x, chunk.y})
		  then CC = CC + 1
  		LX = math.min(LX,chunk.x) ; LY = math.min(LY,chunk.y) ; HX = math.max(HX,chunk.x) ; HY = math.max(HY,chunk.y)
		end 
	end
	write_map_line("outer bounds" .. LX ..','.. LY ..','.. HX ..','.. HY )
	write_map_line(CC .. " charted chunks counted")
	write_map_line("Player at X" .. math.floor(player[1].position.x *10)/10 .. " Y" .. math.floor(player[1].position.y *19)/10 )
	-- print chunks, adding some info on chunks
	local ChunkChar = "?"
  local AsciiMap = { { } } -- (also making a memory ASCIIimage, need when doing graphics(?))
  for Y = LY, HY do
	  iY = Y-LY+1
		tY = Y*32
	  AsciiMap[iY] = { }
		AsciiMapLine = ""
    for X = LX, HX do 
		  iX = X-LX+1
			tX = X*32
  		--write_map_line(iX .. "," .. iY .. " = " .. X .."," .. Y)
			if myforce.is_chunk_charted("nauvis", {X, Y}) then
			  -- Assume "ordinary" ground
				ChunkChar = "·"
				-- Check if "mostly" water
				local watercheck = { }
				for tx = tX, tX+31 do 
				  for ty = tY, tY+31 do
					  local name = world.get_tile(tx,ty).name
					  if watercheck[name] == nil then watercheck[name] = 1
					                           else watercheck[name] = watercheck[name] + 1
					  end
				  end 
				end
				local water = 0
				if watercheck["deepwater"] ~= nil then water = water + watercheck["deepwater"] end
				if watercheck["water"] ~= nil then water = water + watercheck["water"] end
				if water>500 then ChunkChar = "W" end
        -- scan for any ores, whatever is most of in this chunk
				local ores =  world.find_entities_filtered { area = {{tX,tY},{tX+31,tY+31}} }
				if ores ~= nil then
				  orecheck = { } ; line = " "
				  for i = 1, #ores do
					  --line = line .. ores[i].name .. ','
						orecount(ores[i].name, "coal")
						orecount(ores[i].name, "iron-ore")
						orecount(ores[i].name, "uranium-ore")
						orecount(ores[i].name, "copper-ore")
						orecount(ores[i].name, "stone")
					end
					-- write_map_line(serpent.line(orecheck)) -- {["iron-ore"] = 17, stone = 212} 
					-- TBW: find the greater if more than one (NiceToHave: small or capital letter on >300)
					if orecheck["iron-ore"] ~= nil then ChunkChar="I" end
					if orecheck["copper-ore"] ~= nil then ChunkChar="C" end
					if orecheck["uranium-ore"] ~= nil then ChunkChar="U" end
					if orecheck["stone"] ~= nil then ChunkChar="S" end
					if orecheck["coal"] ~= nil then ChunkChar="K" end
				end
				-- change if a radar on it
				if radars ~= nil then
					for i = 1,#radars do
						if X==math.floor(radars[i].position.x/32) and Y==math.floor(radars[i].position.y/32) then
							ChunkChar = "*"  
						end
					end
				end
				-- override with player position
				if X==math.floor(player[1].position.x/32) and Y==math.floor(player[1].position.y/32) then
					ChunkChar = "O"  
				end
			--
			else -- uncharted chunk
			  ChunkChar = " "
			end
			AsciiMap[iY][iX] = ChunkChar
			AsciiMapLine = AsciiMapLine .. ChunkChar
	  end
		--write_map_line(serpent.line(AsciiMap[iY]))
		write_map_line(AsciiMapLine)
	end
end

commands.add_command("dmpmap",nil,dump_map)

