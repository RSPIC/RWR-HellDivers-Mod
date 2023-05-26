#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "all_helper.as"
#include "all_parameter.as"

//Author: RST 
//共享样本和合成研究点
//_ex后缀为玩家实际使用的物品
	// --------------------------------------------
dictionary sample_key = {

        // 空
        {"",-1},

        {"samples_acg.carry_item",1},
        {"samples_bugs.carry_item",2},
        {"samples_cyborgs.carry_item",2},
        {"samples_illuminate.carry_item",2},

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
		_log("share_samples initiate.");
	}

	bool hasEnded() const {
		return false;
	}

	bool hasStarted() const {
		return true;
	}

	// --------------------------------------------
	protected void handleItemDropEvent(const XmlElement@ event) {
		string itemKey = event.getStringAttribute("item_key");
		if(string(sample_key[itemKey]) == ""){return;}

		string position = event.getStringAttribute("position");
		int characterId = event.getIntAttribute("character_id");
		int itemClass = event.getIntAttribute("item_class");
		int playerId = event.getIntAttribute("player_id");
		int containerId = event.getIntAttribute("target_container_type_id");
		const XmlElement@ owner = getCharacterInfo(m_metagame, characterId);
		int factionId = -1;
		if(owner !is null){
			factionId = owner.getIntAttribute("faction_id");
		}

		//containerId = 0(地面) 1(军械库) 2（背包） 3（仓库）
		//itemClass = 0(主、副武器) 1（投掷物） 3（护甲、战利品）
        _log("handle_share_samples:itemKey= " + itemKey);
        _log("handle_share_samples:position= " + position);
        _log("handle_share_samples:characterId= " + characterId);
        _log("handle_share_samples:itemClass= " + itemClass);
        _log("handle_share_samples:playerId= " + playerId);
        _log("handle_share_samples:containerId= " + containerId);

		//
		if (int(sample_key[itemKey])!=0){
			switch(int(sample_key[itemKey]))
			{
				case 0:{break;}
				case 2:{ //通用样本
					if(containerId == 2 ){//拾取进背包
						string equipKey =  getPlayerEquipmentKey(m_metagame,characterId,2);
						_log("equipKey: "+ equipKey);
						array<const XmlElement@>@ allPlayer = getPlayers(m_metagame);
						if(allPlayer is null){return;}
						_log("players num = "+allPlayer.length() );
						_log("sample_target_key exist? "+(string(sample_target_key[itemKey]) == ""));
						if(string(sample_target_key[itemKey]) == ""){return;}
						for(uint i = 0; i < allPlayer.length(); i++){
							const XmlElement@ player = allPlayer[i];
							int cid = player.getIntAttribute("character_id");
							int pid = player.getIntAttribute("player_id");
							int fid = player.getIntAttribute("faction_id");
							Vector3 aim_pos = stringToVector3(player.getStringAttribute("aim_target"));
							const XmlElement@ p_character = getCharacterInfo(m_metagame,cid);
							if(p_character is null){return;}
							Vector3 p_pos =stringToVector3(p_character.getStringAttribute("position"));
							
							if(playerId==0){return;}//测试

							deleteItemInBackpack(m_metagame,cid,"carry_item",itemKey);
							string target_key = string(sample_target_key[itemKey]);
							addItemInBackpack(m_metagame,cid,"carry_item",target_key);
							spawnStaticProjectile(m_metagame,"hd_effect_samples_pick.projectile",p_pos,cid,fid);
						}
					}
				}
			}
		}
    }
}