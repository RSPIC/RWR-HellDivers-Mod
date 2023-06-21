#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "all_helper.as"

#include "debug_reporter.as"
#include "INFO.as"

//Author: RST

class spawn_ai : Tracker {
	protected GameModeInvasion@ m_metagame;
	protected bool m_ended;
	protected bool isStarted;
	protected Timer@ m_Timer = Timer();

	// --------------------------------------------
	spawn_ai(GameModeInvasion@ metagame) {
		@m_metagame = @metagame;
		_log("spawn_ai initiate.");
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
	void start(){
        m_ended = false;
		isStarted =false;
	}
	void update(float time){
		m_Timer.update(time);
	}

	protected void handleResultEvent(const XmlElement@ event) {
		// 空对象呼叫，无CID FID
		string EventKeyGet = event.getStringAttribute("key");	
		Vector3 PosSpawnProjectile = stringToVector3(event.getStringAttribute("position"));
		string Pos= event.getStringAttribute("position");
		if(g_factionInfoBuck.get(EventKeyGet)){
			int fid = g_factionInfoBuck.getFidByGroupName(EventKeyGet);
			SpawnSoldier(m_metagame,1,fid,PosSpawnProjectile,EventKeyGet);
			//_report(m_metagame,"DTIME="+m_Timer.endT());
		}
	}
}