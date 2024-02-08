// internal
#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "gamemode_invasion.as"
#include "task_sequencer.as"

#include "debug_reporter.as"
#include "INFO.as"

//author：rst
//活动具体任务

class ACT_QiangHongBao : Tracker {
    protected const XmlElement@ m_player;
    protected Metagame@ m_metagame;
    protected float m_time = 30;
    protected float m_timer = m_time;
    protected bool m_ended;
    protected array<string> m_regis_base_name;
    protected array<string> m_regis_player_name;
    protected userCountInfoBuck m_userCountInfoBuck;

    ACT_QiangHongBao(Metagame@ metagame){
        @m_metagame = @metagame;
        _log("ACT_QiangHongBao executing");
        spawnHongBaoVehicleAtBase();
    }

    void start(){
        m_ended = false;
    }
    bool hasEnded() const{
		return m_ended;
    }

    void update(float time){
        m_timer -= time;
        if(m_timer < 0 ){
            m_timer = m_time;
            //spawnHongBaoVehicleAtBase(1);
        }
    }

    void endActivity(){
        _report(m_metagame,"活动结束：本局红包已发放至上限,下一局游戏将刷新新的红包！");
        m_ended = true;
    }
    // ----------------------------------------------------
	protected void handleMatchEndEvent(const XmlElement@ event) {
		endActivity();
	}

    protected void spawnHongBaoVehicleAtBase(int num = -1 ,string vehicle_key = "hongbao.vehicle"){
        array<const XmlElement@> bases = getBases(m_metagame);
		for (uint i = 0; i < bases.size(); ++i) {
            const XmlElement@ base = bases[i];
            Vector3 basePosition = stringToVector3(base.getStringAttribute("position"));
            string baseName = base.getStringAttribute("name");
            bool regis = false;
            for(uint j = 0; j < m_regis_base_name.size(); ++j){
                if(m_regis_base_name[j].find(baseName) >= 0){
                    _log("base "+baseName+" has regis for HongBao,continue");
                    regis = true;
                    break;
                }
            }
            if(bases.size() == m_regis_base_name.size()){
                return;
            }
            if(regis){
                continue;
            }else{
                _log("add base "+baseName+" to new HongBao spawn position("+ basePosition.toString() +")");
                m_regis_base_name.insertLast(baseName);
            }
            if(num != -1){
                num--;
                if(num < 0){
                    return;
                }            
            }

            XmlElement command("command");
            command.setStringAttribute("class", "create_instance");
            command.setStringAttribute("instance_class", "vehicle");
            command.setStringAttribute("instance_key", vehicle_key);
            command.setStringAttribute("position", basePosition.toString());
            command.setIntAttribute("faction_id", 0);
            m_metagame.getComms().send(command);
        }
        _report(m_metagame,"活动通知：新的红包已经刷新在随机的据点中，快去寻找吧！");
    }
    protected void handleVehicleDestroyEvent(const XmlElement@ event) {
        string vehicle_name = event.getStringAttribute("vehicle_key");
        int vehicle_id = event.getIntAttribute("vehicle_id");
        int killer_cid = event.getIntAttribute("character_id");
        int killer_fid = event.getIntAttribute("faction_id");
        int vehicle_owner_fid = event.getIntAttribute("owner_id");
        Vector3 position = stringToVector3(event.getStringAttribute("position"));
        if(vehicle_name != "hongbao.vehicle"){return;}

        int pid = g_playerInfoBuck.getPidByCid(killer_cid);
        string name = g_playerInfoBuck.getNameByCid(killer_cid);
        if(pid == -1){
            //spawnHongBaoVehicleAtBase(1);   //重新生成
            return;
        }
        int count = 0;
        m_userCountInfoBuck.addInfo(name);
        m_userCountInfoBuck.getCount(name,"act_hongbao",count);
        _log("count="+count);
        if(count < 1){
            //摧毁的玩家发特殊红包
            m_regis_player_name.insertLast(name);
            addItemInBackpack(m_metagame,killer_cid,"carry_item","hongbao_special.carry_item");
            _notify(m_metagame,pid,"恭喜你获得了特殊红包奖励！");   
            
            array<const XmlElement@> players = getPlayers(m_metagame);
            for(uint i = 0 ;i < players.size() ; ++i){
                const XmlElement@ player = players[i];
                if(player is null){continue;}
                int now_pid = player.getIntAttribute("player_id");
                int now_cid = player.getIntAttribute("character_id");
                const XmlElement@ character = getCharacterInfo(m_metagame,now_cid);
                if(character is null){continue;}
                Vector3 now_position = stringToVector3(character.getStringAttribute("position"));
                float now_distance = getFlatPositionDistance(position,now_position);
                if(now_distance <= 30){ 
                    addItemInBackpack(m_metagame,now_cid,"carry_item","hongbao.carry_item");
                    _notify(m_metagame,now_pid,"你获得了1个共享RP红包");   
                }
            }

            m_userCountInfoBuck.addCount(name,"act_hongbao");
            _log("player "+name+" get HongBao, add 1 time to origin Count:"+count);
            //spawnHongBaoVehicleAtBase(1);
        }else{
            GiveRP(m_metagame,killer_cid,-88888);
            _notify(m_metagame,pid,"你已经获得过特殊红包奖励，不再获得任何奖励。");
            _notify(m_metagame,pid,"你破坏了其他玩家获取红包的机会，扣除88888rp");
            //spawnHongBaoVehicleAtBase(1);
        }
    }
    // ------------------------------------------------------
    protected void handleChatEvent(const XmlElement@ event) {
        string sender = event.getStringAttribute("player_name");
        int senderId = event.getIntAttribute("player_id");

        if(g_debugMode|| g_online_TestMode || m_metagame.getAdminManager().isAdmin(sender,senderId) ){
            string message = event.getStringAttribute("message");
            if(message == "/spawnHongBaoVehicleAtBase"){
                spawnHongBaoVehicleAtBase(1);
            }
        }
	}
}