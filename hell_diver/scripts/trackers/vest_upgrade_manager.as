#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "gamemode_invasion.as"
#include "all_helper.as"

#include "debug_reporter.as"
#include "INFO.as"
#include "math.as"

//author: rst
//护甲升级、功能性道具脚本

class vest_upgrade_manager : Tracker {
    protected Metagame@ m_metagame;
    protected float m_time;
    protected float m_timer;
    protected bool m_ended;

    vest_upgrade_manager(Metagame@ metagame){
        @m_metagame = @metagame;
    }
    // --------------------------------------------
    void start(){
        m_ended = false;
    }
    // --------------------------------------------
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
    protected void handleItemDropEvent(const XmlElement@ event) {
        handleVestUpgradeEvent(event);
    }
    // ----------------------------------------------------
	protected void handleMatchEndEvent(const XmlElement@ event) {
		m_ended = true;
	}
    // --------------------------------------------
    protected void handleVestUpgradeEvent(const XmlElement@ event) {
        int pid = event.getIntAttribute("player_id");
        string itemKey = event.getStringAttribute("item_key");
        int characterId = event.getIntAttribute("character_id");
		if(characterId == -1){return;}
        if(g_vestInfoBuck is null){return;}
        if(g_playerInfoBuck is null){return;}
        string name = g_playerInfoBuck.getNameByCid(characterId);
        int containerId = event.getIntAttribute("target_container_type_id");

        array<string> targetKey = {
            "hd_v_upgrade_speed",
            "hd_v_upgrade_armor",
            "hd_v_upgrade_auto_recover",
            "hd_v_upgrade_stratagems_first",
            "hd_v_upgrade_auto_heal",
            "hd_v_upgrade_clear",
            "hd_v_upgrade_impactGl",
            "hd_v_upgrade_Needle"
        };
        array<array<string>> vestListKey = {
            {
                "helldivers_vest",
                "hd_v_speed+",
                "hd_v_speed++",
                "hd_v_speed+++"
            },
            {
                "hd_v_armor+",
                "hd_v_armor+speed+",
                "hd_v_armor+speed++"
            },
            {
                "hd_v_armor++",
                "hd_v_armor++speed+"
            },
            {
                "hd_v_armor+++"
            }
        };
        for(uint i=0; i<targetKey.length(); ++i){
            if(itemKey == targetKey[i]){
                if(m_ended){
                    notify(m_metagame,"Battle Over", dictionary(), "misc", pid, false,"", 1.0);
                    return;
                }
                const XmlElement@ character = getCharacterInfo(m_metagame,characterId);
                if(character is null){return;}
                int rp = character.getIntAttribute("rp");
                uint upgradeTime = g_vestInfoBuck.upgradeTime(name);
                if(upgradeTime >= 3){
                    notify(m_metagame,"Up to Upgrade Limit", dictionary(), "misc", pid, false,"", 1.0);
                }
                if(i==0){
                    if((upgradeTime == 0 && rp < 10000)
                    || (upgradeTime == 1 && rp < 30000)
                    || (upgradeTime == 2 && rp < 70000)
                    ){
                        notify(m_metagame,"Insufficient Rp", dictionary(), "misc", pid, false,"", 1.0);
                        deleteItemInBackpack(m_metagame,characterId,"carry_item",itemKey);
                        return;
                    }
                    g_vestInfoBuck.upgradeSpeed(name);
                    if(upgradeTime == 0){GiveRP(m_metagame,characterId,-10000);}
                    if(upgradeTime == 1){GiveRP(m_metagame,characterId,-30000);}
                    if(upgradeTime == 2){GiveRP(m_metagame,characterId,-70000);}
                }else if(i==1){
                    if((upgradeTime == 0 && rp < 10000)
                    || (upgradeTime == 1 && rp < 30000)
                    || (upgradeTime == 2 && rp < 70000)
                    ){
                        notify(m_metagame,"Insufficient Rp", dictionary(), "misc", pid, false,"", 1.0);
                        deleteItemInBackpack(m_metagame,characterId,"carry_item",itemKey);
                        return;
                    }
                    g_vestInfoBuck.upgradeArmor(name);
                    if(upgradeTime == 0){GiveRP(m_metagame,characterId,-10000);}
                    if(upgradeTime == 1){GiveRP(m_metagame,characterId,-30000);}
                    if(upgradeTime == 2){GiveRP(m_metagame,characterId,-70000);}
                }else if(i==2){
                    bool state;
                    if(g_vestInfoBuck.setAutoRecover(name,state)){
                        if(state){
                            if(rp < 10000){
                                notify(m_metagame,"Insufficient Rp", dictionary(), "misc", pid, false,"", 1.0);
                                return;
                            }
                            notify(m_metagame,"AutoRecover Set", dictionary(), "misc", pid, false,"", 1.0);
                            GiveRP(m_metagame,characterId,-10000);
                        }else{
                            notify(m_metagame,"AutoRecover Remove", dictionary(), "misc", pid, false,"", 1.0);
                        }
                    }
                    deleteItemInBackpack(m_metagame,characterId,"carry_item",itemKey);
                    return;
                }else if(i==3){
                    uint priority;
                    if(g_vestInfoBuck.getStratagemsFirst(name) < 5){
                        if(rp < 5000){
                                notify(m_metagame,"Insufficient Rp", dictionary(), "misc", pid, false,"", 1.0);
                                deleteItemInBackpack(m_metagame,characterId,"carry_item",itemKey);
                                return;
                            }
                        g_vestInfoBuck.setStratagemsFirst(name,priority);
                        notify(m_metagame,"StratagemsPriority Upgrade "+priority, dictionary(), "misc", pid, false,"", 1.0);
                        GiveRP(m_metagame,characterId,-10000);
                    }else{
                        notify(m_metagame,"StratagemsPriority Upgrade to MAX", dictionary(), "misc", pid, false,"", 1.0);
                    }
                    deleteItemInBackpack(m_metagame,characterId,"carry_item",itemKey);
                    return;
                }else if(i==4){
                    bool state;
                    if(g_vestInfoBuck.setAutoHeal(name,state)){
                        if(state){
                            if(rp < 30000){
                                notify(m_metagame,"Insufficient Rp", dictionary(), "misc", pid, false,"", 1.0);
                                deleteItemInBackpack(m_metagame,characterId,"carry_item",itemKey);
                                return;
                            }
                            notify(m_metagame,"AutoHeal Set", dictionary(), "misc", pid, false,"", 1.0);
                            GiveRP(m_metagame,characterId,-30000);
                        }else{
                            notify(m_metagame,"AutoHeal Remove", dictionary(), "misc", pid, false,"", 1.0);
                        }
                    }
                    deleteItemInBackpack(m_metagame,characterId,"carry_item",itemKey);
                    return;
                }else if(i==5){
                    if(g_vestInfoBuck.clearUpgrade(name)){
                        notify(m_metagame,"Vest Upgeade Clear", dictionary(), "misc", pid, false,"", 1.0);
                    }
                }else if(i==6){
                    bool state;
                    if(g_vestInfoBuck.setImpactGl(name,state)){
                        if(state){
                            if(rp < 10000){
                                notify(m_metagame,"Insufficient Rp", dictionary(), "misc", pid, false,"", 1.0);
                                deleteItemInBackpack(m_metagame,characterId,"carry_item",itemKey);
                                return;
                            }
                            notify(m_metagame,"ImpactGl Set", dictionary(), "misc", pid, false,"", 1.0);
                            GiveRP(m_metagame,characterId,-10000);
                        }else{
                            notify(m_metagame,"ImpactGl Remove", dictionary(), "misc", pid, false,"", 1.0);
                        }
                    }
                    deleteItemInBackpack(m_metagame,characterId,"carry_item",itemKey);
                    return;
                }else if(i==7){
                    bool state;
                    if(g_vestInfoBuck.setHealNeedle(name,state)){
                        if(state){
                            if(rp < 20000){
                                notify(m_metagame,"Insufficient Rp", dictionary(), "misc", pid, false,"", 1.0);
                                deleteItemInBackpack(m_metagame,characterId,"carry_item",itemKey);
                                return;
                            }
                            notify(m_metagame,"Needle Set", dictionary(), "misc", pid, false,"", 1.0);
                            GiveRP(m_metagame,characterId,-20000);
                        }else{
                            notify(m_metagame,"Needle Remove", dictionary(), "misc", pid, false,"", 1.0);
                        }
                    }
                    deleteItemInBackpack(m_metagame,characterId,"carry_item",itemKey);
                    return;
                }
                uint upgradeSpeedTimes = g_vestInfoBuck.upgradeSpeedTime(name);
                uint upgradeArmorTimes = g_vestInfoBuck.upgradeArmorTime(name);
                deleteItemInBackpack(m_metagame,characterId,"carry_item",itemKey);
                if(upgradeArmorTimes >= vestListKey.size()){
                    _log("upgradeSpeedTimes overflow");
                    return;
                }
                if(upgradeSpeedTimes >= vestListKey[upgradeArmorTimes].size()){
                     _log("upgradeArmorTimes overflow");
                    return;
                }
                string newVest = vestListKey[upgradeArmorTimes][upgradeSpeedTimes];
                g_vestInfoBuck.changeVest(name,newVest);
                editPlayerVest(m_metagame,characterId,newVest,4);
                notify(m_metagame,"Vest OnLoad", dictionary(), "misc", pid, false,"", 1.0);
            }
        }
    }
}