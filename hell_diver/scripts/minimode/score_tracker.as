#include "tracker.as"
#include "log.as"
#include "helpers.as"

// --------------------------------------------
// helper tracker used to track scores and notify when max score is reached by a faction
// --------------------------------------------
class ScoreTracker : Tracker {
	protected GameModeMiniModes@ m_metagame;
	protected SubStage@ m_substage;
	protected array<int> m_scores;
	protected int m_maxScore = 100;
	protected dictionary m_includedFactions;

    // ----------------------------------------------------
	ScoreTracker(GameModeMiniModes@ metagame, SubStage@ substage, int maxScore, dictionary includedFactions = dictionary() ) {
		@m_metagame = @metagame;
		@m_substage = @substage;
		m_maxScore = maxScore;
		m_includedFactions = includedFactions;
	}

	// --------------------------------------------
	void setMaxScore(int maxScore) {
		m_maxScore = maxScore;
	}

	// --------------------------------------------
	void reset() {
		m_scores = array<int>(0);
		for (uint id = 0; id < m_substage.m_match.m_factions.length(); ++id) {
			if (m_includedFactions.getSize() > 0 && !(m_includedFactions.exists(formatInt(id)))) {
				continue;
			}
			
			// if faction is neutral or it's name is Bots, continue, do not display this faction's score
			Faction@ faction = m_substage.m_match.m_factions[id];
			if (faction.isNeutral() || faction.m_config.m_name == "Bots") {
				continue;
			}
			
			m_scores.insertLast(0);
			
			string value = "0";
			string color = faction.m_config.m_color;
			string command = "<command class='update_score_display' id='" + id + "' text='" + value + "' color='" + color + "' />";
			m_metagame.getComms().send(command);
		}
		
		{
			string command = "<command class='update_score_display' max_text='" + m_maxScore + "' />";
			m_metagame.getComms().send(command);
		}
	}

	// --------------------------------------------
	int getWinningTeam() {
		int winner = 0;
		bool tie = false;
		for (uint i = 0; i < m_scores.length(); ++i) {
			int score = m_scores[i];
			if (int(i) == winner) {
				continue;
			}
			
			if (score > m_scores[winner]) {
				winner = i;
				tie = false;
			} else if (score == m_scores[winner]) {
				tie = true;
			}
		}

		if (tie) {
			_log("  tie!");
			winner = -1;
		} else {
			_log("  winner is " + winner + "!");
		}

		return winner;
	}

	// ----------------------------------------------------
	void addScore(int factionId) {
		m_scores[factionId] += 1;

		{
			// update game's score display
			int value = m_scores[factionId];
			string command = "<command class='update_score_display' id='" + factionId + "' text='" + value + "' />";
			m_metagame.getComms().send(command);
		}

		scoreChanged();
	}

    	// ----------------------------------------------------
	protected void scoreChanged() {
		int winner = -1;
		int score;
		for (uint i = 0; i < m_scores.length(); ++i) {
			score = m_scores[i];
			if (score >= m_maxScore) {
				winner = i;
				break;
			}
		}
		
		string text = "";
		array<Faction@> factions = m_metagame.getFactions();
		for (uint i = 0; i < factions.length(); ++i) {
			if (m_includedFactions.getSize() > 0 && !(m_includedFactions.exists(formatInt(i)))) {
				continue;
			}
			
			// if faction is neutral or it's name is Bots, continue, do not display this faction's score. Same as in reset()
			Faction@ faction = factions[i];
			if (faction.isNeutral() || faction.m_config.m_name == "Bots") {
				continue;
			}
			
			if (i != 0) {
				text += ", ";
			}
			text += faction.m_config.m_name + ": " + m_scores[i];
		}
		announce(text);

		if (winner >= 0) {
			_log("  winner is " + winner + "!");
			
			// let substage handle this
			//$this.announce("winner is " . $factions[$winner].config.name . "!");

			// inform the substage
			m_substage.maxScoreReached(winner);
		}
	}

	// ----------------------------------------------------
	array<int> getScores() {
		return m_scores;
	}

	// ----------------------------------------------------
	string getScoresAsString() {
		string text = "";
		for (uint i = 0; i < m_scores.length(); ++i) {
			text += m_scores[i];
			if (i != m_scores.length() - 1) {
				text += " - ";
			}
		}
		
		return text;
	}

	// ----------------------------------------------------
	protected void announce(string text) {
		// using a direct console command here
		sendFactionMessage(m_metagame, -1, text);
	}


	// --------------------------------------------
	bool hasEnded() const {
			// always on
			return false;
	}

	// --------------------------------------------
	bool hasStarted() const {
			// always on
			return true;
	}

    	// ----------------------------------------------------
	void update(float time) {
	}
}