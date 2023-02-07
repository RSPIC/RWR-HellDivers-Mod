#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "all_helper.as"

dictionary projectile_eventkey = {

        // 空
        {"",-1},

        {"hd_superearth_airstrike_mk3",0},

        // 占位的
        {"666",-1}
};

class projectile_event : Tracker {
	protected Metagame@ m_metagame;

	// --------------------------------------------
	projectile_event(Metagame@ metagame) {
		@m_metagame = @metagame;
	}

	bool hasEnded() const {
		return false;
	}

	bool hasStarted() const {
		return true;
	}

	protected void handleResultEvent(const XmlElement@ event) {
		string EventKeyGet = event.getStringAttribute("key");
		switch(int(projectile_eventkey[EventKeyGet])) 
        {

            case 0: {
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId); // 1q
                if (character !is null) {
                    Vector3 pos1 = stringToVector3(event.getStringAttribute("position"));
                    Vector3 pos2 = stringToVector3(character.getStringAttribute("position"));
                    int factionid = character.getIntAttribute("faction_id");
                    Event_call_helldiver_superearth_airstrike@ new_task = Event_call_helldiver_superearth_airstrike(m_metagame,0.5,characterId,factionid,pos2,pos1,"airstrike_mk3");
                    TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                    tasker.add(new_task);
                }
            }

            default:
                break;            
        }
    }
}