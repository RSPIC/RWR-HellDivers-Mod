#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "all_helper.as"
#include "all_parameter.as"

#include "debug_reporter.as"
#include "INFO.as"

//Author: RST 
//共享样本和合成研究点
//_ex后缀为玩家实际使用的物品
	// --------------------------------------------
dictionary sample_key = {

        // 空
        {"",-1},

        {"samples_acg.carry_item","special"},
        {"samples_bugs.carry_item","general"},
        {"samples_cyborgs.carry_item","general"},
        {"samples_illuminate.carry_item","general"},

        // 占位的
        {"666",-1}

};
dictionary sample_target_key = {

        // 空
        {"",""},

        {"samples_bugs.carry_item","samples_bugs_ex.carry_item"},
        {"samples_cyborgs.carry_item","samples_cyborgs_ex.carry_item"},
        {"samples_illuminate.carry_item","samples_illuminate_ex.carry_item"},

        // 占位的
        {"666",""}

};

class share_samples : Tracker {
	protected Metagame@ m_metagame;

	// --------------------------------------------
	share_samples(Metagame@ metagame) {
		@m_metagame = @metagame;
	}

	bool hasEnded() const {
		return false;
	}

	bool hasStarted() const {
		return true;
	}

	void update(float time){
	}
	// --------------------------------------------
	protected void handleItemDropEvent(const XmlElement@ event) {
		string itemKey = event.getStringAttribute("item_key");
		string keyValue;
		if(!sample_key.get(itemKey,keyValue)){return;}

		string position = event.getStringAttribute("position");
		int characterId = event.getIntAttribute("character_id");
		int itemClass = event.getIntAttribute("item_class");
		int playerId = event.getIntAttribute("player_id");
		int containerId = event.getIntAttribute("target_container_type_id");

		//containerId = 0(地面) 1(军械库) 2（背包） 3（仓库）
		//itemClass = 0(主、副武器) 1（投掷物） 3（护甲、战利品）

		if(keyValue=="general"){
			if(containerId == 2 ){//拾取进背包
				string equipKey =  getPlayerEquipmentKey(m_metagame,characterId,2);
				array<const XmlElement@>@ allPlayer = getPlayers(m_metagame);
				if(allPlayer is null || allPlayer.size() == 0){return;}
				string targetKey;
				if(!sample_target_key.get(itemKey,targetKey)){return;}
				for(uint i = 0; i < allPlayer.length(); i++){
					const XmlElement@ player = allPlayer[i];
					if(player is null){return;}
					string name = player.getStringAttribute("name");
					string sid = player.getStringAttribute("sid");
					int cid = player.getIntAttribute("character_id");
					int pid = player.getIntAttribute("player_id");
					int fid = player.getIntAttribute("faction_id");

					deleteItemInBackpack(m_metagame,cid,"carry_item",itemKey);

					playerStashInfo@ thePlayer = playerStashInfo(m_metagame,sid,name);
					if(!thePlayer.isOpen()){
						thePlayer.openStash();
					}
					XmlElement newXml("stash");
                        newXml.setStringAttribute("AA_tag",targetKey);
                        newXml.setStringAttribute("A_tag","carry_item");
                        newXml.setIntAttribute("value",1);
                    thePlayer.addPushInObject(newXml);
                    thePlayer.pushInObjects();
                    thePlayer.openStash();
				}
			}
		}
    }

}