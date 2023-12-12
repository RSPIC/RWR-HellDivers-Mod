#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"

#include "stage_minimodes.as"

// --------------------------------------------
class WarmupSubStage : SubStage {
	protected int m_minimumPlayers = 2;

	// --------------------------------------------
	WarmupSubStage(Stage@ stage, int minimumPlayers) {
		super(stage);

		m_name = "warmup";
		m_displayName = "Warm up";

		m_minimumPlayers = minimumPlayers;
	}

	// ----------------------------------------------------
	protected void announce(string text) {
		// using a direct console command here
		sendFactionMessage(m_metagame, -1, text);
	}

	// ----------------------------------------------------
	void startMatch() {
		SubStage::startMatch();

		checkPlayers();
	}

	// ----------------------------------------------------
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
		if (!m_metagame.getAdminManager().isAdmin(sender, senderId)) {
			return;
		}

		if (checkCommand(message, "start")) {
			// start happens by ending this substage
			end();
		}
	}

	// ----------------------------------------------------
	protected void checkPlayers() {
		// get player count
		int players = getPlayerCount(m_metagame);
		if (players >= m_minimumPlayers) {
			announce(players + " players in, warm up is over, about to begin");
			end();
		} else {
			int diff = m_minimumPlayers - players;
			announce(players + " players in, " + diff + " needed to begin");
		}
	}

	// ----------------------------------------------------
	protected void handlePlayerConnectEvent(const XmlElement@ event) {
		checkPlayers();
	}
}