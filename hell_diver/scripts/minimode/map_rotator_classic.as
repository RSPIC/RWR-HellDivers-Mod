#include "map_rotator_minimodes.as"
#include "stage_minimodes.as"
#include "quickmatch_substage.as"

// --------------------------------------------
class MatchClassic : Match {
	string m_scoreMode = "xp";
	float m_maxRp = 5000.0;

	array<string> m_capturableBases;
	
	MatchClassic(GameModeMiniModes@ metagame) {
		_log("setUp MatchClassic A");
		super(metagame);
	}

	// --------------------------------------------
	protected XmlElement@ getStartGameXml() {
		XmlElement doc("doc");
		XmlElement command("command");

		command.setStringAttribute("class", "start_game");
		command.setIntAttribute("vehicles", 1);
		command.setIntAttribute("max_soldiers", m_maxSoldiers);
		command.setFloatAttribute("soldier_capacity_variance", m_soldierCapacityVariance);
		command.setStringAttribute("soldier_capacity_model", m_soldierCapacityModel);
		command.setIntAttribute("player_ai_compensation", m_playerAiCompensation);
		command.setIntAttribute("player_ai_reduction", m_playerAiReduction);    
		command.setFloatAttribute("xp_multiplier", m_xpMultiplier);
		command.setFloatAttribute("rp_multiplier", m_rpMultiplier);
		command.setFloatAttribute("initial_xp", m_initialXp); 
		command.setFloatAttribute("initial_rp", m_initialRp);
		command.setStringAttribute("base_capture_system", m_baseCaptureSystem);
		command.setIntAttribute("clear_profiles_at_start", 0);
		command.setStringAttribute("score_mode", m_scoreMode);
		command.setFloatAttribute("max_rp", m_maxRp);
		command.setIntAttribute("fov", 1);    

		if (m_defenseWinTime >= 0) {
			command.setFloatAttribute("defense_win_time", m_defenseWinTime);
			command.setStringAttribute("defense_win_time_mode", m_defenseWinTimeMode);
		}

		for (uint i = 0; i < m_factions.length(); ++i) {
			Faction@ f = m_factions[i];
			XmlElement faction("faction");
			
			faction.setIntAttribute("capacity_offset", f.m_capacityOffset);
			float overCapacity = f.m_overCapacity;
			if (!f.isNeutral()) {
				overCapacity += 10;
			}
			faction.setFloatAttribute("initial_over_capacity", overCapacity);
			faction.setFloatAttribute("capacity_multiplier", f.m_capacityMultiplier);
			faction.setFloatAttribute("ai_accuracy", m_aiAccuracy);
			
			// if base amount has been declared for the faction, use it

			// allow adventure mode to use the amount of bases we managed to capture 
			// if we were in the map previously

			// TODO: do owned bases correctly; the command can now handle it
			if (f.m_ownedBases.length() > 0) {
				// don't randomize, we'll use the right ones
				//command = command . "initial_occupied_bases='" . count(f.owned_bases) . "' ";
			} else if (f.m_bases >= 0) {
				faction.setIntAttribute("initial_occupied_bases", f.m_bases);
			}
			
			if (f.m_ownedBases.length() > 0) {
				for (uint j = 0; j < f.m_ownedBases.length(); ++j) {
					string baseKey = f.m_ownedBases[j];
					XmlElement base("base");
					base.setStringAttribute("key", baseKey);
					faction.appendChild(base);
				}
			}

			command.appendChild(faction);
		}
		
		{
			XmlElement localPlayer("local_player");
			localPlayer.setIntAttribute("faction_id", 0);
			localPlayer.setStringAttribute("username", "Single player");
			command.appendChild(localPlayer);
		}

		doc.appendChild(command);

		return doc;
	}

	// --------------------------------------------
	const XmlElement@ getStartGameCommandXml() {
		XmlElement@ doc = getStartGameXml();
		const XmlElement@ s = doc.getFirstElementByTagName("command");
		return s;
	}

	// --------------------------------------------
   	void start() {
		_log("MatchClassic::start");

		m_metagame.setFactions(m_factions);

		// before starting, set in base capturabilities if any set
		if (m_capturableBases.length() > 0) {
			array<const XmlElement@> bases = getBases(m_metagame);
			for (uint i = 0; i < bases.length(); ++i) {
				const XmlElement@ base = bases[i];
				
				string baseKey = base.getStringAttribute("key");
				baseKey = baseKey.toLowerCase();
				int capturable = 0;
				
				if (m_capturableBases.find(baseKey) >= 0) { // if base key exists in array
					capturable = 1;
				}
				
				string command = "<command class='update_base' base_key='" + baseKey + "' capturable='" + capturable + "' />";
				m_metagame.getComms().send(command);
			}
		}

		// start game 
		const XmlElement@ startGameCommand = getStartGameCommandXml();
		m_metagame.getComms().send(startGameCommand);
	}		
};

// --------------------------------------------
class MapRotatorMiniModesClassic : MapRotatorMiniModes {
	// --------------------------------------------
	MapRotatorMiniModesClassic(GameModeMiniModes@ metagame) {
		@m_metagame = @metagame;
	}

	// ------------------------------------------------------------------------------------------------
	protected void setupStages() {
		setupPlaylist1(); 
	}

	// --------------------------------------------
	protected array<FactionConfig@> getAvailableFactionConfigs() {
		array<FactionConfig@> availableFactionConfigs;
		//此处决定多人游戏的玩家可选阵营
		availableFactionConfigs.insertLast(FactionConfig(-1, "super_earth.xml", "SuperEarth A", "0.7 0.7 1"));
		availableFactionConfigs.insertLast(FactionConfig(-1, "super_earth.xml", "SuperEarth B", "1 0.3 0"));
		availableFactionConfigs.insertLast(FactionConfig(-1, "super_earth.xml", "SuperEarth C", "0 0.3 1"));
		availableFactionConfigs.insertLast(FactionConfig(-1, "super_earth.xml", "SuperEarth D", "1 0 0"));
		availableFactionConfigs.insertLast(FactionConfig(-1, "super_earth.xml", "SuperEarth E", "0 0 1"));

		return availableFactionConfigs;
	}

	// --------------------------------------------
	protected void setupFactionConfigs() {
		array<FactionConfig@> availableFactionConfigs = getAvailableFactionConfigs();

		// - next add the rest of them, in random order
		// TODO: enable random order
		int index = 0;
		while (availableFactionConfigs.length() > 0) {
			int availableIndex = 0;

			FactionConfig@ faction = availableFactionConfigs[availableIndex];
			_log("setting " + faction.m_name + " as index " + index);
			faction.m_index = index;

			m_factionConfigs.insertLast(faction);
			
			availableFactionConfigs.removeAt(0);

			index++;
		}

		// - finally add neutral and disabled neutral
		// {
		// 	index = m_factionConfigs.length();
		// 	m_factionConfigs.insertLast(FactionConfig(index, "neutral.xml", "", "0 0 0"));
		// }

		// {
		// 	index = m_factionConfigs.length();
		// 	m_factionConfigs.insertLast(FactionConfig(index, "disabled.xml", "", "0 0 0"));
		// }

		_log("total faction configs " + m_factionConfigs.length());
	}

	// ------------------------------------------------------------------------------------------------
	protected void fillClassicMatchSettings(Match@ match) {
		match.m_aiAccuracy = 0.94;
		match.m_playerAiReduction = 6;          // was 4 (1.94)
		match.m_playerAiCompensation = 1;       // was 2 (1.65)
		match.m_initialXp = 0.0;
		match.m_initialRp = 100;				// was 50 (1.94)
		match.m_xpMultiplier = 1.0;
		match.m_rpMultiplier = 1.0; 
    match.m_soldierCapacityVariance = 0.55;     // was 0.5 (1.94)
		match.m_baseCaptureSystem = "any_closest";                 
	}

	// ------------------------------------------------------------------------------------------------
	protected void setResources(Stage@ stage) {
		// here's a trick to load in resources from local files (in gamemodes/classic)
		// and add them to custom map config to be uploaded to clients, allowing control of 
		// resources at server side without requiring clients to update overlay mods or anything
		stage.m_resourcesToLoad = array<string>();
		stage.m_resourcesToLoad.insertLast("<weapon file='GameModePVP/pvp_weapons.xml' />");
		stage.m_resourcesToLoad.insertLast("<projectile file='GameModePVP/pvp_throwables.xml' />");
		stage.m_resourcesToLoad.insertLast("<carry_item file='GameModePVP/pvp_carry_items.xml' />");
		stage.m_resourcesToLoad.insertLast("<call file='GameModePVP/pvp_calls.xml' />");
		stage.m_resourcesToLoad.insertLast("<vehicle file='GameModePVP/pvp_vehicles.xml' />");
		//stage.m_resourcesToLoad.insertLast(read_xml(THIS_DIR."rewards.xml"));
		//stage.m_resourcesToLoad.insertLast(read_xml(THIS_DIR."scene.xml"));
		
		// not sure if this is needed, or if this is the way to do it, but here it is
		// does not seem to change anything whether commented or not
		//stage.m_resourcesToLoad.insertLast("<reward_config file='rewards.xml' />");
		//stage.m_resourcesToLoad.insertLast("<scene file='scene.xml' />");
	}

	// ------------------------------------------------------------------------------------------------
	protected Stage@ createStage() {
		Stage@ stage = MapRotatorMiniModes::createStage();
		setResources(stage);
		stage.m_includeLayers.insertLast("layer1.all"); // dummy
		return stage;
	}

	// ------------------------------------------------------------------------------------------------
	protected MatchClassic@ createMatch() {
		MatchClassic@ match = MatchClassic(m_metagame);
		fillClassicMatchSettings(match);
		return match;
	}

	// ------------------------------------------------------------------------------------------------
	protected void setupPlaylist1() {
		// ------------------------------------------------------------------------------------------------
		// RATTLESNAKE CRESCENT
		// ------------------------------------------------------------------------------------------------
		{

			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Rattlesnake Crescent";
			stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map6";
			stage.m_mapIndex = 6;

			stage.m_includeLayers.insertLast("bases.dominance");
			stage.m_includeLayers.insertLast("layer1.dominance");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[4]);

			{
				float maxTime = m_metagame.getUserSettings().m_quickmatchMaxTime;
				SubStage@ substage = QuickMatchSubStage(stage, maxTime);
        
				substage.m_mapViewOverlayFilename = "map6_mask.png";

				MatchClassic @ match = createMatch();

				// use lowercase here
				match.m_capturableBases = array<string> = {"outskirts", "junkyard", "bazaar", "tv station", "powerhouse", "mosque"};
				
				match.m_maxSoldiers = 15 * 6;
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Outskirts");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Powerhouse");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.m_ownedBases.insertLast("Junkyard");
					faction.m_ownedBases.insertLast("Mosque");
					faction.m_ownedBases.insertLast("TV Station");
					faction.m_ownedBases.insertLast("Bazaar");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[3]);
					faction.m_ownedBases.insertLast("Outpost");
					faction.m_ownedBases.insertLast("Forward HQ Alpha");
					faction.m_ownedBases.insertLast("Forward HQ Bravo");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		} 
		
		// ------------------------------------------------------------------------------------------------
		// RATTLESNAKE CRESCENT KOTH
		// ------------------------------------------------------------------------------------------------
		{

			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Rattlesnake Crescent";
			stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map6";
			stage.m_mapIndex = 6;

			stage.m_includeLayers.insertLast("bases.dominance");
			stage.m_includeLayers.insertLast("layer2.dominance");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[4]);

			{
				float maxTime = m_metagame.getUserSettings().m_kothMaxTime;
				SubStage@ substage = KothSubStage(stage, "Junkyard", 720.0, maxTime); 
                substage.addTracker(Spawner(m_metagame, 2, Vector3(663,10,679), 30, "default_ai"));
			
				substage.m_mapViewOverlayFilename = "map6_mask2.png";

				MatchClassic @ match = createMatch();

				match.m_maxSoldiers = 30 * 3;
				match.m_soldierCapacityModel = "constant";
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Outskirts");
					faction.m_ownedBases.insertLast("Outpost");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.m_ownedBases.insertLast("Bazaar");
					faction.m_ownedBases.insertLast("TV station");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[3]);
					faction.m_ownedBases.insertLast("Junkyard");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[4]);
					faction.m_ownedBases.insertLast("Mosque");
					faction.m_ownedBases.insertLast("Forward HQ alpha");
					faction.m_ownedBases.insertLast("Forward HQ bravo");
					faction.m_ownedBases.insertLast("Powerhouse");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		}	

		// ------------------------------------------------------------------------------------------------
		// KEEPSAKE BAY
		// ------------------------------------------------------------------------------------------------
		{

			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Keepsake Bay";
			stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map2";
			stage.m_mapIndex = 2;

			stage.m_includeLayers.insertLast("layer1.dominance");
			stage.m_includeLayers.insertLast("bases.default");
			stage.m_includeLayers.insertLast("bases.dominance");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[4]);

			{
				float maxTime = m_metagame.getUserSettings().m_quickmatchMaxTime;
				SubStage@ substage = QuickMatchSubStage(stage, maxTime);
        
				substage.m_mapViewOverlayFilename = "map2_mask.png";

				MatchClassic @ match = createMatch();

				// use lowercase here
				match.m_capturableBases = array<string> = {"west end", "docks", "shop lane", "eastern district", "church"};

				match.m_maxSoldiers = 15 * 5;
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("West end");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Church");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.m_ownedBases.insertLast("Docks");
					faction.m_ownedBases.insertLast("Shop lane");
					faction.m_ownedBases.insertLast("Eastern District");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[3]);
					faction.m_ownedBases.insertLast("Villa");
					faction.m_ownedBases.insertLast("Ranch");
					faction.m_ownedBases.insertLast("East Beach");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		} 

		// ------------------------------------------------------------------------------------------------
		// POWER JUNCTION KOTH 
		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Power Junction";
			stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map7";
			stage.m_mapIndex = 7;

//			stage.m_includeLayers.insertLast("layer1.default");
			stage.m_includeLayers.insertLast("bases.default");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[2]);
			// neutral too
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);

			{
				float maxTime = m_metagame.getUserSettings().m_kothMaxTime;
				SubStage@ substage = KothSubStage(stage, "Power plant", 600.0, maxTime);  // was 400 with old koth system (1.94)
				substage.addTracker(Spawner(m_metagame, 3, Vector3(494,10,502), 30, "default_ai"));
        
				substage.m_mapViewOverlayFilename = "map7_mask.png";

				MatchClassic @ match = createMatch();

				match.m_maxSoldiers = 30 * 3;
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[3]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		} 

		// ------------------------------------------------------------------------------------------------
		// VIGIL ISLAND KOTH 
		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Vigil Island";
			stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map8";
			stage.m_mapIndex = 8;

//			stage.m_includeLayers.insertLast("layer1.campaign_only");
			stage.m_includeLayers.insertLast("layer1.classic");
			stage.m_includeLayers.insertLast("bases.default");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			// neutral too
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);

			{
				float maxTime = m_metagame.getUserSettings().m_kothMaxTime;
				SubStage@ substage = KothSubStage(stage, "Airfield", 720.0, maxTime); // was 600 with old koth system (1.94)
                substage.addTracker(Spawner(m_metagame, 2, Vector3(297,10,394), 30, "default_ai"));
			
				substage.m_mapViewOverlayFilename = "map8_mask1.png";

				MatchClassic @ match = createMatch();

				match.m_maxSoldiers = 33 * 3;
				match.m_soldierCapacityModel = "constant";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[3]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		}

		// ------------------------------------------------------------------------------------------------
		// VIGIL ISLAND CAPTURE SOUTH LEG
		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Vigil Island";
			stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map8";
			stage.m_mapIndex = 8;

			stage.m_includeLayers.insertLast("layer1.capture");
			stage.m_includeLayers.insertLast("bases1.dominance");
			stage.m_includeLayers.insertLast("materials.classic");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			// neutral too
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);

			{
				float maxTime = m_metagame.getUserSettings().m_quickmatchMaxTime;
				SubStage@ substage = QuickMatchSubStage(stage, maxTime);

				substage.m_mapViewOverlayFilename = "map8_mask2.png";

				MatchClassic @ match = createMatch();

				// use lower case here
				match.m_capturableBases = array<string> = {"airfield", "southern bulge", "leg sw", "leg se", "south end", "aircraft carrier"};

				match.m_maxSoldiers = 12 * 6;
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Airfield");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Aircraft Carrier");
					faction.m_ownedBases.insertLast("South End");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[3]);
					faction.m_ownedBases.insertLast("Southern Bulge");
					faction.m_ownedBases.insertLast("Leg SW");
					faction.m_ownedBases.insertLast("Leg SE");
				//	faction.m_ownedBases.insertLast("South End");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}

				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		}

		// ------------------------------------------------------------------------------------------------
		// VIGIL ISLAND CAPTURE NORTH LEG
		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Vigil Island";
			stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map8";
			stage.m_mapIndex = 8;

			stage.m_includeLayers.insertLast("layer2.capture");
			stage.m_includeLayers.insertLast("bases2.dominance");
			stage.m_includeLayers.insertLast("materials.classic");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			// neutral too
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);

			{
				float maxTime = m_metagame.getUserSettings().m_quickmatchMaxTime;
				SubStage@ substage = QuickMatchSubStage(stage, maxTime);

				substage.m_mapViewOverlayFilename = "map8_mask3.png";

				MatchClassic @ match = createMatch();

				// use lower case here
				match.m_capturableBases = array<string> = {"airfield", "northern bulge", "leg nw", "leg ne", "aircraft carrier"};

				match.m_maxSoldiers = 12 * 5;
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Airfield");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Aircraft Carrier");
					faction.m_ownedBases.insertLast("Leg NE");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[3]);
					faction.m_ownedBases.insertLast("Northern Bulge");
					faction.m_ownedBases.insertLast("Leg NW");
				//	faction.m_ownedBases.insertLast("Leg NE");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}

				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		}

		// ------------------------------------------------------------------------------------------------
		// COPEHILL DOWN
		// ------------------------------------------------------------------------------------------------
		{

			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Copehill Down";
			stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map11";
			stage.m_mapIndex = 11;

			stage.m_includeLayers.insertLast("layer1.dominance");
			stage.m_includeLayers.insertLast("bases.dominance");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);


			{
				float maxTime = m_metagame.getUserSettings().m_quickmatchMaxTime;
				SubStage@ substage = QuickMatchSubStage(stage, maxTime);
        
				substage.m_mapViewOverlayFilename = "map11_mask.png";

				MatchClassic @ match = createMatch();

				// use lowercase here
				match.m_capturableBases = array<string> = {"town head", "courtyard", "clubhouse", "town center", "cozy road", "town end"};

				match.m_maxSoldiers = 6 * 13;            // was 6*15 in 1.71.2
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("town head");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("town end");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[3]);
					faction.m_ownedBases.insertLast("courtyard");
					faction.m_ownedBases.insertLast("clubhouse");
					faction.m_ownedBases.insertLast("town center");
					faction.m_ownedBases.insertLast("cozy road");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				// add any initial commands here, can be used as modifiers e.g. for substage specific faction resources
				//substage.init_commands.insertLast() = "<command class='commander_ai' active='1' />";
				substage.addInitCommand("<command class='commander_ai' active='1' faction='0' />");
				substage.addInitCommand("<command class='commander_ai' active='1' faction='1' />");        
			}

			m_stages.insertLast(stage);
		}    
    


		// ------------------------------------------------------------------------------------------------
		// OLD FORT CREEK
		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Old Fort Creek";
			stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map3";
			stage.m_mapIndex = 3;

			stage.m_includeLayers.insertLast("layer1.dominance");      
			stage.m_includeLayers.insertLast("bases.default"); 

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[4]);

			{
				float maxTime = m_metagame.getUserSettings().m_quickmatchMaxTime;
				SubStage@ substage = QuickMatchSubStage(stage, maxTime);
        
				substage.m_mapViewOverlayFilename = "map3_mask.png";

				MatchClassic @ match = createMatch();

				// use lower case here
				match.m_capturableBases = array<string> = {"shopping mall", "midtown", "great bridge", "north end"};

				match.m_maxSoldiers = 16 * 6;
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Great Bridge");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Shopping Mall");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.m_ownedBases.insertLast("Midtown");
					faction.m_ownedBases.insertLast("North End");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[3]);
					faction.m_ownedBases.insertLast("Textile Factory");
					faction.m_ownedBases.insertLast("West Residences");
					faction.m_ownedBases.insertLast("East Residences");
					faction.m_ownedBases.insertLast("South Side");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		} 


		// ------------------------------------------------------------------------------------------------
		// FROZEN CANYON
		// ------------------------------------------------------------------------------------------------
		{

			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Frozen Canyon";
			stage.m_mapInfo.m_path = "media/packages/vanilla.winter/maps/map12";
			stage.m_mapIndex = 12;

			stage.m_includeLayers.insertLast("bases.dominance");
			stage.m_includeLayers.insertLast("layer1.dominance");
			stage.m_includeLayers.insertLast("offroad.dominance"); 

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);

			{
				float maxTime = m_metagame.getUserSettings().m_quickmatchMaxTime;
				SubStage@ substage = QuickMatchSubStage(stage, maxTime);
        
				substage.m_mapViewOverlayFilename = "map12_mask.png";

				MatchClassic @ match = createMatch();

				// use lowercase here
				match.m_capturableBases = array<string> = {"research lab", "castle ruins", "arena"};

				match.m_maxSoldiers = 3 * 20;
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("research lab");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					//	faction.m_ownedBases.insertLast() = "castle ruins";
					faction.m_ownedBases.insertLast("arena");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.m_ownedBases.insertLast("castle ruins");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}

				@substage.m_match = @match;

				// add any initial commands here, can be used as modifiers e.g. for substage specific faction resources
				//substage.init_commands.insertLast() = "<command class='commander_ai' active='1' />";
				substage.addInitCommand("<command class='commander_ai' active='1' faction='0' />");
				substage.addInitCommand("<command class='commander_ai' active='1' faction='1' />");        
			}

			m_stages.insertLast(stage);
		}    
    



		// ------------------------------------------------------------------------------------------------
		// BOOTLEG ISLANDS
		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Bootleg Islands";
			stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map5";
			stage.m_mapIndex = 5;

			stage.m_includeLayers.insertLast("bases.default");
			stage.m_includeLayers.insertLast("layer1.default");
			stage.m_includeLayers.insertLast("layer1.dominance");
			
			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[4]);

			{
				float maxTime = m_metagame.getUserSettings().m_quickmatchMaxTime;
				SubStage@ substage = QuickMatchSubStage(stage, maxTime);
        
				substage.m_mapViewOverlayFilename = "map5_mask.png";

				MatchClassic @ match = createMatch();

				// use lower case here
				match.m_capturableBases = array<string> = {"memorium", "diving school", "copabanana", "residence", "village", "bridge"};

				match.m_maxSoldiers = 11 * 7;
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Copabanana");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Bridge");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.m_ownedBases.insertLast("Diving School");
					faction.m_ownedBases.insertLast("Memorium");
					faction.m_ownedBases.insertLast("Village");
					faction.m_ownedBases.insertLast("Residence");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[3]);
					faction.m_ownedBases.insertLast("Frontier");
					faction.m_ownedBases.insertLast("Dunes Camp");
					faction.m_ownedBases.insertLast("Old Fortress");
					faction.m_ownedBases.insertLast("Old Port");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		} 

		// ------------------------------------------------------------------------------------------------
		// RAILROAD GAP 1
		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Railroad Gap";
			stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map10";
			stage.m_mapIndex = 10;
      
			stage.m_includeLayers.insertLast("layer1_1.dominance");
			stage.m_includeLayers.insertLast("bases_1.dominance");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[2]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[4]);

			{
				float maxTime = m_metagame.getUserSettings().m_quickmatchMaxTime;
				SubStage@ substage = QuickMatchSubStage(stage, maxTime);
        
				substage.m_mapViewOverlayFilename = "map10_mask1.png";

				MatchClassic @ match = createMatch();

				// use lower case here
				match.m_capturableBases = array<string> = {"gas station", "hamlet", "main road", "city center", "embassy", "market", "terminus"};

				match.m_maxSoldiers = 20 * 6;         // was 100 in 1.71.2
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Gas Station");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.m_ownedBases.insertLast("Terminus");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[3]);
					faction.m_ownedBases.insertLast("Main Road");
					faction.m_ownedBases.insertLast("Hamlet");                    
					faction.m_ownedBases.insertLast("City Center");
					faction.m_ownedBases.insertLast("Market");
					faction.m_ownedBases.insertLast("Embassy");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[4]);
					faction.m_ownedBases.insertLast("Warehouse");
					faction.m_ownedBases.insertLast("Mosque");
					faction.m_ownedBases.insertLast("Tennis Club");
					faction.m_ownedBases.insertLast("Chemical Factory");
					faction.m_ownedBases.insertLast("Racing Track");
					faction.m_ownedBases.insertLast("Container Port");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		} 

		// ------------------------------------------------------------------------------------------------
		// RAILROAD GAP 2
		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Railroad Gap";
			stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map10";
			stage.m_mapIndex = 10;
      
      stage.m_includeLayers.insertLast("layer1_2.dominance");
			stage.m_includeLayers.insertLast("bases_2.dominance");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[4]);

			{
				float maxTime = m_metagame.getUserSettings().m_quickmatchMaxTime;
				SubStage@ substage = QuickMatchSubStage(stage, maxTime);
        
				substage.m_mapViewOverlayFilename = "map10_mask2.png";

				MatchClassic @ match = createMatch();

				// use lower case here
				match.m_capturableBases = array<string> = {"terminus", "warehouse", "mosque", "tennis club", "chemical factory", "container port"};

				match.m_maxSoldiers = 22 * 5;        // was 100 in 1.71.2
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Container Port");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Terminus");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[3]);
					faction.m_ownedBases.insertLast("Warehouse");
					faction.m_ownedBases.insertLast("Mosque");
					faction.m_ownedBases.insertLast("Tennis Club");
					faction.m_ownedBases.insertLast("Chemical Factory");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[4]);
					faction.m_ownedBases.insertLast("Gas Station");
					faction.m_ownedBases.insertLast("Main Road");
					faction.m_ownedBases.insertLast("City Center");
					faction.m_ownedBases.insertLast("Embassy");
					faction.m_ownedBases.insertLast("Racing Track");
					faction.m_ownedBases.insertLast("Market");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		} 

		// ------------------------------------------------------------------------------------------------
		// BLACK GOLD ESTUARY
		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Black Gold Estuary";
			stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map9";
			stage.m_mapIndex = 9;
      
			stage.m_includeLayers.insertLast("layer1.dominance");
			stage.m_includeLayers.insertLast("bases.dominance");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);
//			stage.m_factionConfigs.insertLast(m_factionConfigs[4]);

			{
				float maxTime = m_metagame.getUserSettings().m_quickmatchMaxTime;
				SubStage@ substage = QuickMatchSubStage(stage, maxTime);
        
				substage.m_mapViewOverlayFilename = "map9_mask.png";

				MatchClassic @ match = createMatch();

				// use lower case here
				match.m_capturableBases = array<string> = {"hotel", "seaside", "village", "construction site", "ocean institute"};

				match.m_maxSoldiers = 20 * 4;
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Hotel");
					faction.m_ownedBases.insertLast("Seaside");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Construction Site");
					faction.m_ownedBases.insertLast("Ocean Institute");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[3]);
					faction.m_ownedBases.insertLast("Village"); 
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}

				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		}
		
		// ------------------------------------------------------------------------------------------------
		// BLACK GOLD ESTUARY KOTH 
		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Black Gold Estuary";
			stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map9";
			stage.m_mapIndex = 9;
      
			stage.m_includeLayers.insertLast("layer2.dominance");
			stage.m_includeLayers.insertLast("bases.dominance");

			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[2]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);
//			stage.m_factionConfigs.insertLast(m_factionConfigs[4]);

			{
				float maxTime = m_metagame.getUserSettings().m_kothMaxTime;
				SubStage@ substage = KothSubStage(stage, "Village", 720.0, maxTime); 
                substage.addTracker(Spawner(m_metagame, 2, Vector3(349,10,551), 30, "default_ai"));
			
				substage.m_mapViewOverlayFilename = "map9_mask2.png";

				MatchClassic @ match = createMatch();

				match.m_maxSoldiers = 33 * 3;
				match.m_soldierCapacityModel = "constant";
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Hotel");
					faction.m_ownedBases.insertLast("Seaside");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.m_ownedBases.insertLast("Construction Site");
					faction.m_ownedBases.insertLast("Ocean Institute");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[3]);
					faction.m_ownedBases.insertLast("Village");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		}		
		
		// ------------------------------------------------------------------------------------------------
		// IRON ENCLAVE
		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Iron Enclave";
			stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map13";
			stage.m_mapIndex = 13;
      
			stage.m_includeLayers.insertLast("layer1.dominance");
			stage.m_includeLayers.insertLast("bases.default");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[2]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[4]);

			{
				float maxTime = m_metagame.getUserSettings().m_quickmatchMaxTime;
				SubStage@ substage = QuickMatchSubStage(stage, maxTime);
        
				substage.m_mapViewOverlayFilename = "map13_mask1.png";

				MatchClassic @ match = createMatch();

				// use lower case here
				match.m_capturableBases = array<string> = {"hotel", "castle", "park", "factory", "promenade", "downtown", "rail station", "western entrance", "western district"};

				match.m_maxSoldiers = 16 * 9;
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Castle");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Rail Station");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.m_ownedBases.insertLast("Western Entrance");
					match.m_factions.insertLast(faction);
				}        
				{
					Faction@ faction = Faction(m_factionConfigs[3]);
					faction.m_ownedBases.insertLast("Western District"); 
					faction.m_ownedBases.insertLast("Promenade");
					faction.m_ownedBases.insertLast("Park");
					faction.m_ownedBases.insertLast("Factory");
					faction.m_ownedBases.insertLast("Downtown");
					faction.m_ownedBases.insertLast("Hotel");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[4]);
					faction.m_ownedBases.insertLast("HQ West 1");
					faction.m_ownedBases.insertLast("HQ West 2");
					faction.m_ownedBases.insertLast("HQ East 1");
					faction.m_ownedBases.insertLast("HQ East 2");
					faction.m_ownedBases.insertLast("HQ South 1");
					faction.m_ownedBases.insertLast("HQ South 2");
					faction.m_ownedBases.insertLast("Port");
               
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		}

		// ------------------------------------------------------------------------------------------------
		// MISTY HEIGHTS 1
		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Misty Heights";
			stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map14";
			stage.m_mapIndex = 14;
      
			stage.m_includeLayers.insertLast("layer1_1.dominance");
			stage.m_includeLayers.insertLast("bases_1.dominance");

			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[2]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[4]);

			{
				float maxTime = m_metagame.getUserSettings().m_quickmatchMaxTime;
				SubStage@ substage = QuickMatchSubStage(stage, maxTime);
        
				substage.m_mapViewOverlayFilename = "map14_mask1.png";
//        substage.m_mapViewOverlayFilename = "mapview_overlay_addition_1.png";        

				MatchClassic @ match = createMatch();

				// use lower case here
				match.m_capturableBases = array<string> = {"chemical plant", "southern village", "northern village", "graveyard"};

				match.m_maxSoldiers = 18 * 4;
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Chemical Plant");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.m_ownedBases.insertLast("Graveyard");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[3]);
					faction.m_ownedBases.insertLast("Northern Village"); 
					faction.m_ownedBases.insertLast("Southern Village");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[4]);
//					faction.m_ownedBases.insertLast("Command Center");
//					faction.m_ownedBases.insertLast("Ruins");
					faction.m_ownedBases.insertLast("North Draw");
					faction.m_ownedBases.insertLast("South Draw");
					faction.m_ownedBases.insertLast("North Beach");
					faction.m_ownedBases.insertLast("Mid Beach");
					faction.m_ownedBases.insertLast("South Beach");
            
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		}

		// ------------------------------------------------------------------------------------------------
		// MISTY HEIGHTS 2
		// ------------------------------------------------------------------------------------------------
		{

			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Misty Heights";
			stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map14";
			stage.m_mapIndex = 14;

			stage.m_includeLayers.insertLast("layer1_2.dominance");
			stage.m_includeLayers.insertLast("bases_2.dominance");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			// stage.m_factionConfigs.insertLast(m_factionConfigs[3]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[4]);

			{
				float maxTime = m_metagame.getUserSettings().m_quickmatchMaxTime;
				SubStage@ substage = QuickMatchSubStage(stage, maxTime);
        
				substage.m_mapViewOverlayFilename = "map14_mask2.png"; 
				// substage.m_mapViewOverlayFilename = "mapview_overlay_addition_2.png";

				MatchClassic @ match = createMatch();

				// use lowercase here
				match.m_capturableBases = array<string> = {"northern village", "southern village", "command center", "cliffs"};

				match.m_maxSoldiers = 20 * 4;
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Northern Village");
					faction.m_ownedBases.insertLast("Southern Village");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Command Center");
					faction.m_ownedBases.insertLast("Cliffs");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[4]);
					faction.m_ownedBases.insertLast("Beach");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		}    
    

		// ------------------------------------------------------------------------------------------------
		// MOORLAND TRENCHES (ALT) 1
		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Moorland Trenches";
			stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map1_2";
			stage.m_mapIndex = 1;
      
			stage.m_includeLayers.insertLast("layer1_1.dominance");
			stage.m_includeLayers.insertLast("bases_1.dominance");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[4]);

			{
				float maxTime = m_metagame.getUserSettings().m_quickmatchMaxTime;
				SubStage@ substage = QuickMatchSubStage(stage, maxTime);
        
				substage.m_mapViewOverlayFilename = "map1_2_mask1.png"; 
//        substage.m_mapViewOverlayFilename = "mapview_overlay_addition_2.png";

				MatchClassic @ match = createMatch();

				// use lower case here
				match.m_capturableBases = array<string> = {"gas station", "east trench", "ruins", "center trench"};

				match.m_maxSoldiers = 20 * 4;
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Gas station");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Center trench");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[3]);
					faction.m_ownedBases.insertLast("Ruins");
					faction.m_ownedBases.insertLast("East trench");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[4]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		} 


		// ------------------------------------------------------------------------------------------------
		// MOORLAND TRENCHES (ALT) 2 (KOTH)
		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Moorland Trenches";
			stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map1_2";
			stage.m_mapIndex = 1;
      
			stage.m_includeLayers.insertLast("layer1_2.dominance");
			stage.m_includeLayers.insertLast("bases_2.dominance");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[2]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);


			{
				float maxTime = m_metagame.getUserSettings().m_kothMaxTime;
				SubStage@ substage = KothSubStage(stage, "Chapel", 720.0, maxTime);  // was 480 with old koth system (1.94)
                substage.addTracker(Spawner(m_metagame, 2, Vector3(335,10,354), 30, "default_ai"));
        
				substage.m_mapViewOverlayFilename = "map1_2_mask2.png"; 
//        substage.m_mapViewOverlayFilename = "mapview_overlay_addition_2.png";

				MatchClassic @ match = createMatch();

				// use lower case here
//				match.m_capturableBases = array<string> = {"mansion", "cottage", "chapel", "center trench", "west town"};

				match.m_maxSoldiers = 20 * 4;
				match.m_soldierCapacityModel = "constant";
                
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Mansion");
					faction.m_ownedBases.insertLast("Cottage");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.m_ownedBases.insertLast("West town");
					faction.m_ownedBases.insertLast("Center trench");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[3]);
					faction.m_ownedBases.insertLast("Chapel");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				} 
				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		}
		


		// ------------------------------------------------------------------------------------------------
		// MOORLAND TRENCHES (ALT) 3
		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Moorland Trenches";
			stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map1_2";
			stage.m_mapIndex = 1;
      
			stage.m_includeLayers.insertLast("layer1_3.dominance");
			stage.m_includeLayers.insertLast("bases_3.dominance");

			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[2]);
//			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[4]);

			{
				float maxTime = m_metagame.getUserSettings().m_quickmatchMaxTime;
				SubStage@ substage = QuickMatchSubStage(stage, maxTime);
        
				substage.m_mapViewOverlayFilename = "map1_2_mask3.png"; 
//        substage.m_mapViewOverlayFilename = "mapview_overlay_addition_2.png";

				MatchClassic @ match = createMatch();

				// use lower case here
				match.m_capturableBases = array<string> = {"power house", "suburbs", "east town", "west town"};

				match.m_maxSoldiers = 20 * 4;
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("East town");
					faction.m_ownedBases.insertLast("West town");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.m_ownedBases.insertLast("Power house");
					faction.m_ownedBases.insertLast("Suburbs");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[4]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		}

		// ------------------------------------------------------------------------------------------------ 
    //  ISLET OF EFLEN 
		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Islet of Eflen";
			stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map15";
			stage.m_mapIndex = 15;
      
			stage.m_includeLayers.insertLast("layer1.dominance");
			stage.m_includeLayers.insertLast("bases.dominance");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);

			{
				float maxTime = m_metagame.getUserSettings().m_quickmatchMaxTime;
				SubStage@ substage = QuickMatchSubStage(stage, maxTime);
        
				substage.m_mapViewOverlayFilename = "map15_mask1.png";

				MatchClassic @ match = createMatch();

				// use lower case here
				match.m_capturableBases = array<string> = {"resort", "heel quarter", "museum", "east coast", "port"};

				match.m_maxSoldiers = 15 * 4;
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Resort");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Port");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[3]);
					faction.m_ownedBases.insertLast("Heel Quarter");
					faction.m_ownedBases.insertLast("Museum");
					faction.m_ownedBases.insertLast("East Coast");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		}


		// ------------------------------------------------------------------------------------------------ 
		// ISLET OF EFLEN (KOTH)
		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Islet of Eflen";
			stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map15";
			stage.m_mapIndex = 15;
      
			stage.m_includeLayers.insertLast("layer1.koth");
			stage.m_includeLayers.insertLast("bases.dominance");

			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[2]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);


			{
				float maxTime = m_metagame.getUserSettings().m_kothMaxTime;
				SubStage@ substage = KothSubStage(stage, "Museum", 720.0, maxTime);  // was 480 with old koth system (1.94)
                substage.addTracker(Spawner(m_metagame, 2, Vector3(507,15,525), 30, "default_ai"));
        
				substage.m_mapViewOverlayFilename = "map15_mask2.png"; 
//        substage.m_mapViewOverlayFilename = "mapview_overlay_addition_2.png";
        
				MatchClassic @ match = createMatch();

				// use lower case here
//				match.m_capturableBases = array<string> = {"mansion", "cottage", "chapel", "center trench", "west town"};

				match.m_maxSoldiers = 15 * 4;
				match.m_soldierCapacityModel = "constant";
                
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Resort");
					faction.m_ownedBases.insertLast("Heel Quarter");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.m_ownedBases.insertLast("East Coast");
					faction.m_ownedBases.insertLast("Port");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[3]); 
					faction.m_ownedBases.insertLast("Museum");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}        
				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		} 
    
		// ------------------------------------------------------------------------------------------------
		// GREEN COAST
		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Green Coast";
			stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map16";
			stage.m_mapIndex = 16;
      
			stage.m_includeLayers.insertLast("layer1.dominance");
			stage.m_includeLayers.insertLast("bases.dominance");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]); 

			{
				float maxTime = m_metagame.getUserSettings().m_quickmatchMaxTime;
				SubStage@ substage = QuickMatchSubStage(stage, maxTime);
        
				substage.m_mapViewOverlayFilename = "map16_mask1.png";

				MatchClassic @ match = createMatch();

				// use lower case here
				match.m_capturableBases = array<string> = {"western heights", "eastern heights", "warehouses", "prison", "old battle port"};

				match.m_maxSoldiers = 20 * 5;
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Prison");
					faction.m_ownedBases.insertLast("Old Battle Port");          
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Eastern Heights");
					faction.m_ownedBases.insertLast("Western Heights");          
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[3]);
					faction.m_ownedBases.insertLast("Warehouses");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		} 

		// ------------------------------------------------------------------------------------------------ 
        //  WARSALT LEGACY 
		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Warsalt Legacy";
			stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map18";
			stage.m_mapIndex = 17;
      
			stage.m_includeLayers.insertLast("layer1.dominance");
			stage.m_includeLayers.insertLast("bases.dominance");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);

			{
				float maxTime = m_metagame.getUserSettings().m_quickmatchMaxTime;
				SubStage@ substage = QuickMatchSubStage(stage, maxTime);
        
				substage.m_mapViewOverlayFilename = "map18_mask1.png";

				MatchClassic @ match = createMatch();

				// use lower case here
				match.m_capturableBases = array<string> = {"warsalt", "warsalt south", "warsalt north", "warsalt harbor", "warsalt east"};

				match.m_maxSoldiers = 20 * 5;
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Warsalt Harbor");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Warsalt North");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[3]);
					faction.m_ownedBases.insertLast("Warsalt South");
					faction.m_ownedBases.insertLast("Warsalt East");
					faction.m_ownedBases.insertLast("Warsalt");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		}


		// ------------------------------------------------------------------------------------------------
		// WARSALT LEGACY (KOTH)
		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Warsalt Legacy";
			stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map18";
			stage.m_mapIndex = 18;
      
			stage.m_includeLayers.insertLast("layer1.koth");
			stage.m_includeLayers.insertLast("bases.dominance");

			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[2]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);


			{
				float maxTime = m_metagame.getUserSettings().m_kothMaxTime;
				SubStage@ substage = KothSubStage(stage, "Warsalt", 720.0, maxTime);  // was 480 with old koth system (1.94)
                substage.addTracker(Spawner(m_metagame, 2, Vector3(617,10,799), 20, "default_ai"));
        
				substage.m_mapViewOverlayFilename = "map18_mask2.png"; 
//        substage.m_mapViewOverlayFilename = "mapview_overlay_addition_2.png";
        
				MatchClassic @ match = createMatch();

				// use lower case here
//				match.m_capturableBases = array<string> = {"mansion", "cottage", "chapel", "center trench", "west town"};

				match.m_maxSoldiers = 20 * 5;
				match.m_soldierCapacityModel = "constant";
                
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Warsalt Harbor");
					faction.m_ownedBases.insertLast("Warsalt South");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.m_ownedBases.insertLast("Warsalt North");
					faction.m_ownedBases.insertLast("Warsalt East");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[3]); 
					faction.m_ownedBases.insertLast("Warsalt");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}        
				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		} 
		
		// ------------------------------------------------------------------------------------------------
		// SWAN RIVER (WEST)
		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Swan River";
			stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map19";
			stage.m_mapIndex = 19;
      
			stage.m_includeLayers.insertLast("layer1.dominance");
			stage.m_includeLayers.insertLast("bases.dominance");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[4]);

			{
				float maxTime = m_metagame.getUserSettings().m_quickmatchMaxTime;
				SubStage@ substage = QuickMatchSubStage(stage, maxTime);
        
				substage.m_mapViewOverlayFilename = "map19_mask1.png";

				MatchClassic @ match = createMatch();

				// use lower case here
				match.m_capturableBases = array<string> = {"south fields", "warehouse", "west end", "train wreck"};

				match.m_maxSoldiers = 20 * 4;
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Train wreck");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("South fields");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[3]);
					faction.m_ownedBases.insertLast("Warehouse");
					faction.m_ownedBases.insertLast("West end");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[4]);
					faction.m_ownedBases.insertLast("East end");
					faction.m_ownedBases.insertLast("Train station");
					faction.m_ownedBases.insertLast("Factory");
            
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}				
				
				
				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		}
		
		// ------------------------------------------------------------------------------------------------
		// SWAN RIVER (EAST)
		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Swan River";
			stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map19";
			stage.m_mapIndex = 19;
      
			stage.m_includeLayers.insertLast("layer1.dominance");
			stage.m_includeLayers.insertLast("bases.dominance");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[4]);

			{
				float maxTime = m_metagame.getUserSettings().m_quickmatchMaxTime;
				SubStage@ substage = QuickMatchSubStage(stage, maxTime);
        
				substage.m_mapViewOverlayFilename = "map19_mask2.png";

				MatchClassic @ match = createMatch();

				// use lower case here
				match.m_capturableBases = array<string> = {"train station", "east end", "factory"};

				match.m_maxSoldiers = 20 * 4;
				match.m_soldierCapacityModel = "constant";
				
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Train station");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("factory");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[3]);
					faction.m_ownedBases.insertLast("East end");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[4]);
					faction.m_ownedBases.insertLast("West end");
					faction.m_ownedBases.insertLast("Warehouse");
					faction.m_ownedBases.insertLast("South fields");
					faction.m_ownedBases.insertLast("Train wreck");
            
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}				
				
				
				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		}		

		// ------------------------------------------------------------------------------------------------
		// SWAN RIVER (KOTH)
		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Swan River";
			stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map19";
			stage.m_mapIndex = 19;
      
			stage.m_includeLayers.insertLast("layer2.dominance");
			stage.m_includeLayers.insertLast("bases_2.dominance");

			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[2]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);


			{
				float maxTime = m_metagame.getUserSettings().m_kothMaxTime;
				SubStage@ substage = KothSubStage(stage, "West bridge", 720.0, maxTime);  // was 480 with old koth system (1.94)
                substage.addTracker(Spawner(m_metagame, 2, Vector3(403,10,707), 20, "default_ai"));
        
				substage.m_mapViewOverlayFilename = "map19_mask3.png"; 
//        substage.m_mapViewOverlayFilename = "mapview_overlay_addition_2.png";
        
				MatchClassic @ match = createMatch();

				// use lower case here
//				match.m_capturableBases = array<string> = {"mansion", "cottage", "chapel", "center trench", "west town"};

				match.m_maxSoldiers = 20 * 3;
				match.m_soldierCapacityModel = "constant";
                
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Market");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.m_ownedBases.insertLast("Hospital");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[3]); 
					faction.m_ownedBases.insertLast("West bridge");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}        
				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		} 
	
		// ------------------------------------------------------------------------------------------------
		// ROUTE 666 
		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Route 666";
			stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map21";
			stage.m_mapIndex = 21;
      
			stage.m_includeLayers.insertLast("layer1.dominance");
			stage.m_includeLayers.insertLast("bases.dominance");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);
			
			{
				float maxTime = m_metagame.getUserSettings().m_quickmatchMaxTime;
				SubStage@ substage = QuickMatchSubStage(stage, maxTime);
        
				substage.addTracker(Spawner(m_metagame, 2, Vector3(793,3,647), 15, "default_ai"));
				substage.addTracker(Spawner(m_metagame, 2, Vector3(850,3,626), 15, "default_ai"));
        
				substage.m_mapViewOverlayFilename = "map21_mask1.png";

				MatchClassic @ match = createMatch();

				// use lower case here
				match.m_capturableBases = array<string> = {"hell east", "hell church", "hell north", "hell west", "hell suburb"};

				match.m_maxSoldiers = 20 * 4;
				match.m_soldierCapacityModel = "constant";
				
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Hell Suburb");
					faction.m_ownedBases.insertLast("Hell West");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Hell East");
					faction.m_ownedBases.insertLast("Hell North");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[3]);
					faction.m_ownedBases.insertLast("Hell Church");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
								
				
				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		}		

		// ------------------------------------------------------------------------------------------------
		// ROUTE 666 (KOTH)
		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Route 666";
			stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map21";
			stage.m_mapIndex = 21;
      
			stage.m_includeLayers.insertLast("layer1.koth");
			stage.m_includeLayers.insertLast("bases.dominance");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[3]);
			
			{
				float maxTime = m_metagame.getUserSettings().m_kothMaxTime;
				SubStage@ substage = KothSubStage(stage, "Hell Church", 720.0, maxTime);  

                substage.addTracker(Spawner(m_metagame, 2, Vector3(793,3,647), 15, "default_ai"));
				substage.addTracker(Spawner(m_metagame, 2, Vector3(850,3,626), 15, "default_ai"));
        
				substage.m_mapViewOverlayFilename = "map21_mask2.png"; 
        
				MatchClassic @ match = createMatch();


				// use lower case here
				match.m_capturableBases = array<string> = {"hell church"};

				match.m_maxSoldiers = 20 * 4;
				match.m_soldierCapacityModel = "constant";
				
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Hell Suburb");
					faction.m_ownedBases.insertLast("Hell West");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Hell East");
					faction.m_ownedBases.insertLast("Hell North");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[3]);
					faction.m_ownedBases.insertLast("Hell Church");
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
								
				
				@substage.m_match = @match;
			}

			m_stages.insertLast(stage);
		}		
	}	
}

