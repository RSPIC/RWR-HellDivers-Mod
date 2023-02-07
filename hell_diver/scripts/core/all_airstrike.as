#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"

//Credit: NetherCrow & Saiwa & RW/Helldiver Staff

array<Airstrike_strafer@> Airstrike_strafe;

dictionary airstrikeIndex = {

        // 空武器
        {"",-1},

        // 绝地潜兵 空袭mk3
        {"hd_superearth_airstrike_mk3",0},

        // 下面这行是用来占位的，在这之上添加新的即可
        {"666",-1}
};

class AirstrikeSystem : Tracker {
	protected GameMode@ m_metagame;
	uint m_fnum;
    uint max_airstrike_per_frame = 10;
    uint airstrike_per_frame = 0;

	// --------------------------------------------
	AirstrikeSystem(GameMode@ metagame) {
		@m_metagame = @metagame;
	}

	void update(float time) {
        if(Airstrike_strafe.length()>0){
            for (uint a=0;a<Airstrike_strafe.length();a++){
                int cid = Airstrike_strafe[a].m_characterId;
                int fid = Airstrike_strafe[a].m_factionid;
                Vector3 start_pos = Airstrike_strafe[a].m_c_pos;
                Vector3 end_pos = Airstrike_strafe[a].m_s_pos;        
                int specialnum = Airstrike_strafe[a].m_specialnum;
                string specialkey = Airstrike_strafe[a].m_specialkey;

                switch(Airstrike_strafe[a].m_straferkey){
                    case 0:{//垂直弹头
                        CreateDirectProjectile(m_metagame,start_pos,end_pos,"hd_offensive_airstrike_mk3_damage.projectile",cid,fid,40);	
                        Airstrike_strafe.removeAt(a);
                        break;                        
                    }

                    default:
                        break;
                }
            }
        }	
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

}

class Airstrike_strafer{
    int m_characterId;
	int m_factionid;
    int m_straferkey;
    Vector3 m_c_pos;
    Vector3 m_s_pos;
    string m_specialkey;
    int m_specialnum;
	Airstrike_strafer(int characterId,int factionid,int straferkey,Vector3 c_pos,Vector3 s_pos)
	{
		m_characterId = characterId;
		m_factionid = factionid;
		m_straferkey = straferkey;
		m_c_pos = c_pos;
		m_s_pos = s_pos;
	}

    void setKey(string a)
    {
        m_specialkey = a;
    }
    void setNum(int a)
    {
        m_specialnum = a;
    }    
}

void insertCommonStrike(int characterId,int factionid,int straferkey,Vector3 c_pos,Vector3 s_pos){
    Airstrike_strafe.insertLast(Airstrike_strafer(characterId,factionid,straferkey,c_pos,s_pos));
}

void insertCommonStrike(int characterId,int factionid,string straferkey,Vector3 c_pos,Vector3 s_pos){
    Airstrike_strafe.insertLast(Airstrike_strafer(characterId,factionid,int(airstrikeIndex[straferkey]),c_pos,s_pos));
}