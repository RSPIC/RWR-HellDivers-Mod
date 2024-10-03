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

        {"hd_ammo_supply_box.projectile",1},

        {"hd_ammo_supply_box_ex_2.projectile",1},

        // 占位的
        {"666",-1}

};
//可补给key
dictionary resupply_getitem_key = {

        {"hd_pst_tox13_avenger_mk3.weapon",10},
        {"hd_pst_flam40_incinerator_mk3.weapon",10},
        {"hd_exp_rec6_demolisher_mk3.weapon",10},
        {"hd_exp_mls4x_commando_mk3.weapon",8},
        {"hd_exp_eta17_mk3.weapon",8},
        {"hd_exp_rl112_recoilless_rifle_mk3.weapon",8},
        {"hd_lmg_mgx42_mk3.weapon",8},

        {"hd_grenade_molotov.projectile",8},
        {"hd_grenade_standard.projectile",10},
        {"hd_md99_injector.projectile",4},

        // 占位的
        {"666",-1}
};

//禁止背包携带物品
dictionary banned_backpack_item = {

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
        {"hd_exo48_obsidian_mk3_cannon_main.weapon","weapon"},
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
//禁止仓库携带物品
dictionary banned_stash_item = {

		{"acg_patricia_fataldrive.weapon","weapon"},
		{"acg_elaina_wand_skill.weapon","weapon"},
		{"ex_hyper_mega_bazooka_launcher_skill.weapon","weapon"},
		{"ex_vergil_skill.weapon","weapon"},
		{"hd_resupply_pack_mk3.carry_item","carry_item"},
		{"hd_resupply_pack_mk3_ex.carry_item","carry_item"},
		{"hd_at_mine_submission_stay.projectile","projectile"},

        // 占位的
        {"666",-1}
};
//禁止背包携带物品 忘记什么用了
dictionary banned_special_item = {

        {"hd_ammo_supply_box_ex.projectile","projectile"},

		// 占位的
        {"666",-1}
};
//高亮提示特殊掉落物
dictionary highlight_item_drop = {

        {"acg_shigure_127mm.weapon","weapon"},
        {"acg_shigure_610mm_torpedo.weapon","weapon"},
        {"acg_exo_toki.weapon","weapon"},
        {"acg_exo_toki_doublefire.weapon","weapon"},
        {"acg_exo_toki_railgun.weapon","weapon"},
        {"acg_exo_toki_skill.weapon","weapon"},

		// 占位的
        {"666",-1}
};
//无法交易物品，丢至地面会返还
dictionary protected_trade = {

        // {"samples_bugs_ex.carry_item","carry_item"},
        // {"samples_cyborgs_ex.carry_item","carry_item"},
        // {"samples_illuminate_ex.carry_item","carry_item"},

		// 占位的
        {"666",-1}
};
//替换对应阵营样本(游戏机制导致不能指定掉落物品)
dictionary samples_drop = {

        {"samples_bugs_backpack.carry_item","Bugs"},
        {"samples_cyborgs_backpack.carry_item","Cyborgs"},
        {"samples_illuminate_backpack.carry_item","Illuminate"},

		// 占位的
        {"666",-1}
};
//掉落物品替换
dictionary replace_drop = {

        {"Bugs","samples_bugs.carry_item"},
        {"Cyborgs","samples_cyborgs.carry_item"},
        {"Illuminate","samples_illuminate.carry_item"},

		// 占位的
        {"666",-1}
};

class itemdrop_event : Tracker {
	protected Metagame@ m_metagame;

	// --------------------------------------------
	itemdrop_event(Metagame@ metagame) {
		@m_metagame = @metagame;
		_log("itemdrop_event initiate.");
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
	//received: TagName=item_drop_event character_id=293 
	//item_class=0 item_key=hd_ar_ar19_liberator_full_upgrade.weapon item_type_id=10 
	//player_id=0 position=295.294 8.50038 518.709 target_container_type_id=2 

	protected void handleItemDropEvent(const XmlElement@ event) {
		string itemKey = event.getStringAttribute("item_key");
		_log("handleItemDropEvent itemKey="+itemKey);
		banVest(event);
		//todo:在此处判断在字典里存在然后选择是否返回，减少下列查询消耗。
		if(	string(resupply_key[itemKey]) == "" 			&&
			string(resupply_getitem_key[itemKey]) == "" 	&&
			string(banned_backpack_item[itemKey]) == "" 	&&
			string(banned_special_item[itemKey]) == "" 		&&
			string(highlight_item_drop[itemKey]) == "" 		&&
			string(protected_trade[itemKey]) == "" 			&&
			string(samples_drop[itemKey]) == "" 			&&
			string(banned_stash_item[itemKey]) == "" 		&&
			string(replace_drop[itemKey]) == "" 			
		){return;}

		string position = event.getStringAttribute("position");
		int characterId = event.getIntAttribute("character_id");
		if(characterId == -1){return;}
		int playerId = event.getIntAttribute("player_id");
		int containerId = event.getIntAttribute("target_container_type_id");
		//const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
		int factionId = -1;

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
						dictionary equipList;
						if(!getPlayerEquipmentInfoArray(m_metagame,characterId,equipList)) return;
						deleteItemInBackpack(m_metagame,characterId,"projectile",itemKey);
						healCharacter(m_metagame,characterId,20);
			//有bug,暂时取消后面的任务
			//return;
						if(isVectorInMap(stringToVector3(position))){
							_log("position is in map");
						}
						playSoundAtLocation(m_metagame,"hd_mg94_mag_out.wav",factionId,position);
						_log("played sound");
						array<Resource@> resources = array<Resource@>();
						Resource@ res;
						_log("pointer initiate");
						for(int i=1;i<=2;i++){
							string equipKey = "null";
							equipList.get(""+i,equipKey);
							_log("get equipKey = "+equipKey);
							if(g_debugMode){
								_report(m_metagame,"Get Player EquipKey ="+equipKey);
								_report(m_metagame,"Item slot ="+i);
							}
							//slot: 0主手 1副手 2投掷物 4护甲
							int maxnum;
							bool noGrenade = false;
							_log("initiate value1");
							if(int(resupply_getitem_key[equipKey]) != 0){//为可补给物品
								_log("initiate value2");
								int ownnum = 0;
								equipList.get(equipKey,ownnum);
								maxnum = int(resupply_getitem_key[equipKey]);
								int resupplyNum = maxnum - ownnum;
								_log("initiate value3");
								if(i==1){//副武器
									@res = Resource(equipKey,"weapon");
                					res.addToResources(resources,resupplyNum);
									_log("add weapon = "+equipKey+" num="+resupplyNum);
								}
								if(i==2){//投掷物
									@res = Resource(equipKey,"projectile");
									res.addToResources(resources,resupplyNum);
									_log("add projectile = "+equipKey+" num="+resupplyNum);
									noGrenade = true;
								}
							}
							_log("initiate value4");
							if(i==2){//补给信物(投掷物栏)
								string tokenkey = "token_";
								string newequipKey = equipKey.substr(0,tokenkey.length());
								_log("initiate value5");
								if(newequipKey == tokenkey){
									_log("initiate value6");
									int ownnum = 0;
									equipList.get(equipKey,ownnum);
									maxnum = 6;
									int resupplyNum = maxnum - ownnum;
									@res = Resource(equipKey,"projectile");
									_log("initiate value7");
									if(resupplyNum <= 0){
										resupplyNum = 0;
									}
									res.addToResources(resources,resupplyNum);
									if(g_debugMode){
										_report(m_metagame,"Success resupply Token");
									}
									_log("add token = "+tokenkey+" num="+resupplyNum);
									addListItemInBackpack(m_metagame,characterId,resources);
									return;
								}
							}
							_log("initiate value8");
							if(i==2 && !noGrenade){//补给手雷
								_log("initiate value9");
								int ownnum = 0;
								_log("initiate value10");
								equipList.get(equipKey,ownnum);
								if(ownnum == 0){
									string key = "hd_grenade_standard.projectile";
									maxnum = int(resupply_getitem_key[key]);
									int resupplyNum = maxnum;
									_log("initiate value11");
									@res = Resource(key,"projectile");
									res.addToResources(resources,resupplyNum);
									_log("add Grenade");
								}
							}
						}
						_log("ready to addInBackPack cid= "+characterId);
						if(resources is null){
							_log("resources is null");
							return;
						}
						addListItemInBackpack(m_metagame,characterId,resources);
					}
				}
			}
		}

		//是否属于删除物品
		if(g_debugMode){return;}
		if(string(banned_backpack_item[itemKey]) != "" || string(banned_special_item[itemKey]) != "" || string(banned_stash_item[itemKey]) != ""){
			if(playerId == -1){return;}//排除AI
			array<Resource@> resources = array<Resource@>();
			Resource@ res;
			if(itemKey == "hd_resupply_pack_mk3.carry_item"){//补给背包特殊机制 上限携带一个包，同时发4个子弹箱
				_log("hd_resupply_pack_mk3 detect");
				string ExKey="hd_resupply_pack_mk3_ex.carry_item";
				string itemtype = string(banned_backpack_item[itemKey]);
				deleteItemInBackpack(m_metagame,characterId,itemtype,ExKey);
				deleteItemInBackpack(m_metagame,characterId,itemtype,ExKey);
				deleteItemInStash(m_metagame,characterId,itemtype,ExKey);
				//addItemInBackpack(m_metagame,characterId,itemtype,ExKey);
				@res = Resource(ExKey,"carry_item");
				res.addToResources(resources,1);
				ExKey="hd_ammo_supply_box_ex.projectile";//发4个特殊的子弹箱在背包(不会被检测删除)
				string ExType="projectile";
				@res = Resource(ExKey,ExType);
				res.addToResources(resources,4);
				addListItemInBackpack(m_metagame,characterId,resources);
			}
			if(containerId == 2 || containerId == 3){//装备进背包或者仓库
				_log("delete banned item in backpack");
				string itemtype = string(banned_backpack_item[itemKey]);
				_log("itemtype "+itemtype);
				if(itemtype != ""){
					deleteItemInBackpack(m_metagame,characterId,itemtype,itemKey);
					deleteItemInStash(m_metagame,characterId,itemtype,itemKey);
					_log("success delete supply item itemKey: "+ itemKey);
					if(itemKey == "hd_ammo_supply_box.projectile" && false){//留给补给兵的特殊机制(自补给+背包额外子弹箱)
						string ExKey="hd_ammo_supply_box_ex.projectile";
						addItemInBackpack(m_metagame,characterId,itemtype,ExKey);
					}
				}
			}
			if(containerId == 3){//装备进仓库
				_log("delete banned item in stash");
				string itemtype = "";
				banned_stash_item.get(itemKey,itemtype);
				_log("itemtype "+itemtype);
				if(itemtype != ""){
					deleteItemInStash(m_metagame,characterId,itemtype,itemKey);
					_log("success delete supply item itemKey: "+ itemKey);
				}
			}
			if(containerId == 0 ){//地面
				_log("containerId = gound");
				if(itemKey == "hd_ammo_supply_box_ex.projectile"){//补给背包特殊机制
					string ExKey="hd_ammo_supply_box_ex_2.projectile";//替换为特殊子弹箱（识取后会补给并被删除)
					Vector3 t_pos = stringToVector3(position);
					if(isVectorInMap(t_pos)){
						spawnStaticItem(m_metagame,ExKey,t_pos,characterId,factionId,"projectile");
					}
				}
			}
		}

		if(string(highlight_item_drop[itemKey]) != ""){//高亮特殊掉落物
			if( containerId == 0 ) {//地面
				_log("special item drop, highliting");
				spawnStaticProjectile(m_metagame,"hd_effect_drop_target.projectile",position,characterId,factionId);
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
				const XmlElement@ character = getCharacterInfo(m_metagame,characterId);
				if(character is null){return;}
				factionId = character.getIntAttribute("faction_id");
				string fact_name = g_factionInfoBuck.getNameByFid(factionId);
				_log("FactioName = " + fact_name);
				_log("TargetNmae = " + string(samples_drop[itemKey]));
				if(fact_name == string(samples_drop[itemKey])){//确认是否为同阵营样本
					string ExKey = string(replace_drop[fact_name]);
					_log("ExKey = " + ExKey);
					Vector3 t_pos = stringToVector3(position);
					spawnStaticItem(m_metagame,ExKey,t_pos,characterId,factionId,itemtype);
				}
			}
		}
    }
	//-------------------------------------------------------
	protected void banVest(const XmlElement@ event){
		// 防止升级的护甲被存起来。
		_log("check delete banVest");
		if(g_debugMode){return;}
		string itemKey = event.getStringAttribute("item_key");
		string targetVestKey = "hd_v_";
		string tempKey = itemKey.substr(0,targetVestKey.size());
		int characterId = event.getIntAttribute("character_id");
		if(characterId == -1){return;}
		if(tempKey == targetVestKey ){
			deleteItemInBackpack(m_metagame,characterId,"carry_item",itemKey);
			deleteItemInStash(m_metagame,characterId,"carry_item",itemKey);
			_log("delete banVest hd_v_");
		}
		targetVestKey = "hd_banzai_";
		tempKey = itemKey.substr(0,targetVestKey.size());
		if(tempKey == targetVestKey ){
			deleteItemInBackpack(m_metagame,characterId,"carry_item",itemKey);
			deleteItemInStash(m_metagame,characterId,"carry_item",itemKey);
			_log("delete banVest hd_banzai_");
		}
		targetVestKey = "helldivers_vest_barrier";
		tempKey = itemKey.substr(0,targetVestKey.size());
		if(tempKey == targetVestKey ){
			deleteItemInBackpack(m_metagame,characterId,"carry_item",itemKey);
			deleteItemInStash(m_metagame,characterId,"carry_item",itemKey);
			_log("delete banVest helldivers_vest_barrier");
		}
	}

}