#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "all_helper.as"
#include "all_parameter.as"

#include "INFO.as"
#include "debug_reporter.as"
#include "math.as"

//author：rst
//抽奖脚本
//十连保底
//百连井
//功能性道具
//命运硬币

class lotteryInfo {
    protected string m_name;
    protected dictionary m_lotteryCount;

}

class lottery_manager : Tracker {
    protected Metagame@ m_metagame;

    lottery_manager(Metagame@ metagame){    
        @m_metagame = @metagame;
    }

    void start(){
    }

    void update(float time) {
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
    // --------------------------------------------
    protected void handleResultEvent(const XmlElement@ event) {
       
    }
    // --------------------------------------------
    protected void handleItemDropEvent(const XmlElement@ event) {
        handleFunctionalItemsEvent(event);
        handleFateCoinEvent(event);
    }

    // --------------------------------------------
    protected void handleFunctionalItemsEvent(const XmlElement@ event) {
        string itemKey = event.getStringAttribute("item_key");
        int pid = event.getIntAttribute("player_id");
        int cid = event.getIntAttribute("character_id");
        if(cid == -1){return;}
        int containerId = event.getIntAttribute("target_container_type_id");
        if(containerId != 1){return;}// 1(军械库)
        string name = g_playerInfoBuck.getNameByPid(pid);
        if(name == ""){return;}
        array<string> targetKey = {"hd_bonusfactor_al_","hd_bonusfactor_xp_","hd_bonusfactor_rp_"};
        for(uint i = 0 ; i < targetKey.size() ; ++i){
            string tempKey = itemKey.substr(0,targetKey[i].length());
            if(tempKey == targetKey[i]){
                string num = itemKey.substr(targetKey[i].size());
                if(isNumeric(num)){
                    float bonusFactor = 0.01*parseFloat(num);
                    if(i == 0){
                        g_battleInfoBuck.addBonusFactor(name,bonusFactor);
                    }else if(i == 1){
                        g_battleInfoBuck.addBonusFactorXp(name,bonusFactor);
                    }else if(i == 2){
                        g_battleInfoBuck.addBonusFactorRp(name,bonusFactor);
                    }
                    if(g_firstUseInfoBuck.isFirst(name,"hd_bonusfactor")){
                        notify(m_metagame,"The bonus has taken effect", dictionary(), "misc", pid, false, "", 1.0);
                    }else{
                        notify(m_metagame,"The bonus can only be applied once", dictionary(), "misc", pid, false, "", 1.0);
                        addItemInBackpack(m_metagame,cid,"carry_item",itemKey);
                    }
                }
            }
        }
    } 
    // --------------------------------------------
    protected void handleFateCoinEvent(const XmlElement@ event) {
        string itemKey = event.getStringAttribute("item_key");
        int containerId = event.getIntAttribute("target_container_type_id");
        if(containerId != 1){return;}// 1(军械库)
        if(itemKey != "fate_coin.carry_item"){return;}
        int pid = event.getIntAttribute("player_id");
        int cid = event.getIntAttribute("character_id");
        string name = g_playerInfoBuck.getNameByPid(pid);
    }
}