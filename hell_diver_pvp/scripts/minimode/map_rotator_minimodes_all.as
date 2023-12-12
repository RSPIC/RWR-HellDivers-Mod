#include "map_rotator_minimodes.as"

#include "safe_zone.as"

#include "stage_minimodes.as"

#include "warmup_substage.as"
#include "team_deathmatch_substage.as"
#include "koth_substage.as"
#include "team_teddy_hunt_substage.as"

// --------------------------------------------
class MapRotatorMiniModesAll : MapRotatorMiniModes {
	
	MapRotatorMiniModesAll(GameModeMiniModes@ metagame) {
		_log("setUp MapRotatorMiniModesAll");
		@m_metagame = @metagame;
	}
	// ------------------------------------------------------------------------------------------------
	protected void setupStages() {
		setupPlaylist1();
		setupPlaylist2();
		setupPlaylist3();
		setupPlaylist4();
		setupPlaylist5();
		setupPlaylist6();
		setupPlaylist7();
		setupPlaylist8();
		setupPlaylist9();         
	}

	// ------------------------------------------------------------------------------------------------
	protected void setupPlaylist1() {
		int maxSoldiers = 15;

		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Rattlesnake Crescent";
			stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map6";
			stage.m_mapIndex = 6;

			stage.m_includeLayers.insertLast("layer1.playlist1");
			stage.m_includeLayers.insertLast("layer1.tdm2");
			stage.m_includeLayers.insertLast("layer1.koth1");
			stage.m_includeLayers.insertLast("layer1.th1");
			stage.m_includeLayers.insertLast("layer1.tdm3"); 
			stage.m_includeLayers.insertLast("layer1.tdm1");
            
			stage.m_includeLayers.insertLast("bases.playlist1");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			// neutral/bots too
			stage.m_factionConfigs.insertLast(m_factionConfigs[2]);

			// examples of different kind of matches=sub gamemodes:
			// - team deathmatch
			// - koth
			// - deliver vehicle/ambush
			// - deliver item/ambush
			// - deliver character/ambush
			// - assault/defend
			// - destroy target/defend

			// each match class can support variety of settings,
			// e.g. 
			// - which bases the factions own as starting point,
			// - which resources are available
			// - timers
			// - targets
			// - ...

			// first is the warmup substage 
			{
				// warmup only ends when there's enough players in the game or an admin decides,
				// by default 2 is enough
				SubStage@ substage = WarmupSubStage(stage, m_metagame.getUserSettings().m_minimumPlayersToStart);
				substage.m_mapViewOverlayFilename = "none.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("TV station");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Bazaar");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				// add any initial commands here, can be used as modifiers e.g. for substage specific faction resources
				//substage.m_initCommands.insertLast("");
				@substage.m_match = @match;
			}

			// actual substages start here
			{
				// the map has declared some additional stuff for the substage, matched with a tag
				float maxTime = m_metagame.getUserSettings().m_tdmMaxTime;
				int maxScore = m_metagame.getUserSettings().m_tdmMaxScore;
				SubStage@ substage = TeamDeathmatchSubStage(stage, maxScore, maxTime);


				substage.m_mapViewOverlayFilename = "map6_overlay_tdm2.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("TV station");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Bazaar");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "tdm2"));
			}

			{
				float maxTime = m_metagame.getUserSettings().m_kothMaxTime;
				float defenseTime = m_metagame.getUserSettings().m_kothDefenseTime;
				SubStage@ substage = KothSubStage(stage, "Mosque", defenseTime, maxTime);
				substage.m_mapViewOverlayFilename = "map6_overlay_koth1.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				// KothSubStage will fill defense win timer
				match.m_baseCaptureSystem = "any";

				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Fennec road");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Powerhouse");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "koth1"));
			}
			
			{
				float maxTime = m_metagame.getUserSettings().m_thMaxTime;
				int maxScore = m_metagame.getUserSettings().m_thMaxScore;
				SubStage@ substage = TeamTeddyHuntSubStage(stage, maxScore, maxTime, "th1");
				substage.m_mapViewOverlayFilename = "map6_overlay_th1.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers; 
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Forward HQ alpha");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Forward HQ bravo");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.m_capacityMultiplier = 0.0001;
					// faction.m_makeNeutral(true);
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addInitCommand("<command class='commander_ai' active='0' />");

				substage.addTracker(SafeZone(m_metagame, "th1"));
			}

			{
				// the map has declared some additional stuff for the substage, matched with a tag
				float maxTime = m_metagame.getUserSettings().m_tdmMaxTime;
				int maxScore = m_metagame.getUserSettings().m_tdmMaxScore;
				SubStage@ substage = TeamDeathmatchSubStage(stage, maxScore, maxTime);
				substage.m_mapViewOverlayFilename = "map6_overlay_tdm3.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Powerhouse");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Fennec road");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "tdm3"));
			}

      {
				// the map has declared some additional stuff for the substage, matched with a tag
				float maxTime = m_metagame.getUserSettings().m_tdmMaxTime;
				int maxScore = m_metagame.getUserSettings().m_tdmMaxScore;
				SubStage@ substage = TeamDeathmatchSubStage(stage, maxScore, maxTime);
				substage.m_mapViewOverlayFilename = "map6_overlay_tdm1.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("West end settlement");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Junkyard");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "tdm1"));
			}

			m_stages.insertLast(stage);
		}
	}

	// ------------------------------------------------------------------------------------------------
	protected void setupPlaylist2() {
		int maxSoldiers = 15;

		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Moorland Trenches";
			stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map1";
			stage.m_mapIndex = 1;

			stage.m_includeLayers.insertLast("layer1.playlist1");
			stage.m_includeLayers.insertLast("layer1.tdm7");
			stage.m_includeLayers.insertLast("layer1.koth3");
			stage.m_includeLayers.insertLast("layer1.th4");
			stage.m_includeLayers.insertLast("layer1.tdm2");
			stage.m_includeLayers.insertLast("layer1.th1");
            
			stage.m_includeLayers.insertLast("bases.playlist1");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			// neutral/bots too
			stage.m_factionConfigs.insertLast(m_factionConfigs[2]);

			// examples of different kind of matches=sub gamemodes:
			// - team deathmatch
			// - koth
			// - deliver vehicle/ambush
			// - deliver item/ambush
			// - deliver character/ambush
			// - assault/defend
			// - destroy target/defend

			// each match class can support variety of settings,
			// e.g. 
			// - which bases the factions own as starting point,
			// - which resources are available
			// - timers
			// - targets
			// - ...

			// first is the warmup substage 
			{
				// warmup only ends when there's enough players in the game or an admin decides,
				// by default 2 is enough
				SubStage@ substage = WarmupSubStage(stage, m_metagame.getUserSettings().m_minimumPlayersToStart);
				substage.m_mapViewOverlayFilename = "none.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("East town");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Suburbs");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				// add any initial commands here, can be used as modifiers e.g. for substage specific faction resources
				//substage.m_initCommands.insertLast("");
				@substage.m_match = @match;
			}

			// actual substages start here
			{
				// the map has declared some additional stuff for the substage, matched with a tag
				float maxTime = m_metagame.getUserSettings().m_tdmMaxTime;
				int maxScore = m_metagame.getUserSettings().m_tdmMaxScore;
				SubStage@ substage = TeamDeathmatchSubStage(stage, maxScore, maxTime);

				substage.m_mapViewOverlayFilename = "map1_overlay_tdm7.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Ruins");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Center trench");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "tdm7"));
			}

			{
				float maxTime = m_metagame.getUserSettings().m_kothMaxTime;
				float defenseTime = m_metagame.getUserSettings().m_kothDefenseTime;
				SubStage@ substage = KothSubStage(stage, "East farm", defenseTime, maxTime);
				substage.m_mapViewOverlayFilename = "map1_overlay_koth3.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				// KothSubStage will fill defense win timer
				match.m_baseCaptureSystem = "any";

				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Warehouse");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Academy");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "koth3"));
			}

			{
				float maxTime = m_metagame.getUserSettings().m_thMaxTime;
				int maxScore = m_metagame.getUserSettings().m_thMaxScore;
				SubStage@ substage = TeamTeddyHuntSubStage(stage, maxScore, maxTime, "th4");
				substage.m_mapViewOverlayFilename = "map1_overlay_th4.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers; 
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("East Town");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Suburbs");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.m_capacityMultiplier = 0.0001;
					//faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addInitCommand("<command class='commander_ai' active='0' />");

				substage.addTracker(SafeZone(m_metagame, "th4"));
			}

            {
				// the map has declared some additional stuff for the substage, matched with a tag
				float maxTime = m_metagame.getUserSettings().m_tdmMaxTime;
				int maxScore = m_metagame.getUserSettings().m_tdmMaxScore;
				SubStage@ substage = TeamDeathmatchSubStage(stage, maxScore, maxTime);

				substage.m_mapViewOverlayFilename = "map1_overlay_tdm2.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Mansion");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("West Farm");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "tdm2"));
			}

			{
				float maxTime = m_metagame.getUserSettings().m_thMaxTime;
				int maxScore = m_metagame.getUserSettings().m_thMaxScore;
				SubStage@ substage = TeamTeddyHuntSubStage(stage, maxScore, maxTime, "th1");
				substage.m_mapViewOverlayFilename = "map1_overlay_th1.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers; 
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Hotel");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Airport");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.m_capacityMultiplier = 0.0001;
					//faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addInitCommand("<command class='commander_ai' active='0' />");

				substage.addTracker(SafeZone(m_metagame, "th1"));
			}


			m_stages.insertLast(stage);
		}
	}

	// ------------------------------------------------------------------------------------------------
	protected void setupPlaylist3() {
		int maxSoldiers = 15;

		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Islet of Eflen";
			stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map15";
			stage.m_mapIndex = 13;
     
			stage.m_includeLayers.insertLast("bases.default");
			stage.m_includeLayers.insertLast("layer1.th1");
			stage.m_includeLayers.insertLast("layer1.minimodes");            

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			// neutral/bots too
			stage.m_factionConfigs.insertLast(m_factionConfigs[2]);

			// examples of different kind of matches=sub gamemodes:
			// - team deathmatch
			// - koth
			// - deliver vehicle/ambush
			// - deliver item/ambush
			// - deliver character/ambush
			// - assault/defend
			// - destroy target/defend

			// each match class can support variety of settings,
			// e.g. 
			// - which bases the factions own as starting point,
			// - which resources are available
			// - timers
			// - targets
			// - ...

			// first is the warmup substage 
			{
				// warmup only ends when there's enough players in the game or an admin decides,
				// by default 2 is enough
				SubStage@ substage = WarmupSubStage(stage, m_metagame.getUserSettings().m_minimumPlayersToStart);
				substage.m_mapViewOverlayFilename = "none.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Heel Quarter");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("East Coast");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				// add any initial commands here, can be used as modifiers e.g. for substage specific faction resources
				//substage.m_initCommands.insertLast("");
				@substage.m_match = @match;
			}

			// actual substages start here
			{
				// the map has declared some additional stuff for the substage, matched with a tag
				float maxTime = m_metagame.getUserSettings().m_tdmMaxTime;
				int maxScore = m_metagame.getUserSettings().m_tdmMaxScore;
				SubStage@ substage = TeamDeathmatchSubStage(stage, maxScore, maxTime);


				substage.m_mapViewOverlayFilename = "map15_overlay_tdm1.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Heel Quarter");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("East Coast");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "tdm2"));
			}

			{
				float maxTime = m_metagame.getUserSettings().m_kothMaxTime;
				float defenseTime = m_metagame.getUserSettings().m_kothDefenseTime;
				SubStage@ substage = KothSubStage(stage, "Museum", defenseTime, maxTime);
				substage.m_mapViewOverlayFilename = "map15_overlay_koth1.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				// KothSubStage will fill defense win timer
				match.m_baseCaptureSystem = "any";

				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("East Coast");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Heel Quarter");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "koth1"));
			}

			{
				float maxTime = m_metagame.getUserSettings().m_thMaxTime;
				int maxScore = m_metagame.getUserSettings().m_thMaxScore;
				SubStage@ substage = TeamTeddyHuntSubStage(stage, maxScore, maxTime, "th1");
				substage.m_mapViewOverlayFilename = "map15_overlay_th1.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers; 
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Heel Quarter");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("East Coast");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.m_capacityMultiplier = 0.0001;
					//faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addInitCommand("<command class='commander_ai' active='0' />");

				substage.addTracker(SafeZone(m_metagame, "th1"));
			}
      
			{
				// the map has declared some additional stuff for the substage, matched with a tag
				float maxTime = m_metagame.getUserSettings().m_tdmMaxTime;
				int maxScore = m_metagame.getUserSettings().m_tdmMaxScore;
				SubStage@ substage = TeamDeathmatchSubStage(stage, maxScore, maxTime);


				substage.m_mapViewOverlayFilename = "map15_overlay_tdm1.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("East Coast");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Heel Quarter");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "tdm2"));
			}
      

			m_stages.insertLast(stage);
		}
	}

	// ------------------------------------------------------------------------------------------------
	protected void setupPlaylist4() {
		int maxSoldiers = 15;

		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Moorland Trenches";
			stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map1";
			stage.m_mapIndex = 1;

			stage.m_includeLayers.insertLast("layer1.playlist2");
			stage.m_includeLayers.insertLast("layer1.tdm3");
			stage.m_includeLayers.insertLast("layer1.th3");
			stage.m_includeLayers.insertLast("layer1.th5");
			stage.m_includeLayers.insertLast("layer1.tdm1");
			stage.m_includeLayers.insertLast("layer1.koth1");
			stage.m_includeLayers.insertLast("layer1.th6");
			stage.m_includeLayers.insertLast("bases.playlist2");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			// neutral/bots too
			stage.m_factionConfigs.insertLast(m_factionConfigs[2]);

			// examples of different kind of matches=sub gamemodes:
			// - team deathmatch
			// - koth
			// - deliver vehicle/ambush
			// - deliver item/ambush
			// - deliver character/ambush
			// - assault/defend
			// - destroy target/defend

			// each match class can support variety of settings,
			// e.g. 
			// - which bases the factions own as starting point,
			// - which resources are available
			// - timers
			// - targets
			// - ...

			// first is the warmup substage 
			{
				// warmup only ends when there's enough players in the game or an admin decides,
				// by default 2 is enough
				SubStage@ substage = WarmupSubStage(stage, m_metagame.getUserSettings().m_minimumPlayersToStart);
				substage.m_mapViewOverlayFilename = "none.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("East town");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("West town");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				// add any initial commands here, can be used as modifiers e.g. for substage specific faction resources
				//substage.m_initCommands.insertLast("");
				@substage.m_match = @match;
			}

			// actual substages start here
			{
				// the map has declared some additional stuff for the substage, matched with a tag
				float maxTime = m_metagame.getUserSettings().m_tdmMaxTime;
				int maxScore = m_metagame.getUserSettings().m_tdmMaxScore;
				SubStage@ substage = TeamDeathmatchSubStage(stage, maxScore, maxTime);

				substage.m_mapViewOverlayFilename = "map1_overlay_tdm3.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("East town");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("West town");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "tdm3"));
			}

			{
				float maxTime = m_metagame.getUserSettings().m_thMaxTime;
				int maxScore = m_metagame.getUserSettings().m_thMaxScore;
				SubStage@ substage = TeamTeddyHuntSubStage(stage, maxScore, maxTime, "th3");
				substage.m_mapViewOverlayFilename = "map1_overlay_th3.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers; 
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Hospital");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("West town");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.m_capacityMultiplier = 0.0001;
					//faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addInitCommand("<command class='commander_ai' active='0' />");

				substage.addTracker(SafeZone(m_metagame, "th3"));
			}

			{
				float maxTime = m_metagame.getUserSettings().m_thMaxTime;
				int maxScore = m_metagame.getUserSettings().m_thMaxScore;
				SubStage@ substage = TeamTeddyHuntSubStage(stage, maxScore, maxTime, "th5");
				substage.m_mapViewOverlayFilename = "map1_overlay_th5.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers; 
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Warehouse");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Academy");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.m_capacityMultiplier = 0.0001;
					//faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addInitCommand("<command class='commander_ai' active='0' />");

				substage.addTracker(SafeZone(m_metagame, "th5"));
			}

			{
				// the map has declared some additional stuff for the substage, matched with a tag
				float maxTime = m_metagame.getUserSettings().m_tdmMaxTime;
				int maxScore = m_metagame.getUserSettings().m_tdmMaxScore;
				SubStage@ substage = TeamDeathmatchSubStage(stage, maxScore, maxTime);

				substage.m_mapViewOverlayFilename = "map1_overlay_tdm1.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Airport");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Hotel");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "tdm1"));
			}

			{
				float maxTime = m_metagame.getUserSettings().m_kothMaxTime;
				float defenseTime = m_metagame.getUserSettings().m_kothDefenseTime;
				SubStage@ substage = KothSubStage(stage, "West farm", defenseTime, maxTime);
				substage.m_mapViewOverlayFilename = "map1_overlay_koth1.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				// KothSubStage will fill defense win timer
				match.m_baseCaptureSystem = "any";

				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Mansion");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("West trench");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "koth1"));
			}

			{
				float maxTime = m_metagame.getUserSettings().m_thMaxTime;
				int maxScore = m_metagame.getUserSettings().m_thMaxScore;
				SubStage@ substage = TeamTeddyHuntSubStage(stage, maxScore, maxTime, "th6");
				substage.m_mapViewOverlayFilename = "map1_overlay_th6.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers; 
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Center trench");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("East trench");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.m_capacityMultiplier = 0.0001;
					//faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addInitCommand("<command class='commander_ai' active='0' />");

				substage.addTracker(SafeZone(m_metagame, "th6"));
			}

			m_stages.insertLast(stage);
		}
	}

	// ------------------------------------------------------------------------------------------------
	protected void setupPlaylist5() {
		int maxSoldiers = 15;

		// ------------------------------------------------------------------------------------------------

		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Rattlesnake Crescent";
			stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map6";
			stage.m_mapIndex = 6;

			stage.m_includeLayers.insertLast("layer1.playlist2");
			stage.m_includeLayers.insertLast("layer1.tdm4");
			stage.m_includeLayers.insertLast("layer1.koth2");
			stage.m_includeLayers.insertLast("layer1.th2");
            
			stage.m_includeLayers.insertLast("bases.playlist2");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			// neutral/bots too
			stage.m_factionConfigs.insertLast(m_factionConfigs[2]);

			// examples of different kind of matches=sub gamemodes:
			// - team deathmatch
			// - koth
			// - deliver vehicle/ambush
			// - deliver item/ambush
			// - deliver character/ambush
			// - assault/defend
			// - destroy target/defend

			// each match class can support variety of settings,
			// e.g. 
			// - which bases the factions own as starting point,
			// - which resources are available
			// - timers
			// - targets
			// - ...

			// first is the warmup substage 
			{
				// warmup only ends when there's enough players in the game or an admin decides,
				// by default 2 is enough
				SubStage@ substage = WarmupSubStage(stage, m_metagame.getUserSettings().m_minimumPlayersToStart);
				substage.m_mapViewOverlayFilename = "none.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Junkyard");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Bazaar");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				// add any initial commands here, can be used as modifiers e.g. for substage specific faction resources
				//substage.m_initCommands.insertLast("");
				@substage.m_match = @match;
			}

			// actual substages start here

			{
				float maxTime = m_metagame.getUserSettings().m_kothMaxTime;
				float defenseTime = m_metagame.getUserSettings().m_kothDefenseTime;
				SubStage@ substage = KothSubStage(stage, "TV station", defenseTime, maxTime);
				substage.m_mapViewOverlayFilename = "map6_overlay_koth2.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				// KothSubStage will fill defense win timer
				match.m_baseCaptureSystem = "any";

				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Junkyard");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Bazaar");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "koth2"));
			}


			{
				// the map has declared some additional stuff for the substage, matched with a tag
				float maxTime = m_metagame.getUserSettings().m_tdmMaxTime;
				int maxScore = m_metagame.getUserSettings().m_tdmMaxScore;
				SubStage@ substage = TeamDeathmatchSubStage(stage, maxScore, maxTime);

				substage.m_mapViewOverlayFilename = "map6_overlay_tdm4.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Outpost");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Forward HQ");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "tdm4"));
			}


			{
				float maxTime = m_metagame.getUserSettings().m_thMaxTime;
				int maxScore = m_metagame.getUserSettings().m_thMaxScore;
				SubStage@ substage = TeamTeddyHuntSubStage(stage, maxScore, maxTime, "th2");
				
				substage.m_mapViewOverlayFilename = "map6_overlay_th2.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers; 
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Bazaar");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Powerhouse");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.m_capacityMultiplier = 0.0001;
					//faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addInitCommand("<command class='commander_ai' active='0' />");

				substage.addTracker(SafeZone(m_metagame, "th2"));
			}

			m_stages.insertLast(stage);
		}
	}

	// ------------------------------------------------------------------------------------------------
	protected void setupPlaylist6() {
		int maxSoldiers = 15;

		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Islet of Eflen";
			stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map15";
			stage.m_mapIndex = 13;
     
			stage.m_includeLayers.insertLast("bases.default");
			stage.m_includeLayers.insertLast("layer1.th1");
			stage.m_includeLayers.insertLast("layer1.minimodes"); 

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			// neutral/bots too
			stage.m_factionConfigs.insertLast(m_factionConfigs[2]);

			// examples of different kind of matches=sub gamemodes:
			// - team deathmatch
			// - koth
			// - deliver vehicle/ambush
			// - deliver item/ambush
			// - deliver character/ambush
			// - assault/defend
			// - destroy target/defend

			// each match class can support variety of settings,
			// e.g. 
			// - which bases the factions own as starting point,
			// - which resources are available
			// - timers
			// - targets
			// - ...

			// first is the warmup substage 
			{
				// warmup only ends when there's enough players in the game or an admin decides,
				// by default 2 is enough
				SubStage@ substage = WarmupSubStage(stage, m_metagame.getUserSettings().m_minimumPlayersToStart);
				substage.m_mapViewOverlayFilename = "none.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Heel Quarter");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("East Coast");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				// add any initial commands here, can be used as modifiers e.g. for substage specific faction resources
				//substage.m_initCommands.insertLast("");
				@substage.m_match = @match;
			}

			// actual substages start here
			{
				// the map has declared some additional stuff for the substage, matched with a tag
				float maxTime = m_metagame.getUserSettings().m_tdmMaxTime;
				int maxScore = m_metagame.getUserSettings().m_tdmMaxScore;
				SubStage@ substage = TeamDeathmatchSubStage(stage, maxScore, maxTime);

				substage.m_mapViewOverlayFilename = "map15_overlay_tdm1.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Heel Quarter");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("East Coast");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "tdm2"));
			}

			{
				float maxTime = m_metagame.getUserSettings().m_kothMaxTime;
				float defenseTime = m_metagame.getUserSettings().m_kothDefenseTime;
				SubStage@ substage = KothSubStage(stage, "Museum", defenseTime, maxTime);
				substage.m_mapViewOverlayFilename = "map15_overlay_koth1.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				// KothSubStage will fill defense win timer
				match.m_baseCaptureSystem = "any";

				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("East Coast");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Heel Quarter");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "koth1"));
			}

			{
				float maxTime = m_metagame.getUserSettings().m_thMaxTime;
				int maxScore = m_metagame.getUserSettings().m_thMaxScore;
				SubStage@ substage = TeamTeddyHuntSubStage(stage, maxScore, maxTime, "th1");
        substage.m_mapViewOverlayFilename = "map15_overlay_th1.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers; 
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Heel Quarter");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("East Coast");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.m_capacityMultiplier = 0.0001;
					//faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addInitCommand("<command class='commander_ai' active='0' />");

				substage.addTracker(SafeZone(m_metagame, "th1"));
			}
      
			{
				// the map has declared some additional stuff for the substage, matched with a tag
				float maxTime = m_metagame.getUserSettings().m_tdmMaxTime;
				int maxScore = m_metagame.getUserSettings().m_tdmMaxScore;
				SubStage@ substage = TeamDeathmatchSubStage(stage, maxScore, maxTime);

				substage.m_mapViewOverlayFilename = "map15_overlay_tdm1.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("East Coast");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Heel Quarter");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "tdm2"));
			}
      
			m_stages.insertLast(stage);
		}
	}

  	// ------------------------------------------------------------------------------------------------
	protected void setupPlaylist7() {
		int maxSoldiers = 15;

		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Rattlesnake Crescent";
			stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map6";
			stage.m_mapIndex = 6;

			stage.m_includeLayers.insertLast("layer1.playlist1");
			stage.m_includeLayers.insertLast("layer1.tdm2");
			stage.m_includeLayers.insertLast("layer1.koth1");
			stage.m_includeLayers.insertLast("layer1.th1");
			stage.m_includeLayers.insertLast("layer1.tdm3");
			stage.m_includeLayers.insertLast("layer1.tdm1");
            
			stage.m_includeLayers.insertLast("bases.playlist1");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			// neutral/bots too
			stage.m_factionConfigs.insertLast(m_factionConfigs[2]);

			// examples of different kind of matches=sub gamemodes:
			// - team deathmatch
			// - koth
			// - deliver vehicle/ambush
			// - deliver item/ambush
			// - deliver character/ambush
			// - assault/defend
			// - destroy target/defend

			// each match class can support variety of settings,
			// e.g. 
			// - which bases the factions own as starting point,
			// - which resources are available
			// - timers
			// - targets
			// - ...

			// first is the warmup substage 
			{
				// warmup only ends when there's enough players in the game or an admin decides,
				// by default 2 is enough
				SubStage@ substage = WarmupSubStage(stage, m_metagame.getUserSettings().m_minimumPlayersToStart);
				substage.m_mapViewOverlayFilename = "none.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("TV station");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Bazaar");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				// add any initial commands here, can be used as modifiers e.g. for substage specific faction resources
				//substage.m_initCommands.insertLast("");
				@substage.m_match = @match;
			}

			// actual substages start here
			{
				// the map has declared some additional stuff for the substage, matched with a tag
				float maxTime = m_metagame.getUserSettings().m_tdmMaxTime;
				int maxScore = m_metagame.getUserSettings().m_tdmMaxScore;
				SubStage@ substage = TeamDeathmatchSubStage(stage, maxScore, maxTime);

				substage.m_mapViewOverlayFilename = "map6_overlay_tdm2.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("TV station");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Bazaar");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "tdm2"));
			}

			{
				float maxTime = m_metagame.getUserSettings().m_kothMaxTime;
				float defenseTime = m_metagame.getUserSettings().m_kothDefenseTime;
				SubStage@ substage = KothSubStage(stage, "Mosque", defenseTime, maxTime);
				substage.m_mapViewOverlayFilename = "map6_overlay_koth1.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				// KothSubStage will fill defense win timer
				match.m_baseCaptureSystem = "any";

				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Fennec road");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Powerhouse");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "koth1"));
			}

			{
				float maxTime = m_metagame.getUserSettings().m_thMaxTime;
				int maxScore = m_metagame.getUserSettings().m_thMaxScore;
				SubStage@ substage = TeamTeddyHuntSubStage(stage, maxScore, maxTime, "th1");
				
				substage.m_mapViewOverlayFilename = "map6_overlay_th1.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers; 
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Forward HQ alpha");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Forward HQ bravo");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.m_capacityMultiplier = 0.0001;
					//faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addInitCommand("<command class='commander_ai' active='0' />");

				substage.addTracker(SafeZone(m_metagame, "th1"));
			}

      {
				// the map has declared some additional stuff for the substage, matched with a tag
				float maxTime = m_metagame.getUserSettings().m_tdmMaxTime;
				int maxScore = m_metagame.getUserSettings().m_tdmMaxScore;
				SubStage@ substage = TeamDeathmatchSubStage(stage, maxScore, maxTime);
				substage.m_mapViewOverlayFilename = "map6_overlay_tdm3.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Powerhouse");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Fennec road");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "tdm3"));
			}

      {
				// the map has declared some additional stuff for the substage, matched with a tag
				float maxTime = m_metagame.getUserSettings().m_tdmMaxTime;
				int maxScore = m_metagame.getUserSettings().m_tdmMaxScore;
				SubStage@ substage = TeamDeathmatchSubStage(stage, maxScore, maxTime);
				substage.m_mapViewOverlayFilename = "map6_overlay_tdm1.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("West end settlement");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Junkyard");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "tdm1"));
			}

			m_stages.insertLast(stage);
		}
	}

	// ------------------------------------------------------------------------------------------------
	protected void setupPlaylist8() {
		int maxSoldiers = 15;

		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Moorland Trenches";
			stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map1";
			stage.m_mapIndex = 1;

			stage.m_includeLayers.insertLast("layer1.playlist3");
			stage.m_includeLayers.insertLast("layer1.tdm4");
			stage.m_includeLayers.insertLast("layer1.tdm5");
			stage.m_includeLayers.insertLast("layer1.tdm6");
			stage.m_includeLayers.insertLast("layer1.koth2");
			stage.m_includeLayers.insertLast("layer1.th2");
			stage.m_includeLayers.insertLast("bases.playlist3");

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			// neutral/bots too
			stage.m_factionConfigs.insertLast(m_factionConfigs[2]);

			// examples of different kind of matches=sub gamemodes:
			// - team deathmatch
			// - koth
			// - deliver vehicle/ambush
			// - deliver item/ambush
			// - deliver character/ambush
			// - assault/defend
			// - destroy target/defend

			// each match class can support variety of settings,
			// e.g. 
			// - which bases the factions own as starting point,
			// - which resources are available
			// - timers
			// - targets
			// - ...

			// first is the warmup substage 
			{
				// warmup only ends when there's enough players in the game or an admin decides,
				// by default 2 is enough
				SubStage@ substage = WarmupSubStage(stage, m_metagame.getUserSettings().m_minimumPlayersToStart);
				substage.m_mapViewOverlayFilename = "none.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Warehouse");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("East farm");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				// add any initial commands here, can be used as modifiers e.g. for substage specific faction resources
				//substage.m_initCommands.insertLast("");
				@substage.m_match = @match;
			}

			// actual substages start here
			{
				// the map has declared some additional stuff for the substage, matched with a tag
				float maxTime = m_metagame.getUserSettings().m_tdmMaxTime;
				int maxScore = m_metagame.getUserSettings().m_tdmMaxScore;
				SubStage@ substage = TeamDeathmatchSubStage(stage, maxScore, maxTime);

				substage.m_mapViewOverlayFilename = "map1_overlay_tdm5.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Warehouse");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("East farm");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "tdm5"));
			}

			{
				// the map has declared some additional stuff for the substage, matched with a tag
				float maxTime = m_metagame.getUserSettings().m_tdmMaxTime;
				int maxScore = m_metagame.getUserSettings().m_tdmMaxScore;
				SubStage@ substage = TeamDeathmatchSubStage(stage, maxScore, maxTime);

				substage.m_mapViewOverlayFilename = "map1_overlay_tdm4.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("East town");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Suburbs");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "tdm4"));
			}

			{
				float maxTime = m_metagame.getUserSettings().m_kothMaxTime;
				float defenseTime = m_metagame.getUserSettings().m_kothDefenseTime;
				SubStage@ substage = KothSubStage(stage, "Ruins", defenseTime, maxTime);
				substage.m_mapViewOverlayFilename = "map1_overlay_koth2.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				// KothSubStage will fill defense win timer
				match.m_baseCaptureSystem = "any";

				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Center trench");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("East trench");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "koth2"));
			}

			{
				float maxTime = m_metagame.getUserSettings().m_thMaxTime;
				int maxScore = m_metagame.getUserSettings().m_thMaxScore;
				SubStage@ substage = TeamTeddyHuntSubStage(stage, maxScore, maxTime, "th2");
				substage.m_mapViewOverlayFilename = "map1_overlay_th2.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers; 
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("West trench");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Mansion");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.m_capacityMultiplier = 0.0001;
					//faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addInitCommand("<command class='commander_ai' active='0' />");

				substage.addTracker(SafeZone(m_metagame, "th2"));
			}

			m_stages.insertLast(stage);
		}
	}

	// ------------------------------------------------------------------------------------------------
	protected void setupPlaylist9() {
		int maxSoldiers = 15;

		// ------------------------------------------------------------------------------------------------
		{
			Stage@ stage = createStage();
			stage.m_mapInfo.m_name = "Islet of Eflen";
			stage.m_mapInfo.m_path = "media/packages/hell_diver/maps/map15";
			stage.m_mapIndex = 13;
     
			stage.m_includeLayers.insertLast("bases.default");
			stage.m_includeLayers.insertLast("layer1.th1");
			stage.m_includeLayers.insertLast("layer1.minimodes"); 

			stage.m_factionConfigs.insertLast(m_factionConfigs[0]);
			stage.m_factionConfigs.insertLast(m_factionConfigs[1]);
			// neutral/bots too
			stage.m_factionConfigs.insertLast(m_factionConfigs[2]);

			// examples of different kind of matches=sub gamemodes:
			// - team deathmatch
			// - koth
			// - deliver vehicle/ambush
			// - deliver item/ambush
			// - deliver character/ambush
			// - assault/defend
			// - destroy target/defend

			// each match class can support variety of settings,
			// e.g. 
			// - which bases the factions own as starting point,
			// - which resources are available
			// - timers
			// - targets
			// - ...

			// first is the warmup substage 
			{
				// warmup only ends when there's enough players in the game or an admin decides,
				// by default 2 is enough
				SubStage@ substage = WarmupSubStage(stage, m_metagame.getUserSettings().m_minimumPlayersToStart);
				substage.m_mapViewOverlayFilename = "none.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Heel Quarter");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("East Coast");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				// add any initial commands here, can be used as modifiers e.g. for substage specific faction resources
				//substage.m_initCommands.insertLast("");
				@substage.m_match = @match;
			}

			// actual substages start here
			{
				// the map has declared some additional stuff for the substage, matched with a tag
				float maxTime = m_metagame.getUserSettings().m_tdmMaxTime;
				int maxScore = m_metagame.getUserSettings().m_tdmMaxScore;
				SubStage@ substage = TeamDeathmatchSubStage(stage, maxScore, maxTime);
				
				substage.m_mapViewOverlayFilename = "map15_overlay_tdm1.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Heel Quarter");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("East Coast");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "tdm2"));
			}

			{
				float maxTime = m_metagame.getUserSettings().m_kothMaxTime;
				float defenseTime = m_metagame.getUserSettings().m_kothDefenseTime;
				SubStage@ substage = KothSubStage(stage, "Museum", defenseTime, maxTime);
				substage.m_mapViewOverlayFilename = "map15_overlay_koth1.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
                match.m_playerAiReduction = 2;
				// KothSubStage will fill defense win timer
				match.m_baseCaptureSystem = "any";

				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("East Coast");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Heel Quarter");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "koth1"));
			}

			{
				float maxTime = m_metagame.getUserSettings().m_thMaxTime;
				int maxScore = m_metagame.getUserSettings().m_thMaxScore;
				SubStage@ substage = TeamTeddyHuntSubStage(stage, maxScore, maxTime, "th1");
				
				substage.m_mapViewOverlayFilename = "map15_overlay_th1.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers; 
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
        match.m_playerAiReduction = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("Heel Quarter");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("East Coast");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.m_capacityMultiplier = 0.0001;
					//faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addInitCommand("<command class='commander_ai' active='0' />");

				substage.addTracker(SafeZone(m_metagame, "th1"));
			}
      
			{
				// the map has declared some additional stuff for the substage, matched with a tag
				float maxTime = m_metagame.getUserSettings().m_tdmMaxTime;
				int maxScore = m_metagame.getUserSettings().m_tdmMaxScore;
				SubStage@ substage = TeamDeathmatchSubStage(stage, maxScore, maxTime);

				substage.m_mapViewOverlayFilename = "map15_overlay_tdm1.png";

				Match@ match = Match(m_metagame);
				match.m_maxSoldiers = maxSoldiers;
				match.m_soldierCapacityModel = "constant";
				match.m_playerAiCompensation = 2;
				match.m_baseCaptureSystem = "none";
				{
					Faction@ faction = Faction(m_factionConfigs[0]);
					faction.m_ownedBases.insertLast("East Coast");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[1]);
					faction.m_ownedBases.insertLast("Heel Quarter");
					match.m_factions.insertLast(faction);
				}
				{
					Faction@ faction = Faction(m_factionConfigs[2]);
					faction.makeNeutral();
					match.m_factions.insertLast(faction);
				}
				@substage.m_match = @match;

				substage.addTracker(SafeZone(m_metagame, "tdm2"));
			}
      

			m_stages.insertLast(stage);
		}
	}

}
