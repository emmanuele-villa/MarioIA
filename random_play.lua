	Filename = "SMB1-1.state"

	ButtonNames = {
		"A",
		"Down",
		"Left",
		"Right",
	}

	function getPositions()
		marioX = memory.readbyte(0x6D) * 0x100 + memory.readbyte(0x86)
		marioY = memory.readbyte(0x03B8)+16

		screenX = memory.readbyte(0x03AD)
		screenY = memory.readbyte(0x03B8)
	end

		
	
	jump_weight = 0.9
	base_left_weight = 0.15
	left_weight = 0.15
	right_weight = 0.9
	down_weight = 0.1
		
	function randomInput()
	
		local outputs = {}

		if math.random() < jump_weight then
			outputs["P1 A"] = true
		end
		
		if math.random() < right_weight then
			outputs["P1 Right"] = true
		end
		
		if math.random() < left_weight then
			outputs["P1 Left"] = true
		end
		
		--if math.random() < down_weight then
		--	outputs["P1 Down"] = true
		--end
		
		if controller["P1 Left"] and controller["P1 Right"] then
				controller["P1 Left"] = true
				controller["P1 Right"] = false
			end
		
		if(left_weight > base_left_weight) then
			left_weight = left_weight - 0.01
		end
		
		return outputs;
	end
		
	function clearJoypad()
		controller = {}
		for b = 1,#ButtonNames do
			controller["P1 " .. ButtonNames[b]] = false
		end
		joypad.set(controller)
	end

	try = 1

	frame_count = 0
	
	function doRun()
	
		savestate.load(Filename);
		
		getPositions()
		
		oldX = marioX
		stuck = 0
		
		if(mainMoves ~= nil) then	
			for a = 1, #mainMoves do
				clearJoypad()
				joypad.set(mainMoves[a])
				gui.drawBox(0, 0, 300, 15, 0xFF000000, 0xFF000000)
				gui.drawText(0, 0, "try number " .. try .. ", Saved moves!", 0xFFFFFFFF, 8)
				emu.frameadvance();
				frame_count = frame_count + 1
			end
		end
		
		subMoves = { }
		
		while true do
			
			if(mainMoves == nil) then
				mainMoves = {}
			end
			
			gui.drawBox(0, 0, 300, 15, 0xFF000000, 0xFF000000)
			gui.drawText(0, 0, "try number " .. try .. ", Random play!", 0xFFFFFFFF, 8)
			
			getPositions()
			
			clearJoypad()
			
			controller = randomInput()
			
			joypad.set(controller)
			table.insert(subMoves, controller)

			if memory.readbyte(0x000E) == 0x06 then
				break
			end
			
			if oldX==marioX then
				stuck = stuck+1
			else
				stuck = 0
			end
			
			if stuck > 300 then
				left_weight = 0.6
				stuck = 0
			end
			
			oldX = marioX
			
			emu.frameadvance();
			frame_count = frame_count + 1
		end
		
		moveCount = #subMoves - 300;
		
		if moveCount > 0 then
			for m = 1, moveCount do
				table.insert(mainMoves, subMoves[m])
			end
		end
		
		--saving mainMoves
		inputBytes = ""
		
		for m = 1, #mainMoves do
			local controller = mainMoves[m]
			if controller["P1 Left"] then
				inputBytes = inputBytes .. 1
			else
				inputBytes = inputBytes .. 0
			end
			
			if controller["P1 Right"] then
				inputBytes = inputBytes .. 1
			else
				inputBytes = inputBytes .. 0
			end
			
			if controller["P1 A"] then
				inputBytes = inputBytes .. 1
			else
				inputBytes = inputBytes .. 0
			end
			
			if controller["P1 Down"] then
				inputBytes = inputBytes .. 1
			else
				inputBytes = inputBytes .. 0
			end
		end
		
		file = io.open(marioX .. "_" .. frame_count .. "_moves.txt", "w")
		file:write(inputBytes)
		
		try = try + 1
		
		doRun()
	end

	mainMoves = nil

	doRun()