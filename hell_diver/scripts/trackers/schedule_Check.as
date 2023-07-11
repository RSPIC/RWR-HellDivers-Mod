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
    protected array<first_use_info@> first_use_list;

    schedule_Check(Metagame@ metagame,float time = 4){
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
		for (uint j = 0; j < players.size(); ++j) {
			const XmlElement@ player = players[j];
			if(player is null){return;}
            if (player.hasAttribute("character_id")) {
                Tutor_63type_107mm(m_metagame,player);
                EXOArmorChange(m_metagame,player);
                checkBanzai(m_metagame,player);
                checkPatricia(m_metagame,player);
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
        // 开局首次复活会记录玩家护甲信息，因此这里读取不到玩家的对应护甲
        if(targetVestKey == ""){    
            editPlayerVest(m_metagame,cid,"helldivers_vest.carry_item",4);//替换为默认甲
        }
	}
    // ----------------------------------------------------
    protected void handlePlayerDisconnectEvent(const XmlElement@ event) {
        const XmlElement@ player = event.getFirstElementByTagName("player");
        if(player is null){return;}
        string name = player.getStringAttribute("name");
        for(uint i=0; i<first_use_list.size(); ++i){
            if(first_use_list[i].getName() == name){
                first_use_list.removeAt(i);
                --i;
            }
        }
    }
    // ----------------------------------------------------
    protected void handlePlayerConnectEvent(const XmlElement@ event) {
        const XmlElement@ player = event.getFirstElementByTagName("player");
        if(player is null){return;}
        string name = player.getStringAttribute("name");
        first_use_info@ newinfo = first_use_info(name);
        first_use_list.insertLast(newinfo);
        //注册首次使用列表

        int pid = player.getIntAttribute("player_id");
        if(!g_debugMode && !g_online_TestMode){
			gameHelp(m_metagame,pid);
        }
        if(g_online_TestMode){
            testHelp(m_metagame,pid);
        }
    }
    // ----------------------------------------------------
	protected void checkBanzai(Metagame@ metagame,const XmlElement@&in player){
		if(player is null){return;}
        string key = "ex_cl_banzai.weapon";
        string p_name = player.getStringAttribute("name");
        for(uint i=0; i<first_use_list.size(); ++i){

            int cid = player.getIntAttribute("character_id");
            string equipKey_sec = getPlayerEquipmentKey(metagame,cid,1);//副手武器
            if(equipKey_sec == "ex_cl_banzai.weapon" ){
                if(first_use_list[i].isFirst(p_name,key)){
                    int pid = player.getIntAttribute("player_id");
                    notify(metagame, "Help - Banzai", dictionary(), "misc", pid, true, "Banzai Help", 1.0);
                    //editPlayerVest(metagame,cid,"helldivers_vest.carry_item",4);//替换为默认甲，此处为防止过图卡脚本执行bug
                    //不在这里检测了，防止以后有其他护甲然后在这里被替换掉
                }
            }
        }
	}
    // ----------------------------------------------------
	protected void checkPatricia(Metagame@ metagame,const XmlElement@&in player){
		if(player is null){return;}
        string key = "acg_patricia_";
        string p_name = player.getStringAttribute("name");
        for(uint i=0; i<first_use_list.size(); ++i){
            int cid = player.getIntAttribute("character_id");
            string equipKey_main = getPlayerEquipmentKey(metagame,cid,0);//主武器
            if(key == equipKey_main.substr(0,key.length()) ){
                if(first_use_list[i].isFirst(p_name,key)){
                    int pid = player.getIntAttribute("player_id");
                    notify(metagame, "Help - Patricia", dictionary(), "misc", pid, true, "Patricia Help", 1.0);
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
	protected void Tutor_63type_107mm(Metagame@ metagame,const XmlElement@&in player){
		if(player is null){return;}
        string key = "63type_107mm_rocket_launcher_resource.weapon";
        string p_name = player.getStringAttribute("name");
        for(uint i=0; i<first_use_list.size(); ++i){
            int cid = player.getIntAttribute("character_id");
            string equipKey_sec = getPlayerEquipmentKey(metagame,cid,1);//副手武器
            if(equipKey_sec == "63type_107mm_rocket_launcher_resource.weapon" ){
                if(first_use_list[i].isFirst(p_name,key)){
                int pid = player.getIntAttribute("player_id");
                notify(metagame, "Help - 63Type 107mm", dictionary(), "misc", pid, true, "63Type 107mm Help", 1.0);
                }
            }
        }
	}
    // ----------------------------------------------------
	protected void EXOArmorChange(Metagame@ metagame,const XmlElement@&in player){
		if(m_ended){return;}
		if(player is null){return;}
		//机甲检测
		int pid = player.getIntAttribute("player_id");
		int cid = player.getIntAttribute("character_id");

		string equipKey_main = getPlayerEquipmentKey(metagame,cid,0);//主手武器
		int equipKey_main_amount = getPlayerEquipmentAmount(metagame,cid,0);//主手武器数量
		string equipKey_sec = getPlayerEquipmentKey(metagame,cid,1);//副手武器
		int equipKey_sec_amount = getPlayerEquipmentAmount(metagame,cid,1);//副手武器数量 
		//slot: 0主手 1副手 2投掷物 4护甲
		if(string(EXO_Armor[equipKey_sec]) != "" || string(EXO_Armor[equipKey_main]) != ""){
            string first_key = "63type_107mm_rocket_launcher_resource.weapon";
            string p_name = player.getStringAttribute("name");
            for(uint i=0; i<first_use_list.size(); ++i){
                if(first_use_list[i].isFirst(p_name,first_key)){
                    notify(metagame, "Help - EXO-2", dictionary(), "misc", pid, true, "EXO-Help", 1.0);
                    notify(metagame, "Help - EXO-3", dictionary(), "misc", pid, false, "EXO-Help", 1.0);
                }
            }
			
			//检查是否为配套武器（主手对应副手、副手对应主手)
			if( equipKey_main == string(EXO_Armor[equipKey_sec]) ||  equipKey_sec == string(EXO_Armor[equipKey_main]) ||
				string(EXO_Armor[equipKey_sec]) == "null" 		 ||  string(EXO_Armor[equipKey_main]) == "null"		
			){
				if(string(EXO_Armor[equipKey_sec]) == "null" ){
					if(equipKey_main_amount != 0){
						//非正常配装，发送警告
						notify(metagame, "Warning - EXO single", dictionary(), "misc", pid, false, "EXO Warning", 1.0);
						editPlayerVest(metagame,cid,"hd_v40",4);//替换为0层甲
						return;
					}
				}
				if(string(EXO_Armor[equipKey_main]) == "null" ){
					if(equipKey_sec_amount != 0){
						//非正常配装，发送警告
						notify(metagame, "Warning - EXO single", dictionary(), "misc", pid, false, "EXO Warning", 1.0);
						editPlayerVest(metagame,cid,"hd_v40",4);//替换为0层甲
						return;
					}
				}
				string equipKey_vest = getPlayerEquipmentKey(metagame,cid,4);//检查护甲
				string key = "EXO_vest_";
				equipKey_vest = equipKey_vest.substr(0,key.length());
				if(equipKey_vest != key){
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
			string equipKey_vest = getPlayerEquipmentKey(metagame,cid,4);//检查护甲
			string key = "EXO_vest_";
			equipKey_vest = equipKey_vest.substr(0,key.length());
			if(equipKey_vest == key){
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
		notify(m_metagame, "Help - EX-1", dictionary(), "misc", pid, true, "Stratagems Help", 1.0);
		notify(m_metagame, "Help - Armor", dictionary(), "misc", pid, true, "Armor Help", 1.0);
		//notify(m_metagame, "Help - Samples", dictionary(), "misc", pid, true, "Samples Help", 1.0);
		notify(m_metagame, "Help - Alert", dictionary(), "misc", pid, true, "Alert Help", 1.0);
		//notify(m_metagame, "Help - Repair", dictionary(), "misc", pid, true, "Repair Help", 1.0);
		//notify(m_metagame, "Help - EXO", dictionary(), "misc", pid, true, "EXO Help", 1.0);
		notify(m_metagame, "Help - Cyborgs", dictionary(), "misc", pid, true, "Cyborgs Help", 1.0);
		notify(m_metagame, "Help - Bugs", dictionary(), "misc", pid, true, "Bugs Help", 1.0);
		notify(m_metagame, "Help - Reward", dictionary(), "misc", pid, true, "Reward Help", 1.0);
		notify(m_metagame, "Help - Reward-2", dictionary(), "misc", pid, true, "Reward Help", 1.0);
		notify(m_metagame, "Help - Dynamic Alert", dictionary(), "misc", pid, true, "Dynamic Alert Help", 1.0);
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
				array<string> vest_key = {"hd_banzai_"}; //指定护甲
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