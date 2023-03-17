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
//弹药箱的补给脚本
//部分补给会扣钱
//禁用物品：指定物品无法装入背包
	// --------------------------------------------
//触发补给key
dictionary resupply_key = {

        // 空
        {"",-1},

        {"hd_ammo_supply_box.projectile",1},

        // 占位的
        {"666",-1}

};
//可补给key
dictionary resupply_getitem_key = {
        // 空
        {"",-1},

        {"hd_md98_injector.weapon",8},
        {"hd_tox13_avenger_mk3.weapon",10},
        {"hd_flam40_incinerator_mk3.weapon",10},
        {"hd_rec6_demolisher_mk3.weapon",10},
        {"hd_mls4x_commando_mk3.weapon",8},
        {"hd_eta17_mk3.weapon",4},
        {"hd_rl112_recoilless_rifle_mk3.weapon",8},
        {"hd_mgx42_mk3.weapon",16},
        {"hd_apb_mk3.weapon",2},

        {"hd_at_mine_mk3.projectile",1},
        {"hd_airdropped_stun_mine_mk3.projectile",1},

        {"hd_grenade_molotov.projectile",5},
        {"hd_grenade_standard.projectile",6},

        // 占位的
        {"666",-1}
};
//再补给价格
dictionary resupply_cost = {
        // 空
        {"",-1},

        {"hd_md98_injector.weapon",0},
        {"hd_tox13_avenger_mk3.weapon",0},
        {"hd_flam40_incinerator_mk3.weapon",0},
        {"hd_rec6_demolisher_mk3.weapon",50},
        {"hd_mls4x_commando_mk3.weapon",0},
        {"hd_eta17_mk3.weapon",0},
        {"hd_rl112_recoilless_rifle_mk3.weapon",0},
        {"hd_mgx42_mk3.weapon",0},
        {"hd_apb_mk3.weapon",0},

        {"hd_at_mine_mk3.projectile",0},
        {"hd_airdropped_stun_mine_mk3.projectile",0},

        {"hd_grenade_molotov.projectile",0},
        {"hd_grenade_standard.projectile",0},

        // 占位的
        {"666",-1}
};
//禁止背包携带物品
dictionary banned_backpack_item = {
        // 空
        {"",-1},

        // Offensive 攻击性支援
        {"hd_offensive_vindicator_dive_bomb_mk3.projectile","projectile"},
        {"hd_offensive_airstrike_mk3.projectile","projectile"},
        {"hd_offensive_laser_strike_mk3.projectile","projectile"},
        {"hd_offensive_shredder_missile_strike_mk3.projectile","projectile"},
        {"hd_offensive_close_air_support_mk3.projectile","projectile"},
        {"hd_offensive_thunderer_barrage_mk3.projectile","projectile"},
        {"hd_offensive_strafing_run_mk3.projectile","projectile"},
        {"hd_offensive_static_field_conductors_mk3.projectile","projectile"},
        {"hd_offensive_sledge_precision_artillery_mk3.projectile","projectile"},
        {"hd_offensive_railcannon_strike_mk3.projectile","projectile"},
        {"hd_offensive_missile_barrage_mk3.projectile","projectile"},
        {"hd_offensive_incendiary_bombs_mk3.projectile","projectile"},
        {"hd_offensive_heavy_strafing_run_mk3.projectile","projectile"},

        // defensive 防御性支援
        {"hd_at_mine_mk3.projectile","projectile"},
        {"hd_airdropped_stun_mine_mk3.projectile","projectile"},
        {"hd_at47_mk3_call.projectile","projectile"},
        {"hd_amg_11_mk3_call.projectile","projectile"},
        {"hd_arx_34_mk3_call.projectile","projectile"},
        {"hd_agl8_mk3_call.projectile","projectile"},
        {"hd_aac6_tesla_mk3_call.projectile","projectile"},

        // special 特殊支援
        {"hd_nux_223_hellbomb.projectile","projectile"},
        {"hd_hellpod.projectile","projectile"},

        // Supply 普通支援
        {"hd_m5_apc_call.projectile","projectile"},
        {"hd_m5_32_hav_call.projectile","projectile"},
        {"hd_td110_bastion_call.projectile","projectile"},
        {"hd_mc109_motor_call.projectile","projectile"},
        {"hd_resupply.projectile","projectile"},
        {"hd_exo44_mk3.projectile","projectile"},
        {"hd_exo48_mk3.projectile","projectile"},
        {"hd_exo51_mk3.projectile","projectile"},

        {"hd_ammo_supply_box.projectile","projectile"},

		//机甲
        {"hd_exo44_walker_mk3_mg.weapon","weapon"},
        {"hd_exo44_walker_mk3_missile.weapon","weapon"},
        {"hd_exo48_obsidian_mk3_cannon.weapon","weapon"},
        {"hd_exo51_lumberer_mk3_cannon.weapon","weapon"},
        {"hd_exo51_lumberer_mk3_flame.weapon","weapon"},

        // 占位的
        {"666",-1}
};


class itemdrop_event : Tracker {
	protected Metagame@ m_metagame;

	// --------------------------------------------
	itemdrop_event(Metagame@ metagame) {
		@m_metagame = @metagame;
	}

	bool hasEnded() const {
		return false;
	}

	bool hasStarted() const {
		return true;
	}

	// --------------------------------------------
	protected void handleItemDropEvent(const XmlElement@ event) {
		string EventKeyGet = event.getStringAttribute("key");
		string itemKey = event.getStringAttribute("item_key");
		string position = event.getStringAttribute("position");
		int characterId = event.getIntAttribute("character_id");
		int itemClass = event.getIntAttribute("item_class");
		int playerId = event.getIntAttribute("player_id");
		int containerId = event.getIntAttribute("target_container_type_id");
		const XmlElement@ owner = getCharacterInfo(m_metagame, characterId);
		if (owner is null) {return;}
		int factionId = owner.getIntAttribute("faction_id");
		//containerId = 0(地面) 1(军械库) 2（背包） 3（仓库）
		//itemClass = 0(主、副武器) 1（投掷物） 3（护甲、战利品）
        _log("handleItemDropEvent:EventKeyGet= " + EventKeyGet);
        _log("handleItemDropEvent:itemKey= " + itemKey);
        _log("handleItemDropEvent:position= " + position);
        _log("handleItemDropEvent:characterId= " + characterId);
        _log("handleItemDropEvent:itemClass= " + itemClass);
        _log("handleItemDropEvent:playerId= " + playerId);
        _log("handleItemDropEvent:containerId= " + containerId);

		//再补给
		if (int(resupply_key[itemKey])!=0){
			switch(int(resupply_key[itemKey]))
			{
				case 0:{break;}
				case 1:{ //通用补给箱
					if(containerId == 2 ){//装备进背包
						string equipKey =  getPlayerEquipmentKey(m_metagame,characterId,2);
						_log("equipKey: "+ equipKey);
						//if(equipKey != itemKey ){break;}//再次检查
						deleteItemInBackpack(m_metagame,characterId,"projectile",itemKey);
						_log("success delete supply item itemKey: "+ itemKey);
						//恢复玩家护甲,播放拾取音效
						healCharacter(m_metagame,characterId,20);
						playSoundAtLocation(m_metagame,"hd_mg94_mag_out.wav",factionId,position);
						
						for(int i=1;i<=4;i++){
							equipKey = getDeadPlayerEquipmentKey(m_metagame,characterId,i);
							_log("ready to add item key= "+equipKey);
							_log("item slot= "+i);
							//slot: 0主手 1副手 2投掷物 4护甲
							if(int(resupply_getitem_key[equipKey])!=0){//为可补给物品
								_log("item resupplyable key= "+equipKey);
								int ownnum = getPlayerEquipmentAmount(m_metagame,characterId,i);
								int maxnum = int(resupply_getitem_key[equipKey]);
								int resupplyNum = maxnum - ownnum;
								_log("item ownnum= "+ownnum);
								_log("item maxnum= "+maxnum);
								_log("item resupplyNum= "+resupplyNum);
								for(;resupplyNum>0;--resupplyNum){
									if(int(resupply_cost[equipKey]) != 0){
										const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
										int t_playerId = character.getIntAttribute("player_id");
										int rp = character.getIntAttribute("rp");
										int cost = int(resupply_cost[equipKey]);
										if(rp <= cost){
											string message= "You don't have enough rp to resupply.";
											sendPrivateMessage(m_metagame,t_playerId,message);
											break;
										}
										GiveRP(m_metagame,characterId,-1*cost);
									}
									if(i==1){//副武器
										addItemInBackpack(m_metagame,characterId,"weapon",equipKey);
										_log("success add weapon key= "+equipKey);
									}
									if(i==2){//投掷物
										addItemInBackpack(m_metagame,characterId,"projectile",equipKey);
										_log("success add projectile key= "+equipKey);
									}
									if(i==4){//护甲
										addItemInBackpack(m_metagame,characterId,"carry_item",equipKey);
										_log("success add carry_item key= "+equipKey);
									}
									_log("failed add item key= "+equipKey);
								}
								continue;
							}
						}
					}
				}
			}
		}

		//检测物品是否存起来了,删除
		if(string(banned_backpack_item[itemKey]) == "" ){
			_log("ban item key exist?:" + "false");
		}
		if(string(banned_backpack_item[itemKey]) != ""){
			//管理可以存
			string sender = event.getStringAttribute("player_name");
			int senderId = event.getIntAttribute("player_id");
			_log("sender"+sender);
			_log("senderId"+senderId);
			if (m_metagame.getAdminManager().isAdmin(sender, senderId)){
				_log("Is admin, exit ban item");
				return;}
			if(containerId == 2 ){//装备进背包
				_log("delete banned item in backpack");
				string itemtype = string(banned_backpack_item[itemKey]);
				_log("itemtype"+itemtype);
				deleteItemInBackpack(m_metagame,characterId,itemtype,itemKey);
				_log("success delete supply item itemKey: "+ itemKey);
			}
		}
    }
}