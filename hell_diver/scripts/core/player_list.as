#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "generic_call_task.as"
#include "task_sequencer.as"

//Originally created by Saiwa
//Adapted by NetherCrow

// 本系统用于容纳有关玩家的请求

array<PlayerList@> PlayerList_Array;

class PlayerList{
    int m_characterid;      //角色id
	int m_playerid;         //玩家id
    string m_weapon1key;    //主武器key
    string m_weapon2key;    //副武器key
    string m_weapon3key;    //投掷物key
    string m_vestkey;       //甲key
    string m_itemkey;       //掉落物key

    string m_pos;
    string m_old_pos;
    int m_rp;
    float m_xp;
    int m_count;

    PlayerList(int cid, int pid, string w1key="-nan-", string w2key="-nan-", string w3key="-nan-", string vkey="-nan-", string ikey="-nan-",int count=0,string pos="-nan-"){
        m_characterid = cid;
	    m_playerid = pid;
        m_weapon1key = w1key;
        m_weapon2key = w2key;
        m_weapon3key = w3key;
        m_vestkey = vkey;
        m_itemkey = ikey;
        m_count = count;
        m_pos = pos;
        m_rp= 0;
        m_xp= 0;
    }

    void updatePos(string pos){ 
        m_old_pos = m_pos;
        m_pos= pos;
    }
}

class playerList_System : Tracker {
	protected GameMode@ m_metagame;
    protected float m_time = 1.0; 
    protected float refresh_time = 5.0; // 刷新时间

	// --------------------------------------------
	playerList_System(GameMode@ metagame) {
		@m_metagame = @metagame;
	}

    void update(float time) {
        m_time -= time;
        if(m_time<0){
            m_time = refresh_time;
            refresh();
        }
    }

    void refresh(){
        while(PlayerList_Array.length()>0){        
            int index_last = PlayerList_Array.length() -1;
            PlayerList@ player = PlayerList_Array[index_last];
            PlayerList_Array.removeLast();
        }            
        
        array<const XmlElement@> nowPlayers = getPlayers(m_metagame);
        if (nowPlayers is null){return;}

        // 彻底删除一次并全部重新更新
        for(uint i=0;i<nowPlayers.length();i++){

            int cid = nowPlayers[i].getIntAttribute("character_id");
            int pid = nowPlayers[i].getIntAttribute("player_id");
            const XmlElement@ targetCharacter = getCharacterInfo2(m_metagame,cid);
            if(targetCharacter is null){continue;}

            string pos = targetCharacter.getStringAttribute("position");
            array<const XmlElement@>@ equipment = targetCharacter.getElementsByTagName("item");

            if(equipment is null){continue;}
            string w1 = equipment[0].getStringAttribute("key");
            string w2 = equipment[1].getStringAttribute("key");
            string w3 = equipment[2].getStringAttribute("key");
            string w4 = equipment[4].getStringAttribute("key");
            string w5 = equipment[3].getStringAttribute("key");
            PlayerList@ new_player = PlayerList(cid, pid, w1, w2, w3, w4, w5, 0,pos); 
            PlayerList_Array.insertLast(new_player);
        }
    }

    void switchListRefreshTime(float time){
        refresh_time = time;
    }

	bool hasEnded() const {
		// always on
		return false;
	}

	// --------------------------------------------
	bool hasStarted() const {
		// always on
		return true;
	}

    protected void Change_refresh_time(float new_refresh_time){
        refresh_time = new_refresh_time;
    }
}

int getPlayerCidFromList(int playerid) {
    if(PlayerList_Array.length()<=0){return -1;}
    for(uint i=0;i<PlayerList_Array.length();i++){
        if(PlayerList_Array[i].m_playerid == playerid){
            return PlayerList_Array[i].m_characterid;
        }
    }
    return -1;
}

string getPlayerWeaponFromList(int playerid, int weaponnum) {
    if(PlayerList_Array.length()<=0){return "-nan-";}
    for(uint i=0;i<PlayerList_Array.length();i++){
        if(PlayerList_Array[i].m_playerid == playerid){
            switch(weaponnum){
                case 0:{return PlayerList_Array[i].m_weapon1key;}
                case 1:{return PlayerList_Array[i].m_weapon2key;}
                case 2:{return PlayerList_Array[i].m_weapon3key;}
                case 3:{return PlayerList_Array[i].m_vestkey;}
                case 4:{return PlayerList_Array[i].m_itemkey;}
                default:{return "-nan-";}
            }
        }
    }
    return "-nan-";
}

void givePlayerRPcount(int playerid,int rp_count){
    if(PlayerList_Array.length()<=0){return;}
    for(uint i=0;i<PlayerList_Array.length();i++){
        if(PlayerList_Array[i].m_playerid == playerid){
            PlayerList_Array[i].m_rp += rp_count;
            return;
        }
    }
}

void givePlayerXPcount(int playerid,float xp_count){
    if(PlayerList_Array.length()<=0){return;}
    for(uint i=0;i<PlayerList_Array.length();i++){
        if(PlayerList_Array[i].m_playerid == playerid){
            PlayerList_Array[i].m_xp += xp_count;
            return;
        }
    } 
}