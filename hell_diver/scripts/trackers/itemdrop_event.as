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
//弹药箱的补给脚本
//部分补给会扣钱
//禁用物品：指定物品无法装入背包
//补给背包机制
//高亮特殊掉落物
//替换对应阵营样本(游戏机制导致不能指定掉落物品)
	// --------------------------------------------
//触发补给key
dictionary resupply_key = {

        // 空
        {"",-1},

        {"hd_ammo_supply_box.projectile",1},

        {"hd_ammo_supply_box_ex_2.projectile",1},

        // 占位的
        {"666",-1}

};
//可补给key
dictionary resupply_getitem_key = {
        // 空
        {"",-1},

        {"hd_pst_tox13_avenger_mk3.weapon",10},
        {"hd_pst_flam40_incinerator_mk3.weapon",10},
        {"hd_exp_rec6_demolisher_mk3.weapon",10},
        {"hd_exp_mls4x_commando_mk3.weapon",8},
        {"hd_exp_eta17_mk3.weapon",4},
        {"hd_exp_rl112_recoilless_rifle_mk3.weapon",8},
        {"hd_lmg_mgx42_mk3.weapon",16},

        {"hd_grenade_molotov.projectile",8},
        {"hd_grenade_standard.projectile",10},

        // 占位的
        {"666",-1}
};
//再补给价格
dictionary resupply_cost = {
        // 空
        {"",-1},

        {"hd_pst_tox13_avenger_mk3.weapon",0},
        {"hd_pst_flam40_incinerator_mk3.weapon",0},
        {"hd_exp_rec6_demolisher_mk3.weapon",0},
        {"hd_exp_mls4x_commando_mk3.weapon",0},
        {"hd_exp_eta17_mk3.weapon",0},
        {"hd_exp_rl112_recoilless_rifle_mk3.weapon",0},
        {"hd_mgx42_mk3.weapon",0},
        {"hd_lmg_mgx42_mk3.weapon",0},

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

        {"acg_arx_34_mk3_call.projectile","projectile"},
		{"acg_amg_11_mk3_call.projectile","projectile"},

        // special 特殊支援
        {"hd_nux_223_hellbomb.projectile","projectile"},
        {"hd_hellpod.projectile","projectile"},
        {"hd_sup_mental_detector_call.projectile","projectile"},

        // Supply 普通支援
        // {"hd_m5_apc_call.projectile","projectile"},
        // {"hd_m5_32_hav_call.projectile","projectile"},
        // {"hd_td110_bastion_call.projectile","projectile"},
        // {"hd_mc109_motor_call.projectile","projectile"},
        {"hd_resupply.projectile","projectile"},
        {"hd_exo44_mk3.projectile","projectile"},
        {"hd_exo48_mk3.projectile","projectile"},
        {"hd_exo51_mk3.projectile","projectile"},

        {"hd_ammo_supply_box.projectile","projectile"},
        {"hd_ammo_supply_box_ex_2.projectile","projectile"},

		//机甲
        {"hd_exo44_walker_mk3_mg.weapon","weapon"},
        {"hd_exo44_walker_mk3_missile.weapon","weapon"},
        {"hd_exo48_obsidian_mk3_cannon.weapon","weapon"},
        {"hd_exo51_lumberer_mk3_cannon.weapon","weapon"},
        {"hd_exo51_lumberer_mk3_flame.weapon","weapon"},

		//战略设备
        {"hd_lmg_mg94_mk3.projectile","projectile"},
        {"hd_lmg_mgx42_mk3.projectile","projectile"},
        {"hd_laser_las98_laser_cannon_mk3.projectile","projectile"},
        {"hd_exp_ac22_dum_dum_mk3.projectile","projectile"},
        {"hd_exp_obliterator_grenade_launcher_full_upgrade.projectile","projectile"},
        {"hd_exp_m25_rumbler_full_upgrade.projectile","projectile"},
        {"hd_pst_flam40_incinerator_mk3.projectile","projectile"},
        {"hd_pst_tox13_avenger_mk3.projectile","projectile"},
        {"hd_exp_rl112_recoilless_rifle_mk3.projectile","projectile"},
        {"hd_exp_eta17_mk3.projectile","projectile"},
        {"hd_exp_mls4x_commando_mk3.projectile","projectile"},
        {"hd_drone_ad334_guard_dog_mk3.projectile","projectile"},
        {"hd_drone_ad289_angel_mk3.projectile","projectile"},
        {"hd_sup_rep80_mk3.projectile","projectile"},
        {"hd_exp_rec6_demolisher_mk3.projectile","projectile"},
        {"hd_resupply_pack_mk3.projectile","projectile"},

		//背包
		{"hd_resupply_pack_mk3.carry_item","carry_item"},

        // 占位的
        {"666",-1}
};
//禁止背包携带物品 忘记什么用了
dictionary banned_special_item = {
        // 空
        {"",-1},

        {"hd_ammo_supply_box_ex.projectile","projectile"},

		// 占位的
        {"666",-1}
};
//高亮提示特殊掉落物
dictionary highlight_item_drop = {
        // 空
        {"",-1},

        {"samples_acg.carry_item","carry_item"},
        {"samples_bugs.carry_item","carry_item"},
        {"samples_cyborgs.carry_item","carry_item"},
        {"samples_illuminate.carry_item","carry_item"},

		// 占位的
        {"666",-1}
};
//无法交易物品，丢至地面会返还
dictionary protected_trade = {
        // 空
        {"",-1},

        {"samples_bugs_ex.carry_item","carry_item"},
        {"samples_cyborgs_ex.carry_item","carry_item"},
        {"samples_illuminate_ex.carry_item","carry_item"},

		// 占位的
        {"666",-1}
};
//替换对应阵营样本(游戏机制导致不能指定掉落物品)
dictionary samples_drop = {
        // 空
        {"",-1},

        {"samples_bugs_backpack.carry_item","Bugs"},
        {"samples_cyborgs_backpack.carry_item","Cyborgs"},
        {"samples_illuminate_backpack.carry_item","Illuminate"},

		// 占位的
        {"666",-1}
};
//掉落物品替换
dictionary replace_drop = {
        // 空
        {"",-1},

        {"Bugs","samples_bugs.carry_item"},
        {"Cyborgs","samples_cyborgs.carry_item"},
        {"Illuminate","samples_illuminate.carry_item"},

		// 占位的
        {"666",-1}
};

class itemdrop_event : Tracker {
	protected Metagame@ m_metagame;
	protected bool debug_mode;

	// --------------------------------------------
	itemdrop_event(Metagame@ metagame) {
		@m_metagame = @metagame;
		debug_mode = g_debugMode;
		_log("itemdrop_event initiate.");
	}

	bool hasEnded() const {
		return false;
	}

	bool hasStarted() const {
		return true;
	}
	void update(float time){
		debug_mode = g_debugMode;
	}

	// --------------------------------------------
	protected void handleItemDropEvent(const XmlElement@ event) {
		string itemKey = event.getStringAttribute("item_key");
		//todo:在此处判断在字典里存在然后选择是否返回，减少下列查询消耗。
		if(	string(resupply_key[itemKey]) == "" 			&&
			string(resupply_getitem_key[itemKey]) == "" 	&&
			string(resupply_cost[itemKey]) == "" 			&&
			string(banned_backpack_item[itemKey]) == "" 	&&
			string(banned_special_item[itemKey]) == "" 		&&
			string(highlight_item_drop[itemKey]) == "" 		&&
			string(protected_trade[itemKey]) == "" 			&&
			string(samples_drop[itemKey]) == "" 			&&
			string(replace_drop[itemKey]) == "" 			
		){return;}

		string position = event.getStringAttribute("position");
		int characterId = event.getIntAttribute("character_id");
		if(characterId == -1){return;}
		int playerId = event.getIntAttribute("player_id");
		int containerId = event.getIntAttribute("target_container_type_id");
		const XmlElement@ owner = getCharacterInfo(m_metagame, characterId);
		_log("query owner info(itemdrop)");
		int factionId = -1;
		if(owner !is null){
			if(owner.hasAttribute("faction_id")){
				factionId = owner.getIntAttribute("faction_id");
				_log("owner fid = " + factionId);
			}
			if(factionId == -1){
				_log("owner fid = -1,return");
				return;
			}
		}else{return;}

		//containerId = 0(地面) 1(军械库) 2（背包） 3（仓库）
		//itemClass = 0(主、副武器) 1（投掷物） 3（护甲、战利品）

		//再补给
		if (int(resupply_key[itemKey])!=0){
			if(playerId == -1){return;}//排除AI
			switch(int(resupply_key[itemKey]))
			{
				case 0:{break;}
				case 1:{ //通用补给箱
					if(containerId == 2 ){//装备进背包
						string equipKey =  getPlayerEquipmentKey(m_metagame,characterId,2);
						_log("equipKey: "+ equipKey);
						deleteItemInBackpack(m_metagame,characterId,"projectile",itemKey);
						_log("success delete supply item itemKey: "+ itemKey);
						healCharacter(m_metagame,characterId,20);
						playSoundAtLocation(m_metagame,"hd_mg94_mag_out.wav",factionId,position);
						
						for(int i=1;i<=4;i++){
							if(i == 3){continue;}
							equipKey = getDeadPlayerEquipmentKey(m_metagame,characterId,i);
							if(debug_mode){
								_report(m_metagame,"Get Player EquipKey ="+equipKey);
								_report(m_metagame,"Item slot ="+i);
							}
							//slot: 0主手 1副手 2投掷物 4护甲
							if(int(resupply_getitem_key[equipKey])!=0){//为可补给物品
								int ownnum = getPlayerEquipmentAmount(m_metagame,characterId,i);
								int maxnum = int(resupply_getitem_key[equipKey]);
								int resupplyNum = maxnum - ownnum;
								for(;resupplyNum>0;--resupplyNum){
									if(int(resupply_cost[equipKey]) != 0){
										const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
										if(character is null){return;}
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
									}
									if(i==2){//投掷物
										addItemInBackpack(m_metagame,characterId,"projectile",equipKey);
									}
									if(i==4){//护甲
										addItemInBackpack(m_metagame,characterId,"carry_item",equipKey);
									}
								}
								continue;
							}
							if(i==2){//补给信物(投掷物栏)
								string tokenkey = "token_";
								string newequipKey = equipKey.substr(0,tokenkey.length());
								if(newequipKey == tokenkey){
									int ownnum = getPlayerEquipmentAmount(m_metagame,characterId,i);
									int maxnum = 6;
									int resupplyNum = maxnum - ownnum;
									for(;resupplyNum>0;--resupplyNum){
										addItemInBackpack(m_metagame,characterId,"projectile",equipKey);
									}
									if(debug_mode){
										_report(m_metagame,"Success resupply Token");
									}
									return;
								}
							}
							if(i==2){//补给手雷
								int ownnum = getPlayerEquipmentAmount(m_metagame,characterId,i);
								if(ownnum == 0){
									string key = "hd_grenade_standard.projectile";
									int maxnum = int(resupply_getitem_key[key]);
									int resupplyNum = maxnum;
									for(;resupplyNum>0;--resupplyNum){
										addItemInBackpack(m_metagame,characterId,"projectile",key);
									}
								}
							}
						}
					}
				}
			}
		}

		//是否属于删除物品
		if(string(banned_backpack_item[itemKey]) != "" || string(banned_special_item[itemKey]) != ""){
			if(debug_mode){return;}
			if(playerId == -1){return;}//排除AI
			int senderId = event.getIntAttribute("player_id");
			const XmlElement@ playerinfo = getPlayerInfo(m_metagame,senderId);
			if(playerinfo is null){return;}
			string sender = playerinfo.getStringAttribute("name");
			_log("sender ="+sender);
			_log("senderId ="+senderId);
			// if (m_metagame.getAdminManager().isAdmin(sender, senderId)){
			// 	_log("Is admin, exit ban item");
			// 	return;
			// }//管理可以存

			if(itemKey == "hd_resupply_pack_mk3.carry_item"){//补给背包特殊机制 上限携带一个包，同时发4个子弹箱
				_log("hd_resupply_pack_mk3 detect");
				string ExKey="hd_resupply_pack_mk3_ex.carry_item";
				string itemtype = string(banned_backpack_item[itemKey]);
				deleteItemInBackpack(m_metagame,characterId,itemtype,ExKey);
				deleteItemInBackpack(m_metagame,characterId,itemtype,ExKey);
				addItemInBackpack(m_metagame,characterId,itemtype,ExKey);
				ExKey="hd_ammo_supply_box_ex.projectile";//发4个特殊的子弹箱在背包(不会被检测删除)
				string ExType="projectile";
				addItemInBackpack(m_metagame,characterId,ExType,ExKey);
				addItemInBackpack(m_metagame,characterId,ExType,ExKey);
				addItemInBackpack(m_metagame,characterId,ExType,ExKey);
				addItemInBackpack(m_metagame,characterId,ExType,ExKey);
			}
			if(containerId == 2 ){//装备进背包
				_log("delete banned item in backpack");
				string itemtype = string(banned_backpack_item[itemKey]);
				_log("itemtype "+itemtype);
				deleteItemInBackpack(m_metagame,characterId,itemtype,itemKey);
				_log("success delete supply item itemKey: "+ itemKey);
				if(itemKey == "hd_ammo_supply_box.projectile" && false){//留给补给兵的特殊机制(自补给+背包额外子弹箱)
					string ExKey="hd_ammo_supply_box_ex.projectile";
					addItemInBackpack(m_metagame,characterId,itemtype,ExKey);
				}
			}
			if(containerId == 0 ){//地面
				_log("containerId = gound");
				if(itemKey == "hd_ammo_supply_box_ex.projectile"){//补给背包特殊机制
					string ExKey="hd_ammo_supply_box_ex_2.projectile";//替换为特殊子弹箱（拾取后会补给并被删除)
					Vector3 t_pos = stringToVector3(position);
					spawnStaticItem(m_metagame,ExKey,t_pos,characterId,factionId,"projectile");
				}
			}
		}

		if(string(highlight_item_drop[itemKey]) != ""){//高亮特殊掉落物
			if( containerId == 0 ) {//地面
				_log("special item drop, highliting");
				spawnStaticProjectile(m_metagame,"hd_effect_target_aim.projectile",position,characterId,factionId);
			}
		}

		if(string(protected_trade[itemKey]) != ""){//交易保护物品
			if(playerId == -1){return;}//排除AI
			if( containerId == 0 ) {//地面
				_log("protected_trade item drop, protecte");
				string itemtype = string(protected_trade[itemKey]);
				addItemInBackpack(m_metagame,characterId,itemtype,itemKey);
				spawnStaticProjectile(m_metagame,"hd_effect_samples_cant_drop.projectile",position,characterId,factionId);
			}
		}

		if(string(samples_drop[itemKey]) != ""){//替换阵营样本掉落
			//if(playerId != -1){return;}//排除玩家
			if( containerId == 0 ) {//掉落
				_log("samples_drop item drop, replace sample");
				string itemtype = "carry_item";
				const XmlElement@ fact_info = getFactionInfo(m_metagame,factionId);
				if(fact_info is null){return;}
				string fact_name = fact_info.getStringAttribute("name");
				_log("FactioName = " + fact_name);
				_log("TargetNmae = " + string(samples_drop[itemKey]));
				if(fact_name != string(samples_drop[itemKey])){//确认是否为同阵营样本
					string ExKey = string(replace_drop[fact_name]);
					_log("ExKey = " + ExKey);
					Vector3 t_pos = stringToVector3(position);
					spawnStaticItem(m_metagame,ExKey,t_pos,characterId,factionId,itemtype);
				}
			}
		}
    }

}