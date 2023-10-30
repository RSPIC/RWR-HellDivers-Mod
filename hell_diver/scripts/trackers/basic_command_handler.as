// internal
#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "generic_call_task.as"
#include "task_sequencer.as"
#include "all_task.as"
#include "all_parameter.as"

#include "INFO.as"
#include "debug_reporter.as"

// --------------------------------------------
class BasicCommandHandler : Tracker {
	protected Metagame@ m_metagame;

	// --------------------------------------------
	BasicCommandHandler(Metagame@ metagame) {
		@m_metagame = @metagame;

	}
	// --------------------------------------------
		// .substr 字符截取函数 substr(string string（文本), int a(截取起始位置), int b(截取长度))
		// .trim() 函数移除字符串两侧的空白字符或其他预定义字符
		// .split() 划分字符串
		// command 和 prenumber是什么作用？
	array<string> MassageBreakUp(string message, string command, int preNumber) 
		{
			string s = message.trim().substr(command.length() + preNumber + 1);
			array<string> a = s.split(" ");
			return a;
		}
		
	// ------------------------------------------------------
	protected void spawnInstanceAtbackpack(int senderId, string key, string type, string num = "1"){
		const XmlElement@ playerInfo = getPlayerInfo(m_metagame, senderId);
		int cid = playerInfo.getIntAttribute("character_id");
		if(type == "vehicle"){
			dictionary dict = {{"TagName", "command"},{"class", "chat"},{"text", "can't spawn vehicle"}};
			m_metagame.getComms().send(XmlElement(dict));
			return;
		}
		float number = parseFloat(num);
		for(float a = 1; a <= number ; a++){
			string command = 
				"<command class='update_inventory' character_id='" + cid + "' container_type_class='backpack'>" + 
					"<item class='" + type + "' key='" + key + "' />" +
				"</command>";
			m_metagame.getComms().send(command);	
		}
	}

	
	// ----------------------------------------------------
	protected void handleChatEvent(const XmlElement@ event) {
		// player_id
		// player_name
		// message
		// global

		string message = event.getStringAttribute("message");
	
		// 建立字符串索引
		array<string> word = MassageBreakUp(message, " ", -1);
		int ws = word.size();
		if (ws == 0) return;
		// 检测指令发出者的名字和ID
		string sender = event.getStringAttribute("player_name");
		int senderId = event.getIntAttribute("player_id");
	
		// for the most part, chat events aren't commands, so check that first 
	
		
		// admin and moderator only from here on
		if(!g_online_TestMode){
			if (!m_metagame.getAdminManager().isAdmin(sender, senderId) && !m_metagame.getModeratorManager().isModerator(sender, senderId)) {
			return;
			}
		}
		
		
		if (checkCommand(message, "modtest")) {
			dictionary dict = {{"TagName", "command"},{"class", "chat"},{"text", "mod or admin"}};
			m_metagame.getComms().send(XmlElement(dict));
		} else if (checkCommand(message, "sidinfo")) {
			handleSidInfo(message,senderId);
		} else if (checkCommand(message, "kick_id")) {
			handleKick(message, senderId, true);
		} else if (checkCommand(message, "kick")) {
			handleKick(message, senderId);
		} else if (checkCommand(message, "0_win")) {
			m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='1' />");
			m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='2' />");
			m_metagame.getComms().send("<command class='set_match_status' win='1' faction_id='0' />");
		} else if (checkCommand(message, "1_win")) {
			m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='0' />");
			m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='2' />");
			m_metagame.getComms().send("<command class='set_match_status' win='1' faction_id='1' />");
		} else if (checkCommand(message, "1_lose")) {
			m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='1' />");
		} else if (checkCommand(message, "1_own")) {
			int factionId = 1;
			array<const XmlElement@> bases = getBases(m_metagame);
			for (uint i = 0; i < bases.size(); ++i) {
				const XmlElement@ base = bases[i];
				if (base.getIntAttribute("owner_id") != factionId) {
					XmlElement command("command");
					command.setStringAttribute("class", "update_base");
					command.setIntAttribute("base_id", base.getIntAttribute("id"));
					command.setIntAttribute("owner_id", factionId);
					m_metagame.getComms().send(command);
				}
			}
		}
		
		// admin only from here on ------------------------------------------------------------------------
		if(!g_online_TestMode){
			if (!m_metagame.getAdminManager().isAdmin(sender, senderId)) {
				return;
			}
		}

		// 任意数值rp xp获取
		if (matchString(word[0], "grp")) {
			const XmlElement@ info = getPlayerInfo(m_metagame, senderId);
			if(ws == 2){
				string num = word[1];
				if (info !is null) {
				int id = info.getIntAttribute("character_id");
				string command =
					"<command class='rp_reward'" +
					"	character_id='" + id + "'" +
					"	reward='"+ num +"'>" + // multiplier affected..
					"</command>";
				m_metagame.getComms().send(command);
				}
			}
		} else if (matchString(word[0], "gxp")){
			const XmlElement@ info = getPlayerInfo(m_metagame, senderId);
			if(ws == 2){
				string num = word[1];
				if (info !is null) {
				int id = info.getIntAttribute("character_id");
				string command =
					"<command class='xp_reward'" +
					"	character_id='" + id + "'" +
					"	reward='"+ num +"'>" + // multiplier affected..
					"</command>";
				m_metagame.getComms().send(command);
				}
			}
		}else if(matchString(word[0], "promote")){
			const XmlElement@ info = getPlayerInfo(m_metagame, senderId);
			if (info !is null) {
				int id = info.getIntAttribute("character_id");
				float xpnum = 1000;
				float rpnum = 1000000;
				string command =
					"<command class='xp_reward'" +
					"	character_id='" + id + "'" +
					"	reward='"+ xpnum +"'>" + // multiplier affected..
					"</command>";
				m_metagame.getComms().send(command);
				command =
					"<command class='rp_reward'" +
					"	character_id='" + id + "'" +
					"	reward='"+ rpnum +"'>" + // multiplier affected..
					"</command>";
				m_metagame.getComms().send(command);
			}
		}
		
		// 检测自己的玩家信息
		if (checkCommand(message, "mycid")){
			const XmlElement@ info = getPlayerInfo(m_metagame, senderId);
			int characterId = info.getIntAttribute("character_id");
			dictionary dict = {{"TagName", "command"},{"class", "chat"},{"text", characterId}};
			m_metagame.getComms().send(XmlElement(dict));
		} else if (checkCommand(message, "myname")){
			dictionary dict = {{"TagName", "command"},{"class", "chat"},{"text", sender}};
			m_metagame.getComms().send(XmlElement(dict));
		} else if (checkCommand(message, "mysid")){
			dictionary dict = {{"TagName", "command"},{"class", "chat"},{"text", senderId}};
			m_metagame.getComms().send(XmlElement(dict));
		}

		// 设定指定坐标
		if (matchString(word[0], "tag")) {
			if (ws == 1){
				const XmlElement@ info = getPlayerInfo(m_metagame, senderId);
				int characterId = info.getIntAttribute("character_id");
				@info = getCharacterInfo(m_metagame, characterId);
				string posStr = info.getStringAttribute("position");
				_log("set tag at " + posStr, 1);
				string command = "<command class='set_marker' faction_id='0' position='" + posStr + "' color='0 0 1' atlas_index='0' text='" + posStr + "' />";
				m_metagame.getComms().send(command);
				dictionary dict = {{"TagName", "command"},{"class", "chat"},{"text", "set tag at "+ posStr}};
				m_metagame.getComms().send(XmlElement(dict));
			}else if (ws == 4){
				string X = word[1];
				string Y = word[2];
				string Z = word[3];
				_log("set tag at "+ X + " " + Y + " " + Z, 1);
				string command = "<command class='set_marker' faction_id='0' position='" + X + " " + Y + " " + Z + "' color='0 0 1' atlas_index='0' text='" + X + " " + Y + " " + Z + "' />";
				m_metagame.getComms().send(command);
				dictionary dict = {{"TagName", "command"},{"class", "chat"},{"text", "set tag at "+ X + " " + Y + " " + Z}};
				m_metagame.getComms().send(XmlElement(dict));
			}
		}
		// 生成各类物品
		if (matchString(word[0], "v")) {
			if (ws == 1){return;}
			string key = word[1];
			if (ws == 2){
			spawnInstanceNearPlayer(senderId, key + ".vehicle", "vehicle");
			} 
		} else if (matchString(word[0], "w")) {
			if (ws == 1){return;}
			string key = word[1];
			if (ws == 2){
			spawnInstanceAtbackpack(senderId, key + ".weapon", "weapon");
			} else if (ws == 3){
			spawnInstanceAtbackpack(senderId, key + ".weapon", "weapon", word[2]);
			}
		}else if (matchString(word[0], "p")) {
			if (ws == 1){return;}
			string key = word[1];
			if (ws == 2){
			spawnInstanceAtbackpack(senderId, key + ".projectile", "projectile");
			} else if (ws == 3){
			spawnInstanceAtbackpack(senderId, key + ".projectile", "projectile", word[2]);
			}
		}else if (matchString(word[0], "c")) {
			if (ws == 1){return;}
			string key = word[1];
			if (ws == 2){
			spawnInstanceAtbackpack(senderId, key , "carry_item");
			} else if (ws == 3){
			spawnInstanceAtbackpack(senderId, key , "carry_item", word[2]);
			}
		}
		// ---------------------------------------------------------------------------------------------------------------
		
		// it's a silent server command, check which one
		if (checkCommand(message, "test")) {
			const XmlElement@ info = getPlayerInfo(m_metagame, senderId);
			if (info is null) {return;}
			int cid = info.getIntAttribute("character_id");
			const XmlElement@ character = getCharacterInfo(m_metagame,cid);
			if(character is null){return;}
			int fid = 0;
			Vector3 ePos = stringToVector3(info.getStringAttribute("aim_target"));
			Vector3 sPos = ePos.add(Vector3(0,30,0));
			string key1 = "acg_exo_toki_ai_spawn.projectile";
			string key2 = "acg_exo_toki_falling.projectile";
			float speed = 25;
			CreateDirectProjectile(m_metagame,sPos,ePos,key1,cid,fid,speed);
			CreateDirectProjectile(m_metagame,ePos,ePos,key2,cid,fid,0);
		} else if (checkCommand(message, "defend")) {
			// make ai defend only, both sides
			for (int i = 0; i < 2; ++i) {
				string command =
					"<command class='commander_ai'" +
					"	faction='" + i + "'" +
					"	base_defense='1.0'" +
					"	border_defense='0.0'>" +
					"</command>";
				m_metagame.getComms().send(command);
			}
			sendPrivateMessage(m_metagame, senderId, "defensive ai set");

		} else if (checkCommand(message, "0_attack")) {
			// make ai attack only, both sides
			string command =
				"<command class='commander_ai'" +
				"	faction='0'" +
				"	base_defense='0.0'" +
				"	border_defense='0.0'>" +
				"</command>";
			m_metagame.getComms().send(command);
			sendPrivateMessage(m_metagame, senderId, "attack green ai set");

		} else if (checkCommand(message, "whereami")) {
			_log("whereami received", 1);
			const XmlElement@ info = getPlayerInfo(m_metagame, senderId);
			if (info !is null) {
				int characterId = info.getIntAttribute("character_id");
				@info = getCharacterInfo(m_metagame, 1);
				if (info !is null) {
					string posStr = info.getStringAttribute("position");
					Vector3 pos = stringToVector3(posStr);
					string region = m_metagame.getRegion(pos);

					string text = posStr + ", " + region;

					sendPrivateMessage(m_metagame, senderId, text);
				} else {
					_log("character info not ok", 1);
				}
			} else {
				_log("player info not ok", 1);
			}
		} else  if(checkCommand(message, "kill_aa")) {
			for (uint f = 1; f < 3; ++f) {
				array<const XmlElement@>@ vehicles = getVehicles(m_metagame, f, "aa_emplacement.vehicle");
				
				for (uint i = 0; i < vehicles.size(); ++i) {
					const XmlElement@ vehicle = vehicles[i];
					int id = vehicle.getIntAttribute("id");
					destroyVehicle(m_metagame, id);
				}
			}
		} else  if(checkCommand(message, "god")) {
			// .. god vest!
			spawnInstanceNearPlayer(senderId, "god_vest.carry_item", "carry_item"); 
		} else if (checkCommand(message, "jeep")) {
			spawnInstanceNearPlayer(senderId, "jeep.vehicle", "vehicle");
		} else if (checkCommand(message, "squad")) {
			spawnInstanceNearPlayer(senderId, "default_ai", "soldier", 0);
			spawnInstanceNearPlayer(senderId, "default_ai", "soldier", 0);
			spawnInstanceNearPlayer(senderId, "default_ai", "soldier", 0);
			spawnInstanceNearPlayer(senderId, "default_ai", "soldier", 0);
			spawnInstanceNearPlayer(senderId, "default_ai", "soldier", 0);
			spawnInstanceNearPlayer(senderId, "default_ai", "soldier", 0);
			spawnInstanceNearPlayer(senderId, "default_ai", "soldier", 0);
			spawnInstanceNearPlayer(senderId, "default_ai", "soldier", 0);
			spawnInstanceNearPlayer(senderId, "default_ai", "soldier", 0);
			spawnInstanceNearPlayer(senderId, "default_ai", "soldier", 0);
        } else if (checkCommand(message, "esquad")) {
			spawnInstanceNearPlayer(senderId, "default_ai", "soldier", 1);                               
			spawnInstanceNearPlayer(senderId, "default_ai", "soldier", 1);                               
			spawnInstanceNearPlayer(senderId, "default_ai", "soldier", 1);                               
			spawnInstanceNearPlayer(senderId, "default_ai", "soldier", 1);                               
			spawnInstanceNearPlayer(senderId, "default_ai", "soldier", 1);                               
			spawnInstanceNearPlayer(senderId, "default_ai", "soldier", 1);                               
			spawnInstanceNearPlayer(senderId, "default_ai", "soldier", 1);                               
			spawnInstanceNearPlayer(senderId, "default_ai", "soldier", 1);                               
			spawnInstanceNearPlayer(senderId, "default_ai", "soldier", 1);                               
			spawnInstanceNearPlayer(senderId, "default_ai", "soldier", 1);                               
		} else  if(checkCommand(message, "aiwound")) {
			const XmlElement@ info = getPlayerInfo(m_metagame, senderId);
			int characterId = info.getIntAttribute("character_id");
			for (int i = 2; i < 200; ++i) {
				if ( i == characterId ) continue;
				string command =
					"<command class='update_character'" +
					"	id='" + i + "'" +	
					"   wounded='1'>" + 
					"</command>";
				m_metagame.getComms().send(command);
			}
		} else  if(checkCommand(message, "aidead")) {
			const XmlElement@ info = getPlayerInfo(m_metagame, senderId);
			int characterId = info.getIntAttribute("character_id");
			for (int i = 2; i < 200; ++i) {
				if ( i == characterId ) continue;
				string command =
					"<command class='update_character'" +
					"	id='" + i + "'" +
					"	dead='1'>" + 
					"</command>";
				m_metagame.getComms().send(command);
			}
		} else  if(checkCommand(message, "wound")) {
			const XmlElement@ info = getPlayerInfo(m_metagame, senderId);
			int characterId = info.getIntAttribute("character_id");
				string command =
					"<command class='update_character'" +
					"	id='" + characterId + "'" +	
					"   wounded='1'>" + 
					"</command>";
				m_metagame.getComms().send(command);
			
		} else  if(checkCommand(message, "dead")) {
			const XmlElement@ info = getPlayerInfo(m_metagame, senderId);
			int characterId = info.getIntAttribute("character_id");
				string command =
					"<command class='update_character'" +
					"	id='" + characterId + "'" +	
					"   dead='1'>" + 
					"</command>";
				m_metagame.getComms().send(command);
			
		} else if (checkCommand(message, "fill")) {
			fillInventory(senderId);
		} else if(checkCommand(message, "pa")) {
			const XmlElement@ playerInfo = getPlayerInfo(m_metagame, senderId);
			const XmlElement@ characterInfo = getCharacterInfo(m_metagame, playerInfo.getIntAttribute("character_id"));
			Vector3 pos = stringToVector3(playerInfo.getStringAttribute("aim_target"));	
			pos=pos.add(Vector3(0,1,0));
			string c = 
				"<command class='create_instance'" +
				" faction_id='" + 0 + "'" +
				" instance_class='grenade'" +
				" instance_key='" + "test_particle.projectile" + "'" +
				" position='" + pos.toString() + "'" +
				" character_id='" + playerInfo.getIntAttribute("character_id") + "'/>";				
			m_metagame.getComms().send(c);
		
		} else if(checkCommand(message, "spawncall")) {
			const XmlElement@ playerInfo = getPlayerInfo(m_metagame, senderId);
			const XmlElement@ characterInfo = getCharacterInfo(m_metagame, playerInfo.getIntAttribute("character_id"));
			Vector3 pos1 = stringToVector3(characterInfo.getStringAttribute("position"));	
			Vector3 pos2 = stringToVector3(playerInfo.getStringAttribute("aim_target"));	
			pos2=pos2.add(Vector3(0,1,0));
			Event_call_helldiver_superearth_airstrike@ new_task = Event_call_helldiver_superearth_airstrike(m_metagame,2.0,playerInfo.getIntAttribute("character_id"),playerInfo.getIntAttribute("faction_id"),pos1,pos2,"hd_superearth_airstrike_1");
			TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
			tasker.add(new_task);
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
	void handleKick(string message, int senderId, bool id = false) {
		const XmlElement@ player = getPlayerByIdOrNameFromCommand(m_metagame, message, id);
		if (player !is null) {
			int playerId = player.getIntAttribute("player_id");
			string name = player.getStringAttribute("name");
			notify(m_metagame, "kicking player", dictionary = {{"%player_name", name}}, "misc");

			notify(m_metagame, "Kicked from server", dictionary(), "misc", playerId, true, "", 1.0);
            ::kickPlayer(m_metagame, playerId);

		} else {
			//_log("* couldn't find a match for name=" + name + "");
			sendPrivateMessage(m_metagame, senderId, "kick missed!");
		}
	}
	
	// --------------------------------------------
	void handleSidInfo(string message, int senderId) {
		// get name given as parameter
		string name = message.substr(string("sidinfo ").length() + 1);

		// assuming player name 
		// ask for player list from the server
		array<const XmlElement@> playerList = getPlayers(m_metagame);
		_log("* "  + playerList.size() + " players found");
		
		// go through the player list and match for the given name
		bool foundFlag = false;
		string playerSid = "";
		for (uint i = 0; i < playerList.size(); ++i) {
			const XmlElement@ player = playerList[i];
			string name2 = player.getStringAttribute("name");
			// case insensitive
			if (name2.toLowerCase() == name.toLowerCase()) {
				// found it
				playerSid = player.getStringAttribute("sid");
				foundFlag = true;
				break;
			}
		}
		if (foundFlag){
			sendPrivateMessage(m_metagame, senderId, "player " + name + " found, SID: " + playerSid);
		} else {
			_log("* couldn't find a match for " + name);
			sendPrivateMessage(m_metagame, senderId, "player not found");
		}
	}
	
	// ----------------------------------------------------
	protected void spawnInstanceNearPlayer(int senderId, string key, string type, int factionId = 0, bool skydive = false) {
		_log("spawnInstanceNearPlayer");
		_log("pid ="+senderId+" name="+g_playerInfoBuck.getNameByPid(senderId));
		const XmlElement@ playerInfo = getPlayerInfo(m_metagame, senderId);
		if (playerInfo !is null) {
			const XmlElement@ characterInfo = getCharacterInfo(m_metagame, playerInfo.getIntAttribute("character_id"));
			if (characterInfo !is null) {
				Vector3 pos = stringToVector3(characterInfo.getStringAttribute("position"));
				pos.m_values[0] += 5.0;
				if (skydive) {
					pos.m_values[1] += 50.0;
				}
				string c = "<command class='create_instance' instance_class='" + type + "' instance_key='" + key + "' position='" + pos.toString() + "' faction_id='" + factionId + "' />";
				m_metagame.getComms().send(c);
			}
		}
	}

	// ----------------------------------------------------
	protected void destroyAllFactionVehicles(uint f, string key) {
		array<const XmlElement@>@ vehicles = getVehicles(m_metagame, f, key);
		
		for (uint i = 0; i < vehicles.size(); ++i) {
			const XmlElement@ vehicle = vehicles[i];
			int id = vehicle.getIntAttribute("id");
			destroyVehicle(m_metagame, id);
		}
	}

	// ----------------------------------------------------
	protected void destroyAllEnemyVehicles(string key) {
		for (uint f = 1; f < 3; ++f) {
			destroyAllFactionVehicles(f, key);
		}
	}

	// ----------------------------------------------------
	protected void addItem(XmlElement@ command, Resource@ r) {
		XmlElement i("item"); 
		i.setStringAttribute("class", r.m_type); 
		i.setStringAttribute("key", r.m_key); 
		command.appendChild(i); 
	}

	// ----------------------------------------------------
	protected void fillInventory(int senderId) {
		const XmlElement@ player = getPlayerInfo(m_metagame, senderId);
		if (player !is null) {
			const XmlElement@ characterInfo = getCharacterInfo(m_metagame, player.getIntAttribute("character_id"));
			if (characterInfo !is null) {
				int characterId = player.getIntAttribute("character_id");
				XmlElement c("command");
				c.setStringAttribute("class", "update_inventory");

				c.setIntAttribute("character_id", characterId); 
				c.setStringAttribute("container_type_class", "backpack");
				
				for (uint i = 0; i < 3; ++i) {
					array<string> typeStr1 = {"weapon", "grenade", "carry_item"};
					array<string> typeStr2 = {"weapons", "grenades", "carry_items"};
					for (uint k = 0; k < typeStr1.size(); ++k) {
						array<const XmlElement@>@ resources = getFactionResources(m_metagame, i, typeStr1[k], typeStr2[k]);
						for (uint j = 0; j < resources.size(); ++j) {
							const XmlElement@ item = resources[j];
							addItem(c, Resource(item.getStringAttribute("key"), typeStr1[k]));
						}
					}
				}
				
				m_metagame.getComms().send(c);
			}
		}
	}
}
