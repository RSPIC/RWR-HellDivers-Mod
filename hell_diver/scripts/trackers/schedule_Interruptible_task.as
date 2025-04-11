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
#include "task_sequencer.as"

#include "debug_reporter.as"
#include "schedule_IRQ.as"
#include "INFO.as"

//author: rst
//可中断延时任务

// 调用方法
//#include "schedule_Interruptible_task.as"
//schedule_Interruptible_task@ new_task = schedule_Interruptible_task(m_metagame,player,5.0,key);
//TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
//tasker.add(new_task);


// getPlayers(m_metagame);
// getPlayerInfo(const Metagame@ metagame, int pid);
// SCRIPT:  received: TagName=query_result query_id=22     
// TagName=player aim_target=416.987 9.21569 464.311 
// character_id=293 color=0.68 0.85 0 1 faction_id=0 
// name=MR. RST player_id=0 profile_hash=ID3986571819 sid=ID0     
// TagName=access_tag name=edelweiss     TagName=access_tag name=ww2 

// getCharacterInfo(m_metagame,cid);
// SCRIPT:  received: TagName=query_result query_id=32     
// TagName=character block=6 16 dead=0 faction_id=0 id=293 
// leader=1 name=Squishie Hazel player_id=0 position=236.49 6.51867 560.955 
// rp=0 soldier_group_name=default squad_size=0 wounded=0 xp=0 

class schedule_Interruptible_task : Task{
    protected const XmlElement@ m_player;
    protected Metagame@ m_metagame;
    protected float m_time;
    protected float m_timer;
    protected float m_timer_ex_timer;
    protected string m_key;     //记录格式为 cid+玩家名+键值
    protected bool m_ended;
    protected bool isShutDown;
    protected bool isStart;
    protected int m_cid;

    schedule_Interruptible_task(Metagame@ metagame,const XmlElement@ player,float time,string key,int cid){
        @m_player = @player;
        @m_metagame = @metagame;
        m_time = time;
        m_timer = m_time;
        m_timer_ex_timer = 0.2;
        m_key = key ;
        m_cid = cid;
        g_IRQ.set(m_key,false); //添加至中断请求存储区
        g_IRQ.set(m_cid,true);  //添加至中断请求存储区
        _log("schedule_Interruptible_task executing");
    }

    void start(){
        m_ended = false;
        isStart = true;
        isShutDown = false;
        MyTask();
    }
    
    void update(float time){
        m_timer -= time;
        m_timer_ex_timer -= time;
        if(m_timer_ex_timer < 0){
            INT();  //检测中断状态
            m_timer_ex_timer = 0.2;
        }
        if(m_timer >0){return;}
        if(!isShutDown){
            MyTask();
        }
        g_IRQ.remove(m_key);     //清除字典内容
        g_IRQ.remove(m_cid);     //清除字典内容
        m_ended = true;
    }

    bool hasEnded() const{
		return m_ended;
    }

    protected void INT(){
        if(g_IRQ.get(m_key)){   //若检测到中断，置计时器零并自动清除存储内容
            //_report(m_metagame,"INT start, get key and delete it, key="+m_key);
            m_timer = 0;
        }
        if(!g_IRQ.cidValid(m_cid)){     //状态为假，结束task，字典会自动清除
            m_timer = 0;
            isShutDown = true;
        }
    }

    protected void MyTask(){
        if(m_player is null){return;}
        string p_name = m_player.getStringAttribute("name");
        uint start = formatInt(m_cid).length() + p_name.length();
        string target_key = m_key.substr(start);
        if(g_debugMode){
            _report(m_metagame,"ISR cut key="+target_key,"中断服务接受键值",false);
        }
        if(target_key == "ex_cl_banzai"){
            banzai();
        }
        if(target_key == "hd_b100_portable_hellbomb"){
            Hellbomb();
        }
    } 

    // --------------------------------------------------------------------
    protected void banzai(){
		if(m_ended){return;}
        const XmlElement@ player = @m_player;
        int cid = player.getIntAttribute("character_id");
        if(m_cid != cid){return;}   //玩家启动时死亡，新角色CID会变
        int fid = player.getIntAttribute("faction_id");
        const XmlElement@ character = getCharacterInfo(m_metagame,cid);
        if(character !is null){
            int wounded = character.getIntAttribute("wounded");
            int dead = character.getIntAttribute("dead");
            int pid = character.getIntAttribute("player_id");
            if(dead !=1 && wounded != 1){
                if(isStart){    //启动时发护甲，结束时替换护甲+爆炸+死亡
                    notify(m_metagame, "BanZai Armor onload", dictionary(), "misc", pid, false, "", 1.0);
                    editPlayerVest(m_metagame,cid,"hd_banzai_0",4);
                    isStart = false;
                }else{
                    string c_position = character.getStringAttribute("position");
                    editPlayerVest(m_metagame,cid,"helldivers_vest",4);
                    spawnStaticProjectile(m_metagame,"ex_cl_banzai_damage.projectile",c_position,cid,fid);
                    setDeadCharacter(m_metagame,cid);
                }
            }
        }
        
	}
    // --------------------------------------------------------------------
    protected void Hellbomb(){
        if(m_ended){return;}
        const XmlElement@ player = @m_player;
        int cid = player.getIntAttribute("character_id");
        if(m_cid != cid){return;}   //玩家启动时死亡，新角色CID会变
        int fid = player.getIntAttribute("faction_id");
        const XmlElement@ character = getCharacterInfo(m_metagame,cid);
        if(character !is null){
            int wounded = character.getIntAttribute("wounded");
            int dead = character.getIntAttribute("dead");
            int pid = character.getIntAttribute("player_id");
            if(dead !=1 && wounded != 1){
                if(isStart){    //启动时播放音乐
                    Vector3 pos = stringToVector3(character.getStringAttribute("position"));
                    // playSoundAtLocation(m_metagame,"hd_b100_portable_hellbomb_launch.wav",0,pos,2.0);
                    isStart = false;
                }else{
                    string c_position = character.getStringAttribute("position");
                    spawnStaticProjectile(m_metagame,"hd_offensive_shredder_missile_strike_mk3_spawn_call.projectile",c_position,cid,fid);
                    setDeadCharacter(m_metagame,cid);
                }
            }
        }
    }
}