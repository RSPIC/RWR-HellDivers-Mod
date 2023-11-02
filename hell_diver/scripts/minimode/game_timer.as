// internal
#include "tracker.as"
#include "log.as"
#include "helpers.as"

// --------------------------------------------
// game timer controls the in-game defense win timer and to-be-winner-by-time 
// - substages utilizing this should listen for match end events from the game
// --------------------------------------------
class GameTimer {
	protected Metagame@ m_metagame;
	protected float m_maxTime = 60.0;
	protected int m_lastSetFactionId = -1;

	// ----------------------------------------------------
	GameTimer(Metagame@ metagame, float maxTime) {
		@m_metagame = @metagame;
		m_maxTime = maxTime;
	}

	// ----------------------------------------------------
	void prepareMatch(Match@ match) {
		// game timer happens through defense_win_time in custom externally controlled mode
		match.m_defenseWinTime = m_maxTime;
		match.m_defenseWinTimeMode = "custom";
	}

	// ----------------------------------------------------
	void start(int initialWinningFactionId = -1) {
		string command = "<command class='set_game_timer' time='" + m_maxTime + "' faction_id='" + initialWinningFactionId + "' />";
		m_metagame.getComms().send(command);

		m_lastSetFactionId = initialWinningFactionId;
	}

	// ----------------------------------------------------
	void setWinningTeam(int factionId) {
		if (factionId != m_lastSetFactionId) {
			string command = "<command class='set_game_timer' faction_id='" + factionId + "' />";
			m_metagame.getComms().send(command);
			m_lastSetFactionId = factionId;
		}
	}

	// ----------------------------------------------------
	void cancel() {
		string command = "<command class='set_game_timer' time='-1.0' />";
		m_metagame.getComms().send(command);
	}
}