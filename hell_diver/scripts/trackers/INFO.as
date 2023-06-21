

#include "admin_manager.as"
#include "tracker.as"
#include "debug_reporter.as"

//author:RST
//阵营信息
//玩家基本信息

class factionInfo {
	protected int m_fid;
	protected string m_name;
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

	factionInfoBuck(){}

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
	protected string m_name;
	protected string m_group;
	protected int m_pid;
	protected int m_cid;
	protected int m_fid;
	protected int m_dead;
	protected int m_wound;
	protected float m_xp;
	protected float m_rp;

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

	string getName(){return m_name;}
	string getGroup(){return m_group;}
	int getPid(){return m_pid;}
	int getCid(){return m_cid;}
	int getFid(){return m_fid;}
	int getWound(){return m_wound;}
	int getDead(){return m_dead;}
	float getXp(){return m_xp;}
	float getRp(){return m_rp;}

	void updateWound(int wound){m_wound = wound;}

	int getCidByPid(const int&in pid){
		if(m_pid == pid){
			return m_cid;
		}
		return -1;
	}
	int getFidByPid(const int&in pid){
		if(m_pid == pid){
			return m_fid;
		}
		return -1;
	}
	int getPidByCid(const int&in cid){
		if(m_cid == cid){
			return m_pid;
		}
		return -1;
	}
	string getNameByCid(const int&in cid){
		if(m_cid == cid){
			return m_name;
		}
		return "";
	}

}

class playerInfoBuck{
	protected array<playerInfo@> m_playerInfo;

	playerInfoBuck(){}

	uint size(){return m_playerInfo.size();}

	void addNewInfo(const string&in name,const int&in pid,const int&in cid,const int&in fid,const int&in dead,const int&in wound,const float&in xp,const float&in rp,string group = "default"){
		playerInfo@ newInfo = playerInfo(name,pid,cid,fid,dead,wound,xp,rp,group);
		m_playerInfo.insertLast(newInfo);
	}

	void update(const string&in name,const int&in pid,const int&in cid,const int&in fid,const int&in dead,const int&in wound,const float&in xp,const float&in rp,string group = "default"){
		for(uint i=0; i<size();++i){
			if(name == m_playerInfo[i].getName()){
				m_playerInfo[i].update(name,pid,cid,fid,dead,wound,xp,rp,group);
			}
		}
	}

	bool exists(string name){
		for(uint i=0; i<size();++i){
			if(name == m_playerInfo[i].getName()){
				return true;
			}
		}
		return false;
	}

	int getCidByPid(const int&in pid){
		for(uint i=0; i<size();++i){
			int cid = m_playerInfo[i].getCidByPid(pid);
			if(cid != -1){
				return cid;
			}
		}
		return -1;
	}
	int getFidByPid(const int&in pid){
		for(uint i=0; i<size();++i){
			int fid = m_playerInfo[i].getFidByPid(pid);
			if(fid != -1){
				return fid;
			}
		}
		return -1;
	}
	int getPidByCid(const int&in cid){
		for(uint i=0; i<size();++i){
			int pid = m_playerInfo[i].getPidByCid(cid);
			if(pid != -1){
				return pid;
			}
		}
		return -1;
	}
	string getNameByCid(const int&in cid){
		for(uint i=0; i<size();++i){
			string name = m_playerInfo[i].getNameByCid(cid);
			if(name != ""){
				return name;
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

	void updateWound(string name,int wound){
		for(uint i=0; i<size();++i){
			if(name == m_playerInfo[i].getName()){
				m_playerInfo[i].updateWound(wound);
			}
		}
	}

	void clearAll(){
		m_playerInfo.resize(0);
	}
}
//----------------------------------------------------------
factionInfoBuck@ g_factionInfoBuck = factionInfoBuck();	
playerInfoBuck@ g_playerInfoBuck = playerInfoBuck();	
bool g_online_TestMode = false;
bool g_debugMode = false;

//----------------------------------------------------------
//初始化用Tracker
class Initiate : Tracker {
	protected GameModeInvasion@ m_metagame;
	protected bool m_ended;
	protected bool isStarted;
	protected bool m_debug_mode;

	Initiate(GameModeInvasion@ metagame) {
		@m_metagame = @metagame;
		const UserSettings@ settings = m_metagame.getUserSettings();
		m_debug_mode = settings.m_debug_mode;
		g_debugMode = m_debug_mode;
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
	protected void handlePlayerSpawnEvent(const XmlElement@ event){
		if(!isStarted || g_factionInfoBuck.size() == 0 ){
            g_factionInfoBuck.clearAll();
			array<const XmlElement@> AllFactions = getFactions(m_metagame);	
			for (uint i = 0; i < AllFactions.size(); ++i) {
				const XmlElement@ Faction = AllFactions[i];
				int fid = Faction.getIntAttribute("id");
				string name = Faction.getStringAttribute("name");
				array<const XmlElement@>@ SoldierGroups = getSoldierGroups(m_metagame,fid);
				g_factionInfoBuck.addNewInfo(fid,name,SoldierGroups);
			}
			isStarted = true;    
		}
	}

	protected void handleChatEvent(const XmlElement@ event){
		string message = event.getStringAttribute("message");
		string p_name = event.getStringAttribute("player_name");
		if(m_metagame.getAdminManager().isAdmin(p_name)){
			if(message == "/debug"){
				g_debugMode = !g_debugMode;
				if(g_debugMode){
					_report(m_metagame,"Debug Mode is On");
				}else{
					_report(m_metagame,"Debug Mode is Off");
				}
			}
		}
	}
}