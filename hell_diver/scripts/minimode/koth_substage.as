#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"

#include "stage_minimodes.as"

#include "timed_round_tracker.as"

// --------------------------------------------
class KothSubStage : SubStage {
	// - team who occupies the given base when the timer runs out, wins
	// - timer is reset whenever a team captures the given base
	// (most of it is handled by the defense timer thing in the game)
	protected string m_captureTargetBase = "";
	protected float m_defenseTime = 10.0;

	// --------------------------------------------
	KothSubStage(Stage@ stage, string captureTargetBase, float defenseTime, float maxTime = -1.0) {
		super(stage);

		m_name = "koth";
		m_displayName = "King of the hill";

		m_captureTargetBase = captureTargetBase;
		m_defenseTime = defenseTime;

		// the trackers get added into active tracking at SubStage::start()
		if (maxTime > 0.0) {
			addTracker(TimedRoundTracker(m_metagame, this, maxTime));
		}
	}

	// --------------------------------------------
	void startMatch() {
		// use match defense win time to provide solution for winning by defense
		m_match.m_defenseWinTime = m_defenseTime;

		// set all bases uncapturable, except the capture target base
		{
			array<const XmlElement@> bases = getBases(m_metagame);
			for (uint i = 0; i < bases.length(); ++i) {
				const XmlElement@ base = bases[i];
				
				string baseKey = base.getStringAttribute("key");
				int capturable = 0;
				if (baseKey.toLowerCase() == m_captureTargetBase.toLowerCase()) {
					capturable = 1;
				}
				string command = "<command class='update_base' base_key='" + baseKey + "' capturable='" + capturable + "' />";
				m_metagame.getComms().send(command);
			}
		}

		// start match, neutral is expected to hold the target base
		SubStage::startMatch();
	}

    // ----------------------------------------------------
	// TimedRoundTracker informs here when time's up
	void onTimeExpired() {
		_log("time expired");

		// query who was winning
		const XmlElement@ general = getGeneralInfo(m_metagame);
		if (general !is null) {
			int winner = general.getIntAttribute("match_winner");
			setWinner(winner);
		}

		// end the stage
		end();
	}

	// --------------------------------------------
	protected void handleMatchEndEvent(const XmlElement@ event) {
		int winner = -1; // equals tie

		array<const XmlElement@> elements = event.getElementsByTagName("win_condition");
		if (elements.length() >= 1) {
			const XmlElement@ winCondition = elements[0];
			winner = winCondition.getIntAttribute("faction_id");
		} else {
			_log("WARNING, couldn't find win_condition tag", -1);
		}

		setWinner(winner);

		end();
	}
}