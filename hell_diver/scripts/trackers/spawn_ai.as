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
//support by NetherCrow
//感谢鸦鸦的代码支持


//实际代码中没用上，但是保留不删，万一要用
dictionary SpawnAiIndex = {

        // 空
        {"",0},
		
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
		{"arx_34_mk1_acg",23},

		// 地狱潜兵
		{"Helldivers",24},
		
		// 占位
		{"None",0}
		

};


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