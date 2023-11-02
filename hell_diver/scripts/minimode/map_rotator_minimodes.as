// internal
#include "tracker.as"
#include "map_info.as"
#include "log.as"
#include "announce_task.as"
#include "generic_call_task.as"
#include "time_announcer_task.as"

// generic trackers
#include "map_rotator.as"

#include "stage_minimodes.as"

// --------------------------------------------
class FactionConfig {
	int m_index = -1;
	string m_file = "unset faction file";
	string m_name = "unset faction name";
	string m_color = "0 0 0";

	FactionConfig(int index, string file, string name, string color) {
		m_index = index;
		m_file = file;
		m_name = name;
		m_color = color;
	}
};

// --------------------------------------------
class MapRotatorMiniModes : MapRotator {
	GameModeMiniModes@ m_metagame;
	array<Stage@> m_stages;
	dictionary m_stagesCompleted;
	bool m_loop = true;
	array<FactionConfig@> m_factionConfigs;
	
	int m_currentStageIndex;
	
	MapRotatorMiniModes() { }
	
	MapRotatorMiniModes(GameModeMiniModes@ metagame) {
		_log("setUp MapRotatorMiniModes B");
		@m_metagame = @metagame;
	}

	// --------------------------------------------
	void setLoop(bool loop) {
		m_loop = loop;
	}

	// --------------------------------------------
	void init() {
		setupFactionConfigs();
		setupStages();
	}

	// --------------------------------------------
	protected array<FactionConfig@> getAvailableFactionConfigs() {
		array<FactionConfig@> availableFactionConfigs;
		
		availableFactionConfigs.insertLast(FactionConfig(-1, "super_earth.xml", "SpuerEarth AA", "0.1 0.5 0"));
		availableFactionConfigs.insertLast(FactionConfig(-1, "super_earth.xml", "SpuerEarth BB", "0.5 0.5 0.5"));
		availableFactionConfigs.insertLast(FactionConfig(-1, "super_earth.xml", "SpuerEarth CC", "1 0 0"));
		availableFactionConfigs.insertLast(FactionConfig(-1, "super_earth.xml", "SpuerEarth DD", "0 1 1"));
		availableFactionConfigs.insertLast(FactionConfig(-1, "super_earth.xml", "SpuerEarth DD", "0 0 1"));

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

			FactionConfig@ factionConfig = availableFactionConfigs[availableIndex];
			_log("setting " + factionConfig.m_name + " as index " + index);
			factionConfig.m_index = index;

			m_factionConfigs.insertLast(factionConfig);

			// removes the first item in array
			//array_splice($available_faction_configs, $available_index, 1);
			availableFactionConfigs.removeAt(0);

			index++;
		}

		// - finally add neutral / protectors
		// {
		// 	index = m_factionConfigs.length();
		// 	m_factionConfigs.insertLast(FactionConfig(index, "brown.xml", "Bots", "0 0 0"));
		// }

		_log("total faction configs " + m_factionConfigs.length());
	}

	// --------------------------------------------
	protected Stage@ createStage() {
		return Stage(m_metagame, this);
	}

	// --------------------------------------------
	protected void setupStages() {
		// override this in derived classes to set up stages and substages for rotation 

		// in PvPvE, a stage defines the map + the resources to load and the substages that will take place in that map

		// the substages define the match / round logic and faction settings
	}

	// -------------------------------------------
	protected void waitAndStart(int time = 30, bool sayCountdown = true) {
		int previousStageIndex = m_currentStageIndex;

		// share some information with the server (and thus clients)
		int index = getNextStageIndex();
		string mapName = getMapName(index);

		_log("previous stage index " + previousStageIndex + ", next stage index " + index);

		// wait a while, and let server announce a few things
		m_metagame.getTaskSequencer().add(TimeAnnouncerTask(m_metagame, time, sayCountdown));

		if (previousStageIndex != index) {
			// start new map
			m_metagame.getTaskSequencer().add(CallInt(CALL_INT(this.startMapEx), index));
		} else {
			// restart same map
			m_metagame.getTaskSequencer().add(Call(CALL(m_metagame.requestRestart)));
		}
	}

	// --------------------------------------------
	protected void readyToAdvance() {
		if (m_stagesCompleted.getSize() == m_stages.length()) {
			_log("all stages completed, request for restart");
			sleep(2);

			//m_metagame->request_restart();
			m_metagame.getTaskSequencer().add(TimeAnnouncerTask(m_metagame, 30, true));
			m_metagame.getTaskSequencer().add(Call(CALL(m_metagame.requestRestart)));

		} else {
			waitAndStart();
		}
	}

	// --------------------------------------------
	protected int getStageCount() {
		return m_stages.length();
	}

	// --------------------------------------------
	protected string getMapName(int index) {
		return m_stages[index].m_mapInfo.m_name;
	}

	// --------------------------------------------
	protected string getChangeMapCommand(int index) {
		return m_stages[index].getChangeMapCommand();
	}

	// --------------------------------------------
	protected string getStartGameCommand(int index) {
		// note, get_start_game_command doesn't make sense in this rotator, and isn't used
		return "";
	}

	// --------------------------------------------
	protected int getNextStageIndex() const {
		//return m_stagesCompleted.getSize();
		array<string> stages = m_stagesCompleted.getKeys();
		array<int> completedStageIndices;
		for (uint i = 0; i < stages.length(); ++i) {
			completedStageIndices.insertLast(parseInt(stages[i]));
		}
        return pickRandomMapIndex(getStageCount(), completedStageIndices);
	}

	// --------------------------------------------------------
	protected bool isStageCompleted(int index) {
		// if Find finds the value in array, it will return a value >= 0
		return (m_stagesCompleted.exists(formatInt(index)));
	}

	// --------------------------------------------------------
	protected Stage@ getCurrentStage() {
		return m_stages[m_currentStageIndex];
	}
	
	// --------------------------------------------
    void startMapEx(int index) {
		startMap(index);
	}

	// --------------------------------------------
	void startMap(int index, bool beginOnly = false) {
		_log("start_map, index=" + index + ", begin_only=" + beginOnly);

		Stage@ stage = m_stages[index];
		m_currentStageIndex = index;

		if (!beginOnly) {
			// change map 
			string changeMapCommand = getChangeMapCommand(index);
			m_metagame.getComms().send(changeMapCommand);
		}
		
		// note, get_start_game_command doesn't make sense in this rotator, and isn't used
		stage.start();
	}

	// --------------------------------------------
   	void restartMap() {
		int index = m_currentStageIndex;
		_log("restart_map, index=" + index);

		Stage@ stage = m_stages[index];
		stage.start();
	}

	// --------------------------------------------
	void stageEnded() {
		m_stagesCompleted[formatInt(m_currentStageIndex)] = true;

		// rotate to next map
		readyToAdvance();
	}

	// --------------------------------------------
	protected void handleMatchEndEvent(const XmlElement@ event) {
		// override the default MapRotator behavior; 

		// don't do anything here, it's up to substages 
	}

	// ----------------------------------------------------
	// debugging tools
	/*
	protected void handleChatEvent(const XmlElement@ event) {
		// player_id
		// player_name
		// message
		// global

		string message = event.getStringAttribute("message");
		// for the most part, chat events aren't commands, so check that first
		if (!startsWith(message, "/")) {
			return;
		}

		string sender = event.getStringAttribute("player_name");
		int senderId = event.getIntAttribute("player_id");

		
		if (!m_metagame.getAdminManger().isAdmin(sender, sender_id)) {
			return;
		}

   		if (checkCommand(message, "warp")) {
			parameters = parseParameters(message, "warp");
			if (parameters.length() > 0) {
				int index = parameters[0];
				m_metagame.getComms().send("say warping to " + index);
				changeMap(index);
			}
		} else if (checkCommand(message, "restart")) {
			restartMap();
		} else if (checkCommand(message, "start_tournament")) {
			parameters = parseParameters(message, "start_tournament");
			if (parameters.length() > 0) {
				string name = parameters[0];
				m_metagame.getComms().send("say starting tournament " + name);
				m_metagame.startTournament(name);
				restartMap();
			}
		} else if (checkCommand(message, "end_tournament")) {
			if (m_metagame.isTournamentOngoing()) {
				m_metagame.getComms().send("say tournament " + m_metagame.getTournamentName() + " ends");
				m_metagame.endTournament();
			}
		} else if (checkCommand(message, "end_substage")) {
			Stage@ stage = getCurrentStage();
			stage.getCurrentSubstage().end();
		}
	}
	*/
	// ----------------------------------------------------
	protected void handlePlayerDisconnectEvent(const XmlElement@ event) {
		// first stage is the stage where we go back to if player count goes below a threshold,
		// thus doesn't make sense to check this while in that first stage
		Stage@ stage = getCurrentStage();
		if (stage.getCurrentSubStageIndex() > 0) {
			int players = getPlayerCount(m_metagame);
			if (players < m_metagame.getUserSettings().m_minimumPlayersToContinue) {
				// time to reset
				m_metagame.requestRestart();
			}
		}
	}
}