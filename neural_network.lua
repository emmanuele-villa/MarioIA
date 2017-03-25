FILE_NAME = "SMB1-1.state"

----------------------
------ READ RAM ------
----------------------

function getTile(dx, dy)
	marioX = memory.readbyte(0x6D) * 0x100 + memory.readbyte(0x86)
	marioY = memory.readbyte(0x03B8)+16
	local x = marioX + dx --+ 8
	local y = marioY + dy --- 16
	local page = math.floor(x/256)%2

	local subx = math.floor((x%256)/16)
	local suby = math.floor((y - 32)/16)
	local addr = 0x500 + page*13*16+suby*16+subx
	
	if suby >= 13 or suby < 0 then
		return 0
	end
	
	if memory.readbyte(addr) ~= 0 then
		return 1
	else
		return 0
	end
end

function enemyDistance(offset)
	enemy1PositionX = memory.readbyte(0x03AE + offset)
	marioX = memory.readbyte(0x6D) * 0x100 + memory.readbyte(0x86)
	local ex = memory.readbyte(0x6E + offset)*0x100 + memory.readbyte(0x87+offset)
	return ex - marioX
end

function enemyExists(offset)
	return memory.readbyte(0xF + offset)
end

----------------------------------
------ ACTIVATION FUNCTIONS ------
----------------------------------

function sigmoid(x)
	local denom = math.exp(-x) + 1
	return 1 / denom
end

function derivative(x)
	return x * (1 - x)
end

function minorThanOutput(neuron)
	if neuron.input < 40 then
		neuron.output = 1
	else
		neuron.output = 0
	end
	return neuron
end

function majorThanOutput(neuron)
	if neuron.input > 20 then
		neuron.output = 1
	else
		neuron.output = 0
	end
	return neuron
end


function roundPerceptron(neuron)
	if neuron.input > 0.9 then
		neuron.output = 1
	else
		neuron.output = 0
	end
	return neuron
end

function inverterPerceptron(neuron)
	if neuron.input == 0 then
		neuron.output = 1
	else
		neuron.output = 0
	end
	return neuron
end

function breakerPerceptron(neuron)
	if neuron.input <= 0 then
		neuron.output = 0
	else
		neuron.output = 1
	end
	return neuron
end

------------------------------------
------ NEURONS "CONSTRUCTORS" ------
------------------------------------

function createPerceptron()
	return createSigmoidNeuron(0)
end

function createSigmoidNeuron(size)
	local neuron = {}
	neuron.weight = {}
	neuron.input = {}
	for i=1, size do
		neuron.weight[i] = math.random()
		neuron.input[i] = 0
	end
	neuron.bias = math.random()
	return neuron
end

----------------------------------
------ NEURONS INPUT/OUTPUT ------
----------------------------------

function getSigmoidOutput(neuron)
	local output = 0
	for i=1, #neuron.weight do
		output = output + neuron.input[i] * neuron.weight[i]
	end
	output = sigmoid(output + neuron.bias)
	return output
end

function setNeuronInput(neuron, input)
	for i=1, #input do
		neuron.input[i] = input[i]
	end
	return neuron
end

function adjustNeuron(neuron)
	for i=1, #neuron.weight do
		neuron.weight[i] = neuron.weight[i] + neuron.error * neuron.input[i]
	end
	neuron.bias = neuron.bias + neuron.error
	return neuron
end

-----------------------------------------
------ NEURAL NETWORK MAIN OBJECTS ------
-----------------------------------------

distanceLayer = {}

andNN = {}
andOutput = {}

orNN = {}
orOutput = {}

breakNN = {}
breakOutput = {}

inverterLayer = {}

roundNeuron = {}

breakNeuron = {}

-----------------------------
------ LAYERS CREATION ------
-----------------------------

function createDistanceLayer()
	distanceLayer[1] = createPerceptron()
	distanceLayer[2] = createPerceptron()
end

function createORLayer()
	orNN[1] = createSigmoidNeuron(4)
	orNN[2] = createSigmoidNeuron(4)
	orNN[3] = createSigmoidNeuron(4)
	orNN[4] = createSigmoidNeuron(4)
	orOutput = createSigmoidNeuron(4)
	
	breakNN[1] = createSigmoidNeuron(4)
	breakNN[2] = createSigmoidNeuron(4)
	breakNN[3] = createSigmoidNeuron(4)
	breakNN[4] = createSigmoidNeuron(4)
	breakOutput = createSigmoidNeuron(4)
end

function createAndLayer()
	andNN[1] = createSigmoidNeuron(5)
	andNN[2] = createSigmoidNeuron(5)
	andNN[3] = createSigmoidNeuron(5)
	andNN[4] = createSigmoidNeuron(5)
	andNN[5] = createSigmoidNeuron(5)
	andOutput = createSigmoidNeuron(5)
end

function createInverterLayer()
	inverterLayer[1] = createPerceptron()
	inverterLayer[2] = createPerceptron()
	inverterLayer[3] = createPerceptron()
	inverterLayer[4] = createPerceptron()
	inverterLayer[5] = createPerceptron()
end

function createJumpHoleLayer()
	createInverterLayer()
	breakNeuron = createPerceptron()
end

function createNeuralNetwork()
	createDistanceLayer()
	createAndLayer()
	createORLayer()
	createJumpHoleLayer();
	roundNeuron = createPerceptron()
end

-------------------------------------
------ NEURAL NETWORK TRAINING ------
-------------------------------------
function trainAndNeuralNetwork()
	neuralInput = {}
	neuralResult = {}
	
	neuralInput[#neuralInput+1] = {0,0,0,0,0}
	neuralResult[#neuralResult+1] = 0

	neuralInput[#neuralInput+1] = {1,0,0,0,0}
	neuralResult[#neuralResult+1] = 0
	
	neuralInput[#neuralInput+1] = {0,1,0,0,0}
	neuralResult[#neuralResult+1] = 0
	
	neuralInput[#neuralInput+1] = {0,0,0,1,1}
	neuralResult[#neuralResult+1] = 0
	
	neuralInput[#neuralInput+1] = {0,1,0,0,1}
	neuralResult[#neuralResult+1] = 0
	
	neuralInput[#neuralInput+1] = {1,1,1,0,0}
	neuralResult[#neuralResult+1] = 0
	
	neuralInput[#neuralInput+1] = {0,1,1,1,1}
	neuralResult[#neuralResult+1] = 0
	
	neuralInput[#neuralInput+1] = {1,1,0,1,0}
	neuralResult[#neuralResult+1] = 0
	
	neuralInput[#neuralInput+1] = {1,0,1,1,1}
	neuralResult[#neuralResult+1] = 0
	
	neuralInput[#neuralInput+1] = {0,1,1,1,1}
	neuralResult[#neuralResult+1] = 0
	
	neuralInput[#neuralInput+1] = {1,1,0,1,1}
	neuralResult[#neuralResult+1] = 0
	
	neuralInput[#neuralInput+1] = {1,1,1,0,1}
	neuralResult[#neuralResult+1] = 0
	
	neuralInput[#neuralInput+1] = {1,1,1,1,0}
	neuralResult[#neuralResult+1] = 0
	
	neuralInput[#neuralInput+1] = {1,1,1,1,1}
	neuralResult[#neuralResult+1] = 1
	
	trainNeuralNetwork(neuralInput, neuralResult, andNN, andOutput)

end

function trainJumpWithBreak()
neuralInput = {}
	neuralResult = {}

	neuralInput[#neuralInput+1] = {0,0,0,0}
	neuralResult[#neuralResult+1] = 0

	neuralInput[#neuralInput+1] = {0,0,1,0}
	neuralResult[#neuralResult+1] = 0
	
	neuralInput[#neuralInput+1] = {0,1,0,0}
	neuralResult[#neuralResult+1] = 0
	
	neuralInput[#neuralInput+1] = {0,1,1,0}
	neuralResult[#neuralResult+1] = 0
	
	neuralInput[#neuralInput+1] = {1,0,0,0}
	neuralResult[#neuralResult+1] = 0
	
	neuralInput[#neuralInput+1] = {1,0,1,0}
	neuralResult[#neuralResult+1] = 0
	
	neuralInput[#neuralInput+1] = {1,1,0,0}
	neuralResult[#neuralResult+1] = 0
	
	neuralInput[#neuralInput+1] = {1,1,1,0}
	neuralResult[#neuralResult+1] = 0
	
	neuralInput[#neuralInput+1] = {0,0,0,1}
	neuralResult[#neuralResult+1] = 0
	
	neuralInput[#neuralInput+1] = {0,0,1,1}
	neuralResult[#neuralResult+1] = 1
	
	neuralInput[#neuralInput+1] = {0,1,0,1}
	neuralResult[#neuralResult+1] = 1
	
	neuralInput[#neuralInput+1] = {0,1,1,1}
	neuralResult[#neuralResult+1] = 1
	
	neuralInput[#neuralInput+1] = {1,0,0,1}
	neuralResult[#neuralResult+1] = 1
	
	neuralInput[#neuralInput+1] = {1,0,1,1}
	neuralResult[#neuralResult+1] = 1
	
	neuralInput[#neuralInput+1] = {1,1,0,1}
	neuralResult[#neuralResult+1] = 1
	
	neuralInput[#neuralInput+1] = {1,1,1,1}
	neuralResult[#neuralResult+1] = 1
	
	trainNeuralNetwork(neuralInput, neuralResult, breakNN, breakOutput)
end

function trainOrNeuralNetwork()
	neuralInput = {}
	neuralResult = {}

	neuralInput[#neuralInput+1] = {0,0,0,0,0}
	neuralResult[#neuralResult+1] = 0

	neuralInput[#neuralInput+1] = {1,0,0,0,0}
	neuralResult[#neuralResult+1] = 1
	
	neuralInput[#neuralInput+1] = {0,1,0,0,0}
	neuralResult[#neuralResult+1] = 1
	
	neuralInput[#neuralInput+1] = {0,0,0,1,1}
	neuralResult[#neuralResult+1] = 1
	
	neuralInput[#neuralInput+1] = {0,1,0,0,1}
	neuralResult[#neuralResult+1] = 1
	
	neuralInput[#neuralInput+1] = {1,1,1,0,0}
	neuralResult[#neuralResult+1] = 1
	
	neuralInput[#neuralInput+1] = {0,1,1,1,1}
	neuralResult[#neuralResult+1] = 1
	
	neuralInput[#neuralInput+1] = {1,1,0,1,0}
	neuralResult[#neuralResult+1] = 1
	
	neuralInput[#neuralInput+1] = {0,0,1,0,0}
	neuralResult[#neuralResult+1] = 1
	
	neuralInput[#neuralInput+1] = {1,1,1,1,1}
	neuralResult[#neuralResult+1] = 1
	
	
	trainNeuralNetwork(neuralInput, neuralResult, orNN, orOutput)
end

function trainNeuralNetwork(neuralInputArg, neuralResultArg, layer, outputN)
	for gen=0, 5000 do
		for i=1, #neuralInputArg do
			for j=1, #layer do
				layer[j] = setNeuronInput(layer[j], neuralInputArg[i])
			end
			
			for j=1, #layer do
				layer[j].output = getSigmoidOutput(layer[j])
			end
			
			for j=1, #layer do
				outputN.input[j] = layer[j].output
			end
			
			outputN.output = getSigmoidOutput(outputN)
			
			outputN.error = derivative(outputN.output) * (neuralResultArg[i] - outputN.output)
			
			outputN = adjustNeuron(outputN)
			
			for j=1, #layer do
				layer[j].error = derivative(layer[j].output) * outputN.error * outputN.weight[j]
			end
			
			for j=1, #layer do
				layer[j] = adjustNeuron(layer[j])
			end
			
			if gen==5000 then
				console.writeline(neuralResultArg[i] - outputN.output)
			end
		end
		--emu.frameadvance();
	end
end


---------------------------
------ NN EVALUATION ------
---------------------------

function evaluateEnemyJump(one, two, three)
	local input = {one, two, three, 1, 1}
	return evaluateNN(input, andNN, andOutput, false)
end

function evaluateEnemiesJump(one, two, three, four)
	local input = {one, two, three, four}
	return evaluateNN(input, orNN, orOutput, false)
end

function evaluateJumpLayer(one, two, three, breaker)
	breakNeuron.input = breaker
	breakNeuron = breakerPerceptron(breakNeuron)
	local input = {one, two, three, breakNeuron.output}
	local result = evaluateNN(input, breakNN, breakOutput, true)
	--console.writeline(one .. two .. three .. breakNeuron.output .. " = " .. result)
	return result
end

function evaluateNN(inputs, layer, outputN, showResult)
	for i=1, #layer do
		layer[i] = setNeuronInput(layer[i], inputs)
	end
	
	for i=1, #layer do
		layer[i].output = getSigmoidOutput(layer[i])
	end
	
	for i=1, #layer do
		outputN.input[i] = layer[i].output
	end
	
	outputN.output = getSigmoidOutput(outputN)
	
	roundNeuron.input = outputN.output
	
	roundNeuron = roundPerceptron(roundNeuron)
	
	return roundNeuron.output
end

function evaluateHoleJump()
	inverterLayer[1].input = getTile(24,40)
	inverterLayer[2].input = getTile(24,48)
	inverterLayer[3].input = getTile(24,56)
	inverterLayer[4].input = getTile(24,64)
	inverterLayer[5].input = getTile(24,72)
		
	for i=1, #inverterLayer do
		inverterLayer[i] = inverterPerceptron(inverterLayer[i])
	end
	
	local input = {inverterLayer[1].output, inverterLayer[2].output, inverterLayer[3].output, inverterLayer[4].output, inverterLayer[5].output}
	local result = evaluateNN(input, andNN, andOutput)
	
	-- DRAWING MADNESS START
	drawIfActive(inverterLayer[1].output, 100, 51)
	drawIfActive(inverterLayer[2].output, 100, 61)
	drawIfActive(inverterLayer[3].output, 100, 71)	
	drawIfActive(inverterLayer[4].output, 100, 81)
	drawIfActive(inverterLayer[5].output, 100, 91)
	drawIfActive(result, 80, 71, 86, 76)
	
	gui.drawLine(85, 73, 100, 53, grey)
	gui.drawLine(85, 73, 100, 63, grey)
	gui.drawLine(85, 73, 100, 73, grey)
	gui.drawLine(85, 73, 100, 83, grey)
	gui.drawLine(85, 73, 100, 93, grey)
	-- DRAWING MADNESS END
	
	return result
end

-----------------------------------------
------ INITIALIZING NEURAL NETWORK ------
-----------------------------------------

console.writeline("createNeuralNetwork")
createNeuralNetwork();

console.writeline("trainOrNeuralNetwork")
trainOrNeuralNetwork();

console.writeline("trainAndNeuralNetwork")
trainAndNeuralNetwork();

console.writeline("trainJumpWithBreak")
trainJumpWithBreak();

console.writeline("loading savestate")
savestate.load(FILE_NAME);

MAX_JUMP_LENGHT = 100
maxJumpLenght = 100

------------------------------
------ PLAY WITH THE NN ------
------------------------------

red = 0xFFFF0000
green = 0xFF00FF00
grey = 0xFF222222

enemiesAnchors = {}
function drawIfActive(result, xCoord, yCoord)
	if result > 0.9 then
		color = green
	else
		color = red
	end
	gui.drawBox(xCoord, yCoord, xCoord+5, yCoord+5, grey, color)
end

function drawIfActiveBig(result, xCoord, yCoord)
	if result > 0.9 then
		color = green
	else
		color = red
	end
	gui.drawBox(xCoord, yCoord, xCoord+10, yCoord+10, grey, color)
end

while true do
	enemyOutputs = {}
		
	y1 = 1
	for i=0, 3 do
		distance = enemyDistance(i)
		
		-- DISTANCE LAYER
		distanceLayer[1].input = distance
		distanceLayer[2].input = distance
		
		distanceLayer[1] = majorThanOutput(distanceLayer[1])
		distanceLayer[2] = minorThanOutput(distanceLayer[2])
		
		-- DISTANCE LAYER OUTPUT GOES INTO ENEMY LAYER INPUT
		enemyOutputs[#enemyOutputs+1] = evaluateEnemyJump(distanceLayer[2].output, distanceLayer[1].output, enemyExists(i))
		
		-- DRAWING MADNESS START
		drawIfActive(distanceLayer[1].output, 1, y1)
		anchor1 = y1+3
		y1 = y1 + 10
		drawIfActive(distanceLayer[2].output, 1, y1)
		drawIfActive(enemyOutputs[#enemyOutputs], 15, y1)
		anchor2 = y1+3
		enemiesAnchors[#enemiesAnchors+1] = anchor2
		y1 = y1 + 10
		drawIfActive(enemyExists(i), 1, y1)
		anchor3 = y1+3
		y1 = y1 + 20
		gui.drawLine(7, anchor1, 15, anchor2, grey)
		gui.drawLine(7, anchor2, 15, anchor2, grey)
		gui.drawLine(7, anchor3, 15, anchor2, grey)
		-- DRAWING MADNESS END
	end
	
	--ENEMIES JUMP LAYER
	local enemies = evaluateEnemiesJump(enemyOutputs[1], enemyOutputs[2], enemyOutputs[3], enemyOutputs[4])
	
	local hole = evaluateHoleJump()
	
	local tube = getTile(16, 8)
	
	local jump = evaluateJumpLayer(enemies, tube, hole, maxJumpLenght)
	
	-- DRAWING MADNESS START
	drawIfActive(enemies, 29, 71)
	gui.drawLine(21, enemiesAnchors[1], 29, 73, grey)
	gui.drawLine(21, enemiesAnchors[2], 29, 73, grey)
	gui.drawLine(21, enemiesAnchors[3], 29, 73, grey)
	gui.drawLine(21, enemiesAnchors[4], 29, 73, grey)
	drawIfActive(tube, 47, 71)
	drawIfActive(breakNeuron.output, 65, 71)
	drawIfActiveBig(jump, 54, 91)
	
	gui.drawLine(32, 76, 60, 91, grey)
	gui.drawLine(50, 76, 60, 91, grey)
	gui.drawLine(68, 76, 60, 91, grey)
	gui.drawLine(82, 76, 60, 91, grey)
	-- DRAWING MADNESS END
	
	controller = {}
		
	controller["P1 A"] = jump == 1
	controller["P1 Right"] = true
	
	if(jump==1) then
		maxJumpLenght = maxJumpLenght-1
	else
		maxJumpLenght = MAX_JUMP_LENGHT
	end
	
	joypad.set(controller)
	
	emu.frameadvance();

end
