/datum/ore_node
	var/list/ores_to_mine
	var/range
	var/scanner_range
	var/x_coord
	var/y_coord
	var/z_coord

/datum/ore_node/New(x, y, z, list/ores, _range)
	x_coord = x
	y_coord = y
	z_coord = z
	ores_to_mine = ores
	range = _range
	scanner_range = range * 2
	//Add to the global list
	if(!GLOB.ore_nodes_by_z_level["[z]"])
		GLOB.ore_nodes_by_z_level["[z]"] = list()
	GLOB.ore_nodes_by_z_level["[z]"] += src

/datum/ore_node/Destroy()
	//Remove from the global list
	GLOB.ore_nodes_by_z_level["[z_coord]"] -= src
	return ..()

/datum/ore_node/proc/GetScannerReadout(turf/scanner_turf)
	//We read out ores based on the distance
	var/list/sorted_ores = ores_to_mine.Copy()
	var/turf/my_turf = locate(x_coord, y_coord, z_coord)
	var/dist = get_dist(my_turf,scanner_turf)
	if(dist <= 0)
		dist = 1
	var/percent = 1-(dist/scanner_range)
	var/precision = round(sorted_ores.len * percent) + 1
	precision = max(1,precision)
	var/is_full_scan = FALSE
	if(precision >= sorted_ores.len)
		precision = sorted_ores.len
		is_full_scan = TRUE
	var/full_string = ""
	for(var/i in 1 to precision)
		var/ore_type
		var/ore_weight = 0
		for(var/b in sorted_ores)
			if(sorted_ores[b] > ore_weight)
				ore_weight = sorted_ores[b]
				ore_type = b
		sorted_ores -= ore_type
		var/described_amount
		switch(ore_weight)
			if(-INFINITY to 5)
				described_amount = "Trace amounts"
			if(6 to 15)
				described_amount = "Small amounts"
			if(15 to 25)
				described_amount = "Notable amounts"
			if(25 to 50)
				described_amount = "Large amounts"
			if(50 to INFINITY)
				described_amount = "Plentiful amounts"
		var/described_ore
		switch(ore_type)
			if(/obj/item/stack/ore/uranium)
				described_ore = "uranium ore"
			if(/obj/item/stack/ore/diamond)
				described_ore = "diamonds"
			if(/obj/item/stack/ore/gold)
				described_ore = "gold ore"
			if(/obj/item/stack/ore/silver)
				described_ore = "silver ore"
			if(/obj/item/stack/ore/plasma)
				described_ore = "plasma ore"
			if(/obj/item/stack/ore/iron)
				described_ore = "iron ore"
			if(/obj/item/stack/ore/titanium)
				described_ore = "titanium ore"
			if(/obj/item/stack/ore/bluespace_crystal)
				described_ore = "bluespace crystals"
			else
				described_ore = "unidentified ore"
		full_string += "<BR>[described_amount] of [described_ore]."
	if(!is_full_scan)
		full_string += "<BR>..and traces of undetected ore."
	return full_string

/datum/ore_node/proc/GetScannerDensity(turf/scanner_turf)
	var/turf/my_turf = locate(x_coord, y_coord, z_coord)
	var/dist = get_dist(my_turf,scanner_turf)
	if(dist <= 0)
		dist = 1
	var/percent = 1-(dist/scanner_range)
	var/total_density = 0
	for(var/i in ores_to_mine)
		total_density += ores_to_mine[i]
	total_density *= percent
	switch(total_density)
		if(-INFINITY to 20)
			. = METAL_DENSITY_NONE
		if(20 to 60)
			. = METAL_DENSITY_LOW
		if(60 to 100)
			. = METAL_DENSITY_MEDIUM
		if(100 to INFINITY)
			. = METAL_DENSITY_HIGH

/datum/ore_node/proc/TakeRandomOre()
	if(!length(ores_to_mine))
		return
	var/obj/item/ore_to_return
	var/type = pickweight(ores_to_mine)
	ores_to_mine[type] = ores_to_mine[type] - 1
	if(ores_to_mine[type] == 0)
		ores_to_mine -= type
	ore_to_return = new type()

	if(!length(ores_to_mine))
		qdel(src)
	return ore_to_return

/proc/GetNearbyOreNode(turf/T)
	if(!GLOB.ore_nodes_by_z_level["[T.z]"])
		return
	var/list/iterated = GLOB.ore_nodes_by_z_level["[T.z]"]
	for(var/i in iterated)
		var/datum/ore_node/ON = i
		if(T.x < (ON.x_coord + ON.range) && T.x > (ON.x_coord - ON.range) && T.y < (ON.y_coord + ON.range) && T.y > (ON.y_coord - ON.range))
			return ON

/proc/GetOreNodeInScanRange(turf/T)
	if(!GLOB.ore_nodes_by_z_level["[T.z]"])
		return
	var/list/iterated = GLOB.ore_nodes_by_z_level["[T.z]"]
	for(var/i in iterated)
		var/datum/ore_node/ON = i
		if(T.x < (ON.x_coord + ON.scanner_range) && T.x > (ON.x_coord - ON.scanner_range) && T.y < (ON.y_coord + ON.scanner_range) && T.y > (ON.y_coord - ON.scanner_range))
			return ON

/obj/effect/ore_node_spawner
	var/list/possible_ore_weight = list(/obj/item/stack/ore/uranium = 5, /obj/item/stack/ore/diamond = 2, /obj/item/stack/ore/gold = 10,
		/obj/item/stack/ore/silver = 12, /obj/item/stack/ore/plasma = 20, /obj/item/stack/ore/iron = 40, /obj/item/stack/ore/titanium = 11,
		/obj/item/stack/ore/bluespace_crystal = 2)
	var/ore_density = 3
	var/ore_variety = 5

/obj/effect/ore_node_spawner/generous
	ore_density = 4

/obj/effect/ore_node_spawner/scarce
	ore_density = 2

/obj/effect/ore_node_spawner/proc/SeedVariables()
	return

/obj/effect/ore_node_spawner/proc/SeedDeviation()
	if(prob(50))
		ore_variety--
	else
		ore_variety++
	ore_variety = max(1, ore_variety)
	var/deviation = (rand(1,5)/10)
	if(prob(50))
		ore_density += deviation
	else
		ore_density -= deviation
	ore_density = max(1, ore_density)

/obj/effect/ore_node_spawner/Initialize()
	. = ..()
	SeedVariables()
	SeedDeviation()
	if(!length(possible_ore_weight))
		qdel(src)
		return
	var/compiled_list = list()
	for(var/i in 1 to ore_variety)
		var/ore_type = pick(possible_ore_weight)
		var/ore_amount = possible_ore_weight[ore_type]
		possible_ore_weight -= ore_type
		compiled_list[ore_type] = round(ore_amount * ore_density)
	new /datum/ore_node(x, y, z, compiled_list, rand(5,8))
	qdel(src)

/obj/effect/ore_node_spawner/planetary
	var/restricted = TRUE

/obj/effect/ore_node_spawner/planetary/unrestricted
	restricted = FALSE

/obj/effect/ore_node_spawner/planetary/SeedVariables()
	var/datum/planet_dictionary/PD = GLOB.planet_dict_by_z_level["[z]"]
	if(!PD)
		return
	possible_ore_weight = PD.ore_weight.Copy()
	ore_density = PD.ore_density
	ore_variety = PD.ore_variety

/obj/effect/ore_node_spawner/planetary/Initialize()
	var/datum/planet_dictionary/PD = GLOB.planet_dict_by_z_level["[z]"]
	if(!PD)
		qdel(src)
		return
	if(restricted)
		if(PD.spawned_ore_nodes >= PD.possible_ore_nodes)
			qdel(src)
			return
		PD.spawned_ore_nodes++
	return ..()
