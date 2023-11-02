// internal
#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"

#include "stage_minimodes.as"

//include_once("timed_round_tracker.php");
#include "game_timer.as"



// --------------------------------------------
class QuickMatchSubStage : SubStage {
	protected GameTimer@ m_gameTimer;

	// --------------------------------------------
	QuickMatchSubStage(Stage@ stage, float maxTime = -1.0) {
		super(stage);

		m_name = "quickmatch";
		m_displayName = "Match";

		// the trackers get added into active tracking at SubStage::start()
		if (maxTime > 0.0) {
			//$this->add_tracker(new TimedRoundTracker($this->metagame, $this, $max_time));
			@m_gameTimer = GameTimer(m_metagame, maxTime);
		}
	}

	// --------------------------------------------
	void startMatch() {
		if (m_gameTimer !is null) {
			// if GameTimer is used, some match settings must be set accordingly before starting the match
			m_gameTimer.prepareMatch(m_match);
		}

		SubStage::startMatch();

		if (m_gameTimer !is null) {
			m_gameTimer.start(-1);
		}
	}

	// track number of bases owned by factions; any of the competing factions owning more than the rest, will be the winning team if timer ends
	// --------------------------------------------
	protected void handleBaseOwnerChangeEvent(const XmlElement@ event) {
        array<const XmlElement@>@ bases = getBases(m_metagame);
		
        if (bases !is null) {
			array<int> factionBases;
			for (uint i = 0; i < m_match.m_factions.length(); ++i) {
				Faction@ faction = m_match.m_factions[i];
				if (faction.isNeutral()) {
					factionBases.insertLast(-1);
				} else {
					factionBases.insertLast(0);
				}
			}

			for (uint i = 0; i < bases.length(); ++i) {
				const XmlElement@ base = bases[i];
				int factionId = base.getIntAttribute("owner_id");
				int capturable = base.getIntAttribute("capturable");
				if (capturable != 0) {
					int value = factionBases[factionId];
					if (value >= 0) {
						factionBases[factionId] = value + 1;
					}
				}
			}

			int maxBases = 0;
			int factionIdWithMaxBases = -1;
			bool tie = false;
			for (uint i = 0; i < factionBases.length(); ++i) {
				int basesCount = factionBases[i];
				if (basesCount > maxBases) {
					maxBases = basesCount;
					factionIdWithMaxBases = i;
					tie = false;
				} else if (basesCount > 0 && basesCount == maxBases) {
					tie = true;
				}
			}

			if (factionIdWithMaxBases >= 0) {
				m_gameTimer.setWinningTeam(tie ? -1 : factionIdWithMaxBases);
			}
        }
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