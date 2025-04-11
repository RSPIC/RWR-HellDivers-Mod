#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "all_parameter.as"

//Credit: NetherCrow & Saiwa & RW/Helldiver Staff

array<Airstrike_strafer@> Airstrike_strafe;

class AirstrikeSystem : Tracker {
	protected GameMode@ m_metagame;
	uint m_fnum;
    uint max_airstrike_per_frame = 10;
    uint airstrike_per_frame = 0;

	// --------------------------------------------
	AirstrikeSystem(GameMode@ metagame) {
		@m_metagame = @metagame;
	}

    int single_airstrike_update(Airstrike_strafer@ airstrike_single) {
        int cid = airstrike_single.m_characterId;
        int fid = airstrike_single.m_factionid;
        Vector3 start_pos = airstrike_single.m_c_pos;
        Vector3 end_pos = airstrike_single.m_s_pos;        
        int specialnum = airstrike_single.m_specialnum;
        string specialkey = airstrike_single.m_specialkey;
        int remove_or_not = 0;

        switch(airstrike_single.m_straferkey){
            case 0:{break;}
            case 1:{//垂直弹头
                CreateDirectProjectile(m_metagame,start_pos,end_pos,"hd_offensive_airstrike_mk3_damage.projectile",cid,fid,40);	
                remove_or_not = 1;
                break;                        
            }

            case 4:{ //重机枪扫射
                float rand_speed = rand(130,160);
                CreateDirectProjectile(m_metagame,start_pos,end_pos,"hd_offensive_heavy_strafing_run_mk3_mg_spawn.projectile",cid,fid,rand_speed);
                remove_or_not = 1;
                break;
            }

            case 8:{ //辩护者
                CreateDirectProjectile(m_metagame,start_pos,end_pos,"hd_vindicator_missile.projectile",cid,fid,60);
                CreateDirectProjectile(m_metagame,start_pos,end_pos,"hd_vindicator_effect.projectile",cid,fid,60);
                //effect 产生半空特效和若干子弹头
                remove_or_not = 1;
                break;
            }

            case 11:{ //燃烧炸弹
                CreateDirectProjectile(m_metagame,start_pos,end_pos,"hd_offensive_incendiary_bombs_mk3_spawn.projectile",cid,fid,60);
                CreateDirectProjectile(m_metagame,start_pos,end_pos,"hd_offensive_incendiary_bombs_mk3_spawn_friendly_damage.projectile",cid,fid,60);
                remove_or_not = 1;
                break;
            }

            case 14:{ //三重轰炸
                float strike_rand = 8;
                for(int j=1;j<=3;j++)
                {
                    float rand_x = rand(-strike_rand,strike_rand);
                    float rand_y = rand(-strike_rand,strike_rand);
                    float rand_z = rand(-7,7);
                CreateDirectProjectile(m_metagame,start_pos.add(Vector3(rand_x,rand_z,rand_y)),end_pos.add(Vector3(rand_x,0,rand_y)),"hd_offensive_thunderer_barrage_mk3_damage.projectile",cid,fid,10);
                }
                remove_or_not = 1;
                break;
            }
            case 17:{ //轨道激光轰炸
                CreateDirectProjectile(m_metagame,start_pos,end_pos,"hd_offensive_laser_strike_mk3_damage.projectile",cid,fid,80);
                remove_or_not = 1;
                break;
            }
            case 20:{   //机枪扫射
                CreateDirectProjectile(m_metagame,start_pos,end_pos,"hd_offensive_strafing_run_mk3_mg_spawn.projectile",cid,fid,160);
                remove_or_not = 1;
                break;
            }
            case 23:{   //近空支援 mg
                float rand_speed = rand(30,50);
                CreateDirectProjectile(m_metagame,start_pos,end_pos,"hd_offensive_close_air_support_mk3_mg_spawn.projectile",cid,fid,rand_speed);
                remove_or_not=1;
                break;
            }
            case 24:{   //近空支援 missile
                CreateDirectProjectile(m_metagame,start_pos,end_pos,"hd_offensive_close_air_support_mk3_damage.projectile",cid,fid,25);
                remove_or_not = 1;
                break;
            }
            case 29:{   //导弹弹幕 missile
                float strike_rand = 6;
                    float rand_x = rand(-strike_rand,strike_rand);
                    float rand_y = rand(-strike_rand,strike_rand);
                CreateDirectProjectile(m_metagame,start_pos.add(Vector3(rand_x,0,rand_y)),end_pos.add(Vector3(rand_x,0,rand_y)),"hd_offensive_missile_barrage_mk3_damage.projectile",cid,fid,25);
                remove_or_not = 1;
                break;
            }
            case 32:{   //轨道炮轰炸
                CreateDirectProjectile(m_metagame,start_pos.add(Vector3(0,50,0)),end_pos,"hd_offensive_railcannon_strike_mk3_damage.projectile",cid,fid,15);
                remove_or_not = 1;
                break;
            }
            case 100:{   //acg_starwars_shipgirls_skill 舰队支援
                float strike_rand = 9;
                    float rand_x = rand(-strike_rand,strike_rand);
                    float rand_y = rand(-strike_rand,strike_rand);
                CreateDirectProjectile(m_metagame,start_pos.add(Vector3(rand_x,0,rand_y)),end_pos.add(Vector3(rand_x,0,rand_y)),"acg_starwars_shipgirls_skill_damage.projectile",cid,fid,25);
                remove_or_not = 1;
                break;
            }
            case 101:{   //acg_sabayon_gun_skill_damage 辉火一模式技能
                CreateDirectProjectile(m_metagame,start_pos,end_pos,"acg_sabayon_gun_skill_damage.projectile",cid,fid,75);
                remove_or_not = 1;
                break;
            }
            default:
                break;
        } 

        return remove_or_not;
    }

	void update(float time) {
        if(Airstrike_strafe.length()<=0){return;}

        for (uint a=0;a<Airstrike_strafe.length();a++){
            if(single_airstrike_update(Airstrike_strafe[a])==1)
                {Airstrike_strafe.removeAt(a);}
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