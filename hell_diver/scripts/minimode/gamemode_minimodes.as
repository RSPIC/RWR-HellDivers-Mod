#include "metagame.as"
#include "log.as"
#include "call_marker_tracker.as"

#include "map_rotator_minimodes_all.as"

// available tracker implementations
#include "basic_command_handler.as"
//#include "gunship_run.as"
#include "emoticons.as"


// --------------------------------------------
class UserSettings {
	array<string> m_overlayPaths;

	int m_minimumPlayersToStart = 2;
	int m_minimumPlayersToContinue = 2;
	float m_timeBetweenSubstages = 30.0;

	float m_tdmMaxTime = 900.0;
	int m_tdmMaxScore = 5;

	float m_kothMaxTime = 900.0;
	float m_kothDefenseTime = 180.0;

	float m_thMaxTime = 900.0;
	int m_thMaxScore = 3;

	float m_quickmatchMaxTime = 3600.0;

	string m_startServerCommand = "";

	bool m_debug_mode = false;
	bool m_server_test_mode = false;
	
	// --------------------------------------------
	UserSettings() {
		m_overlayPaths.insertLast("media/packages/minimodes");
	}
	
	// --------------------------------------------
	void print() const {
		_log(" * minimum players to start: " + m_minimumPlayersToStart);
		_log(" * minimum players to continue: " + m_minimumPlayersToContinue);
		_log(" * time between substages: " + m_timeBetweenSubstages);
		
		_log(" * tdm max time: " + m_tdmMaxTime);
		_log(" * tdm max score: " + m_tdmMaxScore);
		
		_log(" * koth max time: " + m_kothMaxTime);
		_log(" * koth max defense time: " + m_kothDefenseTime);
		
		_log(" * teddy hunt max time: " + m_thMaxTime);
		_log(" * teddy hunt max score: " + m_thMaxScore);
	}
}

// --------------------------------------------
class GameModeMiniModes : Metagame {
	protected UserSettings@ m_userSettings;

	protected MapRotator@ m_mapRotator;

	//protected MapInfo@ m_mapInfo; // already exists in Metagame class
	protected array<Faction@> m_factions;

	protected string m_tournamentName = "";

	// --------------------------------------------
	GameModeMiniModes(UserSettings@ settings) {
		super(settings.m_startServerCommand);
		@m_userSettings = @settings;
	}

	// --------------------------------------------
	void init() {
		Metagame::init();
		
		// trigger map change right now
		setupMapRotator();
		m_mapRotator.init();
		m_mapRotator.startRotation();
	}

	// --------------------------------------------
	const UserSettings@ getUserSettings() const {
		return m_userSettings;
	}
	
	// --------------------------------------------
	protected void setupMapRotator() {
		@m_mapRotator =  MapRotatorMiniModesAll(this);
	}

	// --------------------------------------------
	// MapRotator calls here when a battle has started
	void postBeginMatch() {
		Metagame::postBeginMatch();

		// add tracker for match end to switch to next
		addTracker(m_mapRotator);

		addTracker(BasicCommandHandler(this));
	}


	// --------------------------------------------
	string getTournamentName() {
		return m_tournamentName;
	}

	// --------------------------------------------
	bool isTournamentOngoing() {
		return m_tournamentName != "";
	}

	// --------------------------------------------
	void startTournament(string name) {
		m_tournamentName = name;
	}

	// --------------------------------------------
	void endTournament() {
		m_tournamentName = "";
	}

	// TODO:
	// - consider providing this stuff by default, it's always needed
	// .

	// --------------------------------------------
	// map rotator feeds in data about current situation here
	void setFactions(array<Faction@> factions) {
		m_factions = factions;
	}

	// --------------------------------------------
	// map rotator feeds in data about current situation here
	void setMapInfo(MapInfo@ info) {
		m_mapInfo = info;
	}

	// --------------------------------------------
	array<Faction@> getFactions() {
		return m_factions;
	}

	// --------------------------------------------
	// pos is array of 3 elements, x,y,z
	string getRegion(Vector3@ pos) {
		return Metagame::getRegion(pos);
	}
}