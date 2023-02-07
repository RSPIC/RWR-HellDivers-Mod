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
                    Orientation m_rotate = Orientation(0,1,0,float(rand(0,3.14)));
                    spawnVehicle(m_metagame,1,factionid,getRandomOffsetVector(pos,2,2),m_rotate,"cyborgs_spawn_berserker_model.vehicle"); //生成载具 消耗1c资源
                    spawnVehicle(m_metagame,1,factionid,getRandomOffsetVector(pos,3),m_rotate,"cyborgs_spawn_berserker_model.vehicle"); //生成载具 消耗1c资源

                    spawnStaticProjectile(m_metagame,"cyborgs_dropping_sound.projectile",pos,characterId,factionid); 
                    //生成音效弹头 1c

                    // playSoundAtLocation();
                    //随机生成池 先用rand写，后续再做模块化
                }
            }

            default:
                break;            
        }
    }

	protected void handleVehicleDestroyEvent(const XmlElement@ event) {
		string EventKeyGet = event.getStringAttribute("vehicle_key");
		switch(int(stratagems_call_vehicle_key[EventKeyGet])) 
        {
            case 0: {break;}

            case 1: {
                int m_ownerid  = event.getIntAttribute("owner_id");
                Vector3 m_pos = stringToVector3(event.getStringAttribute("position"));
                const XmlElement@ m_faction = getFactionInfo(m_metagame,m_ownerid);
                if (m_faction !is null){
                    if (m_faction.getStringAttribute("name")=="Cyborgs") //验证阵营信息 消耗1q资源，这是保底，可以为了性能减少稳定性删除本if
                    {
                        SpawnSoldier(m_metagame,1,m_ownerid,m_pos,"Berserker"); //生成兵种 消耗1c资源
                    }
                }
            }

            default:
                break;            
        }
    }
    


}