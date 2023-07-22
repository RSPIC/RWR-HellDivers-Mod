// internal
#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "gamemode_invasion.as"
#include "all_helper.as"
#include "task_sequencer.as"

#include "debug_reporter.as"
#include "INFO.as"

//author: rst
//各种检测工作脚本
//武器首次使用的教程检测
//机甲武器的搭配检测
//复活时板载护甲的检测
//首次进入服务器的教程提示(包括测试服)
//检测刺雷护甲的防止存放
//帕蒂武器充能检查和教程

//机甲武器替换护甲(左副手右主手)
dictionary EXO_Armor = {

        // 空
        {"",-1},

        {"hd_exo44_walker_mk3_mg.weapon","hd_exo44_walker_mk3_missile.weapon"},
        {"hd_exo44_walker_mk3_missile.weapon","hd_exo44_walker_mk3_mg.weapon"},
        {"hd_exo48_obsidian_mk3_cannon.weapon","hd_exo48_obsidian_mk3_cannon_main.weapon"},
        {"hd_exo51_lumberer_mk3_cannon.weapon","hd_exo51_lumberer_mk3_flame.weapon"},
        {"hd_exo51_lumberer_mk3_flame.weapon","hd_exo51_lumberer_mk3_cannon.weapon"},

        // 占位的
        {"666",-1}

};


class schedule_Check : Tracker {
    protected Metagame@ m_metagame;
    protected float m_time;
    protected float m_timer;
    protected bool m_ended;

    schedule_Check(Metagame@ metagame,float time = 5){
        @m_metagame = @metagame;
        m_time = time;
        m_timer = m_time;
        _log("schedule_Check executing");
    }

    void start(){
        m_ended = false;
    }
    
    void update(float time){
        m_timer -= time;
        if(m_timer >0){return;}
        refresh();
        m_timer = m_time;
    }

    // --------------------------------------------
    bool hasEnded() const{
		return m_ended;
    }
	// --------------------------------------------
	bool hasStarted() const {
		// always on
		return true;
	}

    void refresh(){
        array<const XmlElement@> players = getPlayers(m_metagame);
        if(players is null){return;}
		for (uint j = 0; j < players.size(); ++j) {
			const XmlElement@ player = players[j];
			if(player is null){return;}
            if (player.hasAttribute("character_id")) {
                dictionary equipList;
                int cid = player.getIntAttribute("character_id");
                int fid = player.getIntAttribute("faction_id");
                int pid = player.getIntAttribute("player_id");
                string name = player.getStringAttribute("name");

                if(!getPlayerEquipmentInfoArray(m_metagame,cid,equipList)){
                    return;
                }

                Tutor_63type_107mm(m_metagame,name,pid,equipList);
                EXOArmorChange(m_metagame,name,pid,cid,equipList);
                checkBanzai(m_metagame,name,pid,equipList);
                checkPatricia(m_metagame,name,pid,cid,equipList);
            }
        }
    }
    // ----------------------------------------------------
    protected void handleMatchEndEvent(const XmlElement@ event) {
		m_ended = true;
    }
    // ----------------------------------------------------
	protected void handlePlayerSpawnEvent(const XmlElement@ event) {
		const XmlElement@ player = event.getFirstElementByTagName("player");
		if(player is null){return;}
		//int pid = player.getIntAttribute("player_id");
        int cid = player.getIntAttribute("character_id");
        string name = player.getStringAttribute("name");
        string equipKey = getPlayerEquipmentKey(m_metagame,cid,4);//护甲
        array<string> banKey = {"hd_banzai_"}; //指定护甲会被检测并卸下
        string targetVestKey = g_vestInfoBuck.getVestKey(name);
        for(uint i=0;i<banKey.length;i++){
            equipKey = equipKey.substr(0,banKey[i].length());//截取指定前缀并比对
            if(equipKey == banKey[i]){    
                editPlayerVest(m_metagame,cid,"helldivers_vest.carry_item",4);//替换为默认甲
            }
        }
        if(targetVestKey != equipKey){
            editPlayerVest(m_metagame,cid,targetVestKey,4);//替换为对应护甲
        }
        // 开局首次复活会记录玩家护甲信息,因此这里读取不到玩家的对应护甲,需要再次替换
        if(targetVestKey == ""){    
            editPlayerVest(m_metagame,cid,"helldivers_vest.carry_item",4);//替换为默认甲
        }
	}
    // ----------------------------------------------------
    protected void handlePlayerDisconnectEvent(const XmlElement@ event) {
    }
    // ----------------------------------------------------
    protected void handlePlayerConnectEvent(const XmlElement@ event) {
        const XmlElement@ player = event.getFirstElementByTagName("player");
        if(player is null){return;}
        int pid = player.getIntAttribute("player_id");
        if(!g_debugMode && !g_online_TestMode){
			gameHelp(m_metagame,pid);
        }
        if(g_online_TestMode){
            testHelp(m_metagame,pid);
        }
    }
    // ----------------------------------------------------
	protected void checkBanzai(Metagame@ metagame,string&in name,int&in pid,dictionary&in equipList){
		string equipKey;
        if(equipList.get("1",equipKey)){//副手武器
            if(equipKey == "ex_cl_banzai.weapon" ){
                if(g_firstUseInfoBuck.isFirst(name,equipKey)){
                    notify(metagame, "Help - Banzai", dictionary(), "misc", pid, true, "Banzai Help", 1.0);
                }
            }
        }
	}
    // ----------------------------------------------------
	protected void checkPatricia(Metagame@ metagame,string&in name,int&in pid,int&in cid,dictionary&in equipList){
        string equipKey;
        if(equipList.get("0",equipKey)){//主武器
            string targetKey = "acg_patricia_";
            equipKey = equipKey.substr(0,targetKey.length());
            if(equipKey == targetKey){
                if(g_firstUseInfoBuck.isFirst(name,equipKey)){
                    notify(metagame, "Help - Patricia", dictionary(), "misc", pid, true, "Patricia Help", 1.0);
                    deleteItemInBackpack(m_metagame,cid,"weapon","acg_patricia_fataldrive.weapon");
                    deleteItemInBackpack(m_metagame,cid,"weapon","acg_patricia_fataldrive.weapon");
                    deleteItemInBackpack(m_metagame,cid,"weapon","acg_patricia_fataldrive.weapon");
                    deleteItemInBackpack(m_metagame,cid,"weapon","acg_patricia_fataldrive.weapon");
                    deleteItemInBackpack(m_metagame,cid,"weapon","acg_patricia_fataldrive.weapon");
                    deleteItemInStash(m_metagame,cid,"weapon","acg_patricia_fataldrive.weapon");
                    deleteItemInStash(m_metagame,cid,"weapon","acg_patricia_fataldrive.weapon");
                    deleteItemInStash(m_metagame,cid,"weapon","acg_patricia_fataldrive.weapon");
                    deleteItemInStash(m_metagame,cid,"weapon","acg_patricia_fataldrive.weapon");
                    deleteItemInStash(m_metagame,cid,"weapon","acg_patricia_fataldrive.weapon");
                    addItemInBackpack(m_metagame,cid,"weapon","acg_patricia_fataldrive.weapon");
                    addItemInBackpack(m_metagame,cid,"weapon","acg_patricia_fataldrive.weapon");
                    addItemInBackpack(m_metagame,cid,"weapon","acg_patricia_fataldrive.weapon");
                    addItemInBackpack(m_metagame,cid,"weapon","acg_patricia_fataldrive.weapon");
                    addItemInBackpack(m_metagame,cid,"weapon","acg_patricia_fataldrive.weapon");
                }
            }
        }
	}
    // ----------------------------------------------------
	protected void Tutor_63type_107mm(Metagame@ metagame,string&in name,int&in pid,dictionary&in equipList){
		string equipKey;
        if(equipList.get("1",equipKey)){//副手武器
            if(equipKey == "63type_107mm_rocket_launcher_resource.weapon" ){
                if(g_firstUseInfoBuck.isFirst(name,equipKey)){
                    notify(metagame, "Help - 63Type 107mm", dictionary(), "misc", pid, true, "63Type 107mm Help", 1.0);
                }
            }
        }
	}
    // ----------------------------------------------------
	protected void EXOArmorChange(Metagame@ metagame,string&in name,int&in pid,int&in cid,dictionary&in equipList){
		//机甲检测
        if(m_ended){return;}
        string equipKey;    
        uint amount;

		string equipKey_main = "";
        equipList.get("0",equipKey_main);//主手武器
        if(!equipList.get(equipKey_main,amount) || amount == 0){
            equipKey_main = "";
        }

		string equipKey_sec = "";
        equipList.get("1",equipKey_sec);//副手武器
        if(!equipList.get(equipKey_sec,amount) || amount == 0){
            equipKey_sec = "";
        }
       
        string equipKey_vest = "";
        equipList.get("4",equipKey_vest);//护甲

		//slot: 0主手 1副手 2投掷物 4护甲
        string targetKey_main;
        string targetKey_sec;
        //主副手其中之一是否为机甲武器
		if(EXO_Armor.get(equipKey_sec,targetKey_main) || EXO_Armor.get(equipKey_main,targetKey_sec)){
            
			//检查是否为配套武器（主手对应副手、副手对应主手)
            //交叉检测，这样设计武器时不用考虑在主手还是在副手的问题
			if( equipKey_main == targetKey_main ||  equipKey_sec == targetKey_sec){
                //装载机甲护甲
				string key = "EXO_vest_";
				string tempKey = equipKey_vest.substr(0,key.length());
				if(tempKey != key){
					notify(metagame, "EXO Armor onload", dictionary(), "misc", pid, false, "", 1.0);
					editPlayerVest(metagame,cid,"EXO_vest_300",4);
					return;
				}
			}else{
				//非正常配装，发送警告
				notify(metagame, "Warning - EXO", dictionary(), "misc", pid, false, "EXO Warning", 1.0);
				editPlayerVest(metagame,cid,"hd_v40",4);//替换为0层甲
				return;
			}
		}else{ //卸下机甲
			string key = "EXO_vest_";
			string tempKey = equipKey_vest.substr(0,key.length());
			if(tempKey == key){
				editPlayerVest(metagame,cid,"helldivers_vest.carry_item",4);
				notify(metagame, "EXO Armor offload", dictionary(), "misc", pid, false, "", 1.0);
				return;
			}
		}
	}
    //---------------------------------------------------
    protected void handleChatEvent(const XmlElement@ event) {
		string message = event.getStringAttribute("message");
		if(message != "/help"){return;}
		int pid = event.getIntAttribute("player_id");
		gameHelp(m_metagame,pid);
	}
    protected void gameHelp(Metagame@ m_metagame,int pid){
		notify(m_metagame, "Help - Content", dictionary(), "misc", pid, true, "Tutor Help", 1.0);
		notify(m_metagame, "Help - Ammo Supply", dictionary(), "misc", pid, true, "Ammo Supply Help", 1.0);
		notify(m_metagame, "Help - Stratagems", dictionary(), "misc", pid, true, "Stratagems Help", 1.0);
		//notify(m_metagame, "Help - EX-1", dictionary(), "misc", pid, true, "Stratagems Help", 1.0);
		notify(m_metagame, "Help - Armor", dictionary(), "misc", pid, true, "Armor Help", 1.0);
		//notify(m_metagame, "Help - Samples", dictionary(), "misc", pid, true, "Samples Help", 1.0);
		notify(m_metagame, "Help - Alert", dictionary(), "misc", pid, true, "Alert Help", 1.0);
		//notify(m_metagame, "Help - Repair", dictionary(), "misc", pid, true, "Repair Help", 1.0);
		//notify(m_metagame, "Help - EXO", dictionary(), "misc", pid, true, "EXO Help", 1.0);
		notify(m_metagame, "Help - Cyborgs", dictionary(), "misc", pid, true, "Cyborgs Help", 1.0);
		notify(m_metagame, "Help - Bugs", dictionary(), "misc", pid, true, "Bugs Help", 1.0);
		//notify(m_metagame, "Help - Reward", dictionary(), "misc", pid, true, "Reward Help", 1.0);
		//notify(m_metagame, "Help - Reward-2", dictionary(), "misc", pid, true, "Reward Help", 1.0);
		notify(m_metagame, "Help - Dynamic Alert", dictionary(), "misc", pid, true, "Dynamic Alert Help", 1.0);
		notify(m_metagame, "Help - Invite Friend", dictionary(), "misc", pid, true, "Invite Friend Help", 1.0);
		notify(m_metagame, "Help - Vote", dictionary(), "misc", pid, true, "Vote Help", 1.0);
		notify(m_metagame, "Help - TK", dictionary(), "misc", pid, true, "TK Help", 1.0);
		notify(m_metagame, "Help - BattleReward", dictionary(), "misc", pid, true, "BattleReward Help", 1.0);
	}
	protected void testHelp(Metagame@ m_metagame,int pid){
		notify(m_metagame, "Help - TestServer", dictionary(), "misc", pid, true, "Testing Help", 1.0);
	}
    //---------------------------------------------------
    protected void handleItemDropEvent(const XmlElement@ event){
        string itemKey = event.getStringAttribute("item_key");
        int containerId = event.getIntAttribute("target_container_type_id");
        if(g_debugMode){
            _report(m_metagame,"物品"+itemKey+"进入了"+containerId+"容器");
        }
        if(containerId == 3 || containerId == 2){//仓库或者背包
				//1、防止利用刺雷护甲脚本BUG存放冲锋护甲
		        int characterId = event.getIntAttribute("character_id");
				array<string> vest_key = {"hd_banzai_","hd_v"}; //指定护甲
				for(uint i=0; i<vest_key.length; i++){
					string targetKey = itemKey.substr(0,vest_key[i].length());//截取指定前缀并比对
                    if(g_debugMode){
                        _report(m_metagame,"截取的key: "+targetKey);
                    }
					if(targetKey == vest_key[i]){  
				        deleteItemInBackpack(m_metagame,characterId,"carry_item",itemKey);
						deleteItemInStash(m_metagame,characterId,"carry_item",itemKey);
                        if(g_debugMode){
                            _report(m_metagame,"执行删除");
                        }
                        return;
					}
        		}
			}
    }
}