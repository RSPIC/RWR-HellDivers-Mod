

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
	string getNameByPid(const int&in pid){
		if(m_pid == pid){
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
	string getNameByPid(const int&in pid){
		for(uint i=0; i<size();++i){
			string name = m_playerInfo[i].getNameByPid(pid);
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
	int getRpByCid(int&in cid){
		for(uint i=0; i<size();++i){
			if(cid == m_playerInfo[i].getCid()){
				return int(m_playerInfo[i].getRp());
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
	void clearAll(){
		if(m_battleInfos is null){return;}
		m_battleInfos.resize(0);
	}

	float getXpReward(Metagame@ m_metagame,const XmlElement@ player){
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
				float bf = m_battleInfos[i].bonusFactorXp();
				xp = 
				  kc * 0.01 
				+ oc * 0.02*NormalizedConcaveCurve(0.01*oc,0.5) 
				+ mc * 0.5
				+ pt * 0.03
				- tc * 0.05
				- dc * 0.03;
				xp = xp*m_battleInfos[i].bonusFactorXp();
				if(xp<=0){xp=0;}
				dictionary a;
				a["%kx"] = formatInt(int(kc*0.01*10000));
				a["%ox"] = formatInt(int(oc*0.02*NormalizedConcaveCurve(0.01*oc,0.5)*10000));
				a["%mx"] = formatInt(int(mc*0.5*10000));
				a["%px"] = formatInt(int(pt*0.03*10000));
				a["%tx"] = formatInt(int(tc*0.05*10000));
				a["%dx"] = formatInt(int(dc*0.03*10000));
				a["%kc"] = formatInt(kc);
				a["%oc"] = formatInt(oc);
				a["%mc"] = formatInt(mc);
				a["%pt"] = formatInt(pt);
				a["%tc"] = formatInt(tc);
				a["%dc"] = formatInt(dc);
				a["%bf"] = ""+bf;
				a["%xp"] = formatFloat(xp*10000);
				notify(m_metagame,"BattleEndRewardXP", a, "misc", pid, true, "Battle End Reward XP", 1.0);
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
				uint oc = m_battleInfos[i].oneLifekillCount();//100连杀达到100rp，600时接近200rp，极限值200rp
				uint mc = m_battleInfos[i].missionCount(); 
				uint pt = m_battleInfos[i].playingTime();
				uint tc = m_battleInfos[i].tkCount();
				uint dc = m_battleInfos[i].deadCount();
				float bf = m_battleInfos[i].bonusFactorRp();
				rp = 
				  kc * 75
				+ oc * 100*NormalizedConcaveCurve(0.01*oc,0.5)
				+ mc * 3000
				+ pt * 300
				- tc * 500;
				rp = rp*m_battleInfos[i].bonusFactorRp();
				if(rp<=0){rp=0;}
				dictionary a;
				a["%kx"] = formatInt(int(kc*75));
				a["%ox"] = formatInt(int(oc*100*NormalizedConcaveCurve(0.01*oc,0.5)));
				a["%mx"] = formatInt(int(mc*3000));
				a["%px"] = formatInt(int(pt*300));
				a["%tx"] = formatInt(int(tc*500));
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
				if(m_battleInfos[i].playingTime() >= 10){
					if(m_battleInfos[i].deadCount() == 0){
						if(m_battleInfos[i].tkCount() == 0){
							if(m_battleInfos[i].missionCount() != 0){
								return true;
							}
						}
					}
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
	protected uint m_stratagemsFirst;
	protected uint m_speedTime;
	protected uint m_armorTime;
	protected uint m_upgradeTime;

	vestInfo(string&in name,string&in vest = "helldivers_vest.carry_item"){
		m_name = name;
		m_autoRecover = false;
		m_autoHeal = false;
		m_stratagemsFirst = 0;
		m_speedTime = 0;
		m_armorTime = 0;
		m_upgradeTime = 0;
	}
	string name(){return m_name;}
	string vest(){return m_vest;}
	bool autoRecover(){return m_autoRecover;}
	bool autoHeal(){return m_autoHeal;}
	uint stratagemsFirst(){return m_stratagemsFirst;}
	uint speedTime(){return m_speedTime;}
	uint armorTime(){return m_armorTime;}
	uint upgradeTime(){return m_upgradeTime;}

	void changeVest(string&in name,string&in vest){
		if(name == m_name){
			m_vest = vest;
		}
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

	void addInfo(string&in name,string&in vest = "helldivers_vest.carry_item"){
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
			m_vestInfos[i].changeVest(name,vest);
		}
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
        for (uint i = 0; i < first_use_tag.length(); i++) {
            if (first_use_tag[i] == key) {
                return false;
            }
        }
        first_use_tag.insertLast(key);
        return true;
    }
}

class firstUseInfoBuck {
	protected array<first_use_info@> m_firstUseInfos;

	firstUseInfoBuck(){
		first_use_info@ newinfo = first_use_info("");
        m_firstUseInfos.insertLast(newinfo);
	}

	void addInfo(string&in name){
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
}
//----------------------------------------------------------
factionInfoBuck@ g_factionInfoBuck = factionInfoBuck();	
playerInfoBuck@ g_playerInfoBuck = playerInfoBuck();	
battleInfoBuck@ g_battleInfoBuck = battleInfoBuck();
vestInfoBuck@ g_vestInfoBuck = vestInfoBuck();
firstUseInfoBuck@ g_firstUseInfoBuck = firstUseInfoBuck();
bool g_online_TestMode = false;
bool g_debugMode = false;

//----------------------------------------------------------
//初始化用Tracker
class Initiate : Tracker {
	protected GameModeInvasion@ m_metagame;
	protected bool m_ended;
	protected bool isStarted;
	protected bool m_debug_mode;
    protected int m_server_difficulty_level;

	Initiate(GameModeInvasion@ metagame) {
		@m_metagame = @metagame;
		const UserSettings@ settings = m_metagame.getUserSettings();
		m_debug_mode = settings.m_debug_mode;
		g_debugMode = m_debug_mode;
		g_online_TestMode = settings.m_server_test_mode;
		m_server_difficulty_level = settings.m_server_difficulty_level;
	}
	// --------------------------------------------
	bool hasEnded() const {
		// always on
		return m_ended;
	}
	// --------------------------------------------
	bool hasStarted() const {
		// always on
		return true;
	}
	void start(){
        m_ended = false;
		isStarted = false;
		@g_factionInfoBuck = factionInfoBuck();	
 		@g_playerInfoBuck = playerInfoBuck();
 		@g_battleInfoBuck = battleInfoBuck();
 		@g_vestInfoBuck = vestInfoBuck();
		@g_IRQ = _IRQ("",false);
	}
	void update(float time){
	}
	// ----------------------------------------------------
	protected void handlePlayerSpawnEvent(const XmlElement@ event) {
		if(!isStarted){
			initiateFactionInfo();
			isStarted = true;
		}
		initiateBattleInfo(event);
		initiateVestInfo(event);
	}
	// ----------------------------------------------------
	protected void handlePlayerConnectEvent(const XmlElement@ event) {
		const XmlElement@ player = event.getFirstElementByTagName("player");
        if(player is null){return;}
        string name = player.getStringAttribute("name");
		g_firstUseInfoBuck.addInfo(name);
	}
	// ----------------------------------------------------
    protected void handlePlayerDisconnectEvent(const XmlElement@ event) {
        const XmlElement@ player = event.getFirstElementByTagName("player");
        if(player is null){return;}
        string name = player.getStringAttribute("name");
		g_firstUseInfoBuck.removeInfo("name");
    }
	// ----------------------------------------------------
	protected void handleMatchEndEvent(const XmlElement@ event) {
		m_ended = true;
	}
	// ----------------------------------------------------
	protected void initiateBattleInfo(const XmlElement@ event){
		const XmlElement@ player = event.getFirstElementByTagName("player");
		string name = player.getStringAttribute("name");
		g_battleInfoBuck.addInfo(name,m_server_difficulty_level);
	}
	// ----------------------------------------------------
	protected void initiateVestInfo(const XmlElement@ event){
		const XmlElement@ player = event.getFirstElementByTagName("player");
		string name = player.getStringAttribute("name");
		g_vestInfoBuck.addInfo(name);
		if(g_debugMode){
			_report(m_metagame,"add initiateVestInfo");
		}
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
				isStarted = true;  
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