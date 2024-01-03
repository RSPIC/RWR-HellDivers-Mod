// gamemode specific
#include "faction_config.as"
#include "stage_configurator.as"
#include "stage_invasion.as"
#include "phase_controller_map12.as"
#include "pausing_koth_timer.as"
#include "spawn_at_node.as"
#include "comms_capacity_handler.as"
#include "attack_defense_handler_map16.as"
#include "attack_defense_handler_map1_2.as"
#include "run_at_start.as"

// ------------------------------------------------------------------------------------------------
class StageConfiguratorInvasion : StageConfigurator {
	protected GameModeInvasion@ m_metagame;
	protected MapRotatorInvasion@ m_mapRotator;
	protected int m_stagesAdded;

	// ------------------------------------------------------------------------------------------------
	StageConfiguratorInvasion(GameModeInvasion@ metagame, MapRotatorInvasion@ mapRotator) {
		@m_metagame = @metagame;
		@m_mapRotator = mapRotator;
		mapRotator.setConfigurator(this);
		m_stagesAdded = 0;
		
		const UserSettings@ settings = m_metagame.getUserSettings();
		g_server_activity_racing = settings.m_server_activity_racing;
		g_server_activity = settings.m_server_activity;
		if(g_server_activity){
			_log("g_server_activity is true");
		}
		if(g_server_activity_racing){
			_log("g_server_activity_racing is true");
		}
	}

	// ------------------------------------------------------------------------------------------------
	void setup() {
		setupFactionConfigs();

		setupWorld();

		setupNormalStages();
	}

	// ------------------------------------------------------------------------------------------------
	const array<FactionConfig@>@ getAvailableFactionConfigs() const {
		array<FactionConfig@> availableFactionConfigs;
		availableFactionConfigs.push_back(FactionConfig(0, "super_earth.xml", "SuperEarth", "1 0.6 0", "super_earth.xml"));
		availableFactionConfigs.push_back(FactionConfig(1, "infected.xml", "Infected", "0 1 0.3", "infected.xml"));
		//availableFactionConfigs.push_back(FactionConfig(2, "infected2.xml", "Infected2", "0 0.7 0", "infected2.xml"));

		return availableFactionConfigs;
	}

	// ------------------------------------------------------------------------------------------------
	protected void setupFactionConfigs() {
		array<FactionConfig@> availableFactionConfigs = getAvailableFactionConfigs(); // copy for mutability

		const UserSettings@ settings = m_metagame.getUserSettings();
		// - the faction the player picks in lobby campaign menu needs to be inserted first in the faction configs list
		{
			_log("faction choice: " + settings.m_factionChoice, 1);
			FactionConfig@ userChosenFaction = availableFactionConfigs[settings.m_factionChoice];
			_log("player faction: " + userChosenFaction.m_file, 1);

			int index = int(getFactionConfigs().size()); // is 0
			userChosenFaction.m_index = index;
			m_mapRotator.addFactionConfig(userChosenFaction);

			availableFactionConfigs.erase(settings.m_factionChoice);
		}

		// - next add the rest of them, in random order
		while (availableFactionConfigs.size() > 0) {
			int index = int(getFactionConfigs().size());

			int availableIndex = rand(0, availableFactionConfigs.size() - 1);
			FactionConfig@ faction = availableFactionConfigs[availableIndex];

			_log("setting " + faction.m_name + " as index " + index, 1);

			faction.m_index = index;
			m_mapRotator.addFactionConfig(faction);

			availableFactionConfigs.erase(availableIndex);
		}

		// - finally add neutral
		{
			int index = getFactionConfigs().size();
			m_mapRotator.addFactionConfig(FactionConfig(index, "neutral.xml", "Neutral", "0 0 0"));
		}

		_log("total faction configs " + getFactionConfigs().size(), 1);
	}

	// ------------------------------------------------------------------------------------------------
	protected void addRandomSpecialCrates(Stage@ stage, int minCount, int maxCount) {
		array<ScoredResource@> resources = {

		};
		// int count = rand(minCount, maxCount);
		// stage.addTracker(SpawnAtNode(m_metagame, resources, "random_crate", 0, count));
	}
	
	// ------------------------------------------------------------------------------------------------
	protected void addFixedSpecialCrates(Stage@ stage) {
		array<ScoredResource@> resources = {

		};
		// stage.addTracker(SpawnAtNode(m_metagame, resources, "fixed_crate", 0, 1000));
	}
	
	// ------------------------------------------------------------------------------------------------
	protected void addLotteryVehicle(Stage@ stage) {
		array<ScoredResource@> resources = {
			// for testing: 0 score no spawn -> 100% chance for icecream
			//ScoredResource("", "", 0.0f),          
			ScoredResource("", "", 0.0f),
			ScoredResource("icecream.vehicle", "vehicle", 100.0f)
		};
		stage.addTracker(SpawnAtNode(m_metagame, resources, "icecream", 1, 1));
		return;
	}
	
	// ------------------------------------------------------------------------------------------------
	protected void addDarkcatVehicle(Stage@ stage) {
		// array<ScoredResource@> resources = {
		// 	// for testing: 0 score no spawn -> 100% chance for icecream
		// 	//ScoredResource("", "", 0.0f),          
		// 	ScoredResource("", "", 100.0f),
		// 	ScoredResource("darkcat.vehicle", "vehicle", 0.0f)
		// };
		// stage.addTracker(SpawnAtNode(m_metagame, resources, "darkcat", 1, 1));
	}	
	
	// ------------------------------------------------------------------------------------------------
    protected void addArenaJammer(Stage@ stage) {
        array<ScoredResource@> resources = {
            // for testing: 0 score no spawn -> 100% chance for icecream
            //ScoredResource("", "", 0.0f),          
            ScoredResource("", "", 0.0f),
            ScoredResource("radio_jammer2.vehicle", "vehicle", 100.0f)
        };
        stage.addTracker(SpawnAtNode(m_metagame, resources, "arena_jammer", 1, 1));
    }        
    
	
	// ------------------------------------------------------------------------------------------------
	protected void addStage(Stage@ stage) {
		addFixedSpecialCrates(stage);
		addRandomSpecialCrates(stage, stage.m_minRandomCrates, stage.m_maxRandomCrates);
		addLotteryVehicle(stage);
		addDarkcatVehicle(stage);
		addArenaJammer(stage);
		
		if (stage.isCapture()) {
			stage.setIntelManager(IntelManager(m_metagame));
		}

		m_mapRotator.addStage(stage);
		m_stagesAdded++;
	}

	// ------------------------------------------------------------------------------------------------
	protected void setupNormalStages() {
		if(g_server_activity){
			setupActivityStages();
			_log("setupNormalStages add g_server_activity");
		}else{
			_log("setupNormalStages add normal");
			addStage(setupStageBloodandFlowers_01());         // BloodandFlowers_01 By asanonana ver1.5.11
			addStage(setupStage8());          // map8 #13 10 
			addStage(setupStage10());         // map10 #7 4 疑似有bug ver1.5.10
			addStage(setupStage14());         // map6_2 #14 11
			addStage(setupStage2());          // map4 #15 12
			addStage(setupStage3());          // map3 #10 7
			addStage(setupStage6());          // map5 #17 15
			//addStage(setupFinalStage2());     // map12 #18 黑猫
			addStage(setupStage19());         // map18 #19
			addStage(setupStage11());         // map13 #20
			addStage(setupStage7());          // map6 #0
			addStage(setupStage5());          // map1 #16 14 
			addStage(setupStage1());          // map2 #1
			addStage(setupStage9());          // map9 #2
			addStage(setupStage16());         // map8_2 #3 雪地威克岛
			addStage(setupStage21());         // map20 #7 16 战壕小岛
			addStage(setupStage4());          // map7 #4 3
			// addStage(setupStage15());         // map1_2 #5 太大
			addStage(setupStage12());         // map14 #6
			addStage(setupStage17());         // map17  #8 5
			addStage(setupStage18());         // map13_2 #9 6
			addStage(setupStage13());         // map16  #11  8
			addStage(setupFinalStage1());     // map11 #12 潜行9
			addStage(setupStageCasake_Bay());         // Casake_Bay #21
			addStage(setupStage20());         // map19 #17	13 鹅城
			//addStage(setupRoberto());         // 创意工坊图 ver1.6.0  难以修改，删除 12.31 HOTCAT建议
			addStage(setupClairemont());      // 创意工坊图 ver1.6.0
			addStage(setupViper());           // 创意工坊图 ver1.6.0
			addStage(setupDef_lab_koth());    // 创意工坊图 ver1.6.0
			addStage(setupEastport());        // 创意工坊图 ver1.6.0
			addStage(setupWave_Town());       // 创意工坊图 ver1.6.0
		}
	}
	protected void setupActivityStages() {
		if(g_server_activity_racing){
			addStage(setupRacing());         // 创意工坊图 ver1.6.0 赛车地图
		}
	}
	// --------------------------------------------
	protected Stage@ createStage() const {
		Stage@ stage = Stage(m_metagame.getUserSettings());
		return stage;
	}

	// --------------------------------------------
	protected PhasedStage@ createPhasedStage() const {
		return PhasedStage(m_metagame.getUserSettings());
	}

	// --------------------------------------------
	const array<FactionConfig@>@ getFactionConfigs() const {
		return m_mapRotator.getFactionConfigs();
	}

	// ------------------------------------------------------------------------------------------------
	Stage@ setupCompletedStage(Stage@ inputStage) {
		// currently not in use in invasion
		return null;
	}

	// ------------------------------------------------------------------------------------------------
	protected void setDefaultAttackBreakTimes(Stage@ stage) {
		for (uint i = 0; i < stage.m_factions.size(); ++i) {
			XmlElement command("command");
			command.setStringAttribute("class", "commander_ai");
			command.setIntAttribute("faction", i);
			command.setFloatAttribute("start_attack_break_time", 50.0f);
			command.setFloatAttribute("attack_break_time", 60.0f);
			// initially clear final attack boost
			command.setFloatAttribute("reduce_defense_for_final_attack", 0.0f); 
			stage.m_extraCommands.insertLast(command);
		}
	}

	// ------------------------------------------------------------------------------------------------
	protected void setReduceDefenseForFinalAttack(Stage@ stage, float value) {
		XmlElement command("command");
		command.setStringAttribute("class", "commander_ai");
		command.setIntAttribute("faction", 0);
		command.setFloatAttribute("reduce_defense_for_final_attack", value);
		stage.m_extraCommands.insertLast(command);
	}

	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage1() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Keepsake Bay";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map2";
		stage.m_mapInfo.m_id = "map2";
		
		stage.m_includeLayers.insertLast("layer1.invasion"); 


		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));
		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}
		
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"noxe.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		}        

		// metadata
		stage.m_primaryObjective = "capture";

		setDefaultAttackBreakTimes(stage);
		// setReduceDefenseForFinalAttack(stage, 0.1); // use this for final attack boost if needed for friendlies
		return stage;
	}

	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage2() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Fridge Valley";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map4";
		stage.m_mapInfo.m_id = "map4";
		
		stage.m_includeLayers.insertLast("layer1.invasion");		

    stage.m_fogOffset = 20.0;    
    stage.m_fogRange = 50.0;     

		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));
		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}
		// metadata
		stage.m_primaryObjective = "capture";

		setDefaultAttackBreakTimes(stage);
		return stage;
	}

	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage3() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Old Fort Creek";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map3";
		stage.m_mapInfo.m_id = "map3";

		stage.m_includeLayers.insertLast("layer1.invasion");

		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));
		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"flamer_tank.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		}        

		// metadata
		stage.m_primaryObjective = "capture";

		setDefaultAttackBreakTimes(stage);
		return stage;
	}

	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage4() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Power Junction";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map7";
		stage.m_mapInfo.m_id = "map7";

		stage.m_includeLayers.insertLast("layer1.invasion");        

		stage.addTracker(Overtime(m_metagame, 0));


		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"radio_jammer2.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		}        

		// metadata
		stage.m_primaryObjective = "koth";
		stage.m_kothTargetBase = "Power Plant";

		return stage;
	} 

	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage5() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Moorland Trenches";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map1";
		stage.m_mapInfo.m_id = "map1";

		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}


		// aa emplacements work right only if one enemy faction has them
		// - all factions have it disabled by default
		// - manually enable it for faction #1 in map1 
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}

		// metadata
		stage.m_primaryObjective = "capture";

		setDefaultAttackBreakTimes(stage);
		return stage;
	}

	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage6() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Bootleg Islands";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map5";
		stage.m_mapInfo.m_id = "map5";

		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}

		// metadata
		stage.m_primaryObjective = "capture";

		setDefaultAttackBreakTimes(stage);
		return stage;
	} 

	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage7() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Rattlesnake Crescent";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map6";
		stage.m_mapInfo.m_id = "map6";

		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}

		// metadata
		stage.m_primaryObjective = "capture";
		stage.m_radioObjectivePresent = false;

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}

		setDefaultAttackBreakTimes(stage);
		return stage;
	} 

	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage8() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Vigil Island";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map8";
		stage.m_mapInfo.m_id = "map8";

		stage.m_includeLayers.insertLast("layer1.invasion"); 

		stage.addTracker(Overtime(m_metagame, 0));

		stage.m_maxSoldiers = 1;     // was 33 * 3 in 1.65
		stage.m_playerAiCompensation = 0;                                         // was 4 (1.81) was 5 (1.86)
    	stage.m_playerAiReduction = 0;                                            // was 2 (1.81) was 2.5 (1.86)  
		stage.m_soldierCapacityModel = "constant";

		stage.m_defenseWinTime = 720.0;   // was 600 in 1.65
		stage.m_defenseWinTimeMode = "custom";
		stage.addTracker(PausingKothTimer(m_metagame, stage.m_defenseWinTime));

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));      // was  0.1 0.1 in 1.65
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             // was 0.2 0.1 in 1.65
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                      // was 1.32 in 1.65, now working with offset only
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"radio_jammer.vehicle", "radio_jammer2.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		}

		// metadata
		stage.m_primaryObjective = "koth";
		stage.m_kothTargetBase = "Airfield";
		stage.m_radioObjectivePresent = false;

		return stage;
	}

	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage9() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Black Gold Estuary";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map9";
		stage.m_mapInfo.m_id = "map9";

		stage.m_includeLayers.insertLast("layer1.invasion");

		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 200;
			stage.m_factions.insertLast(f);
		}

		// metadata
		stage.m_primaryObjective = "capture";
		stage.m_radioObjectivePresent = true;

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"sev90.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		}         

		setDefaultAttackBreakTimes(stage);
		return stage;
	}

	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage10() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Railroad Gap";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map10";
		stage.m_mapInfo.m_id = "map10";
		
		stage.m_includeLayers.insertLast("layer1.invasion");

		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}

		// metadata
		stage.m_primaryObjective = "capture";
		stage.m_radioObjectivePresent = false;

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}

		setDefaultAttackBreakTimes(stage);
		return stage;
	}

	// ------------------------------------------------------------------------------------------------

	protected Stage@ setupStage11() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Iron Enclave";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map13";
		stage.m_mapInfo.m_id = "map13";

		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 150;
			stage.m_factions.insertLast(f);
		}


		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}

		// metadata
		stage.m_primaryObjective = "capture";

		setDefaultAttackBreakTimes(stage);
		return stage;
	}
  
	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage12() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Misty Heights";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map14";
		stage.m_mapInfo.m_id = "map14";
		
		stage.m_includeLayers.insertLast("layer1.invasion");		

    stage.m_fogOffset = 20.0;    
    stage.m_fogRange = 50.0; 

		stage.addTracker(PeacefulLastBase(m_metagame, 0));    
		stage.addTracker(CommsCapacityHandler(m_metagame));
		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}

		// metadata
		stage.m_primaryObjective = "capture";
		stage.m_radioObjectivePresent = false;

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"radio_jammer.vehicle", "radio_jammer2.vehicle", "radar_tower.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		}


		setDefaultAttackBreakTimes(stage);
		return stage;
	}  
  
	// ------------------------------------------------------------------------------------------------

	protected Stage@ setupStage13() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Green Coast";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map16";
		stage.m_mapInfo.m_id = "map16";
		
		stage.m_includeLayers.insertLast("layer1.invasion");        

        stage.addTracker(AttackDefenseHandlerMap16(m_metagame, 0));   // we use this instead of peacefullastbase for map16
		stage.addTracker(CommsCapacityHandler(m_metagame));
		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"vulcan_tank.vehicle", "radar_tank2.vehicle", "radio_jammer2.vehicle", "apc.vehicle", "apc_1.vehicle", "apc_2.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		} 

		// metadata
		stage.m_primaryObjective = "capture";

		setDefaultAttackBreakTimes(stage);
		return stage;
	} 

	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage14() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Rattlesnake Crescent (alt)";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map6";
		stage.m_mapInfo.m_id = "map6_2";

		// we want to exclude some layers here, as the default ones are already used for the other map6
    int index = stage.m_includeLayers.find("layer1.default");
    if (index >= 0) {
    stage.m_includeLayers.removeAt(index);
    }
    index = stage.m_includeLayers.find("bases.default");
    if (index >= 0) {
    stage.m_includeLayers.removeAt(index);
    }

		stage.m_includeLayers.insertLast("layer1.invasion");
		stage.m_includeLayers.insertLast("layer1_2.default"); 
		stage.m_includeLayers.insertLast("bases_2.default"); 

		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));
		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}
		// metadata
		stage.m_primaryObjective = "capture";
		stage.m_radioObjectivePresent = false;

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"radar_tank2.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		} 

		setDefaultAttackBreakTimes(stage);
		return stage;
	} 
    
	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage15() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Moorland Apocalypse";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map1_2";
		stage.m_mapInfo.m_id = "map1_2";
        
		stage.m_includeLayers.insertLast("layer1.invasion");        

    stage.m_fogOffset = 15.0;    
    stage.m_fogRange = 70.0;          

		// we want to exclude some layers here
    int index = stage.m_includeLayers.find("layer1.default");
    if (index >= 0) {
    stage.m_includeLayers.removeAt(index);
    }
    index = stage.m_includeLayers.find("bases.default");
    if (index >= 0) {
    stage.m_includeLayers.removeAt(index);
    }


		stage.m_includeLayers.insertLast("layer1_2.default"); 
		stage.m_includeLayers.insertLast("bases_2.default"); 


        stage.addTracker(AttackDefenseHandlerMap1_2(m_metagame, 0));   // we use this instead of peacefullastbase for map1_2
		stage.addTracker(CommsCapacityHandler(m_metagame));
		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}

		// metadata
		stage.m_primaryObjective = "capture";
		stage.m_radioObjectivePresent = false;

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"vulcan_tank.vehicle", "radar_tank2.vehicle", "radio_jammer2.vehicle", "apc.vehicle", "apc_1.vehicle", "apc_2.vehicle", "guntruck.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		} 
        
		setDefaultAttackBreakTimes(stage);
		return stage;
	}     

	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage16() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Tropical Blizzard";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map8_2";
		stage.m_mapInfo.m_id = "map8_2";

    stage.m_fogOffset = 15.0;    
    stage.m_fogRange = 42.0;


		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));                
		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}

		// metadata
		stage.m_primaryObjective = "capture";
		stage.m_radioObjectivePresent = false;

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"radar_tank2.vehicle", "wiesel_tow.vehicle", "cargo_helicopter_broken.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		} 

		setDefaultAttackBreakTimes(stage);
		return stage;
	} 
	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage17() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Gotcha Island";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map17";
		stage.m_mapInfo.m_id = "map17";

		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));
		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"m113_tank_acav.vehicle", "radio_jammer.vehicle", "radar_tower.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		}

		// metadata
		stage.m_primaryObjective = "capture";

		setDefaultAttackBreakTimes(stage);
		// setReduceDefenseForFinalAttack(stage, 0.1); // use this for final attack boost if needed for friendlies
		return stage;
	}
	
	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage18() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Dry Enclave";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map13_2";
		stage.m_mapInfo.m_id = "map13_2";

		stage.m_includeLayers.insertLast("layer1.invasion");        

		stage.addTracker(Overtime(m_metagame, 0));
                                        
   	 	stage.m_soldierCapacityModel = "constant";       	

         
		stage.m_defenseWinTime = 800; 
		stage.m_defenseWinTimeMode = "custom";
		stage.addTracker(PausingKothTimer(m_metagame, stage.m_defenseWinTime));
		
		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"technical.vehicle", "radio_jammer2.vehicle", "radar_tank2.vehicle", "legion.vehicle", "noxe.vehicle", "m528.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		} 
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"technical.vehicle", "radio_jammer2.vehicle", "radar_tank2.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		}        
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 2);
			addFactionResourceElements(command, "vehicle", array<string> = {"technical.vehicle", "radio_jammer2.vehicle", "radar_tank2.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		}  
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 3);
			addFactionResourceElements(command, "vehicle", array<string> = {"technical.vehicle", "radio_jammer2.vehicle", "radar_tank2.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}  		


		// metadata
		stage.m_primaryObjective = "koth";
		stage.m_kothTargetBase = "Dry Enclave";

		return stage;
	} 	

	// ------------------------------------------------------------------------------------------------

	protected Stage@ setupStage19() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Warsalt Legacy";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map18";
		stage.m_mapInfo.m_id = "map18";
		
		stage.m_includeLayers.insertLast("layer1.invasion");		

		stage.addTracker(PeacefulLastBase(m_metagame, 0));    
		stage.addTracker(CommsCapacityHandler(m_metagame));
		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}

		// metadata
		stage.m_primaryObjective = "capture";
		stage.m_radioObjectivePresent = false;

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"radio_jammer.vehicle", "radio_jammer2.vehicle", "radar_tower.vehicle", "m528.vehicle", "apc.vehicle", "apc_1.vehicles", "apc_2.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		}


		setDefaultAttackBreakTimes(stage);
		return stage;
	}  

	// ------------------------------------------------------------------------------------------------

	protected Stage@ setupStage20() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Swan River";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map19";
		stage.m_mapInfo.m_id = "map19";
		
		stage.m_includeLayers.insertLast("layer1.invasion");		

    stage.m_fogOffset = 24.0;    
    stage.m_fogRange = 50.0; 


		stage.addTracker(PeacefulLastBase(m_metagame, 0));    
		stage.addTracker(CommsCapacityHandler(m_metagame));
		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}

		// metadata
		stage.m_primaryObjective = "capture";
		stage.m_radioObjectivePresent = false;

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"radio_jammer.vehicle", "radio_jammer2.vehicle", "radar_tower.vehicle", "legion.vehicle", "apc.vehicle", "apc_1.vehicles", "apc_2.vehicle", "flamer_tank.vehicle", "missile_launcher.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		}


		setDefaultAttackBreakTimes(stage);
		return stage;
	} 

	// ------------------------------------------------------------------------------------------------

	protected Stage@ setupStage21() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Elk Island";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map20";
		stage.m_mapInfo.m_id = "map20";
		
		stage.m_includeLayers.insertLast("layer1.invasion");		


		stage.addTracker(PeacefulLastBase(m_metagame, 0));    
		stage.addTracker(CommsCapacityHandler(m_metagame));
		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}

		// metadata
		stage.m_primaryObjective = "capture";
		stage.m_radioObjectivePresent = false;

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"radio_jammer.vehicle", "radio_jammer2.vehicle", "radar_tower.vehicle", "legion.vehicle", "lai-109.vehicle", "wiesel_tow.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		}


		setDefaultAttackBreakTimes(stage);
		return stage;
	} 

	// ------------------------------------------------------------------------------------------------
	// ------------------------------------------------------------------------------------------------
	// FINAL STAGES
	// ------------------------------------------------------------------------------------------------
	// ------------------------------------------------------------------------------------------------
	// --------------------------------------------
	protected Stage@ setupFinalStage1() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Final mission I"; // warning, default.character has reference to this name, careful if it needs to be changed
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map11";
		stage.m_mapInfo.m_id = "map11";
        
		stage.m_includeLayers.insertLast("layer1.invasion");        

		stage.m_finalBattle = true;
		stage.m_hidden = true;

		stage.addTracker(DestroyVehicleToCaptureBase(m_metagame, "radio_jammer.vehicle", 2));
		stage.addTracker(DestroyVehicleToCaptureBase(m_metagame, "radar_tower.vehicle", 2));     
		
		// make neutral instantly not alive to avoid any possibility to gain capacity, like via not losing all bases first 
		// and then gaining bases which have vehicles that give capacity offset..
		{
			XmlElement command("command");
			command.setStringAttribute("class", "set_match_status");
			command.setIntAttribute("faction_id", 2);
			command.setBoolAttribute("lose", true);
			// can't use m_extraCommands, they happen before match start, using trackers instead then
			stage.addTracker(RunAtStart(m_metagame, command));     
		}

		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"mobile_armory.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}
		
		// no calls for friendly faction in the last map
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			command.setBoolAttribute("clear_calls", true);
			stage.m_extraCommands.insertLast(command);
		}

		// metadata
		stage.m_primaryObjective = "final1";

		return stage;
	}

	// --------------------------------------------
	protected Stage@ setupFinalStage2() {
		PhasedStage@ stage = createPhasedStage();
		stage.setPhaseController(PhaseControllerMap12(m_metagame));
		stage.m_mapInfo.m_name = "Final mission II"; // warning, default.character has reference to this name, careful if it needs to be changed
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map12";
		stage.m_mapInfo.m_id = "map12";
		
	stage.m_includeLayers.insertLast("layer1.invasion");	

    stage.m_fogOffset = 20.0;    
    stage.m_fogRange = 50.0; 

		stage.m_finalBattle = true;
		stage.m_hidden = true;

		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}
		// metadata
		stage.m_primaryObjective = "final2";

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"radio_jammer.vehicle", "radar_tower.vehicle"}, false);
			stage.m_extraCommands.insertLast(command);
		}

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);
			stage.m_extraCommands.insertLast(command);
		}
		
		stage.m_allowChangeCapacityOnTheFly = false;

		return stage;
	}


	// --------------------------------------------
	protected void setupWorld() {
		// World disabled in Invasion for now, map10 elements are missing
		//$this->world = new World($this->metagame);
	}

	// --------------------------------------------
	array<XmlElement@>@ getFactionResourceConfigChangeCommands(float completionPercentage, Stage@ stage) {
		array<XmlElement@>@ commands = getFactionResourceChangeCommands(stage.m_factions.size());

		_log("completion percentage: " + completionPercentage);

		const UserSettings@ settings = m_metagame.getUserSettings();
		_log(" variance enabled: " + settings.m_completionVarianceEnabled);
		if (settings.m_completionVarianceEnabled) {
			array<XmlElement@>@ varianceCommands = getCompletionVarianceCommands(stage, completionPercentage);
			// append with command already gathered
			merge(commands, varianceCommands);
		}

		merge(commands, stage.m_extraCommands);

		return commands;
	}

	// --------------------------------------------
	protected array<XmlElement@>@ getFactionResourceChangeCommands(int factionCount) const {
		array<XmlElement@> commands;

		// invasion faction resources are nowadays based on resources declared for factions in the faction files 
		// + some minor changes for common and friendly
		for (int i = 0; i < factionCount; ++i) {
			commands.insertLast(getFactionResourceChangeCommand(i, getCommonFactionResourceChanges()));
		}

		// apply initial friendly faction resource modifications
		commands.insertLast(getFactionResourceChangeCommand(0, getFriendlyFactionResourceChanges()));

		return commands;
	}

	// --------------------------------------------
	protected array<ResourceChange@>@ getCommonFactionResourceChanges() const {
		array<ResourceChange@> list;
	
		list.push_back(ResourceChange(Resource("armored_truck.vehicle", "vehicle"), false));
		list.push_back(ResourceChange(Resource("mobile_armory.vehicle", "vehicle"), false));
		list.push_back(ResourceChange(Resource("a10_gun_run.call", "call"), true));
		list.push_back(ResourceChange(Resource("gunship_run.call", "call"), true));        

		// disable certain weapons here; mainly because Dominance uses the same .resources files but we have further changes for Invasion here
		list.push_back(ResourceChange(Resource("l85a2.weapon", "weapon"), false));
		list.push_back(ResourceChange(Resource("famasg1.weapon", "weapon"), false));
		list.push_back(ResourceChange(Resource("sg552.weapon", "weapon"), false));
		list.push_back(ResourceChange(Resource("minig_resource.weapon", "weapon"), false));
		list.push_back(ResourceChange(Resource("tow_resource.weapon", "weapon"), false));
		list.push_back(ResourceChange(Resource("gl_resource.weapon", "weapon"), false));
		list.push_back(ResourceChange(Resource("hornet_resource.weapon", "weapon"), false));
		
		return list;
	}

	// --------------------------------------------
	protected array<ResourceChange@> getFriendlyFactionResourceChanges() const {
		array<ResourceChange@> list;

		// enable mobile spawn and armory trucks for player faction
		list.push_back(ResourceChange(Resource("armored_truck.vehicle", "vehicle"), true));
		list.push_back(ResourceChange(Resource("mobile_armory.vehicle", "vehicle"), true));
//		list.push_back(ResourceChange(Resource("a10_gun_run.call", "call"), true));
//		list.push_back(ResourceChange(Resource("gunship_run.call", "call"), true));        

		// no m79 for friendlies
		list.push_back(ResourceChange(Resource("m79.weapon", "weapon"), false));

		// no suitcases/laptops carried by friendlies
		list.push_back(ResourceChange(Resource("suitcase.carry_item", "carry_item"), false));
		list.push_back(ResourceChange(Resource("laptop.carry_item", "carry_item"), false));

		// no cargo, prisons or aa
		list.push_back(ResourceChange(Resource("cargo_truck.vehicle", "vehicle"), false));
		list.push_back(ResourceChange(Resource("prison_door.vehicle", "vehicle"), false));
		list.push_back(ResourceChange(Resource("prison_bus.vehicle", "vehicle"), false));
		list.push_back(ResourceChange(Resource("prison_hatch.vehicle", "vehicle"), false));    
		list.push_back(ResourceChange(Resource("aa_emplacement.vehicle", "vehicle"), false));

		return list;
	}

	// --------------------------------------------
	protected array<XmlElement@>@ getCompletionVarianceCommands(Stage@ stage, float completionPercentage) {
		// we want to have a sense of progression 
		// with the starting map vs other maps played before extra final maps

		array<XmlElement@> commands;

		if (stage.isFinalBattle()) {
			// don't use for final battles
			return commands;
		}

		if (completionPercentage < 0.08) {
			_log("below 10%");
			for (uint i = 0; i < stage.m_factions.size(); ++i) {
				// disable comms truck, cargo and radio tower on all factions, same for prisons
				array<string> keys = {
					"radar_truck.vehicle", 
					"cargo_truck.vehicle", 
					"radar_tower.vehicle", 
					"prison_bus.vehicle", 
					"prison_door.vehicle", 
					"aa_emplacement.vehicle",
                    "m113_tank_mortar.vehicle" };

				if (i == 0) {
					// let friendlies have the tank, need it to make a successful tank call
				} else {
					// disable tanks for enemy factions
					keys.insertLast("tank.vehicle");
					keys.insertLast("tank_1.vehicle");
					keys.insertLast("tank_2.vehicle");
				}

				if (keys.size() > 0) {
					XmlElement command("command"); 
					command.setStringAttribute("class", "faction_resources"); 
					command.setIntAttribute("faction_id", i);
					addFactionResourceElements(command, "vehicle", keys, false);

					commands.insertLast(command);
				}
			}
			// a bit odd that we change stage members here in a getter function, but just do it for now, it's just metadata
			stage.m_radioObjectivePresent = false;

		} else if (completionPercentage < 0.20) {
			_log("below 25%, above 10%");
			for (uint i = 0; i < stage.m_factions.size(); ++i) {
				array<string> keys;

				if (i == 0) {
					// disable comms truck and radio tower on friendly faction only
					keys.insertLast("radar_truck.vehicle");
					keys.insertLast("radar_tower.vehicle");

					// cargo & prisons are disabled anyway for friendly faction
				} else {
				}

				if (keys.size() > 0) {
					XmlElement command("command"); 
					command.setStringAttribute("class", "faction_resources"); 
					command.setIntAttribute("faction_id", i);
					addFactionResourceElements(command, "vehicle", keys, false);

					commands.insertLast(command);
				}
			}
		}

		return commands;
	}

	protected Stage@ setupStageCasake_Bay() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Casake Bay";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/Casake_Bay";
		stage.m_mapInfo.m_id = "Casake_Bay";

		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));
		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}

		// metadata
		stage.m_primaryObjective = "capture";

		setDefaultAttackBreakTimes(stage);
		return stage;
	}
	protected Stage@ setupStageBloodandFlowers_01() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "BloodandFlowers_01";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/BloodandFlowers_01";
		stage.m_mapInfo.m_id = "BloodandFlowers_01";

		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));
		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}

		// metadata
		stage.m_primaryObjective = "capture";

		setDefaultAttackBreakTimes(stage);
		return stage;
	}
	protected Stage@ setupRoberto() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "roberto";
        stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/roberto";
		stage.m_mapInfo.m_id = "roberto";

	    stage.addTracker(Spawner(m_metagame, 1, Vector3(485,5,705), 10, "default_ai"));        // outpost filler (1.70)

		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));
		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}

		// metadata
		stage.m_primaryObjective = "capture";
		stage.m_radioObjectivePresent = false;

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}

		setDefaultAttackBreakTimes(stage);
		return stage;
	} 
	
	protected Stage@ setupClairemont() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "clairemont";
        stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/clairemont";
		stage.m_mapInfo.m_id = "clairemont";
    
		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));

		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}

		// metadata
		stage.m_primaryObjective = "capture";
		stage.m_radioObjectivePresent = false;

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}

		setDefaultAttackBreakTimes(stage);
		return stage;
	} 
	protected Stage@ setupViper() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "viper";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/viper";
		stage.m_mapInfo.m_id = "viper";

		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));
		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}

		// metadata
		stage.m_primaryObjective = "capture";

		setDefaultAttackBreakTimes(stage);
		return stage;
	}
	protected Stage@ setupDef_lab_koth() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "def_lab_koth";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/def_lab_koth";
		stage.m_mapInfo.m_id = "def_lab_koth";

		stage.m_soldierCapacityModel = "constant";

		stage.m_defenseWinTime = 780; 
		stage.m_defenseWinTimeMode = "custom";
		stage.addTracker(PausingKothTimer(m_metagame, stage.m_defenseWinTime));
		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}


		// metadata
		stage.m_primaryObjective = "koth";
		stage.m_kothTargetBase = "ALL entrance";

		setDefaultAttackBreakTimes(stage);
		return stage;
	}
	protected Stage@ setupEastport() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "eastport";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/eastport";
		stage.m_mapInfo.m_id = "eastport";

		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));
		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}

		// metadata
		stage.m_primaryObjective = "capture";

		setDefaultAttackBreakTimes(stage);
		return stage;
	}
	protected Stage@ setupWave_Town() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Wave_Town";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/Wave_Town";
		stage.m_mapInfo.m_id = "Wave_Town";

		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));

		{
        XmlElement command("command");
        command.setStringAttribute("class", "change_game_settings");
        for (uint i = 0; i < m_metagame.getFactionCount(); ++i) {
            XmlElement faction("faction");
            if (int(i) == 3) {
                faction.setFloatAttribute("capacity_multiplier", 0.00001);
                faction.setBoolAttribute("lose_without_bases", false);
            }
            command.appendChild(faction);
            }
        m_metagame.getComms().send(command);
        stage.addTracker(RunAtStart(m_metagame, command));
        }
		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}

		// metadata
		stage.m_primaryObjective = "capture";

		setDefaultAttackBreakTimes(stage);
		return stage;
	}
	protected Stage@ setupRacing() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "race1";
		stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/race1";
		stage.m_mapInfo.m_id = "race1";

		stage.addTracker(PeacefulLastBase(m_metagame, 1));
		stage.addTracker(CommsCapacityHandler(m_metagame));

		{
        XmlElement command("command");
        command.setStringAttribute("class", "change_game_settings");
        for (uint i = 0; i < m_metagame.getFactionCount(); ++i) {
            XmlElement faction("faction");
            if (int(i) == 3) {
                faction.setFloatAttribute("capacity_multiplier", 0.00001);
                faction.setBoolAttribute("lose_without_bases", false);
            }
            command.appendChild(faction);
            }
        m_metagame.getComms().send(command);
        stage.addTracker(RunAtStart(m_metagame, command));
        }
		stage.m_maxSoldiers = 1;                                             

		stage.m_soldierCapacityVariance = 0;
		stage.m_playerAiCompensation = 0;                                       
        stage.m_playerAiReduction = 0;                                          

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));     
			f.m_overCapacity = 0;			f.m_capacityOffset = 1;	
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));             
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1;                                                 
			f.m_capacityOffset = 100;
			stage.m_factions.insertLast(f);
		}

		// metadata
		stage.m_primaryObjective = "capture";

		setDefaultAttackBreakTimes(stage);
		return stage;
	}
}
