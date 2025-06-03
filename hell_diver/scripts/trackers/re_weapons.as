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
//复活自带武器

class re_weapons : Tracker {
	protected Metagame@ m_metagame;
	protected bool m_ended;
	protected bool isStarted;

	// --------------------------------------------
	re_weapons(Metagame@ metagame) {
		@m_metagame = @metagame;
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
	}

	protected void handleItemDropEvent(const XmlElement@ event){
        string itemKey = event.getStringAttribute("item_key");
        if(!startsWith(itemKey,"acg_") && !startsWith(itemKey,"ex_")){
            return;
        }
        if(startsWith(itemKey,"ex_piano_") || startsWith(itemKey,"ex_gramophone_") || startsWith(itemKey,"ex_cl_") || startsWith(itemKey,"acg_ex_box")){
            return;
        }
        if(itemKey.find("_call") != -1){
            return;
        }
        int cid = event.getIntAttribute("character_id");
        if(cid == -1){return;}
        int pid = event.getIntAttribute("player_id");
		int containerId = event.getIntAttribute("target_container_type_id");
        string name = g_playerInfoBuck.getNameByPid(pid);

        //containerId = 0(地面) 1(军械库) 2（背包） 3（仓库）
		//itemClass = 0(主、副武器) 1（投掷物） 3（护甲、战利品）
        if(containerId == 1){
            dictionary equipList;
            if(!getPlayerEquipmentInfoArray(m_metagame,cid,equipList)){
                _report(m_metagame,"No information about what the player is carrying was obtained");
                return;
            }
            string equipKey = "";
            int equipNum = 0;
            string weapon_level = "";
            if(equipList.get("0",equipKey) && equipList.get(equipKey,equipNum)){//主武器
                if(equipNum == 0){// 主手为空 副手卖不掉情况
                    string equipKey2;
                    equipList.get("1",equipKey2);
                    if(itemKey != equipKey2){
                        return;
                    }
                }

                if(itemKey == equipKey){
                    if(g_firstUseInfoBuck.isFirst(name,itemKey+"re")){
                        notify(m_metagame, "Now in ReWeapon phase, sell 10 same type weapons while having ONE in your hand, and you can get ReWeapon which can respawn with.", dictionary(), "misc", pid, false, "", 1.0);
                        addItemInBackpack(m_metagame,cid,"weapon",itemKey);
                        return;
                    }
                    int value;
                    g_userCountInfoBuck.addCount(name,itemKey+"re");
                    g_userCountInfoBuck.getCount(name,itemKey+"re",value);
                    dictionary a;
                    a["%value"] = value;
                    notify(m_metagame, "Synthesis progress["+value+"/10]", a, "misc", pid, false, "", 1.0);
                                        
                    if(value >= 10){
                        addItemInBackpack(m_metagame,cid,"weapon","re_"+itemKey);
                        addItemInBackpack(m_metagame,cid,"weapon","re_"+itemKey);
                        g_userCountInfoBuck.clearCount(name,itemKey+"re");
                        notify(m_metagame, "Successed ReWeapon", dictionary(), "misc", pid, false, "", 1.0);
                    }
                    return;
                }else if("re_"+itemKey == equipKey && weaponLevel.get(itemKey,weapon_level)){ // 回收
                    int sell_price = 0;
                    if(weapon_level == "MK5"){
                        sell_price = 100;
                    }else if(weapon_level == "MK4"){
                        sell_price = 30;
                    }else if(weapon_level == "MK3"){
                        sell_price = 10;
                    }else if(weapon_level == "MK2"){
                        GiveRP(m_metagame,cid,30000);
                        notify(m_metagame, "Sell MK2 weapon for 30,000 rp", dictionary(), "misc", pid, false, "", 1.0);
                        return;
                    }else if(weapon_level == "MK1"){
                        GiveRP(m_metagame,cid,10000);
                        notify(m_metagame, "Sell MK1 weapon for 10,000 rp", dictionary(), "misc", pid, false, "", 1.0);
                        return;
                    }
                    g_userCountInfoBuck.addCount(name,"SuperCash",sell_price);
                    notify(m_metagame, "Sell "+weapon_level+" weapon for "+sell_price+" SuperCash", dictionary(), "misc", pid, false, "", 1.0);
                    return;
                }else{
                    if(equipNum != 0){
                        string equipKey2;
                        equipList.get("1",equipKey2);
                        if(itemKey != equipKey2 && "re_"+itemKey != equipKey2){// 主手为空 副手无法合成情况 && 副手回收
                            notify(m_metagame, "Risky operation: Your weapon has been returned. To synthesize a weapon, equip a weapon of the same mode in the weapon bar. If you need to sell weapons, keep the weapons bar empty", dictionary(), "misc", pid, false, "", 1.0);
                            addItemInBackpack(m_metagame,cid,"weapon",itemKey);
                            return;
                        }
                    }
                }
            }
            if(equipList.get("1",equipKey) && equipList.get(equipKey,equipNum)){//副武器
                if(equipNum == 0){return;}

                if(itemKey == equipKey){
                    if(g_firstUseInfoBuck.isFirst(name,itemKey+"re")){
                        notify(m_metagame, "Now in ReWeapon phase, sell 10 same type weapons while having ONE in your hand, and you can get ReWeapon which can respawn with.", dictionary(), "misc", pid, false, "", 1.0);
                        addItemInBackpack(m_metagame,cid,"weapon",itemKey);
                        return;
                    }
                    int value;
                    g_userCountInfoBuck.addCount(name,itemKey+"re");
                    g_userCountInfoBuck.getCount(name,itemKey+"re",value);
                    notify(m_metagame, "Synthesis progress"+"["+value+"/10]", dictionary(), "misc", pid, false, "", 1.0);

                    if(g_userCountInfoBuck.getCount(name,itemKey+"re",value) && value >= 10){
                        addItemInBackpack(m_metagame,cid,"weapon","re_"+itemKey);
                        addItemInBackpack(m_metagame,cid,"weapon","re_"+itemKey);
                        g_userCountInfoBuck.clearCount(name,itemKey+"re");
                        notify(m_metagame, "Successed ReWeapon", dictionary(), "misc", pid, false, "", 1.0);
                    }
                    return;
                }else if("re_"+itemKey == equipKey && weaponLevel.get(itemKey,weapon_level)){ // 回收
                    int sell_price = 0;
                    if(weapon_level == "MK5"){
                        sell_price = 100;
                    }else if(weapon_level == "MK4"){
                        sell_price = 32;
                    }else if(weapon_level == "MK3"){
                        sell_price = 10;
                    }else if(weapon_level == "MK2"){
                        GiveRP(m_metagame,cid,30000);
                        notify(m_metagame, "Sell MK2 weapon for 30,000 rp", dictionary(), "misc", pid, false, "", 1.0);
                        return;
                    }else if(weapon_level == "MK1"){
                        GiveRP(m_metagame,cid,10000);
                        notify(m_metagame, "Sell MK1 weapon for 10,000 rp", dictionary(), "misc", pid, false, "", 1.0);
                        return;
                    }
                    g_userCountInfoBuck.addCount(name,"SuperCash",sell_price);
                    notify(m_metagame, "Sell "+weapon_level+" weapon for "+sell_price+" SuperCash", dictionary(), "misc", pid, false, "", 1.0);
                    return;
                }else{
                    notify(m_metagame, "Risky operation: Your weapon has been returned. To synthesize a weapon, equip a weapon of the same mode in the weapon bar. If you need to sell weapons, keep the weapons bar empty", dictionary(), "misc", pid, false, "", 1.0);
                    addItemInBackpack(m_metagame,cid,"weapon",itemKey);
                    return;
                }
            }
        }
        if(containerId == 2){ //特殊武器兑换
            if(itemKey == "acg_scripts_hoshino_get.weapon"){
                deleteItemInBackpack(m_metagame,cid,"weapon",itemKey);
			    deleteItemInStash(m_metagame,cid,"weapon",itemKey);
                addItemInBackpack(m_metagame,cid,"weapon","acg_takanashi_hoshino_battle.weapon");
                addItemInBackpack(m_metagame,cid,"weapon","acg_takanashi_hoshino_battle_side_pistol.weapon");
                return;
            }
            if(startsWith(itemKey,"acg_sky_striker_ace_")){
                if(itemKey == "acg_sky_striker_ace_clips"){
                    return;
                }
                dictionary equipList;
                if(!getPlayerEquipmentInfoArray(m_metagame,cid,equipList)){
                    return;
                }
                string equipKey;
                if(equipList.get("1",equipKey)){//副武器
                    string targetKey = "re_acg_sky_striker_ace_orig_call";
                    if(startsWith(equipKey,targetKey)){
                        int num;
                        if(equipList.get(equipKey,num)){
                            if(num == 0){
                                deleteItemInBackpack(m_metagame,cid,"carry_item",itemKey);
                                return;
                            }
                        }
                    }else{
                        deleteItemInBackpack(m_metagame,cid,"weapon",itemKey);
                        deleteItemInBackpack(m_metagame,cid,"carry_item",itemKey);
                        return;
                    }
                }
                if(itemKey == "acg_sky_striker_ace_hayate_green_change_model_drop.carry_item"){
                    deleteItemInBackpack(m_metagame,cid,"carry_item",itemKey);
                    addItemInBackpack(m_metagame,cid,"weapon","acg_sky_striker_ace_hayate_green.weapon");
                }
                if(itemKey == "acg_sky_striker_ace_kagari_red_change_model_drop.carry_item"){
                    deleteItemInBackpack(m_metagame,cid,"carry_item",itemKey);
                    addItemInBackpack(m_metagame,cid,"weapon","acg_sky_striker_ace_kagari_red.weapon");
                }
                if(itemKey == "acg_sky_striker_ace_kaina_yellow_change_model_drop.carry_item"){
                    deleteItemInBackpack(m_metagame,cid,"carry_item",itemKey);
                    addItemInBackpack(m_metagame,cid,"weapon","acg_sky_striker_ace_kaina_yellow.weapon");
                }
                if(itemKey == "acg_sky_striker_ace_shizuku_blue_change_model_drop.carry_item"){
                    deleteItemInBackpack(m_metagame,cid,"carry_item",itemKey);
                    addItemInBackpack(m_metagame,cid,"weapon","acg_sky_striker_ace_shizuku_blue.weapon");
                } 
            }

        }
    }

    protected void handleChatEvent(const XmlElement@ event) {
        string message = event.getStringAttribute("message");
        message = message.toLowerCase();
        int pid = event.getIntAttribute("player_id");
        string name = event.getStringAttribute("player_name");
        int cid = g_playerInfoBuck.getCidByPid(pid);

        if(message == "/re"){
            dictionary equipList;
            if(!getPlayerEquipmentInfoArray(m_metagame,cid,equipList)){
                _report(m_metagame,"No information about what the player is carrying was obtained");
                return;
            }
            string equipKey = "";
            int equipNum = 0;

            if(equipList.get("0",equipKey) && equipList.get(equipKey,equipNum)){//主武器
                if(startsWith(equipKey,"re_") && equipNum != 0){
                    addItemInBackpack(m_metagame,cid,"weapon",equipKey); 
                    _notify(m_metagame,pid,"ReWeapon has copy to your backpack");
                }else{
                    _notify(m_metagame,pid,"Can't copy your weapon[Main Weapon]");
                }
            }
            if(equipList.get("1",equipKey) && equipList.get(equipKey,equipNum)){//副武器
                if(startsWith(equipKey,"re_") && equipNum != 0){
                    addItemInBackpack(m_metagame,cid,"weapon",equipKey); 
                    _notify(m_metagame,pid,"ReWeapon has copy to your backpack ");
                }else{
                    _notify(m_metagame,pid,"Can't copy your weapon[Secondary Weapon]");
                }
            }
        }

    }
}