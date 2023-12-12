#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"

#include "stage_minimodes.as"

#include "score_tracker.as"
//#include "timed_round_tracker.as"
#include "game_timer.as"

// --------------------------------------------
class TeamDeathmatchSubStage : SubStage {
	// - team that reaches the given kill count wins 
	// - team that has highest score when timer runs out wins
	protected ScoreTracker@ m_scoreTracker;

	// if false, tracks deaths rather than kills;
	// tracking player deaths is good for bot.player kills to become counted, yet keep player.bot kills not counted
	protected bool m_trackKills = false; 

	protected GameTimer@ m_gameTimer;

	protected int m_baseMaxScore = 10;

	// --------------------------------------------
	TeamDeathmatchSubStage(Stage@ stage, int baseMaxScore, float maxTime, bool trackKills = false) {
		super(stage);

		m_trackKills = trackKills;
		m_baseMaxScore = baseMaxScore;

		m_name = "tdm";
		m_displayName = "Team deathmatch";

		// the trackers get added into active tracking at SubStage::start()
		if (maxTime > 0.0) {
			//addTracker(TimedRoundTracker(m_metagame, this, maxTime));
			@m_gameTimer = GameTimer(m_metagame, maxTime);
		}

		@m_scoreTracker = ScoreTracker(m_metagame, this, getMaxScore(10));
		addTracker(m_scoreTracker);
	}

	// --------------------------------------------
	void startMatch() {
		if (m_gameTimer !is null) {
			// if GameTimer is used, some match settings must be set accordingly before starting the match
			m_gameTimer.prepareMatch(m_match);
		}

		{
			int playerCount = getPlayerCount(m_metagame);
			m_scoreTracker.setMaxScore((getMaxScore(playerCount)));
		}


		SubStage::startMatch();

		m_scoreTracker.reset();

		if (m_gameTimer !is null) {
			m_gameTimer.start(-1);
		}
	}

	// ----------------------------------------------------
	protected void announce(string text) {
		// using a direct console command here
		sendFactionMessage(m_metagame, -1, text);
	}

    // ----------------------------------------------------
	// TimedRoundTracker informs here when time's up
	/*
	on_time_expired() {
		_log("time expired");

		$this.set_winner(m_scoreTracker.get_winning_team());

		// end the stage
		$this.end();
	}
	*/

	// --------------------------------------------
	protected int getMaxScore(int player_count) {
		return m_baseMaxScore * player_count;
	}

	// --------------------------------------------
	// GameTimer uses in-game defense win timer, which reports match end here
	protected void handleMatchEndEvent(const XmlElement@ event) {
		int winner = -1;
		array<const XmlElement@> elements = event.getElementsByTagName("win_condition");
		if (elements.length() >= 1) {
			const XmlElement@ win_condition = elements[0];
			// can be -1 if so set by GameTimer
			winner = win_condition.getIntAttribute("faction_id");
		} else {
			_log("couldn't find win_condition tag");
		}

		setWinner(winner);
		end();
	}

    // ----------------------------------------------------
	// ScoreTracker informs here when max score has been reached
	void maxScoreReached(int winner) {
		_log("max score reached");

		if (m_gameTimer !is null) {
			m_gameTimer.cancel();
		}

		setWinner(winner);
		end();
	}

    // ----------------------------------------------------
	protected void addScore(int factionId) {
		m_scoreTracker.addScore(factionId);

		if (m_gameTimer !is null) {
			// GameTimer controls who wins if time runs out, refresh it each time score changes
			m_gameTimer.setWinningTeam(m_scoreTracker.getWinningTeam());
		}
	}

	// --------------------------------------------
	// track for player kill events
	void handlePlayerKillEvent(const XmlElement@ event) {
		if (!m_trackKills) {
			return;
		}
		_log("handle_player_kill_event");

		array<const XmlElement@> elements = event.getElementsByTagName("killer");
		if (elements.length() > 0) {
			const XmlElement@ element = elements[0];
			int factionId = element.getIntAttribute("faction_id");
			_log("player scores: " + element.getStringAttribute("name") + ", faction " + factionId);

			addScore(factionId);
		}
	}

	// --------------------------------------------
	// actually, track die events, this way we get bot.player kills too counted, yet player.bot kills don't get counted
	void handlePlayerDieEvent(const XmlElement@ event) {
		if (m_trackKills) {
			return;
		}
		if (hasEnded()) { // do not add scores if match is over
			return;
		}
		_log("handle_player_die_event");

		array<const XmlElement@> elements = event.getElementsByTagName("target");
		if (elements.length() > 0) {
			const XmlElement@ element = elements[0];
			int factionId = element.getIntAttribute("faction_id");

			// this only works with 2 factions!
			// flip between 0 and 1

			int scorer = factionId == 0 ? 1 : 0;
			addScore(scorer);
		}
	}
}