// internal
#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "gamemode_invasion.as"

#include "dynamic_alert.as"
#include "debug_reporter.as"
#include "INFO.as"
#include "all_helper.as"

//Author： rst
//服务器管理员辅助脚本


class server_admin_manager : Tracker{
    protected Metagame@ m_metagame;
    protected bool m_ended;
    protected string m_FILENAME="_manager.xml";
    protected array<string> m_admins;
    protected array<string> m_publishers;
    protected array<string> m_guides;
    protected array<string> m_mascots;
    protected string m_version = "";

    //--------------------------------------------
    server_admin_manager(Metagame@ metagame){
        @m_metagame = @metagame;
        m_ended = false;
        initiate();
        mergeAdmin();
        _log("load _manager.xml"+m_admins.size());
    }
    // --------------------------------------------
    void update(float time) {
    }
    // ----------------------------------------------------
    protected void initiate(){
        m_admins.resize(0);
        m_publishers.resize(0);
        m_guides.resize(0);
        m_mascots.resize(0);
        XmlElement@ allInfo = XmlElement(readFile(m_metagame,m_FILENAME));
        if(allInfo is null){
            _log("allInfo is null, in server_admin_manager initiate");
            return;
        }
        array<const XmlElement@> m_stashs = allInfo.getChilds();
        if(m_stashs.size() == 0){
            _log("didnt find "+m_FILENAME+",creating");
            XmlElement actinfos("AdminsManager");
                XmlElement info("Manager");
                    info.setStringAttribute("version","1.0.0");
            actinfos.appendChild(info);
            writeXML(m_metagame,m_FILENAME,actinfos);
            return;
        }
    }
    // --------------------------------------------
	bool hasEnded() const {
		return false;
	}
	// --------------------------------------------
	bool hasStarted() const {
		return true;
	}
    void mergeAdmin(){
        const XmlElement@ allInfo = readFile(m_metagame,m_FILENAME);
        if(allInfo is null){
            _log("allInfo is null, in mergeAdmin");
            return;
        }
        array<const XmlElement@> m_stashs = allInfo.getChilds();
        for(int j = 0 ; j < int(m_stashs.size()) ; ++j){
            const XmlElement@ m_stash = m_stashs[j];
            if(m_stash.getName() == "Publisher"){
                string sid = m_stash.getStringAttribute("sid");
                m_publishers.insertLast(sid);
                _log("loading publishers:"+sid);
            }
            if(m_stash.getName() == "Guide"){
                string sid = m_stash.getStringAttribute("sid");
                m_guides.insertLast(sid);
                _log("loading guides:"+sid);
            }
            if(m_stash.getName() == "Mascot"){
                string sid = m_stash.getStringAttribute("sid");
                m_mascots.insertLast(sid);
                _log("loading mascots:"+sid);
            }
            if(m_stash.getName() == "Manager"){
                m_version = m_stash.getStringAttribute("version");
                _log("loading Version:"+m_version);
            }
            if(m_stash.hasAttribute("sid")){
                string sid = m_stash.getStringAttribute("sid");
                m_admins.insertLast(sid);
                _log("loading admins:"+sid);
            }
        }
    }
    void reload(){
        initiate();
        mergeAdmin();
    }
    bool isAdmin(string sid){
        for(uint i = 0; i< m_admins.size();++i){
            if(sid == m_admins[i]){
                return true;
            }
        }
        return false;
    }
    bool isPublisher(string sid){
        for(uint i = 0; i< m_publishers.size();++i){
            if(sid == m_publishers[i]){
                return true;
            }
        }
        return false;
    }
    bool isGuide(string sid){
        for(uint i = 0; i< m_guides.size();++i){
            if(sid == m_guides[i]){
                return true;
            }
        }
        return false;
    }
    bool isMascot(string sid){
        for(uint i = 0; i< m_mascots.size();++i){
            if(sid == m_mascots[i]){
                return true;
            }
        }
        return false;
    }
    // ------------------------------------------------------
    protected void handleChatEvent(const XmlElement@ event) {
		string message = event.getStringAttribute("message");
        message = message.toLowerCase();
        int pid = event.getIntAttribute("player_id");
        string name = event.getStringAttribute("player_name");
        int cid = g_playerInfoBuck.getCidByPid(pid);
        const XmlElement@ character = getCharacterInfo(m_metagame,cid);
        if(character is null){return;}
        Vector3 ePos = stringToVector3(character.getStringAttribute("position"));
        string sid = g_playerInfoBuck.getSidByName(name);
        if(isAdmin(sid)){
            IO_data@ IO = IO_data(m_metagame);
            string key = "/salary";
            if(message == "/salary"){ // 领薪水
                XmlElement checkXml("root");
                    XmlElement xml("Manager");
                        XmlElement sub("version");
                            sub.setStringAttribute("value","1.0.0");
                    xml.appendChild(sub);
                checkXml.appendChild(xml);
                if(!IO.checkTagsInPlayerInfo(sid,checkXml)){ //检测是否重复领过 领取一次性的仓库扩容 
                    IO.handleReward(name,"AdminStash");
                    array<const XmlElement@> xmls;
                    XmlElement xml2("Manager");
                        xml2.setStringAttribute("player_name",name);
                        xml2.setStringAttribute("version","1.0.0");
                    xmls.insertLast(xml2);
                    IO.addToPlayersInfo(xmls,sid);
                }

                string adminType = "";
                if(isPublisher(sid)){
                    adminType = "Publisher";
                }else if(isGuide(sid)){
                    adminType = "Guide";
                }else if (isMascot(sid)){
                    adminType = "Mascot";
                }else{
                    return;
                }
                XmlElement checkXml2("root");
                    XmlElement xml2(adminType);
                        XmlElement sub2("version");
                            sub2.setStringAttribute("value",m_version);
                    xml2.appendChild(sub2);
                checkXml2.appendChild(xml2);

                if(!IO.checkTagsInPlayerInfo(sid,checkXml2)){ //检测是否重复领过
                    IO.handleReward(name,adminType);
                    array<const XmlElement@> xmls;
                    XmlElement xml3(adminType);
                        xml3.setStringAttribute("player_name",name);
                        xml3.setStringAttribute("version",m_version);
                    xmls.insertLast(xml3);
                    IO.addToPlayersInfo(xmls,sid);
                }else{
                    if(isEng(name)){
                        _notify(m_metagame,pid,"You have already received the salary");
                    }else{
                        _notify(m_metagame,pid,"你已经领取过薪水");
                    }
                }
            }

            key = "/kick";
            if(startsWith(message,key)){ // 踢人
                string id = message.substr(key.size()+1);
                int kick_pid = -1;
                if(isNumeric(id)){
                    kick_pid = parseInt(id);
                }
                dictionary a;
                //初始化
                for(int i = 0 ; i < 20 ; ++i){
                    string strvalue;
                    if(i < 10){
                        strvalue = "%valuea"+i;
                    }else{
                        strvalue = "%valueb"+i;
                    }
                    a[strvalue] = "";
                }
                array<const XmlElement@> players = getPlayers(m_metagame);
                for(uint i = 0 ; i < players.size() ; ++i){
                    const XmlElement@ player = players[i];
                    if(player is null){continue;}
                    int k_pid = player.getIntAttribute("player_id");
                    string kick_name = player.getStringAttribute("name");
                    if(kick_pid == k_pid){
                        g_IRQ.set("tempban"+kick_name,true);
                        _notify(m_metagame,kick_pid,"You are kicked form server after vote",true);
                        _notify(m_metagame,pid,"You kick Player:"+kick_name,true);
                        kickPlayer(m_metagame,kick_pid);
                    }
                    if(k_pid < 10){
                        a["%valuea"+k_pid] = kick_name;
                    }else{
                        a["%valueb"+k_pid] = kick_name;
                    }
                }
                notify(m_metagame, "Admin Kick Player Guide", a, "misc", pid, true, "Admin Kick Player", 1.0);
                if(kick_pid == -1){
                    _notify(m_metagame,pid,"Kick missed");
                }
            }
            if(message == "/adminhelp"){ //管理员菜单
                _notify(m_metagame,pid,"AdminHelp",true);
            }
        }
        if(message == "/reloadadmin"){
            reload();
            _notify(m_metagame,pid,"admin reload");
        }
	}

}