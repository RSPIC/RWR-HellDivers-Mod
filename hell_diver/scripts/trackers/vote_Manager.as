#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "gamemode_invasion.as"
#include "all_helper.as"

#include "debug_reporter.as"
#include "INFO.as"

//author:RST
//玩家投票功能

enum VoteStage {
    NoVote,
    VoteRequested,
    VoteTypeSelected,
    TargetSelected,
    ReasonSelected,
    Voting
};

class VoteManager : Tracker {
    protected Metagame@ m_metagame;
    protected float m_timer;

    protected int m_pid;    //发起投票者id，用于发送信息
    private string m_voterName; //发起投票者name，用于发送信息

    private VoteStage m_voteStage;  //投票阶段
    private float m_voteDuration;   //投票持续时间

    private int m_voteTypeIndex;      //投票类型
    private int m_targetIndex;     //投票对象(玩家)
    private int m_reasonIndex;      //原因

    private array<string> m_yesVoters;
    private array<string> m_noVoters;
    private array<string> m_nameList;   //记录投票对象对应的玩家名
    
    private dictionary m_isVote;    //记录玩家单次投票情况
    
    private array<array<string>> @m_reasonList;
    private array<string> @m_voteList;
    

    VoteManager(Metagame@ metagame){
        @m_metagame = @metagame;
        m_voteDuration = 60.0;
        m_voteStage = VoteStage::NoVote;
        m_timer = m_voteDuration;
        m_yesVoters.resize(0);
        m_noVoters.resize(0);
        m_nameList.resize(0);
        m_isVote = dictionary();
        array<array<string>> dic = {
            {
                "恶意/多次TK其他玩家",
                "辱骂/嘲讽他人",
                "消极/挂机作战",
                "利用恶性BUG",
                "其他"
            },
            {
                "难度过高",
                "存在BUG，无法通关",
                "地图体验过差",
                "其他"
            },
            {
                "有礼貌",
                "乐于助人",
                "高水平玩家",
                "老司机",
                "合格的地狱潜兵",
                "就是想夸你"
            }
        };
        array<string> dic2 = {"踢出玩家","跳过当前地图",""};
        @m_reasonList = dic;
        @m_voteList = dic2;

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
    void update(float time) {
        if(m_voteStage != VoteStage::NoVote){
            m_timer -= time;
            if(m_timer <= 0.0){
                m_timer = m_voteDuration;
                clearStage();
            }
        }
    }
    // -------------------------------------------
    void clearStage(){
        calculateVoteResult(m_yesVoters.size(),m_noVoters.size(),m_voteTypeIndex,true);
        notify(m_metagame, "OverTime,Vote End", dictionary(), "misc", m_pid, false, "", 1.0);
        resetVote();
    }
    void resetVote(){
        m_voteStage = VoteStage::NoVote;
        m_yesVoters.resize(0);
        m_noVoters.resize(0);
        m_nameList.resize(0);
        m_isVote = dictionary();
        m_timer = m_voteDuration;
        m_pid = -1;
    }
    // -------------------------------------------
    protected void handleChatEvent(const XmlElement@ event){
		string message = event.getStringAttribute("message");
		string playerName = event.getStringAttribute("player_name");
        int pid = event.getIntAttribute("player_id");
        if(message == "/clearvote"){
            resetVote();
            return;
        }
        //若有人在使用投票系统，则返回;如果是投票阶段，则许可
        if (m_voteStage != VoteStage::NoVote && m_voteStage != VoteStage::ReasonSelected) {
            if(pid != m_pid){
                notify(m_metagame, "Now has a vote under selecting", dictionary(), "misc", pid, false, "", 1.0);
                return;
            }
        }

        if (message.substr(0, 5) == "/vote" || message == "/yes" || message == "/no") {
            switch (m_voteStage) {
                case VoteStage::NoVote:
                    //玩家请求阶段，给玩家发送投票菜单
                    handleVoteRequest(playerName, message, pid);
                    break;
                case VoteStage::VoteRequested:
                    //玩家选择阶段，玩家选择完毕发送对应的对象选择菜单
                    handleVoteTypeSelection(message);
                    break;
                case VoteStage::VoteTypeSelected:
                    //玩家选择对象阶段，如踢人对象
                    handleTargetSelection(message);
                    break;
                case VoteStage::TargetSelected:
                    //玩家选择原因阶段
                    handleReasonSelection(message);
                    break;
                case VoteStage::ReasonSelected:
                    //集体投票阶段
                    handleVote(playerName, message);
                    break;
            }
        }
	}
    // -------------------------------------------
    void handleVoteRequest(string playerName, string playerMessage,int pid) {//开始投票行为
        m_pid = pid;
        m_voterName = playerName;
        m_voteStage = VoteStage::VoteRequested;
        m_timer = m_voteDuration;
        //发布投票菜单
        showVoteMenu();
    }
    void showVoteMenu(){
        notify(m_metagame, "VoteMenu - content", dictionary(), "misc", m_pid, true, "VoteMenu", 700.0);
    }
    void handleVoteTypeSelection(string voteTypeMessage) {//选择投票类型
        string num = voteTypeMessage.substr(6);
        if(isNumeric(num)){
            m_voteTypeIndex = parseInt(num)-1;
            if(m_voteTypeIndex == -1){
                resetVote();
                return;
            }
        }
        if(!isNumeric(num) || m_voteTypeIndex < 0 || m_voteTypeIndex >= int(m_voteList.size())){
            //玩家输入错误,重新发送菜单
            notify(m_metagame, "VoteTargetInvalid", dictionary(), "misc", m_pid, false, "VoteMenu");
            showVoteMenu();
            m_timer = m_voteDuration;
            return;
        }
         
        m_voteStage = VoteStage::VoteTypeSelected;
        m_timer = m_voteDuration;
        //发布投票类型菜单
        showListMenu(m_voteTypeIndex);
    }
    void showListMenu(int voteTypeIndex){//展示投票对象菜单
        if(voteTypeIndex == 0){//投票踢出玩家
            //发送当前玩家菜单
            showNowPlayers();
        }else if(voteTypeIndex == 1){//投票跳过当前地图（无结算收益）
            //直接进入原因选择阶段
            m_voteStage = VoteStage::TargetSelected;
            //发送原因选择菜单
            showReasonSelection(voteTypeIndex);
        }else if(voteTypeIndex == 2){//赞赏玩家
            //发送当前玩家菜单
            showNowPlayers();
        }else{
            //对象不存在
            notify(m_metagame, "VoteTargetInvalid", dictionary(), "misc", m_pid, false, "VoteMenu");
            resetVote();
            return;
        }
    }
    void showNowPlayers(){
        array<const XmlElement@> players = getPlayers(m_metagame);
        dictionary dic;
        string input;
        for(uint i = 0; i < players.size(); ++i){
            const XmlElement@ player = players[i];
            string name = player.getStringAttribute("name");
            //if(name == m_voterName){continue;}
            m_nameList.insertLast(name);
            dic["%"+i] = "\n";
            input += "#"+(i+1)+" "+name+" "+"%"+i;
        }
        // if(players.size() == 1){
        //     notify(m_metagame, "Only One Player,faild to Vote", dic, "misc", m_pid, true, "VoteMenu");
        //     resetVote();
        //     return;
        // }
        notify(m_metagame, input, dic, "misc", m_pid, true, "VoteMenu", 700.0);
    }
    void handleTargetSelection(string targetMessage) {//投票对象选择
        string num = targetMessage.substr(6);
        if(isNumeric(num)){
            m_targetIndex = parseInt(num)-1;
            if(m_targetIndex == -1){
                resetVote();
                return;
            }
        }
        if(!isNumeric(num) || m_targetIndex < 0 || m_targetIndex >= int(m_nameList.size())){
            //玩家输入错误,重新发送菜单
            notify(m_metagame, "VoteTargetInvalid", dictionary(), "misc", m_pid, false, "VoteMenu");
            showListMenu(m_voteTypeIndex);
            m_timer = m_voteDuration;
            return;
        }

        m_voteStage = VoteStage::TargetSelected;
        m_timer = m_voteDuration;
        //发送原因选择
        showReasonSelection(m_voteTypeIndex);
    }
    void showReasonSelection(int voteTypeIndex){//展示原因选择界面
        dictionary dic;
        string input;
        for(uint i = 0; i < m_reasonList[voteTypeIndex].size(); ++i){
            dic["%"+i] = "\n";
            input += "#"+(i+1)+" "+ m_reasonList[voteTypeIndex][i]+"%"+i;
        }
        notify(m_metagame, input, dic, "misc", m_pid, true, "VoteMenu");
    }
    void handleReasonSelection(string targetMessage) {
        string num = targetMessage.substr(6);
        if(isNumeric(num)){
            m_reasonIndex = parseInt(num) -1;
            if(m_reasonIndex == -1){
                resetVote();
                return;
            }
        }
        if(!isNumeric(num) || m_reasonIndex < 0 || m_reasonIndex >= int(m_reasonList[m_voteTypeIndex].size())){
            //玩家输入错误,重新发送菜单
            notify(m_metagame, "VoteTargetInvalid", dictionary(), "misc", m_pid, false, "VoteMenu");
            showReasonSelection(m_voteTypeIndex);
            m_timer = m_voteDuration;
            return;
        }
        m_voteStage = VoteStage::ReasonSelected;
        m_timer = m_voteDuration;
        //全体发放投票通知
        showVotingInstructions(m_voteTypeIndex);
    }
    void showVotingInstructions(int voteTypeIndex){
        string target;
        if(voteTypeIndex == 0){//踢出玩家，会有m_targetIndex
            target = string(m_voteList[m_voteTypeIndex]) + string(m_nameList[m_targetIndex]);
        }
        if(voteTypeIndex == 1){//跳图
            target = string(m_voteList[m_voteTypeIndex]);
        }
        if(voteTypeIndex == 2){//赞赏无需投票，直接进行结算
            calculateVoteResult(1,0,m_voteTypeIndex);
            return;
        }

        dictionary dic;
        dic["%name"] = m_voterName;
        dic["%target"] = target;
        dic["%reason"] = string(m_reasonList[m_voteTypeIndex][m_reasonIndex]);
        _report(m_metagame,"VoteMenu All",dic,"VoteMenu",true);
        _report(m_metagame,"Vote left time: 60s");
    }
    void handleVote(string playerName, string playerMessage) {
        bool value;
        if(!m_isVote.get(playerName,value)){
            if (playerMessage == "/yes") {
                m_yesVoters.insertLast(playerName);
                m_isVote.set(playerName,true);
            } else if (playerMessage == "/no") {
                m_noVoters.insertLast(playerName);
                m_isVote.set(playerName,true);
            }
        }else{
            int pid = g_playerInfoBuck.getPidByName(playerName);
            notify(m_metagame, "You have voted", dictionary(), "misc", pid, false, "", 1.0);
            return;
        }
        calculateVoteResult(m_yesVoters.size(),m_noVoters.size(),m_voteTypeIndex);
    }

    void calculateVoteResult(uint yesNum,uint noNum,int voteTypeIndex,bool m_timeOut = false){
        if(m_voteStage == VoteStage::ReasonSelected){
            bool isHandled = false;
            if(voteTypeIndex == 0){//踢出玩家需要过半数
                _report(m_metagame,"赞成["+yesNum+"]"+"反对["+noNum+"]"+"总数["+m_nameList.size()+"]");
                if(yesNum > noNum && int(yesNum+noNum) >= int(m_nameList.size()/2)+1 || int(yesNum) >= 3){
                    handlePlayerKick(m_targetIndex);
                    isHandled = true;
                }
                if(m_timeOut){
                    string name = m_nameList[m_targetIndex];
                    _report(m_metagame,"玩家"+name+"没有被踢出游戏");
                    resetVote();
                    return;
                }
            }else if(voteTypeIndex == 1){//换图必须全员确认
                _report(m_metagame,"赞成["+yesNum+"]"+"反对["+noNum+"]"+"总数["+g_playerInfoBuck.size()+"]");
                if(noNum == 0 && yesNum + noNum >= g_playerInfoBuck.size()){
                    handleMapChange();
                    isHandled = true;
                }
                if(noNum != 0 || m_timeOut){
                    _report(m_metagame,"有玩家反对/未投票 跳图失败");
                    resetVote();
                    return;
                }
            }else if(voteTypeIndex == 2){//赞赏无需投票
                handleAppreciate(m_targetIndex);
                resetVote();
                return;
            }else{
                if(g_debugMode){
                    _report(m_metagame,"VoteResult Index is not exist,index = "+m_voteTypeIndex);
                }
                return;
            }
            if(isHandled){
                resetVote();
                _report(m_metagame,"Vote successd");
            }
        }
    }

    void handlePlayerKick(int index){
        if(index >= int(m_nameList.size())){
            _report(m_metagame,"index overflowr in handlePlayerKick");
            return;
        }
        
        string name = m_nameList[index];
        g_IRQ.set("tempban"+name,true);
        int pid = g_playerInfoBuck.getPidByName(name);
        g_battleInfoBuck.removeInfo(name);
        notify(m_metagame,"You are kicked form server after vote", dictionary(), "misc", pid, false, "", 1.0);
        kickPlayer(m_metagame,pid);
        _report(m_metagame,"玩家"+name+"已被投票踢出");
        
    }
    void handleMapChange(){
        g_battleInfoBuck.clearAll();
        m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='1' />");
        m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='2' />");
        m_metagame.getComms().send("<command class='set_match_status' win='1' faction_id='0' />");
    }
    void handleAppreciate(int index){
        if(index >= int(m_nameList.size())){
            _report(m_metagame,"index overflowr in handlePlayerKick");
            return;
        }
        string name = m_nameList[index];
        int pid = g_playerInfoBuck.getPidByName(name);
        notify(m_metagame, "你成功赞赏了"+name, dictionary(), "misc", m_pid, false, "", 1.0);
        if(pid == m_pid){//不能赞赏自己
            _report(m_metagame,"玩家："+m_voterName+" 称赞了他自己");
            return;
        }
        int cid = g_playerInfoBuck.getCidByPid(pid);
        if(cid == -1 || pid == -1){
            _report(m_metagame,"handleAppreciate target is not find");
            return;
        }
        dictionary dic;
        dic["%name"] = m_voterName;
        dic["%reason"] = string(m_reasonList[m_voteTypeIndex][m_reasonIndex]);
        if(g_firstUseInfoBuck.isFirst(name,"BeAppreciated")){
            GiveRP(m_metagame,cid,3000);
            GiveXP(m_metagame,cid,1.0);
            notify(m_metagame, "You are Appreciated and rewarded", dic, "misc", pid, true, "", 700.0);
        }else{
            notify(m_metagame, "You are Appreciated, but no reward for second times", dic, "misc", pid, true, "", 700.0);
        }
    }

}

