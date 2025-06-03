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
            GiveRP(m_metagame,killer_cid,-18888);
            _notify(m_metagame,pid,"你已经获得过特殊红包奖励，不再获得任何奖励。");
            _notify(m_metagame,pid,"你破坏了其他玩家获取红包的机会，扣除18888rp");
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
class ACT_PlayingCard : Tracker {
    protected const XmlElement@ m_player;
    protected Metagame@ m_metagame;
    protected float m_time = 30;
    protected float m_timer = m_time;
    protected bool m_ended;
    protected array<array<string>> m_cardPools; // 用于存储五个卡池
    protected userCountInfoBuck m_userCountInfoBuck;

    ACT_PlayingCard(Metagame@ metagame){
        @m_metagame = @metagame;
        _log("ACT_PlayingCard executing");
        initializeCardPools();
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
        }
    }

    void endActivity(){
        _report(m_metagame,"扑克牌活动结束");
        m_ended = true;
    }

    protected void handleMatchEndEvent(const XmlElement@ event) {
        endActivity();
    }

    protected void handleItemDropEvent(const XmlElement@ event) {
        string itemKey = event.getStringAttribute("item_key");
        int characterId = event.getIntAttribute("character_id");
        if(characterId == -1){return;}
        int playerId = event.getIntAttribute("player_id");
        int containerId = event.getIntAttribute("target_container_type_id");

        if(containerId == 0 && startsWith(itemKey, "collect_playing_card_radom")) { // 地面掉落随机牌
            processCardDraw(itemKey, characterId, playerId);
        }
    }

    protected void handleChatEvent(const XmlElement@ event) {
        string sender = event.getStringAttribute("player_name");
        int senderId = event.getIntAttribute("player_id");

        if(g_debugMode || g_online_TestMode || m_metagame.getAdminManager().isAdmin(sender, senderId)) {
            string message = event.getStringAttribute("message");
            if(message == "/resetCardPools") {
                initializeCardPools();
                _report(m_metagame, "扑克牌所有卡池已重置！");
            }
        }
    }

    protected void initializeCardPools() {
        array<string> allCards = getAllCards();
        m_cardPools.resize(5);
        for(int i = 0; i < 5; ++i) {
            m_cardPools[i] = allCards;
        }
        _log("All card pools initialized.");
    }

    protected void resetCardPool(int poolIndex) {
        if(poolIndex >= 0 && poolIndex < int(m_cardPools.size())) {
            array<string> allCards = getAllCards();
            m_cardPools[poolIndex] = allCards;
            _report(m_metagame,"扑克牌卡组:"+ poolIndex + "已重置！");
        }
    }

    protected array<string> getAllCards() const {
        return array<string> = {
            "collect_playing_card_clubs_a", "collect_playing_card_clubs_2", "collect_playing_card_clubs_3", "collect_playing_card_clubs_4",
            "collect_playing_card_clubs_5", "collect_playing_card_clubs_6", "collect_playing_card_clubs_7", "collect_playing_card_clubs_8",
            "collect_playing_card_clubs_9", "collect_playing_card_clubs_10", "collect_playing_card_clubs_j", "collect_playing_card_clubs_q",
            "collect_playing_card_clubs_k",
            "collect_playing_card_diamonds_a", "collect_playing_card_diamonds_2", "collect_playing_card_diamonds_3", "collect_playing_card_diamonds_4",
            "collect_playing_card_diamonds_5", "collect_playing_card_diamonds_6", "collect_playing_card_diamonds_7", "collect_playing_card_diamonds_8",
            "collect_playing_card_diamonds_9", "collect_playing_card_diamonds_10", "collect_playing_card_diamonds_j", "collect_playing_card_diamonds_q",
            "collect_playing_card_diamonds_k",
            "collect_playing_card_hearts_a", "collect_playing_card_hearts_2", "collect_playing_card_hearts_3", "collect_playing_card_hearts_4",
            "collect_playing_card_hearts_5", "collect_playing_card_hearts_6", "collect_playing_card_hearts_7", "collect_playing_card_hearts_8",
            "collect_playing_card_hearts_9", "collect_playing_card_hearts_10", "collect_playing_card_hearts_j", "collect_playing_card_hearts_q",
            "collect_playing_card_hearts_k",
            "collect_playing_card_spades_a", "collect_playing_card_spades_2", "collect_playing_card_spades_3", "collect_playing_card_spades_4",
            "collect_playing_card_spades_5", "collect_playing_card_spades_6", "collect_playing_card_spades_7", "collect_playing_card_spades_8",
            "collect_playing_card_spades_9", "collect_playing_card_spades_10", "collect_playing_card_spades_j", "collect_playing_card_spades_q",
            "collect_playing_card_spades_k",
            "collect_playing_card_joker_diver", "collect_playing_card_joker_pig"
        };
    }

    protected void processCardDraw(const string &in itemKey, int characterId, int playerId) {
        int poolIndex = parseInt(itemKey.substr(itemKey.length() - 1)) - 1;
        if(poolIndex < 0 || poolIndex >= int(m_cardPools.size())) {
            _log("Invalid card pool index: " + poolIndex);
            return;
        }

        array<string>@ cardPool = m_cardPools[poolIndex];
        if(cardPool.size() == 0) {
            resetCardPool(poolIndex);
        }

        int randIndex = rand(0, cardPool.size() - 1);
        string selectedCard = cardPool[randIndex];
        cardPool.removeAt(randIndex);

        addItemInBackpack(m_metagame, characterId, "carry_item", selectedCard);
        _notify(m_metagame, playerId, "扑克牌卡组:"+ poolIndex + "还剩下" + cardPool.size() + "张牌");
    }
}
