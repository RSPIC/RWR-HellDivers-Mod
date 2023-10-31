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
        if(startsWith(itemKey,"ex_piano_") || startsWith(itemKey,"ex_gramophone_") || startsWith(itemKey,"ex_cl_")){
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
                _report(m_metagame,"未获取到玩家携带物品信息");
                return;
            }
            string equipKey = "";
            int equipNum = 0;
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
                        notify(m_metagame, "已进入武器合成阶段，现在开始持续出售十件同类型武器即可获得复活自带版本", dictionary(), "misc", pid, false, "", 1.0);
                        addItemInBackpack(m_metagame,cid,"weapon",itemKey);
                        return;
                    }
                    int value;
                    g_userCountInfoBuck.addCount(name,itemKey+"re");
                    g_userCountInfoBuck.getCount(name,itemKey+"re",value);
                    notify(m_metagame, "合成进度["+value+"/10]", dictionary(), "misc", pid, false, "", 1.0);
                                        
                    if(value == 10){
                        addItemInBackpack(m_metagame,cid,"weapon","re_"+itemKey);
                        addItemInBackpack(m_metagame,cid,"weapon","re_"+itemKey);
                        g_userCountInfoBuck.clearCount(name,itemKey+"re");
                        notify(m_metagame, "已成功合成", dictionary(), "misc", pid, false, "", 1.0);
                    }
                    return;
                }else{
                    if(equipNum != 0){
                        string equipKey2;
                        equipList.get("1",equipKey2);
                        if(itemKey != equipKey2){// 主手为空 副手无法合成情况
                            notify(m_metagame, "风险操作：已退还你的武器。若要合成武器，请在武器栏装备同样模式的武器。如果需要出售武器，请保持武器栏为空", dictionary(), "misc", pid, false, "", 1.0);
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
                        notify(m_metagame, "已进入武器合成阶段，现在开始持续出售十件同类型武器即可获得复活自带版本", dictionary(), "misc", pid, false, "", 1.0);
                        addItemInBackpack(m_metagame,cid,"weapon",itemKey);
                        return;
                    }
                    int value;
                    g_userCountInfoBuck.addCount(name,itemKey+"re");
                    g_userCountInfoBuck.getCount(name,itemKey+"re",value);
                    notify(m_metagame, "合成进度["+value+"/10]", dictionary(), "misc", pid, false, "", 1.0);

                    if(g_userCountInfoBuck.getCount(name,itemKey+"re",value) && value == 10){
                        addItemInBackpack(m_metagame,cid,"weapon","re_"+itemKey);
                        addItemInBackpack(m_metagame,cid,"weapon","re_"+itemKey);
                        g_userCountInfoBuck.clearCount(name,itemKey+"re");
                        notify(m_metagame, "已成功合成", dictionary(), "misc", pid, false, "", 1.0);
                    }
                    return;
                }else{
                    notify(m_metagame, "风险操作：已退还你的武器。若要合成武器，请在武器栏装备同样模式的武器。如果需要出售武器，请保持武器栏为空", dictionary(), "misc", pid, false, "", 1.0);
                    addItemInBackpack(m_metagame,cid,"weapon",itemKey);
                    return;
                }
            }
        }
    }
}