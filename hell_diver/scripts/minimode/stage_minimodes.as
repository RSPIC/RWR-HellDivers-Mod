
#include "tracker.as"

// internal
#include "metagame.as"
#include "map_info.as"
#include "query_helpers.as"

// generic trackers
#include "map_rotator.as"

// --------------------------------------------
// this is a bit awkwardly handled, but
// minimodes need to be able to locate
// the user profiles to duplicate them 
// each round

// the vanilla location for the scripts, the working dir is:
// media\packages\vanilla\scripts\
// making it correct if the profiles are found relatively with

// this is true only for servers, but it's only
// servers that do profile copying anyway


// --------------------------------------------
class Stage {
	protected GameModeMiniModes@ m_metagame;
	protected MapRotatorMiniModes@ m_mapRotator;

	MapInfo@ m_mapInfo;
	int m_mapIndex = -1;

	// factions involved in this stage,
	// - note that this is FactionConfig, not Faction,
	//   it's different from Invasion specific Stages
	array<FactionConfig@> m_factionConfigs;

	array<string> m_includeLayers;

	protected array<SubStage@> m_substages;
	protected uint m_currentSubStageIndex = 0;

	array<string> m_resourcesToLoad;

	// --------------------------------------------
	Stage(GameModeMiniModes@ metagame, MapRotatorMiniModes@ mapRotator) {
		@m_metagame = @metagame;
		@m_mapRotator = @mapRotator;
		@m_mapInfo = MapInfo();

		m_resourcesToLoad.insertLast("<weapon file='GameModePVP/pvp_weapons.xml' />");
		m_resourcesToLoad.insertLast("<projectile file='GameModePVP/pvp_throwables.xml' />");
		m_resourcesToLoad.insertLast("<call file='GameModePVP/pvp_calls.xml' />");
		m_resourcesToLoad.insertLast("<carry_item file='GameModePVP/pvp_carry_items.xml' />");
		m_resourcesToLoad.insertLast("<vehicle file='GameModePVP/pvp_vehicles.xml' />");
		// m_resourcesToLoad.insertLast("<vehicle file='event_crate.vehicle' />");
	}

	// --------------------------------------------
	void addSubstage(SubStage@ subStage) {
		m_substages.insertLast(subStage);
	}

	// --------------------------------------------
	GameModeMiniModes@ getMetagame() {
		return m_metagame;
	}

	// --------------------------------------------
	int getCurrentSubStageIndex() {
		return m_currentSubStageIndex;
	}

	// --------------------------------------------
	SubStage@ getCurrentSubStage() {
		return m_substages[m_currentSubStageIndex];
	}

	// --------------------------------------------
	string getChangeMapCommand() {
		string mapConfig = "<map_config>\n";

		for (uint i = 0; i < m_includeLayers.length(); ++i) {
			mapConfig += "<include_layer name='" + m_includeLayers[i] + "' />\n";
		}

		for (uint i = 0; i < m_factionConfigs.length(); ++i) {
			mapConfig += "<faction file='" + m_factionConfigs[i].m_file + "' />\n";
		}
		
		for (uint i = 0; i < m_resourcesToLoad.length(); ++i) {
			mapConfig += m_resourcesToLoad[i] + "\n";
		}
		
		mapConfig += "</map_config>\n";

		string overlays = "";
		
		// user settings were passed in constructor
		for (uint i = 0; i < m_metagame.getUserSettings().m_overlayPaths.length(); ++i) {
			string path = m_metagame.getUserSettings().m_overlayPaths[i];
			_log("adding overlay " + path);
			overlays += "<overlay path='" + path + "' />\n";
		}

		string changeMapCommand = 
			"<command class='change_map'" +
			"	map='" + m_mapInfo.m_path + "'>" +
			overlays +
			mapConfig +
			"</command>";

		return changeMapCommand;
	}

	// --------------------------------------------
	void start() {
		_log("Stage::start");
		
		m_metagame.setMapInfo(m_mapInfo);

		SubStage@ substage = getCurrentSubStage();

		// call substage to start the match
		// - does pre/post match in metagame clearing old trackers
		// - starts the match in server
		// - adds substage specific trackers in metagame, and self
		substage.startMatch();
	}

	// --------------------------------------------
	/* // not using profiles to gather stats anymore
	protected string getProfileFolderName() {
		// day-month-year_hour-minute_second
		now = datetime();
		string name = "" + now.get_day() +
						"-" + now.get_month() +
						"-" + now.get_year() +
						"_" + now.get_hour() +
						"-" + now.get_minute() +
						"_" + now.get_second();
		name += "_profiles_minimodes_";
		name += m_currentSubStageIndex + "_";
		SubStage@ subStage = getCurrentSubStage();
		if (subStage !is null) {
			name += subStage.m_name;
		}
		return name;
	}
	*/

	// --------------------------------------------
	void substageEnded() {
		_log("Stage::substage_ended");

		// store profiles in game now
		//m_metagame.getComms().send("save_profiles");

		/*
		// only execute on server
		global $argv;
		if (!test_parameter($argv, "single_player")) {
			// let it happen
			sleep(1);
			// now take a copy of the profile folder, effectively saving round results separately

			// store in own subfolder
			$round_profile_folder = "archived_profiles/" . $this->get_profile_folder_name();

			copy_profiles($round_profile_folder);
			// also collect total stats separately, so merge the latest results with the total stats so far
			merge_profiles($round_profile_folder, "total_profiles");

			// also collect ongoing tournament stats, if ongoing
			if ($this->metagame->is_tournament_ongoing()) {
				merge_profiles($round_profile_folder, $this->metagame->get_tournament_name() . "_profiles");
			}
		}
		*/

		// prepare to start next substage, allow a moment to read messages and chat

		if (m_currentSubStageIndex == m_substages.length() - 1) {
			// if we are at the last substage, do insta-advance in order to begin changing the stage which includes waiting
		} else {
			// not at last substage yet

			// wait a while
			// user settings are not in metagame.as
			// $time = $this->metagame->user_settings->time_between_substages;
			float time = m_metagame.getUserSettings().m_timeBetweenSubstages;
			m_metagame.getTaskSequencer().add(TimeAnnouncerTask(m_metagame,time,true));
		}

		// start new map, using the task sequencer which includes the potential time wait task just added above
		//$this->metagame->task_sequencer->add(new GenericCallTask($this, "advance_to_next_substage", array()));
		m_metagame.getTaskSequencer().add(Call(CALL(this.advanceToNextSubstage)));
		
	}

	// --------------------------------------------
	void advanceToNextSubstage() {
		// rotate to next substage
		m_currentSubStageIndex++;
		if (m_currentSubStageIndex >= m_substages.length()) {
			_log("all substages completed");
			// inform the map rotator that we're done
			// stageEnded() does not exist in map_rotator.as
			m_mapRotator.stageEnded();
		} else {
			_log("next substage: " + m_currentSubStageIndex);
			start();
		}
	}
}

// --------------------------------------------
// SubStage works as a base class for specialized substages that define the actual mode logic
// - the stage rotates substages one by one, calling SubStage::start when it's time for SubStage to do its thing
// - substage itself defines how and when it ends; to get the stage advance to the next substage, the stage
//   must be notified with Stage::substage_ended call
abstract class SubStage : Tracker {
	protected GameModeMiniModes@ m_metagame;
	protected Stage@ m_stage; 
	// substage specific trackers
	protected array<Tracker@> m_trackers;

	protected array<string> m_initCommands;

	protected int m_winner = -1;

	// name is used a directory name, so avoid spaces and oddball characters
	string m_name = "unset_substage_name";	
	// use display name as what is announced to players
	string m_displayName = "";	

	Match@ m_match;
	string m_mapViewOverlayFilename = "none.png";

	protected bool m_started = false;
	protected bool m_ended = false;

	// --------------------------------------------
	SubStage(Stage@ stage) {
		// setup two-way connection between substage and stage
		@m_stage = @stage;
		m_stage.addSubstage(this);
		// cache metagame
		@m_metagame = m_stage.getMetagame();

		m_started = false;
		m_ended = false;
	}

	// --------------------------------------------
	// trackers added through this method are added in metagame at start_match
	void addTracker(Tracker@ tracker) {
		m_trackers.insertLast(tracker);
	}

	// --------------------------------------------
	void addInitCommand(string command) {
		m_initCommands.insertLast(command);
	}

	// --------------------------------------------
   	void startMatch() {
		_log("SubStage::start_match");

		sendFactionMessage(m_metagame, -1, m_displayName + " starts!");

		// clear game's score display
		for (uint i = 0; i < m_match.m_factions.length(); ++i) {
			int id = i;
			string command = "<command class='update_score_display' id='" + id + "' text='' />";
			m_metagame.getComms().send(command);
		}

		{
			string command = "<command class='update_score_display' max_text='' />";
			m_metagame.getComms().send(command);
		}

		m_winner = -1;

		// enable respawning now
		for (uint i = 0; i < m_match.m_factions.length(); ++i) {
			int id = i;
			string command = "<command class='set_soldier_spawn' faction_id='" + id + "' enabled='1' />";
			m_metagame.getComms().send(command);
		}

		{
			string command = "<command class='update_map_view' overlay_texture='" + m_mapViewOverlayFilename + "' />";
			m_metagame.getComms().send(command);
		}

		m_metagame.preBeginMatch();

		m_match.start();
		
		// wait here 
		/* // not certain how to make queries, or why, leaving for now. TODO
		{
			// - make a query, the game will serve it as soon as it can (->marks that map resources have been changed and the match has been started)
			$query_doc = new DOMDocument();
			$command = "<command class='make_query' id='" . $this->metagame->comms->get_query_uid() . "'/>\n";
			$query_doc->loadXML($command);
			$doc = $this->metagame->comms->query($query_doc);

			$this->metagame->reset_timer();
			$this->metagame->comms->clear_queue();
		}
		*/

		// substage itself is a tracker, add it
		m_metagame.addTracker(this);

		// create substage specific trackers:
		_log("trackers: " + m_trackers.length());
		for (uint i = 0; i < m_trackers.length(); ++i) {
			m_metagame.addTracker(m_trackers[i]);
		}
		m_metagame.postBeginMatch();

		for (uint i = 0; i < m_initCommands.length(); ++i) {
			m_metagame.getComms().send(m_initCommands[i]);
		}

		// keep $started false; metagame tracker activation will call start() here
	}		

	// --------------------------------------------
	void start() {
		m_started = true;
	}

	// --------------------------------------------
   	protected void setWinner(int winner) {
		m_winner = winner;
	}

	// --------------------------------------------
	void maxScoreReached(int winner) { }
	
	// --------------------------------------------
	void onItemDelivery(int factionId, string factionName, int playerId, string playerName) { }
	
	// --------------------------------------------
   	void end() {
		m_ended = true;

		// force respawn lock now
		for (uint i = 0; i < m_match.m_factions.length(); ++i) {
			int id = i;
			string command = "<command class='set_soldier_spawn' faction_id='" + id + "' enabled='0' />";
			m_metagame.getComms().send(command);
		}

		// make losing factions lose
		if (m_winner >= 0) {
			for (uint i = 0; i < m_match.m_factions.length(); ++i) {
				int id = i;
				if (id == m_winner) {
					continue;
				}
				
				string command = "<command class='set_match_status' faction_id='" + id + "' lose='1' />";
				m_metagame.getComms().send(command);
			}
			
			// kill all characters left alive on losing side, don't give additional score from execution
			for (uint i = 0; i < m_match.m_factions.length(); ++i) {
				int factionId = i;
				if (factionId == m_winner) {
					continue;
				}
				
				array<const XmlElement@> characters = getCharacters(m_metagame, factionId);
				if (characters !is null) {
					for (uint j = 0; j < characters.length(); ++j) {
						const XmlElement@ character = characters[j];
						int characterId = character.getIntAttribute("id");
						string command = "<command class='update_character' id='" + characterId + "' dead='1' />";
						m_metagame.getComms().send(command);
					}
				}
			}
		}

		if (m_winner >= 0) {
			Faction@ faction = m_match.m_factions[m_winner];
			sendFactionMessage(m_metagame, -1, "round winner " + faction.m_config.m_name + "!");
		} else {	
			sendFactionMessage(m_metagame, -1, "the round is a tie");
		}

		// remove trackers added by this substage in order to make after-game events not register as game events
		for (uint i = 0; i < m_trackers.length(); ++i) {
			m_metagame.removeTracker(m_trackers[i]);
		}
		m_stage.substageEnded();
	}

	// --------------------------------------------
	bool hasEnded() const {
			return m_ended;
	}

	// --------------------------------------------
	bool hasStarted() const {
			return m_started;
	}

    // ----------------------------------------------------
	void update(float time) {
	}
}

// --------------------------------------------
// match-specific faction settings
class Faction {
	FactionConfig@ m_config;

	int m_bases = -1;

	float m_overCapacity = 0;
	float m_capacityMultiplier = 1.0;
	int m_capacityOffset = 0;

	// this is optional
	array<string> m_ownedBases;

	Faction(FactionConfig@ factionConfig) {
		@m_config = @factionConfig;
	}

	void makeNeutral() {
		m_capacityMultiplier = 0.0;
	}

	bool isNeutral() {
		return m_capacityMultiplier <= 0.0;
	}

	string getName() {
		return m_config.m_name;
	}
}


// --------------------------------------------
class Match {
	protected GameModeMiniModes@ m_metagame;

	// match specific settings
	int m_maxSoldiers = 0;
	float m_soldierCapacityVariance = 0.30;
	string m_soldierCapacityModel = "variable";
	float m_defenseWinTime = -1.0;
	string m_defenseWinTimeMode = "hold_bases";
	int m_playerAiCompensation = 2;                  // was 2 (1.65)
	int m_playerAiReduction = 1;                     // was 0 (1.65)
	string m_baseCaptureSystem = "any";

	array<Faction@> m_factions;

	float m_initialXp = 0.5;
	float m_initialRp = 200.0;
	float m_aiAccuracy = 0.94;

	float m_xpMultiplier = 1.0;
	float m_rpMultiplier = 1.0;

	// --------------------------------------------
	Match(GameModeMiniModes@ metagame) {
		@m_metagame = @metagame;
	}

	// --------------------------------------------
	string getStartGameCommand() {
		string command = 
			"<command class='start_game'" +
			"	vehicles='1'" +
			"	max_soldiers='" + m_maxSoldiers + "'" +
			"	soldier_capacity_variance='" + m_soldierCapacityVariance + "'" +
			"	soldier_capacity_model='" + m_soldierCapacityModel + "'" +
			"	player_ai_compensation='" + m_playerAiCompensation + "'" +
			"	player_ai_reduction='" + m_playerAiReduction + "'" +
			"	xp_multiplier='" + m_xpMultiplier + "'" +
			"	rp_multiplier='" + m_rpMultiplier + "'" +
			"   initial_xp='" + m_initialXp + "'" + 
			"   initial_rp='" + m_initialRp + "'" + 
			"	base_capture_system='" + m_baseCaptureSystem + "'" +
			"	clear_profiles_at_start='1'" +
			"	preserve_items_on_team_kill='0'" +
			"	preserve_items_on_disconnect='0'" +
            " fov='1'";

		if (m_defenseWinTime >= 0) {
			command += 
				"  defense_win_time='" + m_defenseWinTime + "'" +
				"  defense_win_time_mode='" + m_defenseWinTimeMode + "'";
		}

		command += ">\n";
		
		for (uint i = 0; i < m_factions.length(); ++i) {
			Faction@ faction = m_factions[i];
			command += 
				"	<faction capacity_offset='" + faction.m_capacityOffset + "' initial_over_capacity='" + faction.m_overCapacity + "' ";
			command += "capacity_multiplier='" + faction.m_capacityMultiplier + "' ";
			command += "ai_accuracy='" + m_aiAccuracy + "' ";

			// if base amount has been declared for the faction, use it

			// allow adventure mode to use the amount of bases we managed to capture 
			// if we were in the map previously

			// TODO: do owned bases correctly; the command can now handle it
			if (faction.m_ownedBases.length() > 0) {
				// don't randomize, we'll use the right ones
			} else if (faction.m_bases >= 0) {
				command += "initial_occupied_bases='" + faction.m_bases + "' ";
			}

			command += ">\n";

			if (faction.m_ownedBases.length() > 0) {
				for (uint j = 0; j < faction.m_ownedBases.length(); ++j) {
					command +=
						"<base key='" + faction.m_ownedBases[j] + "' />\n";
				}
			}

			command += "</faction>\n";
		}

		command +=
			"   <local_player faction_id='0' username='Single player' />\n" +
			"</command>\n";

		return command;
	}

	// --------------------------------------------
   	void start() {
		_log("Match::start");

		m_metagame.setFactions(m_factions);

		// start game 
		string startGameCommand = getStartGameCommand();
		m_metagame.getComms().send(startGameCommand);
	}		

}
