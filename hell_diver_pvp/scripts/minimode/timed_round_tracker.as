#include "tracker.as"
#include "log.as"
#include "helpers.as"

// --------------------------------------------
// helper tracker used to track time for ending a substage round
// --------------------------------------------
class TimedRoundTracker : Tracker {
	protected Metagame@ m_metagame;
	protected KothSubStage@ m_substage;
	protected float m_maxTime = 60.0;
	protected float m_timeLeft = 0.0;

    	// ----------------------------------------------------
	TimedRoundTracker(Metagame@ metagame, KothSubStage@ substage, float maxTime) {
		@m_metagame = @metagame;
		@m_substage = @substage;
		m_maxTime = maxTime;
		m_timeLeft = maxTime;
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
		if (m_timeLeft >= 0.0) {
			m_timeLeft -= time;
			if (m_timeLeft < 0.0) {
				m_substage.onTimeExpired();
			}
		}
	}

	// ----------------------------------------------------
	// debugging tools
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

   		if (checkCommand(message, "time")) {
			string text = m_timeLeft + " second(s)";
			sendPrivateMessage(m_metagame, senderId, text);			
		}

		if (!m_metagame.getAdminManager().isAdmin(sender, senderId)) {
			return;
		}

	}

}