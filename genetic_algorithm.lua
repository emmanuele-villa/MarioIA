FRAME_COUNT = 3500
POPULATION_SIZE = 20
TOURNAMENT_SIZE = 5
JUMP_WEIGHT = 0.93
RIGHT_WEIGHT = 0.9
MUTATION_RATE_0 = 0.02
MUTATION_RATE_1 = 0.005
FILE_NAME = "SMB1-1.state"

population = {}
backgroundColor = 0xFF000000

function generateIndividual()
	local individual = {}
	individual.bytes = {}
	bytes = "_"
	for count=0, FRAME_COUNT do
		if math.random() < JUMP_WEIGHT then
			individual.bytes[#individual.bytes+1] = 1
		else
			individual.bytes[#individual.bytes+1] = 0
		end
		
		bytes = bytes .. individual.bytes[#individual.bytes]
		gui.drawBox(0, 0, 300, 15, backgroundColor, backgroundColor)
		gui.drawText(0, 0, "Generating individual #" .. #population, 0xFFFFFFFF, 8)
			
		emu.frameadvance();
	end	
		
	return individual

end

function generatePopulation()
	
	for count=0,POPULATION_SIZE do
		population[#population+1] = generateIndividual()
	end
	
end

function tournamentSelection()
	
	highestIndex = 0
	highestFit = 0
	highestSpeed = 3500
	
	for i=0, TOURNAMENT_SIZE do
		index = math.random(#population)
		if population[index].fitness > highestFit or (population[index].fitness == highestFit and population[index].frameNumber < highestSpeed) then
			highestIndex = index
			highestSpeed = population[index].frameNumber
			highestFit = population[index].fitness
		end	
	end
	
	return population[highestIndex]
	
end

function crossover(indiv1, indiv2)
	
	newIndiv = {}
	newIndiv.bytes = {}
	
	index = math.random(#indiv1.bytes)
		
	for i=1, index do
		newIndiv.bytes[#newIndiv.bytes+1] = indiv1.bytes[i]
	end
	
	for i=index, #indiv1. bytes do
		newIndiv.bytes[#newIndiv.bytes+1] = indiv2.bytes[i]
	end
	
	return newIndiv
	
end

function mutate(indiv)

	newIndiv = {}
	newIndiv.bytes = {}

	for i=1, #indiv.bytes do
		if indiv.bytes[i] == 1 and math.random() < MUTATION_RATE_1 then
			newIndiv.bytes[#newIndiv.bytes+1] = 0
		else if indiv.bytes[i] == 0 and math.random() < MUTATION_RATE_0 then
				newIndiv.bytes[#newIndiv.bytes+1] = 1
			else
				newIndiv.bytes[#newIndiv.bytes+1] = indiv.bytes[i]
			end
		end
	end
	
	return newIndiv
	
end

highestFit = 0
highestSpeed = 3500

function evolvePopulation()

	local newPopulation = {}
	
	--keeping the highest fitness
	highestIndex = 0
	highestFit = 0
	highestSpeed = 3500
	for i=1, #population do
		if population[i].fitness > highestFit or (population[i].fitness == highestFit and population[i].frameNumber < highestSpeed) then
			highestIndex = i
			highestSpeed = population[i].frameNumber
			highestFit = population[i].fitness
		end	
	end

	newPopulation[#newPopulation+1] = population[highestIndex]
	
	for i=2, POPULATION_SIZE do
		indiv1 = tournamentSelection()
		indiv2 = tournamentSelection()
		newPopulation[#newPopulation+1] = crossover(indiv1, indiv2)
	end
	
	for i=2, POPULATION_SIZE do
		newPopulation[i] = mutate(newPopulation[i])
	end
	
	population = newPopulation
	
end

generatePopulation()
generation = 0
while true do 	--Do this until the fitness is reached	
	generation = generation + 1
	for index=1, #population do		--foreach individual in population
		
		local moveIndex = 0
		savestate.load(FILE_NAME);
		
		population[index].frameNumber = 0
		while true do	--play with the individual
		
			population[index].fitness = memory.readbyte(0x6D) * 0x100 + memory.readbyte(0x86)	--mario X position in level
			
			population[index].fitness = population[index].fitness / 20
			
			population[index].fitness = math.floor(population[index].fitness)
			
			population[index].frameNumber = population[index].frameNumber + 1
			
			gui.drawBox(0, 0, 300, 35, backgroundColor, backgroundColor)
			gui.drawText(0, 0, "Gen #" .. generation .. "- Individual #" .. index, 0xFFFFFFFF, 8)
			gui.drawText(0, 10, "Fitness = " .. population[index].fitness .. " in " .. population[index].frameNumber .. " frames", 0xFFFFFFFF, 8)
			gui.drawText(0, 20, "Best Fitness = " .. highestFit .. " in " .. highestSpeed .. " frames", 0xFFFFFFFF, 8)
			
			controller = {}
			
			controller["P1 A"] = population[index].bytes[moveIndex] == 1
			moveIndex = moveIndex + 1
			
			controller["P1 Right"] = true
			
			joypad.set(controller)
				
			emu.frameadvance();
			
			if memory.readbyte(0x000E) == 0x06 then
				break
			end
		end
		
		console.writeline("Fitness reached: " .. population[index].fitness)
	end
	
	evolvePopulation()
	
end
