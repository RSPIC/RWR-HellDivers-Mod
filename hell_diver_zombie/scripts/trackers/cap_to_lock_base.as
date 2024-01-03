#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "all_helper.as"
#include "all_parameter.as"
#include "debug_reporter.as"
#include "INFO.as"
//Author:RST
//占领后强制锁定据点

class cap_to_lock_base : Tracker {
	protected Metagame@ m_metagame;
	protected bool m_locked = false;
	// --------------------------------------------
	cap_to_lock_base(Metagame@ metagame) {
		@m_metagame = @metagame;
		
	}
	// --------------------------------------------
    bool hasEnded() const{
		return false;
    }
	// --------------------------------------------
	bool hasStarted() const {
		// always on
		return true;
	}
	protected void handleBaseOwnerChangeEvent(const XmlElement@ event) {
		int previous_owner_id = event.getIntAttribute("previous_owner_id"); 
		int owner_id = event.getIntAttribute("owner_id"); 
		int base_id = event.getIntAttribute("base_id"); 
		bool was_attack_target = event.getBoolAttribute("was_attack_target"); 
		string base_key = event.getStringAttribute("base_key"); 
		if(previous_owner_id != 0 && owner_id == 0){
			string command = "<command class='update_base' base_key='" + base_key + "' capturable='0' />";
			m_metagame.getComms().send(command);
		}
	}
	protected void handlePlayerSpawnEvent(const XmlElement@ event) {
		if(!m_locked){
			lockAllMyBase();
		}
	}
	protected void lockAllMyBase(){
		array<const XmlElement@> bases = getBases(m_metagame);
		for (uint i = 0; i < bases.size(); ++i) {
			const XmlElement@ base = bases[i];
			int owner_id = base.getIntAttribute("owner_id");
			if(owner_id == 0){
				string base_key = base.getStringAttribute("key"); 
				string command = "<command class='update_base' base_key='" + base_key + "' capturable='0' />";
				m_metagame.getComms().send(command);
			}
		}
		m_locked = true;
		_log("locked all bases");
	}
}


