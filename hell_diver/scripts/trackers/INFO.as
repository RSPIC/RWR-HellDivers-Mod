

#include "admin_manager.as"
#include "tracker.as"
#include "debug_reporter.as"
#include "schedule_IRQ.as"
#include "math.as"

//author:RST
//阵营信息
//玩家基本信息

class factionInfo {
	protected int m_fid;
	protected string m_name;	//faction_name
	protected dictionary m_soldier_groups;	//with spawn_score

	factionInfo(int fid,string name,array<const XmlElement@> groups){
		m_fid = fid;
		m_name = name;
		for(uint j =0; j<groups.size(); ++j){
			string groupsName = groups[j].getStringAttribute("name");
			float spawn_score = groups[j].getIntAttribute("spawn_score");
			m_soldier_groups[groupsName] = spawn_score;
		}
	}
	bool get(string group_name){
		float spawn_score;
		if(m_soldier_groups.get(group_name,spawn_score)){
			return true;
		}
		return false;
	}
	bool get(int fid,string name,string group_name){
		if(fid == m_fid && name == m_name){
			float spawn_score;
			if(m_soldier_groups.get(group_name,spawn_score)){
				return true;
			}
		}
		return false;
	}
	bool get(int fid,string group_name){
		if(fid == m_fid){
			float spawn_score;
			if(m_soldier_groups.get(group_name,spawn_score)){
				return true;
			}
		}
		return false;
	}
	int getFid(string group_name){
		float spawn_score;
		if(m_soldier_groups.get(group_name,spawn_score)){
			return m_fid;
		}
		return -1;
	}
	string getNameByFid(int fid){
		if(m_fid == fid){
			return m_name;
		}
		return "";
	}
	int getFidByName(string name){
		if(m_name == name){
			return m_fid;
		}
		return -1;
	}
	float getScore(string group_name){
		float spawn_score;
		if(m_soldier_groups.get(group_name,spawn_score)){
			return spawn_score;
		}
		return 0;
	}
	float getScore(int fid,string name,string group_name){
		if(fid == m_fid && name == m_name){
			float spawn_score;
			if(m_soldier_groups.get(group_name,spawn_score)){
				return spawn_score;
			}
		}
		return 0;
	}
	float getScore(int fid,string group_name){
		if(fid == m_fid){
			float spawn_score;
			if(m_soldier_groups.get(group_name,spawn_score)){
				return spawn_score;
			}
		}
		return 0;
	}
}
class factionInfoBuck {
	protected array<factionInfo@> m_factionInfo;	

	factionInfoBuck(){
		clearAll();
	}

	uint size(){
		return m_factionInfo.size();
	}
	void addNewInfo(int fid,string name,array<const XmlElement@> groups){
		factionInfo@ info = factionInfo(fid, name, groups);
    	m_factionInfo.insertLast(info);
		return;
	}
	bool get(string group_name,int fid = -1,string name = ""){
		for(uint i=0; i<size(); ++i){
			if(name != "" && fid != -1){
				if(m_factionInfo[i].get(fid,name,group_name)){
					return true;
				}
			}else if(fid != -1){
				if(m_factionInfo[i].get(fid,group_name)){
					return true;
				}
			}else{
				if(m_factionInfo[i].get(group_name)){
					return true;
				}
			}
		}
		return false;
	}
	float getScore(string group_name,int fid = -1,string name = ""){
		for(uint i=0; i<size(); ++i){
			if(name != "" && fid != -1){
				if(m_factionInfo[i].get(fid,name,group_name)){
					return m_factionInfo[i].getScore(fid,name,group_name);
				}
			}else if(fid != -1){
				if(m_factionInfo[i].get(fid,group_name)){
					return m_factionInfo[i].getScore(fid,group_name);
				}
			}else{
				if(m_factionInfo[i].get(group_name)){
					return m_factionInfo[i].getScore(group_name);
				}
			}
		}
		return 0;
	}
	int getFidByGroupName(string group_name){
		for(uint i=0; i<size(); ++i){
			if(m_factionInfo[i].getFid(group_name) != -1){
				return m_factionInfo[i].getFid(group_name);
			}
		}
		return -1;
	}
	string getNameByFid(int fid){
		for(uint i=0; i<size(); ++i){
			if(m_factionInfo[i].getNameByFid(fid) != ""){
				return m_factionInfo[i].getNameByFid(fid);
			}
		}
		return "";
	}
	int getFidByName(string name){
		for(uint i=0; i<size(); ++i){
			if(m_factionInfo[i].getFidByName(name) != -1){
				return m_factionInfo[i].getFidByName(name);
			}
		}
		return -1;
	}
	void clearAll(){
		m_factionInfo.resize(0);
	}
}
//----------------------------------------------------------
class playerInfo {
	string m_name;
	string m_group;
	int m_pid;
	int m_cid;
	int m_fid;
	int m_dead;
	int m_wound;
	float m_xp;
	float m_rp;
	string m_hash;
	string m_sid;
	bool m_english_player = false;

	playerInfo(const string&in name,const int&in pid,const int&in cid,const int&in fid,const int&in dead,const int&in wound,const float&in xp,const float&in rp,string group = "default"){
		m_name = name;
		m_group = group;
		m_pid = pid;
		m_cid = cid;
		m_fid = fid;
		m_dead = dead;
		m_wound = wound;
		m_xp = xp;
		m_rp = rp;
	}

	void update(const string&in name,const int&in pid,const int&in cid,const int&in fid,const int&in dead,const int&in wound,const float&in xp,const float&in rp,string group = "default"){
		m_name = name;
		m_group = group;
		m_pid = pid;
		m_cid = cid;
		m_fid = fid;
		m_dead = dead;
		m_wound = wound;
		m_xp = xp;
		m_rp = rp;
	}

	string output(){
		string data = "debugOPT"+"name="+m_name+" "+
		"pid="+m_pid+" "+
		"cid="+m_cid+" "+
		"sid="+m_sid+" "+
		"fid="+m_fid+" "+
		"hash="+m_hash+" ";
		return data;
	}
	bool compare(playerInfo@ new){
		if(m_name == new.m_name ||
		m_pid == new.m_pid ||
		m_cid == new.m_cid ||
		m_hash == new.m_hash ||
		m_sid == new.m_sid 
		){
			_log("compare the same data");
			_log(output());
			_log(new.output());
			return true;
		}
		return false;
	}

	string getName(){return m_name;}
	string getGroup(){return m_group;}
	string getHash(){return m_hash;}
	string getSid(){return m_sid;}
	int getPid(){return m_pid;}
	int getCid(){return m_cid;}
	int getFid(){return m_fid;}
	int getWound(){return m_wound;}
	int getDead(){return m_dead;}
	float getXp(){return m_xp;}
	float getRp(){return m_rp;}

	void updateWound(int wound){m_wound = wound;}
	void setHash(string&in hash){m_hash = hash;}
	void setSid(string&in sid){m_sid = sid;}
	bool setEnglishPlayer(){
		m_english_player = !m_english_player;
		return m_english_player;
	}
	bool isEng(){
		return m_english_player;
	}

	int getCidByPid(int&in pid){
		if(m_pid == pid){
			return m_cid;
		}
		return -1;
	}
	int getCidByName(string&in name){
		if(m_name == name){
			return m_cid;
		}
		return -1;
	}
	int getFidByPid(int&in pid){
		if(m_pid == pid){
			return m_fid;
		}
		return -1;
	}
	int getFidByCid(int&in cid){
		if(m_cid == cid){
			return m_fid;
		}
		return -1;
	}
	int getPidByCid(int&in cid){
		if(m_cid == cid){
			return m_pid;
		}
		return -1;
	}
	int getPidByName(string&in name){
		if(m_name == name){
			return m_pid;
		}
		return -1;
	}
	string getNameByCid(int&in cid){
		if(m_cid == cid){
			return m_name;
		}
		return "";
	}
	string getNameByPid(int&in pid){
		if(m_pid == pid){
			return m_name;
		}
		return "";
	}

}

class playerInfoBuck{
	protected array<playerInfo@> m_playerInfo;
	protected Metagame@ metagame;

	string output(){
		string data;
		_log("m_playerInfo.size="+size());
		for(uint i=0; i<size();++i){
			string data0 = m_playerInfo[i].output();
			_log("index="+i+" "+data0);
			data = data + data0;
		}
		return data;
	}
	void refresh(){
		for(uint i=0; i<size();++i){
			playerInfo@ m_info = m_playerInfo[i];
			for(uint j=0; j<size();++j){
				if(j == i){continue;}
				if(m_info.compare(m_playerInfo[j])){
					_log("find same info in playerinfos,refresh");
					updateAll();
				}
			}
		}
	}

	void updateAll(){
		_log("updateAll 301");
		if(metagame is null){return;}
		array<const XmlElement@> players = getPlayers(metagame);
        clearAll();
        for(uint i = 0 ; i < players.size() ; i++){
            const XmlElement@ player = players[i];
            if(player is null){continue;}
            string name = player.getStringAttribute("name");
            string profile_hash = player.getStringAttribute("profile_hash");
            string sid = player.getStringAttribute("sid");
            int cid = player.getIntAttribute("character_id");
            int pid = player.getIntAttribute("player_id");
            if(g_debugMode) _report(metagame,"更新玩家CID，玩家名为="+name+",CID为="+cid);
            int fid = player.getIntAttribute("faction_id");
            const XmlElement@ character = getCharacterInfo(metagame,cid);
            if(character is null){continue;}
            int wound = character.getIntAttribute("wounded");
            int dead = character.getIntAttribute("dead");
            string group = character.getStringAttribute("soldier_group_name");
            float xp = character.getFloatAttribute("xp");
            float rp = character.getFloatAttribute("rp");
            addNewInfo(name,pid,cid,fid,dead,wound,xp,rp,group);
            setHash(name,profile_hash);
            setSid(name,sid);
        }
		output();
	}

	playerInfoBuck(){
		clearAll();
	}
	playerInfoBuck(Metagame@ in_metagame){
		@metagame = @in_metagame;
		clearAll();
	}

	uint size(){return m_playerInfo.size();}

	void addNewInfo(string&in name,int&in pid,int&in cid,int&in fid,int&in dead,int&in wound,float&in xp,float&in rp,string group = "default"){
		if(m_playerInfo !is null){
			update(name,pid,cid,fid,dead,wound,xp,rp,group);
		}
		playerInfo@ newInfo = playerInfo(name,pid,cid,fid,dead,wound,xp,rp,group);
		m_playerInfo.insertLast(newInfo);
		_log("addNewInfo");
		output();
		refresh();
	}

	void update(string&in name,int&in pid,int&in cid,int&in fid,int&in dead,int&in wound,float&in xp,float&in rp,string group = "default"){
		for(uint i=0; i<size();++i){
			if(name == m_playerInfo[i].getName()){
				m_playerInfo[i].update(name,pid,cid,fid,dead,wound,xp,rp,group);
			}
		}
		_log("update");
		output();
		refresh();
	}

	bool exists(string name){
		for(uint i=0; i<size();++i){
			if(name == m_playerInfo[i].getName()){
				return true;
			}
		}
		return false;
	}

	void outPutTest(Metagame@ m_metagame){
		for(uint i=0; i<size();++i){
			string name = m_playerInfo[i].getName();
			int cid = m_playerInfo[i].getCid();
			_report(m_metagame,"玩家名="+name+"。CID为="+cid);
		}
	}

	int getCidByPid(int&in pid){
		for(uint i=0; i<size();++i){
			int cid = m_playerInfo[i].getCidByPid(pid);
			if(cid != -1){
				return cid;
			}
		}
		return -1;
	}
	int getCidByPid(Metagame@ m_metagame,int&in pid){
		array<const XmlElement@> players = getPlayers(m_metagame);
		for(uint j = 0; j < players.size() ; ++j){
			const XmlElement@ player = players[j];
			if(player is null){continue;}
			if(pid == player.getIntAttribute("player_id")){
				return player.getIntAttribute("character_id");
			}
		}
		return -1;
	}
	int getCidByName(string&in name){
		for(uint i=0; i<size();++i){
			int cid = m_playerInfo[i].getCidByName(name);
			if(cid != -1){
				return cid;
			}
		}
		return -1;
	}
	int getCidByName(Metagame@ m_metagame,string&in name){
		array<const XmlElement@> players = getPlayers(m_metagame);
		for(uint j = 0; j < players.size() ; ++j){
			const XmlElement@ player = players[j];
			if(player is null){continue;}
			if(name == player.getStringAttribute("name")){
				return player.getIntAttribute("character_id");
			}
		}
		return -1;
	}
	int getFidByPid(int&in pid){
		for(uint i=0; i<size();++i){
			int fid = m_playerInfo[i].getFidByPid(pid);
			if(fid != -1){
				return fid;
			}
		}
		return -1;
	}
	int getFidByPid(Metagame@ m_metagame,int&in pid){
		array<const XmlElement@> players = getPlayers(m_metagame);
		for(uint j = 0; j < players.size() ; ++j){
			const XmlElement@ player = players[j];
			if(player is null){continue;}
			if(pid == player.getIntAttribute("player_id")){
				return player.getIntAttribute("faction_id");
			}
		}
		return -1;
	}
	int getFidByCid(int&in cid){
		for(uint i=0; i<size();++i){
			int fid = m_playerInfo[i].getFidByCid(cid);
			if(fid != -1){
				return fid;
			}
		}
		return -1;
	}
	int getFidByCid(Metagame@ m_metagame,int&in cid){
		array<const XmlElement@> players = getPlayers(m_metagame);
		for(uint j = 0; j < players.size() ; ++j){
			const XmlElement@ player = players[j];
			if(player is null){continue;}
			if(cid == player.getIntAttribute("character_id")){
				return player.getIntAttribute("faction_id");
			}
		}
		return -1;
	}
	int getPidByCid(int&in cid){
		for(uint i=0; i<size();++i){
			int pid = m_playerInfo[i].getPidByCid(cid);
			if(pid != -1){
				return pid;
			}
		}
		return -1;
	}
	int getPidByCid(Metagame@ m_metagame,int&in cid){
		array<const XmlElement@> players = getPlayers(m_metagame);
		for(uint j = 0; j < players.size() ; ++j){
			const XmlElement@ player = players[j];
			if(player is null){continue;}
			if(cid == player.getIntAttribute("character_id")){
				return player.getIntAttribute("player_id");
			}
		}
		return -1;
	}
	int getPidByName(string&in name){
		for(uint i=0; i<size();++i){
			int pid = m_playerInfo[i].getPidByName(name);
			if(pid != -1){
				return pid;
			}
		}
		return -1;
	}
	int getPidByName(Metagame@ m_metagame,string&in name){
		array<const XmlElement@> players = getPlayers(m_metagame);
		for(uint j = 0; j < players.size() ; ++j){
			const XmlElement@ player = players[j];
			if(player is null){continue;}
			if(name == player.getStringAttribute("name")){
				return player.getIntAttribute("player_id");
			}
		}
		return -1;
	}
	string getNameByCid(int&in cid){
		for(uint i=0; i<size();++i){
			string name = m_playerInfo[i].getNameByCid(cid);
			if(name != ""){
				return name;
			}
		}
		return "";
	}
	string getNameByCid(Metagame@ m_metagame,int&in cid){
		array<const XmlElement@> players = getPlayers(m_metagame);
		for(uint j = 0; j < players.size() ; ++j){
			const XmlElement@ player = players[j];
			if(player is null){continue;}
			if(cid == player.getIntAttribute("character_id")){
				return player.getStringAttribute("name");
			}
		}
		return "";
	}
	string getNameByPid(int&in pid){
		for(uint i=0; i<size();++i){
			string name = m_playerInfo[i].getNameByPid(pid);
			if(name != ""){
				return name;
			}
		}
		return "";
	}
	string getNameByPid(Metagame@ m_metagame,int&in pid){
		array<const XmlElement@> players = getPlayers(m_metagame);
		for(uint j = 0; j < players.size() ; ++j){
			const XmlElement@ player = players[j];
			if(player is null){continue;}
			if(pid == player.getIntAttribute("player_id")){
				return player.getStringAttribute("name");
			}
		}
		return "";
	}
	void removeByName(string name){
		for(uint i=0; i<size();++i){
			string p_name = m_playerInfo[i].getName();
			if(name == p_name){
				m_playerInfo.removeAt(i);
				--i;
			}
		}
	}

	int getWoundByName(string name){
		for(uint i=0; i<size();++i){
			if(name == m_playerInfo[i].getName()){
				return m_playerInfo[i].getWound();
			}
		}
		return -1;
	}
	int getDeadByName(string name){
		for(uint i=0; i<size();++i){
			if(name == m_playerInfo[i].getName()){
				return m_playerInfo[i].getDead();
			}
		}
		return -1;
	}
	int getRpByCid(int&in cid){
		for(uint i=0; i<size();++i){
			if(cid == m_playerInfo[i].getCid()){
				return int(m_playerInfo[i].getRp());
			}
		}
		return -1;
	}
	string getHashByName(string&in name){
		for(uint i=0; i<size();++i){
			if(name == m_playerInfo[i].getName()){
				return m_playerInfo[i].getHash();
			}
		}
		return "";
	}
	string getHashByName(Metagame@ m_metagame,string&in name){
		array<const XmlElement@> players = getPlayers(m_metagame);
		for(uint j = 0; j < players.size() ; ++j){
			const XmlElement@ player = players[j];
			if(player is null){continue;}
			if(name == player.getStringAttribute("name")){
				return player.getStringAttribute("profile_hash");
			}
		}
		return "";
	}
	string getHashBySid(string&in sid){
		for(uint i=0; i<size();++i){
			if(sid == m_playerInfo[i].getSid()){
				return m_playerInfo[i].getHash();
			}
		}
		return "";
	}
	string getHashBySid(Metagame@ m_metagame,string&in sid){
		array<const XmlElement@> players = getPlayers(m_metagame);
		for(uint j = 0; j < players.size() ; ++j){
			const XmlElement@ player = players[j];
			if(player is null){continue;}
			if(sid == player.getStringAttribute("sid")){
				return player.getStringAttribute("profile_hash");
			}
		}
		return "";
	}
	string getSidByHash(string&in hash){
		for(uint i=0; i<size();++i){
			if(hash == m_playerInfo[i].getHash()){
				return m_playerInfo[i].getSid();
			}
		}
		return "";
	}
	string getSidByHash(Metagame@ m_metagame,string&in hash){
		array<const XmlElement@> players = getPlayers(m_metagame);
		for(uint j = 0; j < players.size() ; ++j){
			const XmlElement@ player = players[j];
			if(player is null){continue;}
			if(hash == player.getStringAttribute("profile_hash")){
				return player.getStringAttribute("sid");
			}
		}
		return "";
	}
	string getSidByName(string&in name){
		if(g_single_player && g_playerCount <= 1){
            return "ID0"; // 单机模式固定玩家的SID为0，防止变动
        }
		for(uint i=0; i<size();++i){
			if(name == m_playerInfo[i].getName()){
				return m_playerInfo[i].getSid();
			}
		}
		return "";
	}
	string getSidByName(Metagame@ m_metagame,string&in name){
		if(g_single_player && g_playerCount <= 1){
            return "ID0"; // 单机模式固定玩家的SID为0，防止变动
        }
		array<const XmlElement@> players = getPlayers(m_metagame);
		for(uint j = 0; j < players.size() ; ++j){
			const XmlElement@ player = players[j];
			if(player is null){continue;}
			if(name == player.getStringAttribute("name")){
				return player.getStringAttribute("sid");
			}
		}
		return "";
	}
	float getXpByName(string&in name){
		for(uint i=0; i<size();++i){
			if(name == m_playerInfo[i].getName()){
				return m_playerInfo[i].getXp();
			}
		}
		return -1;
	}
	string getGroupByName(string&in name){
		for(uint i=0; i<size();++i){
			if(name == m_playerInfo[i].getName()){
				return m_playerInfo[i].getGroup();
			}
		}
		return "";
	}

	void updateWound(string&in name,int&in wound){
		for(uint i=0; i<size();++i){
			if(name == m_playerInfo[i].getName()){
				m_playerInfo[i].updateWound(wound);
			}
		}
	}
	void setHash(string&in name,string&in hash){
		for(uint i=0; i<size();++i){
			if(name == m_playerInfo[i].getName()){
				m_playerInfo[i].setHash(hash);
			}
		}
	}
	void setSid(string&in name,string&in sid){
		for(uint i=0; i<size();++i){
			if(name == m_playerInfo[i].getName()){
				m_playerInfo[i].setSid(sid);
			}
		}
	}
	bool setEnglishPlayer(string name){
		for(uint i=0; i<size();++i){
			if(name == m_playerInfo[i].getName()){
				return m_playerInfo[i].setEnglishPlayer();
			}
		}
		return false;
	}
	bool isEng(string name){
		for(uint i=0; i<size();++i){
			if(name == m_playerInfo[i].getName()){
				return m_playerInfo[i].isEng();
			}
		}
		return false;
	}

	void clearAll(){
		m_playerInfo.resize(0);
	}

}
//----------------------------------------------------------
class battleInfo {
	protected string m_name;
	protected uint m_killCount;
	protected uint m_oneLifekillCount;
	protected uint m_counter;
	protected uint m_deadCount;
	protected uint m_tkCount;
	protected uint m_missionCount;
	protected int m_server_difficulty_level;
	protected uint m_playingTime; // 分钟
	protected float m_bonusFactor;
	protected float m_bonusFactorXp;
	protected float m_bonusFactorRp;

	battleInfo(string&in name , int&in level){
		m_name = name;
		m_killCount = 0;
		m_oneLifekillCount = 0;
		m_counter = 0;
		m_deadCount = 0;
		m_tkCount = 0;
		m_missionCount = 0;
		m_server_difficulty_level = level;
		m_playingTime = 0;	
		m_bonusFactor = 1.0;
		m_bonusFactorXp = 1.0;
		m_bonusFactorRp = 1.0;
	}

	string name(){return m_name;}
	uint killCount(){return m_killCount;}
	uint oneLifekillCount(){return m_oneLifekillCount;}
	uint deadCount(){return m_deadCount;}
	uint tkCount(){return m_tkCount;}
	uint missionCount(){return m_missionCount;}
	int level(){return m_server_difficulty_level;}
	uint playingTime(){return m_playingTime;}
	float bonusFactor(){return m_bonusFactor;}
	float bonusFactorXp(){return m_bonusFactorXp;}
	float bonusFactorRp(){return m_bonusFactorRp;}

	void addKill(string&in name){
		if(name == m_name){
			m_killCount++;
			m_counter++;
			if(m_counter > m_oneLifekillCount){
				m_oneLifekillCount = m_counter;
			}
		}
	}
	void addDead(string&in name){
		if(name == m_name){
			m_deadCount++;
			m_counter = 0;
		}
	}
	void addTk(string&in name){
		if(name == m_name){
			m_tkCount++;
		}
	}
	void addMission(string&in name){
		if(name == m_name){
			m_missionCount++;
		}
	}
	void addTime(string&in name){
		if(name == m_name){
			m_playingTime++;
		}
	}
	void setBonusFactor(string&in name,float&in factor){
		if(name == m_name){
			m_bonusFactor = factor;
		}
	}
	void setBonusFactorXp(string&in name,float&in factor){
		if(name == m_name){
			m_bonusFactorXp = factor;
		}
	}
	void setBonusFactorRp(string&in name,float&in factor){
		if(name == m_name){
			m_bonusFactorRp = factor;
		}
	}
}

class battleInfoBuck{
	protected array<battleInfo@> m_battleInfos;

	battleInfoBuck(){
		battleInfo@ newInfo = battleInfo("",0);
		m_battleInfos.insertLast(newInfo);
	}

	uint size(){
		return m_battleInfos.size();
	}
	int getKilled(string&in name){
		for(uint i=0;i<m_battleInfos.size();++i){
			string m_name = m_battleInfos[i].name();
			if(name == m_name){
				return m_battleInfos[i].killCount();
			}
		}
		return -1;
	}

	uint playingTime(string&in name){
		for(uint i=0;i<m_battleInfos.size();++i){
			string m_name = m_battleInfos[i].name();
			if(name == m_name){
				return m_battleInfos[i].playingTime();
			}
		}
		return 0;
	}
	float bonusFactor(string&in name){
		for(uint i=0;i<m_battleInfos.size();++i){
			string m_name = m_battleInfos[i].name();
			if(name == m_name){
				return m_battleInfos[i].bonusFactor();
			}
		}
		return -1;
	}
	float bonusFactorXp(string&in name){
		for(uint i=0;i<m_battleInfos.size();++i){
			string m_name = m_battleInfos[i].name();
			if(name == m_name){
				return m_battleInfos[i].bonusFactorXp();
			}
		}
		return -1;
	}
	float bonusFactorRp(string&in name){
		for(uint i=0;i<m_battleInfos.size();++i){
			string m_name = m_battleInfos[i].name();
			if(name == m_name){
				return m_battleInfos[i].bonusFactorRp();
			}
		}
		return -1;
	}

	void addInfo(string&in name,int&in level){
		if(m_battleInfos is null){_log("m_battleInfos is null");return;}
		for(uint i=0;i<m_battleInfos.size();++i){
			string m_name = m_battleInfos[i].name();
			if(name == m_name){
				return;
			}
		}
		battleInfo@ newInfo = battleInfo(name,level);
		m_battleInfos.insertLast(newInfo);
	}
	void removeInfo(string&in name){
		if(m_battleInfos is null){_log("m_battleInfos is null");return;}
		for(uint i=0;i<m_battleInfos.size();++i){
			string m_name = m_battleInfos[i].name();
			if(name == m_name){
				m_battleInfos.removeAt(i);
				i--;
			}
		}
	}
	bool exist(string&in name){
		for(uint i=0;i<m_battleInfos.size();++i){
			string m_name = m_battleInfos[i].name();
			if(name == m_name){
				return true;
			}
		}
		return false;
	}

	void addKill(string&in name){
		if(m_battleInfos is null){return;}
		for(uint i = 0 ; i < m_battleInfos.size() ; ++i){
			m_battleInfos[i].addKill(name);
		}
	}
	void addDead(string&in name){
		if(m_battleInfos is null){return;}
		for(uint i = 0 ; i < m_battleInfos.size() ; ++i){
			m_battleInfos[i].addDead(name);
		}
	}
	void addTk(string&in name){
		if(m_battleInfos is null){return;}
		for(uint i = 0 ; i < m_battleInfos.size() ; ++i){
			m_battleInfos[i].addTk(name);
		}
	}
	void addMission(string&in name){
		if(m_battleInfos is null){return;}
		for(uint i = 0 ; i < m_battleInfos.size() ; ++i){
			m_battleInfos[i].addMission(name);
		}
	}
	void addTime(){
		if(m_battleInfos is null){return;}
		for(uint i = 0 ; i < m_battleInfos.size() ; ++i){
			string name = m_battleInfos[i].name();
			if(g_playerInfoBuck !is null){
				if(g_playerInfoBuck.exists(name)){
					m_battleInfos[i].addTime(name);
				}
			}
		}
	}
	void setBonusFactor(string&in name,float&in factor){
		if(m_battleInfos is null){return;}
		for(uint i = 0 ; i < m_battleInfos.size() ; ++i){
			m_battleInfos[i].setBonusFactor(name,factor);
		}
	}
	void setBonusFactorXp(string&in name,float&in factor){
		if(m_battleInfos is null){return;}
		for(uint i = 0 ; i < m_battleInfos.size() ; ++i){
			m_battleInfos[i].setBonusFactorXp(name,factor);
		}
	}
	void setBonusFactorRp(string&in name,float&in factor){
		if(m_battleInfos is null){return;}
		for(uint i = 0 ; i < m_battleInfos.size() ; ++i){
			m_battleInfos[i].setBonusFactorRp(name,factor);
		}
	}
	void addBonusFactor(string&in name,float&in factor){
		if(m_battleInfos is null){return;}
		for(uint i = 0 ; i < m_battleInfos.size() ; ++i){
			m_battleInfos[i].setBonusFactor(name,m_battleInfos[i].bonusFactor()+factor);
		}
	}
	void addBonusFactorXp(string&in name,float&in factor){
		if(m_battleInfos is null){return;}
		for(uint i = 0 ; i < m_battleInfos.size() ; ++i){
			m_battleInfos[i].setBonusFactorXp(name,m_battleInfos[i].bonusFactorXp()+factor);
		}
	}
	void addBonusFactorRp(string&in name,float&in factor){
		if(m_battleInfos is null){return;}
		for(uint i = 0 ; i < m_battleInfos.size() ; ++i){
			m_battleInfos[i].setBonusFactorRp(name,m_battleInfos[i].bonusFactorRp()+factor);
		}
	}
	void setLoseBonusFactor(){
		if(m_battleInfos is null){return;}
		for(uint i = 0 ; i < m_battleInfos.size() ; ++i){
			m_battleInfos[i].setBonusFactor(m_battleInfos[i].name(),m_battleInfos[i].bonusFactor()*0.5);
		}
	}
	void setServerBonusFactor(float factor){
		if(m_battleInfos is null){return;}
		for(uint i = 0 ; i < m_battleInfos.size() ; ++i){
			m_battleInfos[i].setBonusFactor(m_battleInfos[i].name(),m_battleInfos[i].bonusFactor()+factor);
		}
	}
	void clearAll(){
		if(m_battleInfos is null){return;}
		m_battleInfos.resize(0);
	}

	float getXpReward(Metagame@ m_metagame,const XmlElement@ player,bool report = true){
		if(m_battleInfos is null || player is null){return 0;}
		int pid = player.getIntAttribute("player_id");
		string name = player.getStringAttribute("name");
		for(uint i = 0 ; i < m_battleInfos.size() ; ++i){
			if(m_battleInfos[i].name() == name){ 	//1.0=1w xp
				float xp;
				uint kc = m_battleInfos[i].killCount();
				uint oc = m_battleInfos[i].oneLifekillCount();//100连杀达到200xp，600时接近400xp，极限值400xp
				uint mc = m_battleInfos[i].missionCount(); 
				uint pt = m_battleInfos[i].playingTime();
				uint tc = m_battleInfos[i].tkCount();
				uint dc = m_battleInfos[i].deadCount();
				float bf = m_battleInfos[i].bonusFactor() + m_battleInfos[i].bonusFactorXp() - 1 - tc*0.04;
				if(pt >= 30){
					bf = bf*(1-(pt-30.0)/60.0);
					if(report){
						notify(m_metagame,"Battle Time Too Long,BonusFacto Decrease", dictionary(), "misc", pid, false, "", 1.0);
					}
				}
				if(bf > 10){
					bf = 10;
				}
				float pt_bf = bf; //游玩时长的独立倍率因子
				if(pt_bf <= 1){
					pt_bf = 1;
				}
				if(bf <= 0){
					bf = 0.01;
				}
				if(mc >= 8 ){	//防刷
					mc = 8;
				}
				float ptRewardBase = 0.1; //游玩时长奖励 1000xp
				float mcRewardBase = 0.75; //支线任务奖励 7500xp
				float kcRewardBase = 0.01; //杀敌奖励 100xp
				float ocRewardBase = 0.007; //连杀奖励 70xp
				float dcRewardBase = 0.03; //死亡奖励 300xp
				float tcPunishBase = 0.15; //TK惩罚 1500xp
				if(g_server_difficulty_level == 3){ //挂机服降低收益
					ptRewardBase = 0.05;
				}
				
				uint maxKc = kc;
				uint maxPt = pt;
				if(maxKc >= 1000){maxKc = 1000;}//最高只记录1000杀
				if(maxPt >= 30){maxPt = 30;} //最高只记录30分钟游玩时间
				xp = 
				  maxKc * kcRewardBase 
				+ oc * ocRewardBase*NormalizedConcaveCurve(0.002*oc,0.5) 
				+ dc * dcRewardBase
				- tc * tcPunishBase;
				if(bf < 1){
					xp = bf*(xp + mc*mcRewardBase)+pt_bf*maxPt*ptRewardBase; //游玩时长奖励和支线任务不参与乘算,超时除外
				}else{
					xp = xp*bf + maxPt*ptRewardBase + mc*mcRewardBase; //游玩时长奖励和支线任务不参与乘算
				}
				
				if(xp<=0){xp=0;}
				if(xp>=100){xp=100;}
				dictionary a;
				a["%kx"] = formatInt(int(maxKc*kcRewardBase*10000));
				a["%ox"] = formatInt(int(oc*ocRewardBase*NormalizedConcaveCurve(0.002*oc,0.5)*10000));
				a["%mx"] = formatInt(int(mc*mcRewardBase*10000));
				a["%px"] = formatInt(int(maxPt*ptRewardBase*10000));
				a["%tx"] = formatInt(int(tc*tcPunishBase*10000));
				a["%dx"] = formatInt(int(dc*dcRewardBase*10000));
				a["%kc"] = formatInt(kc);
				a["%oc"] = formatInt(oc);
				a["%mc"] = formatInt(mc);
				a["%pt"] = formatInt(pt);
				a["%tc"] = formatInt(tc);
				a["%dc"] = formatInt(dc);
				a["%bf"] = ""+bf;
				a["%xp"] = formatFloat(xp*10000);
				if(report){
					notify(m_metagame,"BattleEndRewardXP", a, "misc", pid, true, "Battle End Reward XP", 1.0);
				}
				return xp;
			}
		}
		return 0;
	}
	float getRpReward(Metagame@ m_metagame,const XmlElement@ player){
		if(m_battleInfos is null || player is null){return 0;}
		int pid = player.getIntAttribute("player_id");
		string name = player.getStringAttribute("name");
		for(uint i = 0 ; i < m_battleInfos.size() ; ++i){
			if(m_battleInfos[i].name() == name){ 	//1.0=1 rp
				float rp;
				uint kc = m_battleInfos[i].killCount();
				uint oc = m_battleInfos[i].oneLifekillCount();
				uint mc = m_battleInfos[i].missionCount(); 
				uint pt = m_battleInfos[i].playingTime();
				uint tc = m_battleInfos[i].tkCount();
				uint dc = m_battleInfos[i].deadCount();
				float bf = m_battleInfos[i].bonusFactor() + m_battleInfos[i].bonusFactorRp() - 1 - tc*0.04;
				if(pt >= 30){
					bf = bf*(1-(pt-30.0)/60.0);
					notify(m_metagame,"Battle Time Too Long,BonusFactor Decrease", dictionary(), "misc", pid, false, "", 1.0);
				}
				if(bf > 10){
					bf = 10;
				}
				float pt_bf = bf;
				if(pt_bf <= 1){ //游玩时长的独立倍率因子
					pt_bf = 1;
				}
				if(bf <= 0){
					bf = 0.01;
				}
				if(mc >= 8 ){	//防刷
					mc = 8;
				}
				int ptRewardBase = g_rp_ptRewardBase; //游玩时长奖励
				int mcRewardBase = 5000; //支线任务奖励
				int kcRewardBase = 50; //杀敌奖励
				int ocRewardBase = 15; //连杀奖励
				int tcPunishBase = 700; //TK惩罚
				if(g_server_difficulty_level == 3){ //挂机服降低收益
					ptRewardBase = 1000;
				}
				uint maxKc = kc;
				uint maxPt = pt;
				if(maxKc >= 1000){maxKc = 1000;} //最高只记录1000杀
				if(maxPt >= 30){maxPt = 30;} //最高只记录30分钟游玩时间
				rp = 
				maxKc * kcRewardBase
				+ oc * ocRewardBase*NormalizedConcaveCurve(0.002*oc,0.5)
				- tc * tcPunishBase;
				if(bf < 1){
					rp = bf*(rp  + mc*mcRewardBase) + pt_bf*maxPt*ptRewardBase; //游玩时长奖励和支线任务不参与乘算,超时除外
				}else{
					rp = rp*bf + maxPt*ptRewardBase + mc*mcRewardBase; //游玩时长奖励和支线任务不参与乘算
				}
				if(rp<=0){rp=0;}
				if(rp>=640000){rp=640000;} //上限
				dictionary a;
				a["%kx"] = formatInt(int(maxKc*kcRewardBase));
				a["%ox"] = formatInt(int(oc*ocRewardBase*NormalizedConcaveCurve(0.002*oc,0.5)));
				a["%mx"] = formatInt(int(mc*mcRewardBase));
				a["%px"] = formatInt(int(maxPt*ptRewardBase));
				a["%tx"] = formatInt(int(tc*tcPunishBase));
				a["%kc"] = formatInt(kc);
				a["%oc"] = formatInt(oc);
				a["%mc"] = formatInt(mc);
				a["%pt"] = formatInt(pt);
				a["%tc"] = formatInt(tc);
				a["%dc"] = formatInt(dc);
				a["%bf"] = ""+bf;
				a["%rp"] = formatFloat(rp);
				notify(m_metagame,"BattleEndRewardRP", a, "misc", pid, true, "Battle End Reward RP", 1.0);
				return rp;
			}
		}
		return 0;
	}
	bool getLootReward(string&in name){
		if(m_battleInfos is null){return false;}
		for(uint i = 0 ; i < m_battleInfos.size() ; ++i){
			if(m_battleInfos[i].name() == name){
				if(m_battleInfos[i].playingTime() >= 7 && m_battleInfos[i].playingTime() <= 30){
					if(m_battleInfos[i].tkCount() <= 1){
						if(m_battleInfos[i].missionCount() != 0){
							return true;
						}
					}
					if(m_battleInfos[i].deadCount() >= 20){
						return true;
					}
				}
				if(m_battleInfos[i].playingTime() >= 60){
					return true;
				}
				if(m_battleInfos[i].killCount() >= 750){
					return true;
				}
			}
		}
		return false;
	}
	bool gambleKillCount(){
		return false;
	}
}
//----------------------------------------------------------
class vestInfo {
	protected string m_name;
	protected string m_vest;
	protected bool m_autoRecover;
	protected bool m_autoHeal;
	protected bool m_impactGl;
	protected bool m_healNeedle;
	protected uint m_stratagemsFirst;
	protected uint m_speedTime;
	protected uint m_armorTime;
	protected uint m_upgradeTime;

	vestInfo(string&in name,string&in vest = "helldivers_vest"){
		m_name = name;
		m_autoRecover = false;
		m_autoHeal = false;
		m_impactGl = false;
		m_healNeedle = false;
		m_stratagemsFirst = 0;
		m_speedTime = 0;
		m_armorTime = 0;
		m_upgradeTime = 0;
	}

	string name(){return m_name;}
	string vest(){return m_vest;}
	bool autoRecover(){return m_autoRecover;}
	bool autoHeal(){return m_autoHeal;}
	bool impactGl(){return m_impactGl;}
	bool healNeedle(){return m_healNeedle;}
	uint stratagemsFirst(){return m_stratagemsFirst;}
	uint speedTime(){return m_speedTime;}
	uint armorTime(){return m_armorTime;}
	uint upgradeTime(){return m_upgradeTime;}

	bool changeVest(string&in name,string&in vest){
		if(name == m_name){
			m_vest = vest;
			return true;
		}
		return false;
	}
	bool upgradeSpeed(string&in name){
		if(name == m_name){
			m_speedTime++;
			m_upgradeTime++;
			return true;
		}
		return false;
	}
	bool upgradeArmor(string&in name){
		if(name == m_name){
			m_armorTime++;
			m_upgradeTime++;
			return true;
		}
		return false;
	}
	bool clearUpgrade(string&in name){
		if(name == m_name){
			m_armorTime = 0;
			m_speedTime = 0;
			m_upgradeTime = 0;
			return true;
		}
		return false;
	}
	bool resetUpgrade(string&in name){
		if(name == m_name){
			m_autoRecover = false;
			m_autoHeal = false;
			m_impactGl = false;
			m_healNeedle = false;
			m_stratagemsFirst = 0;
			m_speedTime = 0;
			m_armorTime = 0;
			m_upgradeTime = 0;
			return true;
		}
		return false;
	}
	bool setAutoRecover(string&in name,bool&out state){
		if(name == m_name){
			m_autoRecover = !m_autoRecover;
			state = m_autoRecover;
			return true;
		}
		return false;
	}
	bool setAutoHeal(string&in name,bool&out state){
		if(name == m_name){
			m_autoHeal = !m_autoHeal;
			state = m_autoHeal;
			return true;
		}
		return false;
	}
	bool setImpactGl(string&in name,bool&out state){
		if(name == m_name){
			if(m_healNeedle){ // 同时只能存在一个手雷位检测
				m_healNeedle = !m_healNeedle;
			}
			m_impactGl = !m_impactGl;
			state = m_impactGl;
			return true;
		}
		return false;
	}
	bool setHealNeedle(string&in name,bool&out state){
		if(name == m_name){
			if(m_impactGl){ // 同时只能存在一个手雷位检测
				m_impactGl = !m_impactGl;
			}
			m_healNeedle = !m_healNeedle;
			state = m_healNeedle;
			return true;
		}
		return false;
	}
	void setStratagemsFirst(string&in name,uint&out priority){
		if(name == m_name){
			m_stratagemsFirst++;
			priority = m_stratagemsFirst;
		}
	}
}

class vestInfoBuck {
	protected array<vestInfo@> m_vestInfos;

	vestInfoBuck(){
		vestInfo@ newinfo = vestInfo("");
		m_vestInfos.insertLast(newinfo);
	}

	string printTest(){
		string str;
		for(uint i=0;i<m_vestInfos.size();++i){
			str += " name="+m_vestInfos[i].name()+" vest="+ m_vestInfos[i].vest();
		}
		return str;
	}

	void addInfo(string&in name,string&in vest = "helldivers_vest"){
		if(m_vestInfos is null){_log("m_vestInfos is null");return;}
		for(uint i=0;i<m_vestInfos.size();++i){
			string m_name = m_vestInfos[i].name();
			if(name == m_name){
				return;
			}
		}
		vestInfo@ newinfo = vestInfo(name,vest);
		m_vestInfos.insertLast(newinfo);
	}

	void removeInfo(string&in name){
		for(uint i=0;i<m_vestInfos.size();++i){
			string m_name = m_vestInfos[i].name();
			if(name == m_name){
				m_vestInfos.removeAt(i);
				--i;
			}
		}
	}

	string getVestKey(string&in name){
		for(uint i = 0 ; i < m_vestInfos.size() ; ++i){
			if(m_vestInfos[i].name() == name){
				return m_vestInfos[i].vest();
			}
		}
		return "";
	}

	void changeVest(string&in name,string&in vest){
		for(uint i = 0 ; i < m_vestInfos.size() ; ++i){
			if(m_vestInfos[i].changeVest(name,vest)){
				return;
			}
		}
		addInfo(name,vest);
	}
	uint upgradeSpeed(string&in name){
		for(uint i = 0 ; i < m_vestInfos.size() ; ++i){
			if(m_vestInfos[i].upgradeSpeed(name)){
				return m_vestInfos[i].speedTime();
			}	
		}
		return 0;
	}
	uint upgradeArmor(string&in name){
		for(uint i = 0 ; i < m_vestInfos.size() ; ++i){
			if(m_vestInfos[i].upgradeArmor(name)){
				return m_vestInfos[i].armorTime();
			}	
		}
		return 0;
	}
	uint upgradeTime(string&in name){
		for(uint i = 0 ; i < m_vestInfos.size() ; ++i){
			if(m_vestInfos[i].name() == name){
				return m_vestInfos[i].upgradeTime();
			}	
		}
		return 0;
	}
	uint upgradeSpeedTime(string&in name){
		for(uint i = 0 ; i < m_vestInfos.size() ; ++i){
			if(m_vestInfos[i].name() == name){
				return m_vestInfos[i].speedTime();
			}	
		}
		return 0;
	}
	uint upgradeArmorTime(string&in name){
		for(uint i = 0 ; i < m_vestInfos.size() ; ++i){
			if(m_vestInfos[i].name() == name){
				return m_vestInfos[i].armorTime();
			}	
		}
		return 0;
	}
	bool clearUpgrade(string&in name){
		for(uint i = 0 ; i < m_vestInfos.size() ; ++i){
			if(m_vestInfos[i].clearUpgrade(name)){
				return true;
			}	
		}
		return false;
	}
	bool resetUpgrade(string&in name){
		for(uint i = 0 ; i < m_vestInfos.size() ; ++i){
			if(m_vestInfos[i].resetUpgrade(name)){
				return true;
			}	
		}
		return false;
	}
	bool setAutoRecover(string&in name,bool&out state){
		for(uint i = 0 ; i < m_vestInfos.size() ; ++i){
			if(m_vestInfos[i].setAutoRecover(name,state)){
				return true;
			}
		}
		return false;
	}
	bool setAutoHeal(string&in name,bool&out state){
		for(uint i = 0 ; i < m_vestInfos.size() ; ++i){
			if(m_vestInfos[i].setAutoHeal(name,state)){
				return true;
			}
		}
		return false;
	}
	bool setImpactGl(string&in name,bool&out state){
		for(uint i = 0 ; i < m_vestInfos.size() ; ++i){
			if(m_vestInfos[i].setImpactGl(name,state)){
				return true;
			}
		}
		return false;
	}
	bool setHealNeedle(string&in name,bool&out state){
		for(uint i = 0 ; i < m_vestInfos.size() ; ++i){
			if(m_vestInfos[i].setHealNeedle(name,state)){
				return true;
			}
		}
		return false;
	}
	bool getAutoHeal(string&in name){
		for(uint i = 0 ; i < m_vestInfos.size() ; ++i){
			if(m_vestInfos[i].name() == name){
				return m_vestInfos[i].autoHeal();
			}
		}
		return false;
	}
	bool getAutoRecover(string&in name){
		for(uint i = 0 ; i < m_vestInfos.size() ; ++i){
			if(m_vestInfos[i].name() == name){
				return m_vestInfos[i].autoRecover();
			}
		}
		return false;
	}
	bool getHealNeedle(string&in name){
		for(uint i = 0 ; i < m_vestInfos.size() ; ++i){
			if(m_vestInfos[i].name() == name){
				return m_vestInfos[i].healNeedle();
			}
		}
		return false;
	}
	bool getImpactGl(string&in name){
		for(uint i = 0 ; i < m_vestInfos.size() ; ++i){
			if(m_vestInfos[i].name() == name){
				return m_vestInfos[i].impactGl();
			}
		}
		return false;
	}
	uint getStratagemsFirst(string&in name){
		for(uint i = 0 ; i < m_vestInfos.size() ; ++i){
			if(m_vestInfos[i].name() == name){
				return m_vestInfos[i].stratagemsFirst();
			}
		}
		return 0;
	}
	bool setStratagemsFirst(string&in name,uint&out priority){
		for(uint i = 0 ; i < m_vestInfos.size() ; ++i){
			m_vestInfos[i].setStratagemsFirst(name,priority);
		}
		return true;
	}

	void clearAll(){
		if(m_vestInfos is null){return;}
		m_vestInfos.resize(0);
	}
}
//----------------------------------------------------------
class first_use_info{
    protected string name;
    protected array<string> first_use_tag;

    first_use_info(string InName){
        name = InName;
    }

    string getName(){
        return name;
    }

    bool isFirst(string&in InName,string&in key){
        if(name != InName){return false;}
        for (uint i = 0; i < first_use_tag.length(); ++i) {
            if (first_use_tag[i] == key) {
                return false;
            }
        }
        first_use_tag.insertLast(key);
        return true;
    }
    bool removeFirst(string&in InName,string&in key){
        if(name != InName){return false;}
        for (uint i = 0; i < first_use_tag.length(); ++i) {
            if (first_use_tag[i] == key) {
                first_use_tag.removeAt(i);
				i--;
            }
        }
        return true;
    }
}

class firstUseInfoBuck {
	protected array<first_use_info@> m_firstUseInfos;

	firstUseInfoBuck(){
		clearAll();
		first_use_info@ newinfo = first_use_info("");
        m_firstUseInfos.insertLast(newinfo);
	}

	uint size(){
		return m_firstUseInfos.size();
	}

	void addInfo(string&in name){
		for(uint i=0; i<m_firstUseInfos.size(); ++i){
            if(m_firstUseInfos[i].getName() == name){
                return;
            }
        }
		first_use_info@ newinfo = first_use_info(name);
        m_firstUseInfos.insertLast(newinfo);
	}

	void removeInfo(string&in name){
		for(uint i=0; i<m_firstUseInfos.size(); ++i){
            if(m_firstUseInfos[i].getName() == name){
                m_firstUseInfos.removeAt(i);
                --i;
            }
        }
	}

	bool isFirst(string&in name,string&in key){
		for(uint i=0; i<m_firstUseInfos.size(); ++i){
            if(m_firstUseInfos[i].isFirst(name,key)){
				return true;
			}
        }
		return false;
	}
	bool removeFirst(string&in name,string&in key){
		for(uint i=0; i<m_firstUseInfos.size(); ++i){
            if(m_firstUseInfos[i].removeFirst(name,key)){
				return true;
			}
        }
		return false;
	}

	void clearAll(){
		m_firstUseInfos.resize(0);
	}
}
//----------------------------------------------------------
class userCountInfo{
    protected string m_name;
    protected dictionary countList;

    userCountInfo(string name){
        m_name = name;
    }

    string getName(){
        return m_name;
    }

    bool getCount(string&in name,string&in key,int&out count){
		if(m_name == name){
			if(countList.get(key,count)){
				return true;
			}else{
				countList.set(key,0);
				count = 0;
				return true;
			}
		}
		return false;
    }
    bool addCount(string&in name,string&in key,int&in count){
		if(m_name == name){
			int value;
			if(g_fullcost){
				value = 9999;
				countList.set(key,value);
				return true;
			}
			if(countList.get(key,value)){
				value += count;
				countList.set(key,value);
				return true;
			}else{
				countList.set(key,count);
				return true;
			}
		}
		return false;
    }
    bool clearCount(string&in name,string&in key){
		if(m_name == name){
			int value;
			if(countList.get(key,value)){
				countList.set(key,0);
				return true;
			}else{
				countList.set(key,0);
				return true;
			}
		}
		return false;
    }
}

class userCountInfoBuck {
	protected array<userCountInfo@> m_userCountInfos;

	userCountInfoBuck(){
		userCountInfo@ newinfo = userCountInfo("");
		m_userCountInfos.insertLast(newinfo);
	}

	uint size(){
		return m_userCountInfos.size();
	}

	string indexName(uint index){
		if(index < size()){
			return m_userCountInfos[index].getName();
		}
		return "";
	}

	void addInfo(string&in name){
		if(m_userCountInfos !is null){
			for(uint i = 0 ; i < m_userCountInfos.size() ; ++i){
				if(m_userCountInfos[i].getName() == name){
					return;
            	}
			}
		}
		userCountInfo@ newinfo = userCountInfo(name);
		m_userCountInfos.insertLast(newinfo);
	}

	bool getCount(string&in name,string&in key,int&out count){
		for(uint i = 0 ; i < m_userCountInfos.size() ; ++i){
			if(m_userCountInfos[i].getCount(name,key,count)){
				return true;
			}else{
				continue;
			}
		}
		return false;
    }
	bool addCount(string&in name,string&in key,int&in count = 1){
		for(uint i = 0 ; i < m_userCountInfos.size() ; ++i){
			if(m_userCountInfos[i].addCount(name,key,count)){
				return true;
			}else{
				continue;
			}
		}
		return false;
    }
	bool clearCount(string&in name,string&in key){
		for(uint i = 0 ; i < m_userCountInfos.size() ; ++i){
			if(m_userCountInfos[i].clearCount(name,key)){
				return true;
			}else{
				continue;
			}
		}
		return false;
    }
	void removeInfo(string&in name){
		for(uint i=0; i<m_userCountInfos.size(); ++i){
            if(m_userCountInfos[i].getName() == name){
                m_userCountInfos.removeAt(i);
                --i;
            }
        }
	}
	void clearAll(){
		m_userCountInfos.resize(0);
	}
}
//----------------------------------------------------------
factionInfoBuck@ g_factionInfoBuck = factionInfoBuck();	
playerInfoBuck@ g_playerInfoBuck = playerInfoBuck();	
battleInfoBuck@ g_battleInfoBuck = battleInfoBuck();
vestInfoBuck@ g_vestInfoBuck = vestInfoBuck();
firstUseInfoBuck@ g_firstUseInfoBuck = firstUseInfoBuck();
userCountInfoBuck@ g_userCountInfoBuck = userCountInfoBuck();
playerMissionInfoBuck@ g_playerMissionInfoBuck = playerMissionInfoBuck();
bool g_online_TestMode = false;
bool g_debugMode = true;
bool g_server_activity = false;
bool g_server_activity_racing = false;
bool g_single_player = false; //开关一些进服提示
bool g_auto_heal = true; // 开关自动回血
bool g_spawn_with_ai = true; // 复活自带AI
// bool g_spawn_with_ai = false; // 复活自带AI

bool g_fastScriptDebug = false; // 脚本快速测试
bool g_useMergedXml = false; // 采用快速打包加载文件
bool g_English_version = false; // 采用英文
bool g_restartMetagame = false; // 结束后重启metagame
bool g_manualCrash = false; // 手动导致进程崩溃以重启

bool g_heal_on_kill = true; // 击杀回甲
bool g_exo_armor = true; // 机甲是否装配护甲
bool g_disable_stratagems = false; //是否禁用战略呼叫
bool g_top_down = true; //是否启用俯视角
bool g_acg_weapon_count = false; //是否启用ACG武器击杀计数
bool g_fullcost = false; //是否启用无限cost技能
bool g_fullcd = false; //是否启用无限cd技能

int g_server_difficulty_level = 0;
int g_playerCount = 0;

string g_GameMode = "";

float g_stratagems_call_factor = 1.0; //调整战略呼叫CD倍率，0为关闭
float g_server_added_bonus_factor = 0.0; //战役结算额外的倍率

int g_rp_ptRewardBase = 3600; //游玩时长奖励
float g_xp_ptRewardBase = 0.1; //游玩时长奖励 2000xp
//----------------------------------------------------------
//初始化用Tracker
class Initiate : Tracker {
	protected GameModeInvasion@ m_metagame;
	protected bool m_ended = false;
	protected bool m_debug_mode;
    protected int m_server_difficulty_level;
    protected float m_time = 60;
    protected float m_timer = 60;

	Initiate(GameModeInvasion@ metagame) {
		@m_metagame = @metagame;
		const UserSettings@ settings = m_metagame.getUserSettings();
		m_debug_mode = settings.m_debug_mode;
		g_debugMode = m_debug_mode;
		g_online_TestMode = settings.m_server_test_mode;

		m_server_difficulty_level = settings.m_server_difficulty_level;
		g_server_difficulty_level = m_server_difficulty_level;
		g_single_player = settings.m_single_player;;
		g_server_added_bonus_factor = settings.m_server_added_bonus_factor;;

		g_GameMode = settings.m_GameMode;
		_log("g_GameMode="+g_GameMode);
		_log("g_server_difficulty_level="+g_server_difficulty_level);

		@g_factionInfoBuck = factionInfoBuck();	
 		@g_playerInfoBuck = playerInfoBuck(m_metagame);
 		@g_battleInfoBuck = battleInfoBuck();
 		@g_vestInfoBuck = vestInfoBuck();
		@g_IRQ = _IRQ("",false);
		@g_firstUseInfoBuck = firstUseInfoBuck();
		@g_playerMissionInfoBuck = playerMissionInfoBuck();

		g_userCountInfoBuck.clearAll();
		g_firstUseInfoBuck.addInfo("admin");
		//First Run
		initiateFactionInfo();
		GameModeInitiate();
	}

	protected void GameModeInitiate(){
		if(g_GameMode != ""){
			if(g_GameMode == "Zombie"){
				g_stratagems_call_factor = 5.0;
				g_auto_heal = false;
				g_spawn_with_ai = false;
				g_heal_on_kill = false;
				g_exo_armor = false;
				g_rp_ptRewardBase = 2000;
				g_disable_stratagems = true;
			}
			if(g_GameMode == "Vanilla"){
				g_stratagems_call_factor = 2.0;
				g_heal_on_kill = false;
				g_acg_weapon_count = true;
				g_spawn_with_ai = false;
				g_rp_ptRewardBase = 5000;
				g_disable_stratagems = true;
				g_server_added_bonus_factor = 0.0; //战役结算额外的倍率
			}
		}
	}
	// --------------------------------------------
	bool hasEnded() const {
		return false;
	}
	// --------------------------------------------
	bool hasStarted() const {
		// always on
		return true;
	}

	void update(float time){
		m_timer -= time;
        if(m_timer < 0){
            m_timer = m_time;
        }
	}
	// ----------------------------------------------------
	protected void handlePlayerSpawnEvent(const XmlElement@ event) {
		initiateBattleInfo(event);
		initiateVestInfo(event);
		initiateMissionInfo(event);
	}
	// ----------------------------------------------------
	protected void handlePlayerConnectEvent(const XmlElement@ event) {
		const XmlElement@ player = event.getFirstElementByTagName("player");
		if(player is null){return;}
		string name = player.getStringAttribute("name");
		g_firstUseInfoBuck.addInfo(name);
		g_userCountInfoBuck.addInfo(name);
	}
	// ----------------------------------------------------
    protected void handlePlayerDisconnectEvent(const XmlElement@ event) {
        const XmlElement@ player = event.getFirstElementByTagName("player");
        if(player is null){return;}
        string name = player.getStringAttribute("name");
		g_userCountInfoBuck.removeInfo(name);
    }
	// ----------------------------------------------------
	protected void handleMatchEndEvent(const XmlElement@ event) {
		// g_userCountInfoBuck.clearAll();
		m_ended = true;
	}
	// ----------------------------------------------------
	protected void initiateBattleInfo(const XmlElement@ event){
		const XmlElement@ player = event.getFirstElementByTagName("player");
		string name = player.getStringAttribute("name");
		if(g_firstUseInfoBuck.isFirst(name,"initiateBattleInfo")){
			_log("player first connect server,remove battleinfo");
			g_battleInfoBuck.removeInfo(name);
		}
		g_battleInfoBuck.addInfo(name,m_server_difficulty_level);
	}
	// ----------------------------------------------------
	protected void initiateVestInfo(const XmlElement@ event){
		const XmlElement@ player = event.getFirstElementByTagName("player");
		string name = player.getStringAttribute("name");
		if(g_firstUseInfoBuck.isFirst(name,"initiateVestInfo")){
			_log("player first connect server,remove vestinfo");
			g_vestInfoBuck.removeInfo(name);
		}
		g_vestInfoBuck.addInfo(name);
	}
	// ----------------------------------------------------
	protected void initiateMissionInfo(const XmlElement@ event){
		const XmlElement@ player = event.getFirstElementByTagName("player");
		string name = player.getStringAttribute("name");
		g_playerMissionInfoBuck.addInfo(m_metagame,name);
	}
	protected void initiateFactionInfo(){
		if(g_factionInfoBuck !is null){
			g_factionInfoBuck.clearAll();
			array<const XmlElement@> AllFactions = getFactions(m_metagame);	
			if(AllFactions !is null){
				for (uint i = 0; i < AllFactions.size(); ++i) {
					const XmlElement@ Faction = AllFactions[i];
					int fid = Faction.getIntAttribute("id");
					string name = Faction.getStringAttribute("name");
					array<const XmlElement@>@ SoldierGroups = getSoldierGroups(m_metagame,fid);
					g_factionInfoBuck.addNewInfo(fid,name,SoldierGroups);
				}
			}else{
				_log("AllFactions is null");
			}
		}else{
			_log("g_factionInfoBuck is null in INFO.as");
		}
	}

	protected void handleChatEvent(const XmlElement@ event){
		string message = event.getStringAttribute("message");
		string p_name = event.getStringAttribute("player_name");
		int pid = event.getIntAttribute("player_id");
		if(message == "/english" || message == "/ENGLISH"){
			if(g_playerInfoBuck.setEnglishPlayer(p_name)){
				_notify(m_metagame,pid,"[Local] English Translation is On");
			}else{
				_notify(m_metagame,pid,"[Local] English Translation is OFF");
			}
			if(g_single_player){
				g_English_version = !g_English_version;
			}
			if(g_English_version){
				_notify(m_metagame,pid,"[Gloalbal] English Translation is On");
			}else{
				_notify(m_metagame,pid,"[Gloalbal] English Translation is On");
			}
		}
		if(m_metagame.getAdminManager().isAdmin(p_name)){
			if(message == "/debug"){
				g_debugMode = !g_debugMode;
				if(g_debugMode){
					_report(m_metagame,"Debug Mode is On");
				}else{
					_report(m_metagame,"Debug Mode is Off");
				}
			}
			if(message == "/fullcost"){
				g_fullcost = !g_fullcost;
				if(g_debugMode){
					if(g_fullcost){
						_report(m_metagame,"FullCost Mode is On");
					}else{
						_report(m_metagame,"FullCost Mode is Off");
					}
				}
			}
			if(message == "/fullcd"){
				g_fullcd = !g_fullcd;
				if(g_debugMode){
					if(g_fullcost){
						_report(m_metagame,"FullCD Mode is On");
					}else{
						_report(m_metagame,"FullCD Mode is Off");
					}
				}
			}
			if(message == "/outputPinfodata"){
				_report(m_metagame,"管理员测试输出："+g_playerInfoBuck.output());
			}
			if(message == "/refreshPinfodata"){
				g_playerInfoBuck.updateAll();
			}
			if(message == "/addkill"){
				uint i = 1000;
				while(i>0){
					g_battleInfoBuck.addKill(p_name);
					--i;
				}
				i = 30;
				while(i>0){
					g_battleInfoBuck.addTime();
					--i;
				}
			}
			if(message == "/endserveractivity"){
				g_server_activity = false;
				_report(m_metagame,"活动结束");
			}
			if(message == "/restartMetagame"){
				g_restartMetagame = true;
				_report(m_metagame,"重启Metagame");
			}
		}
		if(message == "/myfact"){
			float bf = g_battleInfoBuck.bonusFactor(p_name);
			float bfx = g_battleInfoBuck.bonusFactorXp(p_name);
			float bfr = g_battleInfoBuck.bonusFactorRp(p_name);
			notify(m_metagame,"你的全局倍率="+bf+"，xp倍率="+bfx+"，rp倍率="+bfr, dictionary(), "misc", pid, false, "", 1.0);
		}
		if(message == "/sid"){
			string sid;
			array<const XmlElement@> players = getPlayers(m_metagame);
			for(uint j = 0; j < players.size() ; ++j){
				const XmlElement@ player = players[j];
				if(player is null){continue;}
				if(p_name == player.getStringAttribute("name")){
					sid = player.getStringAttribute("sid");
				}
			}
			notify(m_metagame,"你的SID="+sid, dictionary(), "misc", pid, false, "", 1.0);
		}
		if(message == "/vest"){
			string vest = g_vestInfoBuck.getVestKey(p_name);
			_notify(m_metagame,pid,"你注册的护甲="+vest);
		}
		if(message == "/vestinfo"){
			_notify(m_metagame,pid,g_vestInfoBuck.printTest());
		}
	}
		
}

// 方便英文检测的全局方法
bool isEng(string name){
	return g_playerInfoBuck.isEng(name);
}