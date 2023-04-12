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

//周期任务脚本
//1、自动回甲：每4秒回复四层，倒地和死亡状态无效
//2、进入服务器，右上角显示游玩提示
//3、首次使用107火提示教程

//机甲武器替换护甲
dictionary EXO_Armor = {

        // 空
        {"",-1},

        {"hd_exo44_walker_mk3_mg.weapon","hd_exo44_walker_mk3_missile.weapon"},
        {"hd_exo44_walker_mk3_missile.weapon","hd_exo44_walker_mk3_mg.weapon"},
        {"hd_exo48_obsidian_mk3_cannon.weapon","hd_exo48_obsidian_mk3_cannon.weapon"},
        {"hd_exo51_lumberer_mk3_cannon.weapon","hd_exo51_lumberer_mk3_flame.weapon"},
        {"hd_exo51_lumberer_mk3_flame.weapon","hd_exo51_lumberer_mk3_cannon.weapon"},

        // 占位的
        {"666",-1}

};

class PlayerInfo {
    protected string m_name;
    protected const XmlElement@ m_player;
    protected float m_cd_time;
    protected float m_count_time;
    protected array<bool> m_first_time;
	// 0_检测首次机甲使用

    PlayerInfo(string name, const XmlElement@ player, float cd_time) {
        m_name = name;
        @m_player = @player;
        m_cd_time = cd_time;
        m_count_time = cd_time;
		m_first_time.insertLast(true);//id：0 检测首次使用机甲
		m_first_time.insertLast(true);//id：1 检测首次使用107火箭炮
		m_first_time.insertLast(true);//id：2 
    }

    string getName() {
        return m_name;
    }

    const XmlElement@ getPlayer() {
        return m_player;
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
        if (findPlayerByName(name) is null) {
            PlayerInfo@ newPlayer = PlayerInfo(name, player, cd_time);
            m_allPlayers.insertLast(newPlayer);
        }
    }

    void removePlayerByName(const string&in name) {
        for (uint i = 0; i < m_allPlayers.length(); ++i) {
            if (m_allPlayers[i].getName() == name) {
                m_allPlayers.removeAt(i);
                break;
            }
        }
    }
}


// --------------------------------------------
class scheduled_task : Tracker {
	protected GameMode@ m_metagame;
	protected float m_maxIdleTime;
	protected float m_timer;
	protected PlayerInfoBucket allplayers;

	// --------------------------------------------
	scheduled_task(GameMode@ metagame, float time = 4.0) {
		@m_metagame = @metagame;

		m_maxIdleTime = time;
		m_timer = m_maxIdleTime;
	}
	
	// --------------------------------------------
	void update(float time) {
		m_timer -= time;
		if (m_timer < 0.0) {
			refresh();
			_log("scheduled task refresh");
			m_timer = m_maxIdleTime;
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
			}
		}
	}
	// ----------------------------------------------------
	protected void Tutor_63type_107mm(Metagame@ m_metagame,const XmlElement@&in player){
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
		//自动回甲
		int cid = player.getIntAttribute("character_id");
		const XmlElement@ character = getCharacterInfo(m_metagame,cid);
		if(character !is null){
			int wounded = character.getIntAttribute("wounded");
			int dead = character.getIntAttribute("dead");
			//int p_cid = character.getIntAttribute("character_id");
			if(dead !=1 && wounded != 1){
				string equipKey = getPlayerEquipmentKey(m_metagame,cid,4);//护甲
				bool marker=false;
				for(int ii=0;ii<=300;ii++){
					string armorName = "anti_hit_vest_"+ii;
					if(equipKey == armorName || equipKey == "anti_hit_vest.carry_item"){
						marker = true;
						break;
					}
				}
				if(!marker){
					healCharacter(m_metagame,cid,4);
				}
			}
		}
	}
	// ----------------------------------------------------
	protected void EXOArmorChange(Metagame@ m_metagame,const XmlElement@&in player){
		//机甲检测
		int pid = player.getIntAttribute("player_id");
		int cid = player.getIntAttribute("character_id");
		string p_name = player.getStringAttribute("name");

		string equipKey_main = getPlayerEquipmentKey(m_metagame,cid,0);//主手武器
		string equipKey_sec = getPlayerEquipmentKey(m_metagame,cid,1);//副手武器
		//slot: 0主手 1副手 2投掷物 4护甲
		if(string(EXO_Armor[equipKey_sec]) != "" || string(EXO_Armor[equipKey_main]) != ""){

			if(allplayers.exists(p_name)){//本局首次使用检测
				PlayerInfo@ m_playerinfo = allplayers.findPlayerByName(p_name);
				if(m_playerinfo.isFirst(0)){
					notify(m_metagame, "Help - EXO-2", dictionary(), "misc", pid, false, "EXO Help", 1.0);
					notify(m_metagame, "Help - EXO-3", dictionary(), "misc", pid, false, "EXO Help", 1.0);
					m_playerinfo.noFirst(0);
				}
			}
			//检查是否为配套武器（主手对应副手、副手对应主手、单独副手、单独主手)
			if(		equipKey_main == string(EXO_Armor[equipKey_sec]) ||  equipKey_sec == string(EXO_Armor[equipKey_main]) 
				||  equipKey_sec == string(EXO_Armor[equipKey_sec])  ||  equipKey_main == string(EXO_Armor[equipKey_main])){
				string equipKey_vest = getPlayerEquipmentKey(m_metagame,cid,4);//检查护甲
				if(equipKey_vest != "anti_hit_vest.carry_item"){
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
			for(int i=0;i<=300;i++){
				string armorName = "anti_hit_vest_"+i;
				if(equipKey_vest == armorName || equipKey_vest == "anti_hit_vest.carry_item"){
					editPlayerVest(m_metagame,cid,"helldivers_vest.carry_item",4);
					notify(m_metagame, "EXO Armor offload", dictionary(), "misc", pid, false, "", 1.0);
					return;
				}
			}
		}
	}

	// ----------------------------------------------------
	protected void handlePlayerDisconnectEvent(const XmlElement@ event) {
		const XmlElement@ player = event.getFirstElementByTagName("player");
		if (player !is null) {
			string name = player.getStringAttribute("name");
			if(allplayers.exists(name)){
				allplayers.removePlayerByName(name);
			}
		}		
	}	
	// ----------------------------------------------------
	protected void handlePlayerConnectEvent(const XmlElement@ event) {
		const XmlElement@ player = event.getFirstElementByTagName("player");
		if (player !is null) {
			string name = player.getStringAttribute("name");
			if(!allplayers.exists(name)){
				allplayers.addPlayer(name,player);
			}
			int pid = player.getIntAttribute("player_id");
			gameHelp(m_metagame,pid);
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

}
