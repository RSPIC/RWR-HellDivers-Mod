#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"

//Author: RST
//support by NetherCrow
//感谢鸦鸦的代码支持


	// --------------------------------------------
		//建立关键字与index联系
dictionary SpawnAiIndex = {

        // Helldivers
        {"Helldivers",0},
		
		// 生化人：initiate 初始者
		{"Initiate",1},
		
		// 生化人：squadleader 班长战士
		{"Squadleader",2},
		
		// 生化人：berserker 狂暴者
		{"Berserker",3},
		
		// 生化人：comrade 复合人
		{"Comrade",4},
		
		// 生化人：grotesque 畸形人
		{"Grotesque",5},
		
		// 生化人：hound 猎犬
		{"Hound",6},
		
		// 生化人: butcher 屠夫
		{"Butcher",7},
		
		// 生化人：legionnaire 军团士兵
		{"Legionnaire",8},
		
		// 生化人：immolator 生化兵
		{"Immolator",9},
		
		// 生化人：hulk 巨型者
		{"Hulk",10},
		
		// 生化人：warlord 首领
		{"Warlord",11}

};
	// --------------------------------------------
void SpawnSoldier(Metagame@ metagame, uint count, uint factionId, Vector3 position, string instanceKey) {	//copy from GFLhelpers.as
	for (uint i = 0; i < count; ++i) {
		metagame.getComms().send(
		"<command " +
		" class='create_instance' " + 
		" faction_id='" + factionId + "' " +
		" position='" + position.toString() + "' " + 
		" offset='0 0 0' " +
		" instance_class='soldier' " + 
		" instance_key='" + instanceKey + "'> " + 
		"</command>");
	}
}
	// --------------------------------------------
class spawn_ai : Tracker {
	protected Metagame@ m_metagame;

	// --------------------------------------------
	spawn_ai(Metagame@ metagame) {
		@m_metagame = @metagame;
	}

	// --------------------------------------------
	protected void handleResultEvent(const XmlElement@ event) {
		_log("handleResultEvent");
		//checking if the event was triggered by a notify_script	
		string EventKeyGet = event.getStringAttribute("key");		//读取事件关键字
		// 调用方法 array<const XmlElement@>@ getFactions(const Metagame@ metagame) {
		// 调用方法 const XmlElement@ getFactionInfo(const Metagame@ metagame, int factionId)
	
		array<const XmlElement@> AllFactions = getFactions(m_metagame);	


		switch(int(SpawnAiIndex[EventKeyGet]))
		{
			case 0:{//生成Helldivers
				Vector3 PosSpawnProjectile = stringToVector3(event.getStringAttribute("position"));
				_log("PosSpawnProjectile");
				//获取投掷物位置
				SpawnSoldier(m_metagame,1,0,PosSpawnProjectile,"default_ai");
				_log("spawn_success");
				break;
			}
			case 1:{//生成 initiate 初始者
				Vector3 PosSpawnProjectile = stringToVector3(event.getStringAttribute("position"));
				SpawnSoldier(m_metagame,1,1,PosSpawnProjectile,"Initiate");
				break;
			}
			case 2:{//生成 squadleader 班长战士
				Vector3 PosSpawnProjectile = stringToVector3(event.getStringAttribute("position"));
				SpawnSoldier(m_metagame,1,1,PosSpawnProjectile,"Squadleader");
				break;
			}
			case 3:{//生成 berserker 狂暴者
				Vector3 PosSpawnProjectile = stringToVector3(event.getStringAttribute("position"));
				SpawnSoldier(m_metagame,1,1,PosSpawnProjectile,"Berserker");
				break;
			}
			case 4:{//生成 comrade 复合人
				Vector3 PosSpawnProjectile = stringToVector3(event.getStringAttribute("position"));
				SpawnSoldier(m_metagame,1,1,PosSpawnProjectile,"Comrade");
				break;
			}
			case 5:{//生成 grotesque 畸形人
				Vector3 PosSpawnProjectile = stringToVector3(event.getStringAttribute("position"));
				SpawnSoldier(m_metagame,1,1,PosSpawnProjectile,"Grotesque");
				break;
			}
			case 6:{//生成 hound 猎犬
				Vector3 PosSpawnProjectile = stringToVector3(event.getStringAttribute("position"));
				SpawnSoldier(m_metagame,1,1,PosSpawnProjectile,"Hound");
				break;
			}
			case 7:{//生成 butcher 屠夫
				Vector3 PosSpawnProjectile = stringToVector3(event.getStringAttribute("position"));
				SpawnSoldier(m_metagame,1,1,PosSpawnProjectile,"Butcher");
				break;
			}
			case 8:{//生成 legionnaire 军团士兵
				Vector3 PosSpawnProjectile = stringToVector3(event.getStringAttribute("position"));
				SpawnSoldier(m_metagame,1,1,PosSpawnProjectile,"Legionnaire");
				break;
			}
			case 9:{//生成 immolator 生化兵
				Vector3 PosSpawnProjectile = stringToVector3(event.getStringAttribute("position"));
				SpawnSoldier(m_metagame,1,1,PosSpawnProjectile,"Immolator");
				break;
			}
			case 10:{//生成 hulk 巨型者
				Vector3 PosSpawnProjectile = stringToVector3(event.getStringAttribute("position"));
				SpawnSoldier(m_metagame,1,1,PosSpawnProjectile,"Hulk");
				break;
			}
			case 11:{//生成 warlord 首领
				Vector3 PosSpawnProjectile = stringToVector3(event.getStringAttribute("position"));
				SpawnSoldier(m_metagame,1,1,PosSpawnProjectile,"Warlord");
				break;
			}
			
			default:{
				break;
			}
		}
	}
}