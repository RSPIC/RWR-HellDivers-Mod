#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "all_helper.as"

//Author: RST
//support by NetherCrow
//感谢鸦鸦的代码支持


	// --------------------------------------------
		//建立关键字与index联系
dictionary SpawnAiIndex = {

		// 空
        {"",-1},

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
		{"Warlord",11},
		
		// 自动炮台:A-MG-11-mk3 HD
		{"amg_11_mk3_hd",12},
		// 自动炮台:A-MG-11-mk3 ACG阵营
		{"amg_11_mk3_acg",13},
		// 自动炮台:A-MG-11-mk2 HD
		{"amg_11_mk2_hd",14},
		// 自动炮台:A-MG-11-mk2 ACG阵营
		{"amg_11_mk2_acg",15},
		// 自动炮台:A-MG-11-mk1 HD
		{"amg_11_mk1_hd",16},
		// 自动炮台:A-MG-11-mk1 ACG阵营
		{"amg_11_mk1_acg",17},
		
		// 自动炮台:A-RX-34-mk3 HD
		{"arx_34_mk3_hd",18},
		// 自动炮台:A-RX-34-mk3 ACG阵营
		{"arx_34_mk3_acg",19},
		// 自动炮台:A-RX-34-mk2 HD
		{"arx_34_mk2_hd",20},
		// 自动炮台:A-RX-34-mk2 ACG阵营
		{"arx_34_mk2_acg",21},
		// 自动炮台:A-RX-34-mk1 HD
		{"arx_34_mk1_hd",22},
		// 自动炮台:A-RX-34-mk1 ACG阵营
		{"arx_34_mk1_acg",23}
		

};

class spawn_ai : Tracker {
	protected Metagame@ m_metagame;

	// --------------------------------------------
	spawn_ai(Metagame@ metagame) {
		@m_metagame = @metagame;
	}

	// --------------------------------------------
	protected void handleResultEvent(const XmlElement@ event) {
		_log("handleResultEvent");
		Vector3 PosSpawnProjectile = stringToVector3(event.getStringAttribute("position"));
		//checking if the event was triggered by a notify_script	
		string EventKeyGet = event.getStringAttribute("key");		//读取事件关键字
		

		// 调用方法 array<const XmlElement@>@ getFactions(const Metagame@ metagame) {
		// 调用方法 const XmlElement@ getFactionInfo(const Metagame@ metagame, int factionId)

		int CyborgsId = -1;
		int SuperEarthId = -1;
		int BugsId = -1;
		int IlluminateId = -1;
		int ACGId = -1;
		array<const XmlElement@> AllFactions = getFactions(m_metagame);	

		for (uint i = 0; i < AllFactions.size(); ++i) {
			const XmlElement@ Faction = AllFactions[i];
			uint faction_id = Faction.getIntAttribute("id");
			
			if (Faction.getStringAttribute("name")=="Cyborgs") {
				CyborgsId = faction_id;
			}else if(Faction.getStringAttribute("name")=="Super Earth"){
				SuperEarthId = faction_id;
			}else if(Faction.getStringAttribute("name")=="Bugs"){
				BugsId = faction_id;
			}else if(Faction.getStringAttribute("name")=="Illuminate"){
				IlluminateId = faction_id;
			}else if(Faction.getStringAttribute("name")=="ACG"){
				ACGId = faction_id;
			}
		}
		//_log("testing spawn ai");
		
		switch(int(SpawnAiIndex[EventKeyGet]))
		{
			case 0:{//生成Helldivers
				if(SuperEarthId == -1){break;}
				SpawnSoldier(m_metagame,1,SuperEarthId,PosSpawnProjectile,"default_ai");
				break;
			}
			case 1:{//生成 initiate 初始者	------------------------------------------
				if(CyborgsId == -1){break;}
				SpawnSoldier(m_metagame,1,CyborgsId,PosSpawnProjectile,"Initiate");
				break;
			}
			case 2:{//生成 squadleader 班长战士
				if(CyborgsId == -1){break;}
				SpawnSoldier(m_metagame,1,CyborgsId,PosSpawnProjectile,"Squadleader");
				break;
			}
			case 3:{//生成 berserker 狂暴者
				if(CyborgsId == -1){break;}
				SpawnSoldier(m_metagame,1,CyborgsId,PosSpawnProjectile,"Berserker");
				break;
			}
			case 4:{//生成 comrade 复合人
				if(CyborgsId == -1){break;}
				SpawnSoldier(m_metagame,1,CyborgsId,PosSpawnProjectile,"Comrade");
				break;
			}
			case 5:{//生成 grotesque 畸形人
				if(CyborgsId == -1){break;}
				SpawnSoldier(m_metagame,1,CyborgsId,PosSpawnProjectile,"Grotesque");
				break;
			}
			case 6:{//生成 hound 猎犬
				if(CyborgsId == -1){break;}
				SpawnSoldier(m_metagame,1,CyborgsId,PosSpawnProjectile,"Hound");
				break;
			}
			case 7:{//生成 butcher 屠夫
				if(CyborgsId == -1){break;}
				SpawnSoldier(m_metagame,1,CyborgsId,PosSpawnProjectile,"Butcher");
				break;
			}
			case 8:{//生成 legionnaire 军团士兵
				if(CyborgsId == -1){break;}
				SpawnSoldier(m_metagame,1,CyborgsId,PosSpawnProjectile,"Legionnaire");
				break;
			}
			case 9:{//生成 immolator 生化兵
				if(CyborgsId == -1){break;}
				SpawnSoldier(m_metagame,1,CyborgsId,PosSpawnProjectile,"Immolator");
				break;
			}
			case 10:{//生成 hulk 巨型者
				if(CyborgsId == -1){break;}
				SpawnSoldier(m_metagame,1,CyborgsId,PosSpawnProjectile,"Hulk");
				break;
			}
			case 11:{//生成 warlord 首领
				if(CyborgsId == -1){break;}
				SpawnSoldier(m_metagame,1,CyborgsId,PosSpawnProjectile,"Warlord");
				break;
			}
			case 12:{//自动炮台：A-MG-11-mk3	------------------------------------------
				if(SuperEarthId == -1){break;}
				SpawnSoldier(m_metagame,1,SuperEarthId,PosSpawnProjectile,"amg_11_mk3_hd");
				break;
			}
			case 13:{//自动炮台：A-MG-11-mk3
				if(ACGId == -1){break;}
				SpawnSoldier(m_metagame,1,ACGId,PosSpawnProjectile,"amg_11_mk3_acg");
				break;
			}
			case 14:{//自动炮台：A-MG-11-mk2
				if(SuperEarthId == -1){break;}
				SpawnSoldier(m_metagame,1,SuperEarthId,PosSpawnProjectile,"amg_11_mk2_hd");
				break;
			}
			case 15:{//自动炮台：A-MG-11-mk2
				if(ACGId == -1){break;}
				SpawnSoldier(m_metagame,1,ACGId,PosSpawnProjectile,"amg_11_mk2_acg");
				break;
			}
			case 16:{//自动炮台：A-MG-11-mk1
				if(SuperEarthId == -1){break;}
				SpawnSoldier(m_metagame,1,SuperEarthId,PosSpawnProjectile,"amg_11_mk1_hd");
				break;
			}
			case 17:{//自动炮台：A-MG-11-mk1
				if(ACGId == -1){break;}
				SpawnSoldier(m_metagame,1,ACGId,PosSpawnProjectile,"amg_11_mk1_acg");
				break;
			}
			case 18:{//自动炮台：A-RX-34-mk3	------------------------------------------
				if(SuperEarthId == -1){break;}
				SpawnSoldier(m_metagame,1,SuperEarthId,PosSpawnProjectile,"arx_34_mk3_hd");
				break;
			}
			case 19:{//自动炮台：A-RX-34-mk3
				if(ACGId == -1){break;}
				SpawnSoldier(m_metagame,1,ACGId,PosSpawnProjectile,"arx_34_mk3_acg");
				break;
			}
			case 20:{//自动炮台：A-RX-34-mk2
				if(SuperEarthId == -1){break;}
				SpawnSoldier(m_metagame,1,SuperEarthId,PosSpawnProjectile,"arx_34_mk2_hd");
				break;
			}
			case 21:{//自动炮台：A-RX-34-mk2
				if(ACGId == -1){break;}
				SpawnSoldier(m_metagame,1,ACGId,PosSpawnProjectile,"arx_34_mk2_acg");
				break;
			}
			case 22:{//自动炮台：A-RX-34-mk1
				if(SuperEarthId == -1){break;}
				SpawnSoldier(m_metagame,1,SuperEarthId,PosSpawnProjectile,"arx_34_mk1_hd");
				break;
			}
			case 23:{//自动炮台：A-RX-34-mk1
				if(ACGId == -1){break;}
				SpawnSoldier(m_metagame,1,ACGId,PosSpawnProjectile,"arx_34_mk1_acg");
				break;
			}

			
			default:{
				break;
			}
		}
	}
}