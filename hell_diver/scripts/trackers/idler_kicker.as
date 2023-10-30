// internal
#include "gamemode.as"
#include "tracker.as"
#include "log.as"

// --------------------------------------------
class IdlerKicker : Tracker {
	protected GameMode@ m_metagame;

	protected float m_maxIdleTime;
	protected float m_timer;
	
	protected dictionary m_positions;

	protected bool m_readyToKick;
	protected float m_kickTimer;
	protected array<int> m_kickPidList;

	// --------------------------------------------
	IdlerKicker(GameMode@ metagame, float time = 300.0) {
		@m_metagame = @metagame;

		m_readyToKick = false;
		m_maxIdleTime = time;
		m_kickTimer = 60;
		m_timer = m_maxIdleTime;
	}
	
	// --------------------------------------------
	void update(float time) {
		m_timer -= time;
		if (m_timer < 0.0) {
			refresh();
			m_timer = m_maxIdleTime;
		}
		if(m_readyToKick){
			m_kickTimer -= time;
			if(m_kickTimer < 0.0){
				handelKick();
				m_readyToKick = false;
				m_kickTimer = 60;
			}
		}
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
	// --------------------------------------------
	protected void startKickCountDown(){
		m_readyToKick = true;
	}

	// --------------------------------------------
	protected void refresh() {
		//_debugReport(m_metagame,"refresh IdlerKicker");
		// query player positions
		if(g_server_difficulty_level != 3){
			array<const XmlElement@> players = getPlayers(m_metagame);
			for (uint i = 0; i < players.size(); ++i) {
				const XmlElement@ player = players[i];
				
				// ignore admins and mods
				string name = player.getStringAttribute("name");
				// if (m_metagame.getAdminManager().isAdmin(name) || 
				// 	m_metagame.getModeratorManager().isModerator(name)) {
				// 	continue;
				// }

				if (player.hasAttribute("character_id")) {
					const XmlElement@ character = getCharacterInfo(m_metagame, player.getIntAttribute("character_id"));
					if (character !is null) {
						string position = character.getStringAttribute("position");
						//_debugReport(m_metagame,"Position="+position);
						string oldPosition = "";
						// check if they're same as last time
						// if so, kick
						if (m_positions.get(name, oldPosition) && position == oldPosition) {
							int id = player.getIntAttribute("player_id");
							m_kickPidList.insertLast(id);
						} else {
							// store new position
							m_positions.set(name, position);
						}
					}
				}
			}
			handelPlayerConfirm();
		}
	}
	
	// ----------------------------------------------------
	protected void handlePlayerDisconnectEvent(const XmlElement@ event) {
		const XmlElement@ player = event.getFirstElementByTagName("player");
		if (player !is null) {
			string name = player.getStringAttribute("name");
			m_positions.delete(name);
		}		
	}	
	// ----------------------------------------------------
	protected void handleChatEvent(const XmlElement@ event) {
		string message = event.getStringAttribute("message");
		string playerName = event.getStringAttribute("player_name");
        int pid = event.getIntAttribute("player_id");
		if(message == "/live"){
            for(uint i = 0 ; i < m_kickPidList.size() ; ++i){
				int k_pid = m_kickPidList[i];
				if(k_pid == pid){
					m_kickPidList.removeAt(i);
					_notify(m_metagame,pid,"已确认，踢出请求取消");
					return;
				}
			}
        }
	}
	// ----------------------------------------------------
	protected void handelPlayerConfirm() {
		for(uint i = 0 ; i < m_kickPidList.size() ; ++i){
			int pid = m_kickPidList[i];
			_notify(m_metagame,pid,"检测到你在非[挂机服务器]有挂机行为,请在60秒内输入/live确认您的状况");
		}
		startKickCountDown();
	}
	// ----------------------------------------------------
	protected void handelKick(){
		for(uint i = 0 ; i < m_kickPidList.size() ; ++i){
			int pid = m_kickPidList[i];
			notify(m_metagame, "Kicked - Idling", dictionary(), "misc", pid, true, "Kicked from server", 1.0);
			kickPlayer(m_metagame, pid);
			string name = g_playerInfoBuck.getNameByPid(pid);
			g_battleInfoBuck.removeInfo(name);
		}
	}
}
