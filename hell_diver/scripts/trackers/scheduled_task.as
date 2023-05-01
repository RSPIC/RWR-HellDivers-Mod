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
#include "all_parameter.as"
//Author： rst
//周期任务脚本
//1、自动回甲：每4秒回复四层，倒地和死亡状态无效
//2、进入服务器，右上角显示游玩提示
//3、首次使用107火提示教程
//4、指定延时任务

//机甲武器替换护甲
dictionary EXO_Armor = {

        // 空
        {"",-1},

        {"hd_exo44_walker_mk3_mg.weapon","hd_exo44_walker_mk3_missile.weapon"},
        {"hd_exo44_walker_mk3_missile.weapon","hd_exo44_walker_mk3_mg.weapon"},
        {"hd_exo48_obsidian_mk3_cannon.weapon","null"},
        {"hd_exo51_lumberer_mk3_cannon.weapon","hd_exo51_lumberer_mk3_flame.weapon"},
        {"hd_exo51_lumberer_mk3_flame.weapon","hd_exo51_lumberer_mk3_cannon.weapon"},

        // 占位的
        {"666",-1}

};
//计时任务
dictionary timer_task = {

        // 空
        {"",-1},

        {"ex_cl_banzai",1},

        // 占位的
        {"666",-1}

};

class PlayerInfo {
    protected string m_name;
    protected const XmlElement@ m_player;
    protected float m_cd_time;
    protected float m_count_time;
    protected array<bool> m_first_time;

    PlayerInfo(string name, const XmlElement@ player, float cd_time) {
        m_name = name;
        @m_player = @player;
        m_cd_time = cd_time;
        m_count_time = cd_time;
		m_first_time.insertLast(true);//id：0 检测首次使用机甲
		m_first_time.insertLast(true);//id：1 检测首次使用107火箭炮
		m_first_time.insertLast(true);//id：2 检测首次使用刺雷 
    }

    string getName() {
        return m_name;
    }

    const XmlElement@ getPlayer() {
        return m_player;
    }

    void updatePlayer(const XmlElement@ player) {
        @m_player = @player;
    }

    void setTime(float cd_time) {
        m_cd_time = cd_time;
    }

    float getTimer() {
        return m_count_time;
    }

	bool isFirst(uint i){
		if(i < m_first_time.length()){
			return m_first_time[i];
		}
		return false;
	}
	void noFirst(uint i){
		if(i < m_first_time.length()){
			m_first_time[i] = false;
		}
	}
}

class PlayerInfoBucket {
    array<PlayerInfo@> m_allPlayers;

    PlayerInfo@ findPlayerByName(const string&in name) {
        for (uint i = 0; i < m_allPlayers.length(); ++i) {
            if (m_allPlayers[i].getName() == name) {
                return m_allPlayers[i];
            }
        }
        return null;
    }

	bool exists(const string&in name) {
        return findPlayerByName(name) !is null;
    }

    void addPlayer(string name, const XmlElement@ player, float cd_time = 5.0f) {
		if(player is null){return;}
        if (findPlayerByName(name) is null) {
            PlayerInfo@ newPlayer = PlayerInfo(name, player, cd_time);
            m_allPlayers.insertLast(newPlayer);
        }
    }
    void updatePlayer(string name, const XmlElement@ player) {
		if(player is null){return;}
		for (uint i = 0; i < m_allPlayers.length(); ++i) {
			if (m_allPlayers[i].getName() == name) {
				m_allPlayers[i].updatePlayer(player);
				break;
			}
        }
    }

    void removePlayerByName(const string&in name) {
        for (uint i = 0; i < m_allPlayers.length(); ++i) {
            if (m_allPlayers[i].getName() == name) {
                m_allPlayers.removeAt(i);
				i--;
                break;
            }
        }
    }

	void outputTest(){
		for (uint i = 0; i < m_allPlayers.length(); ++i) {
        	string name = m_allPlayers[i].getName();
            _log("outputTest, list: "+i+" name= "+name);
        }
	}
}
funcdef void FUNC_PTR(string p_name);

// --------------------------------------------
class scheduled_task : Tracker {
	protected GameModeInvasion@ m_metagame;
	protected float m_maxIdleTime;
	protected float m_timer;
	protected PlayerInfoBucket allplayers;
	protected array<float> m_timer_list;	//延时时间
	protected array<bool> m_timer_list_flag;	//启动flag
	protected array<string> m_timer_list_key;	//存储使用对象或者key
	protected array<string> m_timer_list_name;	//存储列表名用于查询和二次修改
	protected array<FUNC_PTR@> m_timer_list_func; //函数指针
	protected array<int> m_counter; //计数器
	protected array<int> m_counter_cd; //计数器
	protected bool debug_mode;
	protected bool first_bgm;
	protected bool m_ended;

	// --------------------------------------------
	scheduled_task(GameModeInvasion@ metagame, float time = 4.0) {
		@m_metagame = @metagame;
		const UserSettings@ settings = m_metagame.getUserSettings();
        debug_mode = settings.m_debug_mode;
		if(debug_mode){
			_log("debug_mode is on ");
		}
        
		m_maxIdleTime = time;
		m_timer = m_maxIdleTime;
		m_counter.insertLast(0); //天使无人机mk3计数
		m_counter_cd.insertLast(0); //天使无人机mk3计数

		first_bgm=false;	//进入游戏加载BGM
		m_ended = false;	//是否结束
	}
	
	// --------------------------------------------
	void update(float time) {
		m_timer -= time;
		if (m_timer < 0.0) {
			refresh();
			//_log("scheduled task refresh");
			m_timer = m_maxIdleTime;
		}
		for(uint p=0 ; p<m_timer_list_func.length() ; p++){
			if(p >= m_timer_list_flag.length()){continue;}
			if(m_timer_list_flag[p]){
				if(p >= m_timer_list.length()){continue;}
				m_timer_list[p] -= time;
				if(m_timer_list[p] <= 0.0){
					m_timer_list_func[p](m_timer_list_key[p]);
					m_timer_list_func.removeAt(p);
					m_timer_list_flag.removeAt(p);
					m_timer_list_key.removeAt(p);
					m_timer_list_name.removeAt(p);
					m_timer_list.removeAt(p);
					p--;
				}
			}
		}

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
	protected void refresh() {
		// query player positions
		array<const XmlElement@> players = getPlayers(m_metagame);
		for (uint j = 0; j < players.size(); ++j) {
			const XmlElement@ player = players[j];
			if(player is null){continue;}
			// ignore admins and mods
			// string name = player.getStringAttribute("name");
			// if (m_metagame.getAdminManager().isAdmin(name) || 
			//     m_metagame.getModeratorManager().isModerator(name)) {
			// 	continue;
			// }

			if (player.hasAttribute("character_id")) {
				//自动回甲
				AutoHeal(m_metagame,player);
				
				//机甲武器检测
				EXOArmorChange(m_metagame,player);

				//107火箭炮使用教程
				Tutor_63type_107mm(m_metagame,player);

				//刺雷使用教程
				checkBanzai(m_metagame,player);

				//自动天使治疗
				autoAngel(m_metagame,player);
			}
		}
	}
	// ----------------------------------------------------
	protected void autoAngel(Metagame@ m_metagame,const XmlElement@&in player){
		//倒地自动奶
		int cid = player.getIntAttribute("character_id");
		const XmlElement@ character = getCharacterInfo(m_metagame,cid);
		if(character !is null){
			string equipKey = getPlayerEquipmentKey(m_metagame,cid,1);//副武器栏
			if(equipKey == "hd_drone_ad289_angel_mk3.weapon"){
				if(m_counter_cd[0] >= 0){
					if(m_counter_cd[0] == 0){ //cd结束
						if(m_counter[0] >= 0 ){
							if(m_counter[0] == 0){
								m_counter[0]=3;		//3x4s
								m_counter_cd[0]=3;	//3x4s
								return;
							}
							Vector3 t_pos = stringToVector3(character.getStringAttribute("position"));
							Vector3 s_pos = t_pos.add(Vector3(0,0,0));
							int fid = character.getIntAttribute("faction_id");
							for(int c=0;c<2;c++){
								s_pos = s_pos.add(Vector3(0,0,0));
								CreateDirectProjectile(m_metagame,s_pos,t_pos,"hd_drone_ad289_angel_heal.projectile",cid,fid,10);
							}
							m_counter[0]--;
							return;
						}
					}
					m_counter_cd[0]--;
				}
			}
		}
	}
	// ----------------------------------------------------
	protected void checkBanzai(Metagame@ m_metagame,const XmlElement@&in player){
		if(player is null){return;}
		int cid = player.getIntAttribute("character_id");
		string p_name = player.getStringAttribute("name");
		
		if(allplayers.exists(p_name)){//玩家存在
			PlayerInfo@ m_playerinfo = allplayers.findPlayerByName(p_name);
			if(m_playerinfo.isFirst(2)){//本局首次使用检测
				string equipKey_sec = getPlayerEquipmentKey(m_metagame,cid,1);//副手武器
				if(equipKey_sec == "ex_cl_banzai.weapon" ){
					int pid = player.getIntAttribute("player_id");
					notify(m_metagame, "Help - Banzai", dictionary(), "misc", pid, true, "Banzai Help", 1.0);
					m_playerinfo.noFirst(2);
					editPlayerVest(m_metagame,cid,"helldivers_vest.carry_item",4);//替换为默认甲，此处为防止过图卡脚本执行bug
				}
			}
		}
	}
	// ----------------------------------------------------
	protected void Tutor_63type_107mm(Metagame@ m_metagame,const XmlElement@&in player){
		if(player is null){return;}
		int cid = player.getIntAttribute("character_id");
		string p_name = player.getStringAttribute("name");
		
		if(allplayers.exists(p_name)){//玩家存在
			PlayerInfo@ m_playerinfo = allplayers.findPlayerByName(p_name);
			if(m_playerinfo.isFirst(1)){//本局首次使用检测
				string equipKey_sec = getPlayerEquipmentKey(m_metagame,cid,1);//副手武器
				if(equipKey_sec == "63type_107mm_rocket_launcher_resource.weapon" ){
					int pid = player.getIntAttribute("player_id");
					notify(m_metagame, "Help - 63Type 107mm", dictionary(), "misc", pid, true, "63Type 107mm Help", 1.0);
					m_playerinfo.noFirst(1);
				}
			}
		}
		
	}
	// ----------------------------------------------------
	protected void AutoHeal(Metagame@ m_metagame,const XmlElement@&in player){
		if(player is null){return;}
		//自动回甲
		int cid = player.getIntAttribute("character_id");
		const XmlElement@ character = getCharacterInfo(m_metagame,cid);
		if(character !is null){
			int wounded = character.getIntAttribute("wounded");
			int dead = character.getIntAttribute("dead");
			//int p_cid = character.getIntAttribute("character_id");
			if(dead !=1 && wounded != 1){
				string equipKey = getPlayerEquipmentKey(m_metagame,cid,4);//护甲
				string key = "anti_hit_vest";
				equipKey = equipKey.substr(0,key.length());
				if(equipKey != key){
					healCharacter(m_metagame,cid,4);
					return;
				}
			}
		}
	}
	// ----------------------------------------------------
	protected void EXOArmorChange(Metagame@ m_metagame,const XmlElement@&in player){
		if(m_ended){return;}
		if(player is null){return;}
		//机甲检测
		int pid = player.getIntAttribute("player_id");
		int cid = player.getIntAttribute("character_id");
		string p_name = player.getStringAttribute("name");

		string equipKey_main = getPlayerEquipmentKey(m_metagame,cid,0);//主手武器
		int equipKey_main_amount = getPlayerEquipmentAmount(m_metagame,cid,0);//主手武器数量
		string equipKey_sec = getPlayerEquipmentKey(m_metagame,cid,1);//副手武器
		int equipKey_sec_amount = getPlayerEquipmentAmount(m_metagame,cid,1);//副手武器数量 
		//slot: 0主手 1副手 2投掷物 4护甲
		if(string(EXO_Armor[equipKey_sec]) != "" || string(EXO_Armor[equipKey_main]) != ""){

			if(allplayers.exists(p_name)){//本局首次使用检测
				PlayerInfo@ m_playerinfo = allplayers.findPlayerByName(p_name);
				if(m_playerinfo.isFirst(0)){
					notify(m_metagame, "Help - EXO-2", dictionary(), "misc", pid, true, "EXO-Help", 1.0);
					notify(m_metagame, "Help - EXO-3", dictionary(), "misc", pid, false, "EXO-Help", 1.0);
					m_playerinfo.noFirst(0);
				}
			}
			//检查是否为配套武器（主手对应副手、副手对应主手)
			if( equipKey_main == string(EXO_Armor[equipKey_sec]) ||  equipKey_sec == string(EXO_Armor[equipKey_main]) ||
				string(EXO_Armor[equipKey_sec]) == "null" 		 ||  string(EXO_Armor[equipKey_main]) == "null"		
			){
				if(string(EXO_Armor[equipKey_sec]) == "null" ){
					if(equipKey_main_amount != 0){
						//非正常配装，发送警告
						notify(m_metagame, "Warning - EXO single", dictionary(), "misc", pid, true, "EXO Warning", 1.0);
						editPlayerVest(m_metagame,cid,"hd_v40",4);//替换为0层甲
						return;
					}
				}
				if(string(EXO_Armor[equipKey_main]) == "null" ){
					if(equipKey_sec_amount != 0){
						//非正常配装，发送警告
						notify(m_metagame, "Warning - EXO single", dictionary(), "misc", pid, true, "EXO Warning", 1.0);
						editPlayerVest(m_metagame,cid,"hd_v40",4);//替换为0层甲
						return;
					}
				}
				string equipKey_vest = getPlayerEquipmentKey(m_metagame,cid,4);//检查护甲
				string key = "anti_hit_vest";
				equipKey_vest = equipKey_vest.substr(0,key.length());
				if(equipKey_vest != key){
					notify(m_metagame, "EXO Armor onload", dictionary(), "misc", pid, false, "", 1.0);
					editPlayerVest(m_metagame,cid,"anti_hit_vest.carry_item",4);
					return;
				}
				
			}else{
				//非正常配装，发送警告
				notify(m_metagame, "Warning - EXO", dictionary(), "misc", pid, true, "EXO Warning", 1.0);
				editPlayerVest(m_metagame,cid,"hd_v40",4);//替换为0层甲
				return;
			}
		}else{ //卸下机甲
			string equipKey_vest = getPlayerEquipmentKey(m_metagame,cid,4);//检查护甲
			string key = "anti_hit_vest";
			equipKey_vest = equipKey_vest.substr(0,key.length());
			if(equipKey_vest == key){
				editPlayerVest(m_metagame,cid,"helldivers_vest.carry_item",4);
				notify(m_metagame, "EXO Armor offload", dictionary(), "misc", pid, false, "", 1.0);
				return;
			}
		}
	}

	// ----------------------------------------------------
	protected void handleMatchEndEvent(const XmlElement@ event) {
		m_ended = true;
		const XmlElement@ winCondition = event.getFirstElementByTagName("win_condition");
		if (winCondition !is null) {
			if(debug_mode){
				allplayers.outputTest();
			}

			//factionId = winCondition.getIntAttribute("faction_id");
		}
	}
	// ----------------------------------------------------
	protected void handlePlayerDisconnectEvent(const XmlElement@ event) {
		const XmlElement@ player = event.getFirstElementByTagName("player");
		if (player !is null) {
			string name = player.getStringAttribute("name");
			if(allplayers.exists(name)){
				_log("player disconnect, name = "+ name);
				allplayers.removePlayerByName(name);
			}
		}		
	}	
	// ----------------------------------------------------
	protected void handlePlayerConnectEvent(const XmlElement@ event) {
		if(!first_bgm){
			array<string> bgmList = {
				"cyborgs_fighting_bgm_1.wav",
				"cyborgs_fighting_bgm_2.wav",
				"cyborgs_fighting_bgm_3.wav",
				"cyborgs_fighting_bgm_4.wav",
				"cyborgs_fighting_bgm_5.wav",
				"cyborgs_fighting_bgm_6.wav",
				"cyborgs_fighting_bgm_7.wav",
				"cyborgs_searching_bgm_1.wav",
				"cyborgs_searching_bgm_1.wav",
				"cyborgs_searching_bgm_2.wav",
				"cyborgs_searching_bgm_2.wav"
			};
			int soundrnd= rand(0,bgmList.length() - 1);
			playSoundtrack(m_metagame,bgmList[soundrnd]);
			first_bgm = true;
		}

		const XmlElement@ playerinfo = event.getFirstElementByTagName("player");
		if(playerinfo is null){return;}
		int p_id = playerinfo.getIntAttribute("player_id");
		const XmlElement@ player = getPlayerInfo(m_metagame,p_id);
		if (player !is null) {
			string name = player.getStringAttribute("name");
			_log("player connect, name = "+ name);
			if(!allplayers.exists(name)){
				allplayers.addPlayer(name,player);
			}else if(allplayers.exists(name)){
				allplayers.updatePlayer(name,player);
			}
			int pid = player.getIntAttribute("player_id");
			if(!debug_mode){
				gameHelp(m_metagame,pid);
			}
		}		
	}
	// ----------------------------------------------------
	protected void handlePlayerSpawnEvent(const XmlElement@ event) {
		const XmlElement@ playerinfo = event.getFirstElementByTagName("player");
		if(playerinfo is null){return;}
		int pid = playerinfo.getIntAttribute("player_id");
		const XmlElement@ player = getPlayerInfo(m_metagame,pid);
		if (player !is null) {
			string name = player.getStringAttribute("name");
			_log("player connect, name = "+ name);
			if(!allplayers.exists(name)){
				allplayers.addPlayer(name,player);
			}else if(allplayers.exists(name)){
				allplayers.updatePlayer(name,player);
			}
		}		
	}

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
		notify(m_metagame, "Help - Samples", dictionary(), "misc", pid, true, "Samples Help", 1.0);
		notify(m_metagame, "Help - Alert", dictionary(), "misc", pid, true, "Alert Help", 1.0);
		notify(m_metagame, "Help - Repair", dictionary(), "misc", pid, true, "Repair Help", 1.0);
		notify(m_metagame, "Help - EXO", dictionary(), "misc", pid, true, "EXO Help", 1.0);
		notify(m_metagame, "Help - Cyborgs", dictionary(), "misc", pid, true, "Cyborgs Help", 1.0);
		notify(m_metagame, "Help - Reward", dictionary(), "misc", pid, true, "Reward Help", 1.0);
		notify(m_metagame, "Help - Reward-2", dictionary(), "misc", pid, true, "Reward Help", 1.0);
		notify(m_metagame, "Help - Dynamic Alert", dictionary(), "misc", pid, true, "Dynamic Alert Help", 1.0);
	}

	protected void handleResultEvent(const XmlElement@ event) {
		string EventKeyGet = event.getStringAttribute("key");
		_log("projectile event key[st]= " + EventKeyGet);
		//_log("int(timer_task[EventKeyGet])= " + int(timer_task[EventKeyGet]));
		if(int(timer_task[EventKeyGet]) != 0){
		//_log("swtiching");
			switch (int(timer_task[EventKeyGet])){
				case 1:{//刺雷
					if(m_ended){return;}

					int characterId = event.getIntAttribute("character_id");
					const XmlElement@ character = getCharacterInfo(m_metagame, characterId);	
					if(character is null){return;}
					int pid = character.getIntAttribute("player_id");
					if(pid == -1){return;}
					const XmlElement@ playerinfo  = getPlayerInfo(m_metagame,pid);
					if(playerinfo is null){return;}
					string p_name = playerinfo.getStringAttribute("name");

					//-----------------------------------------
					for(uint p=0 ; p<m_timer_list_func.length() ; p++){	//判断是否二次触发,直接执行自爆
						if(p >= m_timer_list_flag.length()){continue;}
						if(m_timer_list_key[p] == p_name){
							if(m_timer_list_name[p] == "banzai"){
								m_timer_list_func[p](m_timer_list_key[p]);
								m_timer_list_func.removeAt(p);
								m_timer_list_flag.removeAt(p);
								m_timer_list_key.removeAt(p);
								m_timer_list_name.removeAt(p);
								m_timer_list.removeAt(p);
								p--;
								return;
							}
						}
					}

					m_timer_list_flag.insertLast(true);	//启动
					m_timer_list_key.insertLast(p_name);//key,玩家名
					m_timer_list.insertLast(2.5);	//延时时间
					FUNC_PTR@ callback = FUNC_PTR(banzai);	//目标函数
					m_timer_list_func.insertLast(callback);
					m_timer_list_name.insertLast("banzai"); //列表名
					//-----------------------------------------

				//_log("sending delay task case 1");
					//发专属甲
					if(character !is null){
						int wounded = character.getIntAttribute("wounded");
						int dead = character.getIntAttribute("dead");
						if(dead !=1 && wounded != 1){
							string equipKey = getPlayerEquipmentKey(m_metagame,characterId,4);//护甲
							notify(m_metagame, "BanZai Armor onload", dictionary(), "misc", pid, false, "", 1.0);
							editPlayerVest(m_metagame,characterId,"hd_banzai_0",4);
						}
					}
					break;
				}
			}
		}
	}
	protected void banzai(string p_name){
		if(m_ended){return;}
		//_log("exe banzai");
		if(allplayers.exists(p_name)){
			//_log("player "+p_name+" exists");
			PlayerInfo@ playerinfo = allplayers.findPlayerByName(p_name);
			const XmlElement@ player = playerinfo.getPlayer();
			if(player is null){return;}
			int cid = player.getIntAttribute("character_id");
			int fid = player.getIntAttribute("faction_id");
			const XmlElement@ character = getCharacterInfo(m_metagame,cid);
			if(character !is null){
				int wounded = character.getIntAttribute("wounded");
				int dead = character.getIntAttribute("dead");
				if(dead !=1 && wounded != 1){
					string c_position = character.getStringAttribute("position");
					spawnStaticProjectile(m_metagame,"ex_cl_banzai_damage.projectile",c_position,cid,fid);
				}
			}
		}
	}
}
