#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "all_helper.as"

dictionary stratagems_call_notify_key = {

        // 空
        {"",0},

        {"squadleader_cyborg",1},

        // 占位的
        {"666",-1}
};

dictionary stratagems_call_vehicle_key = {

        // 空
        {"",0},

        {"cyborgs_spawn_berserker_model.vehicle",1}, // 狂暴者

        // 占位的
        {"666",-1}
};

class stratagems_call : Tracker {
	protected Metagame@ m_metagame;

	// --------------------------------------------
	stratagems_call(Metagame@ metagame) {
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

        if (!(stratagems_call_notify_key.exists(EventKeyGet))){
			return;        
		}

		switch(int(stratagems_call_notify_key[EventKeyGet])) 
        {
            case 0: {break;}

            case 1: {
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId); // 1q
                if (character !is null) {
                    Vector3 pos = stringToVector3(event.getStringAttribute("position"));
                    int factionid = character.getIntAttribute("faction_id");
                    Vector3 pos_offset = Vector3(0,20,0); //这里修改高度偏移
                    pos=pos.add(pos_offset);
                    Orientation m_rotate = Orientation(0,1,0,0);
                    spawnVehicle(m_metagame,1,factionid,getRandomOffsetVector(pos,2,2),m_rotate,"cyborgs_spawn_berserker_model.vehicle"); //生成载具 消耗1c资源
                    spawnVehicle(m_metagame,1,factionid,getRandomOffsetVector(pos,3),m_rotate,"cyborgs_spawn_berserker_model.vehicle"); //生成载具 消耗1c资源

                    spawnStaticProjectile(m_metagame,"cyborgs_dropping_sound.projectile",pos,characterId,factionid); 
                    //生成音效弹头 1c

                    // playSoundAtLocation();
                    //随机生成池 先用rand写，后续再做模块化
                }
            }

            default:{
                break;
            }
        }
    }

}