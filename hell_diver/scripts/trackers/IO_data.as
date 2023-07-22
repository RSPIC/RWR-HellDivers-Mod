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
//HD专用的数据存取脚本
//需要按一定格式存写

//子项中带有onRemove="1"标签的将会被排除
//子项中的"_"用于标签排序
//基于player_name标签来实现数据融并，融并时会自动简并子项中的player_name属性
//子项的TagName将会变为主数据access_tag标签中的_tag属性

//密钥兑换系统

const XmlElement@ readXML(const Metagame@ metagame, string filename){
	XmlElement@ query = XmlElement(
		makeQuery(metagame, array<dictionary> = {
			dictionary = { {"TagName", "data"}, {"class", "saved_data"}, {"filename", filename}, {"location", "app_data"} } }));
	const XmlElement@ xml = metagame.getComms().query(query);
    if(xml is null){
        writeXML(metagame,filename,XmlElement("filename"));
    }
	return xml;
}

void writeXML(const Metagame@ metagame, string filename, XmlElement@ xml, string location = "app_data" ){
	XmlElement command("command");
		command.setStringAttribute("class", "save_data");
		command.setStringAttribute("filename", filename);
		command.setStringAttribute("location", location);
		command.appendChild(xml);
	metagame.getComms().send(command);
}

class IO_data : Tracker {
    protected Metagame@ m_metagame;
    protected bool save_data;
    protected float m_time;
    protected float m_timer;
    protected string m_playerInfo_FILENAME;
    protected string m_reward_keys_FILENAME;


    IO_data(Metagame@ metagame){
        @m_metagame = @metagame;
        m_time = 1.0;
        m_timer = m_time;
        save_data = false;
        m_playerInfo_FILENAME = "_playerinfo.xml";
        m_reward_keys_FILENAME = "reward_keys.xml";
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
        m_timer -= time;
        if(m_timer <= 0.0){
            m_timer = m_time;
        }
      }
    // -------------------------------------------
    void start(){
        //addToPlayersInfo();
    }
    // -------------------------------------------
    protected void handlePlayerDisconnectEvent(const XmlElement@ event) {
        const XmlElement@ player = event.getFirstElementByTagName("player");
        if(player is null){return;}
        updatePlayers(player,false);
    }
    // -------------------------------------------
	protected void handlePlayerConnectEvent(const XmlElement@ event) {
		const XmlElement@ player = event.getFirstElementByTagName("player");
        if(player is null){return;}
        updatePlayers(player);
	}
    // -------------------------------------------
    protected void handleChatEvent(const XmlElement@ event){
		string message = event.getStringAttribute("message");
		string p_name = event.getStringAttribute("player_name");
		debug(message,p_name);
        setMainAccount(message,p_name);
		handleRewardKeys(message,p_name);
		handleSoilderChangeKeys(message,p_name);
		handleMyInviteKey(message,p_name);
	}
    // -------------------------------------------
    protected void handleRewardKeys(string&in message,string&in p_name){
        if(startsWith(message,"/key")){
            XmlElement@ allInfo = XmlElement(readFile(m_reward_keys_FILENAME));
            if(allInfo is null){
                _log("allInfo is null, in handleRewardKeys");
                _report(m_metagame,"handleRewardKeys Failed, please report this bug");
                return;
            }

            array<const XmlElement@> infos = allInfo.getElementsByTagName("reward_key");
            bool isValid = false;
            string access_tag = "";
            int pid = g_playerInfoBuck.getPidByName(p_name);
            string m_sid = g_playerInfoBuck.getSidByName(p_name);
            //遍历密钥列表
            XmlElement@ targetInfo;
            uint index;
            for(uint i=0;i<infos.size();++i){
                XmlElement@ info = XmlElement(infos[i]);
                if(info.hasAttribute("_key")){
                    string targetKey = info.getStringAttribute("_key");
                    string player_name = info.getStringAttribute("player_name");
                    //正确
                    if("/key " + targetKey == message){
                        notify(m_metagame, "Key Valid", dictionary(), "misc", pid, false, "", 1.0);
                        access_tag = info.getStringAttribute("access_tag");

                        //检测是否为重复使用
                        bool double_use = false;
                        if(info.hasAttribute("sid")){
                            bool isUsed = info.getBoolAttribute("sid");
                            if(isUsed){
                                if(g_debugMode){
                                    _report(m_metagame,"isUsed,my sid="+m_sid);
                                }
                                
                                double_use = true;
                            }
                        }
                        if(player_name == p_name){
                            if(g_debugMode){
                                _report(m_metagame,"player_name = p_name, Key double used");
                            }
                            double_use = true;
                        }
                        //若密钥为指定对象才能使用
                        if(info.hasAttribute("bond_target")){
                            string compare_key = info.getStringAttribute("bond_target");
                            if(compare_key != p_name && compare_key != m_sid){
                                double_use = true;
                            }
                        }
                        if(!double_use){
                            //单次使用密钥,无max_use标签
                            if(info.hasAttribute("used")){
                                int used = info.getIntAttribute("used");
                                if(used >= 1 && !info.hasAttribute("max_use")){
                                    if(g_debugMode){
                                        _report(m_metagame,"single used key,had been used");
                                    }
                                    isValid = false;
                                }else{
                                    if(g_debugMode){
                                        _report(m_metagame,"single used key,is not been used");
                                    }
                                    used++;
                                    info.setIntAttribute("used",used);
                                    info.setBoolAttribute("sid",true);
                                    isValid = true;
                                }
                            }
                            //多次使用密钥,有max_use标签,记录各个使用者的sid
                            if(info.hasAttribute("max_use")){
                                int times = info.getIntAttribute("max_use");
                                if(times != 0){
                                    if(g_debugMode){
                                        _report(m_metagame,"multi used key,is not been used out");
                                    }
                                    times--;
                                    info.setIntAttribute("max_use",times);
                                    info.setBoolAttribute("sid",true);
                                    isValid = true;
                                }else{
                                    if(g_debugMode){
                                        _report(m_metagame,"multi used key,has been used out");
                                    }
                                    isValid = false;
                                }
                            }
                        }

                        if(!isValid || double_use){
                            notify(m_metagame,"Key had been used", dictionary(), "misc", pid, false, "", 1.0);
                            return;
                        }

                        info.setStringAttribute("player_name",p_name);
                        // allInfo.appendChild(info);
                        // allInfo.removeChild("reward_key",i);
                        @targetInfo = info;
                        index = i;
                        break;
                    }
                }
            }
            if(g_debugMode && isValid){
                _report(m_metagame,"Key Valid");
            }
            if(isValid){
                if(handleReward(p_name,access_tag)){
                    // 兑换成功才进行记录
                    allInfo.removeChild("reward_key",index);
                    allInfo.appendChild(targetInfo);
                    writeXML(m_metagame,m_reward_keys_FILENAME,allInfo);
                    notify(m_metagame, "Successful exchange", dictionary(), "misc", pid, true, "", 1.0);
                }else{
                    notify(m_metagame, "Not meet the condition", dictionary(), "misc", pid, true, "", 1.0);
                }
                
            }else{
                notify(m_metagame, "Key Invalid", dictionary(), "misc", pid, false, "", 1.0);
            }
        }
    }
    // -------------------------------------------
    protected void handleSoilderChangeKeys(string&in message,string&in p_name){
        
        string msg = "/change ";
        if(startsWith(message,msg)){
            int pid = g_playerInfoBuck.getPidByName(p_name);
            int cid = g_playerInfoBuck.getCidByPid(pid);
            int fid = g_playerInfoBuck.getFidByCid(cid);

            XmlElement@ allInfo = XmlElement(readFile(m_reward_keys_FILENAME));
            if(allInfo is null){
                _log("allInfo is null, in handleRewardKeys");
                _report(m_metagame,"handleRewardKeys Failed, please report this bug");
                return;
            }

            string target_soldier = message.substr(msg.length());
            string original_soldier = g_playerInfoBuck.getGroupByName(p_name);
            bool valid = false;
            valid = g_factionInfoBuck.get(target_soldier,fid);
            if(valid){
                dictionary dic;
                dic["%target"] = target_soldier;
                notify(m_metagame, "Change Target Valid", dic, "misc", pid, false, "", 1.0);

            }else{
                dictionary dic;
                dic["%target"] = target_soldier;
                notify(m_metagame, "Change Target InValid", dic, "misc", pid, false, "", 1.0);
            }

            array<XmlElement@> xmls;
            XmlElement mySoldier("soldier");
            mySoldier.setStringAttribute("player_name",p_name);
            mySoldier.setStringAttribute("soldier_group_name",original_soldier);
            mySoldier.setStringAttribute("target_soldier",target_soldier);
            mySoldier.setBoolAttribute("valid",valid);
            xmls.insertLast(mySoldier);
        }
    }
    
    // -------------------------------------------
    protected void setMainAccount(string&in message,string&in p_name){
        if(startsWith(message,"/register")){
            XmlElement@ allInfo = XmlElement(readFile(m_playerInfo_FILENAME));
            if(allInfo is null){
                _log("allInfo is null, in setMainAccount");
                return;
            }
            if(allInfo is null){return;}

            array<const XmlElement@> infos = allInfo.getElementsByTagName("player");
            bool is_main_account = false;
            bool isValid = false;
            //遍历玩家数据存档
            for(uint i=0;i<infos.size();++i){
                XmlElement@ info = XmlElement(infos[i]);
                //获取到当前名字下的存档
                if(info.hasAttribute("player_name")){
                    string player_name = info.getStringAttribute("player_name");
                    //_report(m_metagame,"now i and player_name"+i+" "+player_name);
                    if(player_name == p_name){
                        //获取到sid值，设置当前账号为主账号，移除其余同sid值账号主账号
                        string sid = info.getStringAttribute("sid");
                        //重新遍历，倒序
                        for(int j = int(infos.size())-1 ; j >= 0 ; --j){
                            @info = XmlElement(infos[j]);
                            string new_sid = info.getStringAttribute("sid");
                            string new_player_name = info.getStringAttribute("player_name");
                            //_report(m_metagame,"new_player_name="+new_player_name);
                            //_report(m_metagame,"now i and j="+i+" "+j);
                            //是子账户
                            if(new_sid == sid){
                                is_main_account = false;
                            }
                            //是主账号
                            if(new_player_name == player_name){
                                is_main_account = true;
                            }
                            //覆写所有同SID存档
                            if(new_sid == sid){
                                array<const XmlElement@> childs = allInfo.getLowerChilds("player",j);
                                allInfo.removeChild("player",j);
                                info.removeAllChild();
                                info.setBoolAttribute("is_main_account",is_main_account);
                                info.appendChilds(childs);
                                allInfo.appendChild(info);
                                isValid=true;
                            }
                            
                        }
                        break;
                    }
                }
            }

            if(g_debugMode && isValid){
                _report(m_metagame,"Key Valid");
            }
            int pid = g_playerInfoBuck.getPidByName(p_name);
            if(isValid){
                writeXML(m_metagame,m_playerInfo_FILENAME,allInfo);
                notify(m_metagame, "Key Valid", dictionary(), "misc", pid, false, "", 1.0);
            }else{
                notify(m_metagame, "Key Invalid", dictionary(), "misc", pid, false, "", 1.0);
            }
        }
    }
    // -------------------------------------------
    protected void handleMyInviteKey(string&in message,string&in p_name){
        //逻辑：玩家需要先注册自己的邀请码，会生成以hash为邀请码的标签存入玩家存档
        //注册时，会生成inviter标签、invited标签，只有注册了的号才能领奖
        //用户任意账号下存在invited标签，均不能再次被邀请
        //因此用户的任意账号可以多次邀请不同用户，而只能被邀请一次

        if(startsWith(message,"/mykey")){
            XmlElement@ allInfo = XmlElement(readFile(m_playerInfo_FILENAME));
            if(allInfo is null){
                _log("allInfo is null, in handleMyInviteKey");
                return;
            }
            if(allInfo is null){return;}

            array<const XmlElement@> infos = allInfo.getElementsByTagName("player");
            string m_sid = g_playerInfoBuck.getSidByName(p_name);
            string m_hash = g_playerInfoBuck.getHashByName(p_name);
            int pid = g_playerInfoBuck.getPidByName(p_name);
            float xp = g_playerInfoBuck.getXpByName(p_name);
            //盗版小号
            if(m_sid == "ID0"){
                notify(m_metagame, "You are not steam User", dictionary(), "misc", pid, false, "", 1.0);
                return;
            }
            //满30级才能邀请他人
            if(xp < 251.773 ){
                notify(m_metagame, "You didnt reach the Level 30", dictionary(), "misc", pid, false, "", 1.0);
                return;
            }
            for(uint i = 0; i<infos.size(); ++i){
                string m_name = infos[i].getStringAttribute("player_name");
                if(m_name == p_name){
                    array<const XmlElement@> access_tags = infos[i].getElementsByTagName("access_tag");
                    bool isEmpty = true;
                    //检测是否已经创建过邀请码
                    for(uint j = 0; j<access_tags.size(); ++j){
                        if(access_tags[j].hasAttribute("__tag")){
                            if(access_tags[j].getStringAttribute("__tag") == "InviteKey"){
                                //检测曾经是否是被邀请者
                                if(access_tags[j].hasAttribute("invited") && !access_tags[j].hasAttribute("inviter")){
                                    isEmpty = true;
                                    break;
                                }
                                isEmpty = false;
                            }
                        }
                    }
                    //没有则创建,创建的账号不能受邀请
                    if(isEmpty){
                        //同一用户的不同账号创建的邀请码不一样，因为根据profile_hash决定邀请码
                        //因此同一用户的不同角色都可以受到邀请奖励，但是被邀请者会被注册，无法再次被邀请
                        //发放奖励时会检测发放对象的profile_hash对应角色是否在线
                        //invited这个标签是否存在来判断是否被邀请过，只会在成功被邀请时生成
                        //默认下，已经是inviter的玩家不能被invited

                        XmlElement newXml("InviteKey");
                        newXml.setStringAttribute("player_name",p_name);//会被自动删除
                        newXml.setStringAttribute("profile_hash",m_hash);
                        newXml.setIntAttribute("invite_time",0);
                        newXml.setBoolAttribute("inviter",true);
                        newXml.setBoolAttribute("invited",true);//创建的账号不能受邀请
                        array<const XmlElement@> xmls;
                        xmls.insertLast(newXml);
                        addToPlayersInfo(xmls);
                    }
                    notify(m_metagame, m_hash, dictionary(), "misc", pid, true, "InviteKey", 1.0);
                    return;
                }
            }

        }
        if(startsWith(message,"/inviter")){
            XmlElement@ allInfo = XmlElement(readFile(m_playerInfo_FILENAME));
            if(allInfo is null){
                _log("allInfo is null, in handleMyInviteKey");
                return;
            }
            if(allInfo is null){return;}
            string a = "/inviter ";
            string t_hash = message.substr(a.length());

            array<const XmlElement@> infos = allInfo.getElementsByTagName("player");
            string m_sid = g_playerInfoBuck.getSidByName(p_name);
            
            string m_hash = g_playerInfoBuck.getHashByName(p_name);
            int pid = g_playerInfoBuck.getPidByName(p_name);
            float xp = g_playerInfoBuck.getXpByName(p_name);
            //盗版小号
            if(m_sid == "ID0"){
                notify(m_metagame, "You are not steam User", dictionary(), "misc", pid, false, "", 1.0);
                return;
            }
            //大于三十级玩家不能被邀请
            if(xp >= 251.773 ){
                notify(m_metagame, "You over reach the Level 30", dictionary(), "misc", pid, false, "", 1.0);
                return;
            }
            bool invited = false;
            bool valid = false;
            string t_name;
            array<const XmlElement@> xmls;
            for(uint i = 0; i<infos.size(); ++i){
                //遍历存档
                XmlElement@ info = XmlElement(infos[i]);
                string t_profile_hash = info.getStringAttribute("profile_hash");
                string t_sid = info.getStringAttribute("sid");
                string t_player_name = info.getStringAttribute("player_name");
                bool is_online = info.getBoolAttribute("is_online");

                array<const XmlElement@> access_tags = info.getElementsByTagName("access_tag");
                //对象时否为自己已有的账号（SID相同），旗下所有号是否有被邀请记录
                if(m_sid == t_sid){
                    for(uint j = 0; j<access_tags.size(); ++j){
                        XmlElement@ access_tag = XmlElement(access_tags[j]);
                        if(access_tag.hasAttribute("__tag")){
                            if(access_tag.getStringAttribute("__tag") == "InviteKey"){
                                if(access_tag.hasAttribute("invited")){
                                    invited = access_tag.getBoolAttribute("invited");
                                    if(invited){//任意账号已经被邀请过，返回
                    notify(m_metagame, "You had been invited!", dictionary(), "misc", pid, false, "", 1.0);
                                        return;
                                    }
                                }
                            }
                        }
                    }
                }

                //对象是邀请者，且在线（profile_hash相同）
                if(t_hash == t_profile_hash){
                    if(!is_online){
                        notify(m_metagame, "Inviter is not in the same Server", dictionary(), "misc", pid, false, "", 1.0);
                        return;
                    }
                    //是否在同一个服务器内
                    // if(!g_playerInfoBuck.exists(p_name)){
                    //     notify(m_metagame, "Inviter is not in the same Server", dictionary(), "misc", pid, false, "", 1.0);
                    //     return;
                    // }
                    // 对象是否有邀请条件
                    for(uint j = 0; j<access_tags.size(); ++j){
                        XmlElement@ access_tag = XmlElement(access_tags[j]);
                        if(access_tag.hasAttribute("__tag")){
                            if(access_tag.getStringAttribute("__tag") == "InviteKey"){
                                if(access_tag.hasAttribute("inviter")){
                                    if(access_tag.getBoolAttribute("inviter") == true){
                                        // 邀请条件满足
                                        int invite_time = access_tag.getIntAttribute("invite_time");
                                        invite_time++;
                                        access_tag.setIntAttribute("invite_time",invite_time);
                                        access_tag.setStringAttribute("player_name",t_player_name);
                                        access_tag.setStringAttribute("TagName","InviteKey");
                                        // 存入邀请者玩家存档信息
                                        xmls.insertLast(access_tag);
                                        t_name = t_player_name;
                                        valid = true;
                                    }
                                }
                            }
                        }
                    }
                }
            }
            //自己所有账户没有邀请记录且密钥正确，邀请者有邀请资格
            if(valid && !invited){
                // 更新邀请者和被邀请者玩家存档
                XmlElement aa("InviteKey");
                aa.setStringAttribute("player_name",p_name);
                aa.setBoolAttribute("invited",true);
                xmls.insertLast(aa);
                addToPlayersInfo(xmls);

                handleReward(p_name,"invited_reward");
                handleReward(t_name,"inviter_reward");
                if(g_debugMode){
                    _report(m_metagame,"invite key successed reward");
                }
            }
        }
    }

    // -------------------------------------------
    protected void debug(string&in message,string&in p_name){
        if(m_metagame.getAdminManager().isAdmin(p_name)){
			if(message == "/updatePlayers"){
				updatePlayers();
			}
			if(message == "/addToPlayersInfo"){
                // XmlElement@ root = XmlElement(readXML(m_metagame,"reward_keys.xml"));
                // array<const XmlElement@> infos = root.getLowerChilds("reward_keys",0);
                const XmlElement@ allInfo = readFile("reward_keys.xml");
                array<const XmlElement@> infos = allInfo.getElementsByTagName("reward_key");
				addToPlayersInfo(infos);
			}
			if(message == "/playerin"){
                array<const XmlElement@> players = getPlayers(m_metagame);
                const XmlElement@ player = null;
                for(uint i=0;i<players.size();++i){
                    @player = players[i];
                    if(player.getStringAttribute("name") == p_name){
                        break;
                    }
                }
                if(player is null){
                    _report(m_metagame,"didnt find yourself data");
                    return;
                }
                updatePlayers(player,true);
    		}
			if(message == "/playerout"){
                array<const XmlElement@> players = getPlayers(m_metagame);
                const XmlElement@ player = null;
                for(uint i=0;i<players.size();++i){
                    @player = players[i];
                    if(player.getStringAttribute("name") == p_name){
                        break;
                    }
                }
                if(player is null){
                    _report(m_metagame,"didnt find yourself data");
                    return;
                }
                updatePlayers(player,false);
			}
		}
    }
    // -------------------------------------------
    protected void addToPlayersInfo(array<const XmlElement@> xmls){
        XmlElement@ allInfo = XmlElement(readPlayerInfo());
        if(allInfo is null){
            _log("allInfo is null, in addToPlayersInfo");
            return;
        }
        array<const XmlElement@> m_players = allInfo.getElementsByTagName("player");
        //读原玩家文件信息
        for(int i=int(m_players.size())-1;i>=0;--i){
            XmlElement m_player(m_players[i]);
            if(m_player is null){continue;}
            string player_name = m_player.getStringAttribute("player_name");
            bool isTarget = false;
            //读新传入文件信息
            XmlElement@ xml;
            for(uint k=0;k<xmls.size();++k){
                @xml = XmlElement(xmls[k]);
                if(!xml.hasAttribute("player_name")){continue;}
                string name = xml.getStringAttribute("player_name");
                xml.removeKey("player_name");
            
                //排除onRemove对象
                bool isToRemove = false;
                if(xml.hasAttribute("onRemove")){
                    isToRemove = xml.getBoolAttribute("onRemove");
                    if(isToRemove){
                        continue;
                    }
                }
                
                //名字匹配
                if(name == player_name){
                    isTarget = true;
                    //修改键值和TagName以符合规范
                    string TagName;
                    if(xml.hasAttribute("access_tag")){
                        TagName = xml.getStringAttribute("access_tag");
                        xml.removeKey("access_tag");
                    }else{
                        TagName = xml.getName();
                    }
                    xml.setStringAttribute("TagName","access_tag");
                    xml.setStringAttribute("__tag",TagName);

                    //是否有同类项，有则覆写
                    bool isExist = false;
                    array<const XmlElement@> access_tags = m_player.getElementsByTagName("access_tag");
                    m_player.removeAllChild();

                    //解决空子项问题
                    XmlElement a("access_tag");
                    a.setBoolAttribute("onRemove",true);
                    m_player.appendChild(a);

                    if(access_tags.size() != 0){
                        for(int j = 0 ; j < int(access_tags.size()) ; ++j){
                            const XmlElement@ access_tag = access_tags[j];
                            string m_TagName = access_tag.getStringAttribute("__tag");

                            //排除onRemove对象
                            if(access_tag.hasAttribute("onRemove")){
                                isToRemove = access_tag.getBoolAttribute("onRemove");
                                if(isToRemove){
                                    continue;
                                }
                            }
                            //保存或替换原对象
                            if(TagName == m_TagName){
                                m_player.appendChild(xml);
                                isExist = true;
                            }else{
                                m_player.appendChild(access_tag);
                            }
                        }
                    }
                    // 没有同类项
                    if(!isExist){
                        m_player.appendChild(xml);
                    }
                    m_player.removeChild("access_tag",0);
                }
            }
            //覆写玩家数据
            if(isTarget){
                allInfo.appendChild(m_player);
                allInfo.removeChild("player",i);
            }
        }
        writeXML(m_metagame,m_playerInfo_FILENAME,allInfo);
        if(g_debugMode){
            _report(m_metagame,"addToPlayersInfo");
        }
    }
    // -------------------------------------------
    protected void updatePlayers(const XmlElement@ newplayer = null,bool&in isOnline = true){
        array<const XmlElement@> players;
        if(newplayer is null){
            players = getPlayers(m_metagame);
        }else{
            players.insertLast(newplayer);
        }
        
        //读取存档玩家信息
        XmlElement@ allInfo = XmlElement(readPlayerInfo());
        if(allInfo is null){
            _log("allInfo is null, in updatePlayers");
            return;
        }
        //获取在线玩家信息
        for(uint i=0;i<players.size();++i){
            XmlElement@ player = XmlElement(players[i]);
            if(player is null){continue;}
            bool is_online = isOnline;
            bool is_main_account = false;
            string player_name = player.getStringAttribute("name");
            string profile_hash = player.getStringAttribute("profile_hash");
            string sid = player.getStringAttribute("sid");
            //读取存档玩家信息
            array<const XmlElement@> m_players = allInfo.getElementsByTagName("player");
            allInfo.removeAllChild();
            //解决空子项问题
            XmlElement a("player");
            a.setBoolAttribute("onRemove",true);
            allInfo.appendChild(a);

            bool isExist = false;
            for(int j = 0 ; j < int(m_players.size()) ; ++j){
                XmlElement@ m_player = XmlElement(m_players[j]);
                string m_name = m_player.getStringAttribute("player_name");
                //排除onRemove对象
                if(m_player.hasAttribute("onRemove")){
                    bool isToRemove = m_player.getBoolAttribute("onRemove");
                    if(isToRemove){
                        continue;
                    }
                }
                //玩家信息存在，则删除重写覆盖
                if(m_name == player_name){
                    is_main_account = m_player.getBoolAttribute("is_main_account");
                    
                    array<const XmlElement@> childs = m_player.getElementsByTagName("access_tag");
                    m_player.removeAllChild();
                    m_player.setBoolAttribute("is_online",is_online);
                    m_player.appendChilds(childs);
                    allInfo.appendChild(m_player);

                    isExist = true;
                }else{//其他玩家信息不修改存回去

                    allInfo.appendChild(m_player);
                }
            }
            //不存在，新建信息
            if(!isExist){
                XmlElement playerinfo("player");
                playerinfo.setBoolAttribute("is_online",is_online);
                playerinfo.setBoolAttribute("is_main_account",is_main_account);
                playerinfo.setStringAttribute("player_name",player_name);
                playerinfo.setStringAttribute("profile_hash",profile_hash);
                playerinfo.setStringAttribute("sid",sid);
                allInfo.appendChild(playerinfo);
            }
            allInfo.removeChild("player",0);
        }
        writeXML(m_metagame,m_playerInfo_FILENAME,allInfo);
        if(g_debugMode){
            _report(m_metagame,"savePlayers");
        }
    }

    protected const XmlElement@ readFile(string filename){
        const XmlElement@ root = readXML(m_metagame,filename).getFirstChild();
        if(root is null){
            _log("readFile is null,create");
            writeXML(m_metagame,filename,XmlElement(filename));
            @root = readXML(m_metagame,filename).getFirstChild();
        }
        return root;
    }
    protected const XmlElement@ readPlayerInfo(){
        const XmlElement@ root = readXML(m_metagame,m_playerInfo_FILENAME).getFirstChild();
        if(root is null){
            _log("readPlayerInfo is null,create");
            writeXML(m_metagame,m_playerInfo_FILENAME,XmlElement("players"));
            @root = readXML(m_metagame,m_playerInfo_FILENAME).getFirstChild();
        }
        return root;
    }

    protected bool handleReward(string&in p_name,string&in access_tag){
        int pid = g_playerInfoBuck.getPidByName(p_name);
        int cid = g_playerInfoBuck.getCidByPid(pid);
        int fid = g_playerInfoBuck.getFidByCid(cid);
        float xp = g_playerInfoBuck.getXpByName(p_name);

        if(access_tag == "green_hand_level_10"){//十级新手礼包
            if(xp >= 12.965){
                for(uint i=0;i<3;++i){
                    addItemInBackpack(m_metagame,cid,"carry_item","hd_bonusfactor_al_75");
                }
                GiveRP(m_metagame,cid,120000);
                dictionary a;
                a["%reward"] = "RP: 12w";
                notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
                return true;
            }else{
                notify(m_metagame, "You didnt reach the required Rank!", dictionary(), "misc", pid, false, "", 1.0);
                return false;
            }
        }
        if(access_tag == "green_hand_level_20"){//二十级新手礼包
            if(xp >= 84.248){
                for(uint i=0;i<5;++i){
                    addItemInBackpack(m_metagame,cid,"carry_item","hd_bonusfactor_al_75");
                }
                GiveRP(m_metagame,cid,240000);
                dictionary a;
                a["%reward"] = "RP: 24w";
                notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
                return true;
            }else{
                notify(m_metagame, "You didnt reach the required Rank!", dictionary(), "misc", pid, false, "", 1.0);
                return false;
            }
        }
        if(access_tag == "green_hand_level_30"){//三十级新手礼包
            
            if(xp >= 251.773){
                for(uint i=0;i<7;++i){
                    addItemInBackpack(m_metagame,cid,"carry_item","hd_bonusfactor_al_75");
                }
                GiveRP(m_metagame,cid,480000);
                dictionary a;
                a["%reward"] = "RP: 48w";
                notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
                return true;
            }else{
                notify(m_metagame, "You didnt reach the required Rank!", dictionary(), "misc", pid, false, "", 1.0);
                return false;
            }
        }
        if(access_tag == "green_hand_level_50"){//五十级礼包
            if(xp >= 1000){
                for(uint i=0;i<5;++i){
                    addItemInBackpack(m_metagame,cid,"carry_item","hd_bonusfactor_al_240");
                }
                GiveRP(m_metagame,cid,600000);
                dictionary a;
                a["%reward"] = "RP: 60w";
                notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
                return true;
            }else{
                notify(m_metagame, "You didnt reach the required Rank!", dictionary(), "misc", pid, false, "", 1.0);
                return false;
            }
        }
        if(access_tag == "tester_player"){//参与测试服的玩家
            
            for(uint i=0;i<30;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","reward_box_skin.carry_item");
            }
            for(uint i=0;i<10;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","reward_box_vehicle.carry_item");
            }
            for(uint i=0;i<3;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","reward_box_music.carry_item");
            }
            for(uint i=0;i<3;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","reward_box_weapon_1.carry_item");
            }
            for(uint i=0;i<3;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","reward_box_weapon_2.carry_item");
            }
            for(uint i=0;i<3;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","hd_bonusfactor_al_240");
            }
            for(uint i=0;i<5;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","hd_bonusfactor_al_125");
            }
            for(uint i=0;i<15;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","hd_bonusfactor_al_45");
            }
            dictionary a;
            a["%reward"] = "已送至背包";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "sponsor_mk1"){//赞助者
            for(uint i=0;i<3;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","hd_bonusfactor_al_75");
            }
            for(uint i=0;i<15;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","hd_bonusfactor_al_20");
            }
            for(uint i=0;i<10;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","reward_box_skin.carry_item");
            }

            GiveRP(m_metagame,cid,100000);
            dictionary a;
            a["%reward"] = "RP: 10w 和加成卡";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "sponsor_mk2"){//赞助者

            for(uint i=0;i<5;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","hd_bonusfactor_al_125");
            }
            for(uint i=0;i<15;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","hd_bonusfactor_al_45");
            }
            for(uint i=0;i<10;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","reward_box_skin.carry_item");
            }
            for(uint i=0;i<1;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","reward_box_weapon_1.carry_item");
            }

            GiveRP(m_metagame,cid,300000);
            dictionary a;
            a["%reward"] = "RP: 30w 和加成卡";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "sponsor_mk3"){//赞助者

            for(uint i=0;i<5;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","hd_bonusfactor_al_125");
            }
            for(uint i=0;i<15;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","hd_bonusfactor_al_45");
            }
            for(uint i=0;i<10;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","reward_box_skin.carry_item");
            }
            for(uint i=0;i<1;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","reward_box_weapon_1.carry_item");
            }

            GiveRP(m_metagame,cid,1000000);
            dictionary a;
            a["%reward"] = "RP: 100w 和加成卡";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "Gift_alpha_1"){//小礼品

            for(uint i=0;i<5;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","hd_bonusfactor_al_75");
            }
            for(uint i=0;i<1;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","reward_box_weapon_1.carry_item");
            }
            for(uint i=0;i<1;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","reward_box_weapon_2.carry_item");
            }
            for(uint i=0;i<10;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","reward_box_skin.carry_item");
            }
            for(uint i=0;i<3;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","reward_box_vehicle.carry_item");
            }

            GiveRP(m_metagame,cid,100000);
            dictionary a;
            a["%reward"] = "RP: 10w 、加成卡和战利品箱子";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "ESC"){//ESC小队成员

            for(uint i=0;i<8;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","hd_bonusfactor_al_240");
            }
            for(uint i=0;i<15;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","hd_bonusfactor_al_125");
            }
            for(uint i=0;i<20;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","hd_bonusfactor_al_75");
            }
            for(uint i=0;i<3;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","reward_box_weapon_1.carry_item");
            }
            for(uint i=0;i<15;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","reward_box_skin.carry_item");
            }
            for(uint i=0;i<15;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","reward_box_vehicle.carry_item");
            }

            GiveRP(m_metagame,cid,1000000);
            dictionary a;
            a["%reward"] = "RP: 100w 、加成卡和战利品箱子";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "inviter_reward"){//邀请者奖励
            for(uint i=0;i<1;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","hd_bonusfactor_al_240");
            }
            for(uint i=0;i<1;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","reward_box_weapon_1.carry_item");
            }
            for(uint i=0;i<10;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","reward_box_skin.carry_item");
            }

            GiveRP(m_metagame,cid,100000);
            dictionary a;
            a["%reward"] = "RP: 10w 、加成卡和战利品箱子";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "invited_reward"){//被邀请者奖励
            for(uint i=0;i<10;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","hd_bonusfactor_al_75");
            }
            for(uint i=0;i<2;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","reward_box_weapon_2.carry_item");
            }
            for(uint i=0;i<10;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","reward_box_skin.carry_item");
            }
            for(uint i=0;i<5;++i){
                addItemInBackpack(m_metagame,cid,"carry_item","reward_box_vehicle.carry_item");
            }

            GiveRP(m_metagame,cid,300000);
            dictionary a;
            a["%reward"] = "RP: 30w 、加成卡和战利品箱子";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        array<string> word = MassageBreakUp(access_tag, " ", -1);
        int ws = word.size();
        if(startsWith(access_tag,"w")){// 获取指定武器
            if (ws == 1){return false;}
			string key = word[1];
            bool isSend = false;
            if (ws == 2){
			    spawnInstanceAtbackpack(pid, key + ".weapon", "weapon");
                isSend = true;
            } else if (ws == 3){
			    spawnInstanceAtbackpack(pid, key + ".weapon", "weapon", word[2]);
                isSend = true;
            }
            if(isSend){
                dictionary a;
                a["%reward"] = key;
                notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
                 return true;
            }
        }
        if(startsWith(access_tag,"c")){// 获取指定道具
            if (ws == 1){return false;}
			string key = word[1];
            bool isSend = false;
			if (ws == 2){
			    spawnInstanceAtbackpack(pid, key, "carry_item");
                isSend = true;
			} else if (ws == 3){
			    spawnInstanceAtbackpack(pid, key, "carry_item", word[2]);
                isSend = true;
            }
            if(isSend){
                dictionary a;
                a["%reward"] = key;
                notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
                return true;
            }
        }
        if(startsWith(access_tag,"p")){// 获取指定道具
            if (ws == 1){return false;}
			string key = word[1];
            bool isSend = false;
			if (ws == 2){
			    spawnInstanceAtbackpack(pid, key + ".projectile", "projectile");
                isSend = true;
			} else if (ws == 3){
			    spawnInstanceAtbackpack(pid, key + ".projectile", "projectile", word[2]);
                isSend = true;
            }
            if(isSend){
                dictionary a;
                a["%reward"] = key;
                notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
                return true;
            }
        }
        if(startsWith(access_tag,"v")){// 获取指定载具
            if (ws == 1){return false;}
			string key = word[1];
            bool isSend = false;
			if (ws == 2){
			    spawnInstanceNearPlayer(pid, key + ".vehicle", "vehicle");
                isSend = true;
			} 
            if(isSend){
                dictionary a;
                a["%reward"] = key;
                notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
                return true;
            }
        }
        return false;
    }
    array<string> MassageBreakUp(string message, string command, int preNumber) 
    {
        string s = message.trim().substr(command.length() + preNumber + 1);
        array<string> a = s.split(" ");
        return a;
    }
    // ------------------------------------------------------
	protected void spawnInstanceAtbackpack(int senderId, string key, string type, string num = "1"){
		const XmlElement@ playerInfo = getPlayerInfo(m_metagame, senderId);
		int cid = playerInfo.getIntAttribute("character_id");
		if(type == "vehicle"){
			dictionary dict = {{"TagName", "command"},{"class", "chat"},{"text", "can't spawn vehicle"}};
			m_metagame.getComms().send(XmlElement(dict));
			return;
		}
		float number = parseFloat(num);
		for(float a = 1; a <= number ; a++){
			string command = 
				"<command class='update_inventory' character_id='" + cid + "' container_type_class='backpack'>" + 
					"<item class='" + type + "' key='" + key + "' />" +
				"</command>";
			m_metagame.getComms().send(command);	
		}
	}
    // ----------------------------------------------------
	protected void spawnInstanceNearPlayer(int senderId, string key, string type, int factionId = 0, bool skydive = false) {
		const XmlElement@ playerInfo = getPlayerInfo(m_metagame, senderId);
		if (playerInfo !is null) {
			const XmlElement@ characterInfo = getCharacterInfo(m_metagame, playerInfo.getIntAttribute("character_id"));
			if (characterInfo !is null) {
				Vector3 pos = stringToVector3(characterInfo.getStringAttribute("position"));
				pos.m_values[0] += 5.0;
				if (skydive) {
					pos.m_values[1] += 50.0;
				}
				string c = "<command class='create_instance' instance_class='" + type + "' instance_key='" + key + "' position='" + pos.toString() + "' faction_id='" + factionId + "' />";
				m_metagame.getComms().send(c);
			}
		}
	}
}