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
//子项中的"A_"用于标签排序
//基于player_name标签来实现数据融并，融并时会自动简并子项中的player_name属性
//子项的TagName将会变为主数据access_tag标签中的A_tag属性

//密钥兑换系统
int g_readCounter = 0;
const XmlElement@ readXML(const Metagame@ metagame, string filename, string location = "savegame" ){
	XmlElement@ query = XmlElement(
		makeQuery(metagame, array<dictionary> = {
			dictionary = { {"TagName", "data"}, {"class", "saved_data"}, {"filename", filename}, {"location", location} } }));
	const XmlElement@ xml = metagame.getComms().query(query);
    if(xml is null){
        _log("readXml is null,create and reRead for filename="+filename+",in location="+location);
        writeXML(metagame,filename,XmlElement(filename),location);

        g_readCounter++;
        _log("g_readCounter="+g_readCounter);
        if(g_readCounter > 3){
            g_readCounter = 0;
            return null;
        }
        @xml = readXML(metagame,filename,location);
        g_readCounter = 0;
    }
	return xml;
}

void writeXML(const Metagame@ metagame, string filename, XmlElement@ xml, string location = "savegame" ){
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
    }
    // -------------------------------------------
    void start(){
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
            if(int(infos.size()) == 0){ 
                _report(m_metagame,"密钥列表为空"); 
                writeXML(m_metagame,m_reward_keys_FILENAME,XmlElement(m_reward_keys_FILENAME));
                return;
            }
            bool isValid = false;
            string access_tag = "";
            int pid = g_playerInfoBuck.getPidByName(p_name);
            string m_sid = g_playerInfoBuck.getSidByName(p_name);   
            //遍历密钥列表
            XmlElement@ targetInfo;
            uint index;
            for(uint i=0;i<infos.size();++i){
                XmlElement@ info = XmlElement(infos[i]);
                if(info.hasAttribute("A_key")){
                    string targetKey = info.getStringAttribute("A_key");
                    string player_name = info.getStringAttribute("player_name");
                    //正确
                    if("/key " + targetKey == message){
                        notify(m_metagame, "Key Valid", dictionary(), "misc", pid, false, "", 1.0);
                        access_tag = info.getStringAttribute("access_tag");

                       
                        bool double_use = false;
                        //检测是否为重复使用
                        XmlElement checkXml("root");

                            XmlElement xml2(access_tag);
                                XmlElement xml2_1("A_key");
                                xml2_1.setStringAttribute("value",targetKey);
                            xml2.appendChild(xml2_1);

                            XmlElement xml3(access_tag);
                                XmlElement xml3_1("only_one");
                                xml3_1.setStringAttribute("value","1");
                            xml3.appendChild(xml3_1);

                        checkXml.appendChild(xml2);
                        checkXml.appendChild(xml3);

                        if(checkTagsInPlayerInfo(m_sid,checkXml)){
                            notify(m_metagame, "不能重复领取该密钥", dictionary(), "misc", pid, true, "", 1.0);
                            double_use = true;
                        }

                        // if(info.hasAttribute(m_sid)){
                        //     bool isUsed = info.getBoolAttribute(m_sid);
                        //     if(isUsed){
                        //         if(g_debugMode){
                        //             _report(m_metagame,"isUsed,my sid="+m_sid);
                        //         }
                        //         double_use = true;
                        //     }
                        // }

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
                                    //info.setBoolAttribute(m_sid,true);
                                    isValid = true;
                                }
                            }
                            //多次使用密钥,有max_use标签,记录各个使用者的sid
                            //不记录sid了，直接存入玩家存档系统，方便同步
                            if(info.hasAttribute("max_use")){
                                int times = info.getIntAttribute("max_use");
                                if(times != 0){
                                    if(g_debugMode){
                                        _report(m_metagame,"multi used key,is not been used out");
                                    }
                                    times--;
                                    info.setIntAttribute("max_use",times);
                                    //info.setBoolAttribute(m_sid,true);
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
                        // 默认情况下会被override覆盖，这个标签是为了录入时不被覆写而设置的
                        info.setStringAttribute("player_name",p_name);
                        if(!info.hasAttribute("override")){
                            info.setStringAttribute("override","0");
                        }
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

                    array<const XmlElement@> xmls;
                    xmls.insertLast(targetInfo);
                    addToPlayersInfo(xmls,m_sid);

                    notify(m_metagame, "Successful exchange", dictionary(), "misc", pid, true, "", 1.0);
                }else{
                    notify(m_metagame, "Not meet the condition", dictionary(), "misc", pid, true, "", 1.0);
                }
                
            }else{
                notify(m_metagame, "密钥不正确或已被使用完，注意大小写", dictionary(), "misc", pid, false, "", 1.0);
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
            string sid = g_playerInfoBuck.getSidByName(p_name);

            XmlElement@ allInfo = XmlElement(readPlayerInfo(sid));
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
            string m_sid = g_playerInfoBuck.getSidByName(p_name);

            XmlElement@ allInfo = XmlElement(readPlayerInfo(m_sid));
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
                                array<const XmlElement@> childs = allInfo.getLowerChilds(j);
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
                savePlayerInfo(m_metagame,m_sid,allInfo);
                notify(m_metagame, "你已成功绑定主账号", dictionary(), "misc", pid, false, "", 1.0);
            }else{
                notify(m_metagame, "绑定主账号失败", dictionary(), "misc", pid, false, "", 1.0);
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
            
            string m_sid = g_playerInfoBuck.getSidByName(p_name);
            string m_hash = g_playerInfoBuck.getHashByName(p_name);
            int pid = g_playerInfoBuck.getPidByName(p_name);
            float xp = g_playerInfoBuck.getXpByName(p_name);

            XmlElement@ allInfo = XmlElement(readPlayerInfo(m_sid));
            if(allInfo is null){
                _log("allInfo is null, in handleMyInviteKey");
                _report(m_metagame,"未读取到你自己的信息");
                return;
            }
            array<const XmlElement@> infos = allInfo.getElementsByTagName("player");

            //盗版小号
            if(m_sid == "ID0"){
                notify(m_metagame, "You are not steam User", dictionary(), "misc", pid, false, "", 1.0);
                return;
            }
            //满30级才能邀请他人
            if(xp < 251.773){
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
                        if(access_tags[j].hasAttribute("AA_tag")){
                            if(access_tags[j].getStringAttribute("AA_tag") == "InviteKey"){
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
                        addToPlayersInfo(xmls,m_sid);
                    }
                    notify(m_metagame, m_hash, dictionary(), "misc", pid, true, "InviteKey", 1.0);
                    return;
                }
            }
        }
        if(startsWith(message,"/inviter")){
            string m_sid = g_playerInfoBuck.getSidByName(p_name);

            string a = "/inviter ";
            string t_hash = message.substr(a.length());
            string tg_sid = g_playerInfoBuck.getSidByHash(t_hash);
            string m_hash = g_playerInfoBuck.getHashByName(p_name);
            int pid = g_playerInfoBuck.getPidByName(p_name);
            float xp = g_playerInfoBuck.getXpByName(p_name);

            if(tg_sid == ""){
                notify(m_metagame, "您输入的账户不存在，请重新输入。注意大小写，对方的密钥需要以ID开头", dictionary(), "misc", pid, false, "", 1.0);
                return;
            }
            if(m_sid == ""){
                notify(m_metagame, "未查询到自己账户SID", dictionary(), "misc", pid, false, "", 1.0);
                return;
            }
            XmlElement@ allInfo = XmlElement(readPlayerInfo(m_sid));
            XmlElement@ t_allInfo = XmlElement(readPlayerInfo(tg_sid));
            if(allInfo is null || t_allInfo is null ){
                _log("allInfo is null, in handleMyInviteKey");
                return;
            }
            array<const XmlElement@> infos = allInfo.getElementsByTagName("player");
            array<const XmlElement@> t_infos = t_allInfo.getElementsByTagName("player");
            for(uint b=0; b<t_infos.size(); ++b){
                infos.insertLast(t_infos[b]);
            }

            //盗版小号
            if(m_sid == "ID0"){
                notify(m_metagame, "You are not steam User", dictionary(), "misc", pid, false, "", 1.0);
                return;
            }
            //大于三十级玩家不能被邀请
            if(xp < 84.248){
                notify(m_metagame, "You didnt reach the Level 20", dictionary(), "misc", pid, false, "", 1.0);
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
                //对象是否为自己已有的账号（SID相同），旗下所有号是否有被邀请记录
                if(m_sid == t_sid){
                    XmlElement xml1("root");
                        XmlElement xml2("InviteKey");
                            XmlElement xml3("invited");
                            xml3.setStringAttribute("value","1");
                        xml2.appendChild(xml3);
                    xml1.appendChild(xml2);

                    if(checkTagsInPlayerInfo(m_sid,xml1)){//任意账号已经被邀请过，返回
                        notify(m_metagame, "You had been invited!", dictionary(), "misc", pid, false, "", 1.0);
                        return;
                    }
                }
                //对象是邀请者，且在线（profile_hash相同）
                if(t_hash == t_profile_hash){
                    if(!is_online){
                        notify(m_metagame, "Inviter is not in the same Server", dictionary(), "misc", pid, false, "", 1.0);
                        return;
                    }

                    for(uint j = 0; j<access_tags.size(); ++j){
                        XmlElement@ access_tag = XmlElement(access_tags[j]);
                        if(access_tag.hasAttribute("AA_tag")){
                            if(access_tag.getStringAttribute("AA_tag") == "InviteKey"){
                                if(access_tag.hasAttribute("inviter")){
                                    if(access_tag.getBoolAttribute("inviter") == true){
                                        if(g_debugMode) _report(m_metagame,"邀请条件满足");
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
                if(g_debugMode) _report(m_metagame,"通过，更新玩家存档");
                // 更新邀请者和被邀请者玩家存档
                XmlElement aa("InviteKey");
                aa.setStringAttribute("player_name",p_name);
                aa.setBoolAttribute("invited",true);
                xmls.insertLast(aa);
                addToPlayersInfo(xmls,m_sid);
                addToPlayersInfo(xmls,tg_sid);

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
			if(message == "/readfile"){
                string sid = g_playerInfoBuck.getSidByName(p_name);
				const XmlElement@ root = readPlayerInfo(sid);
                if(root is null) _report(m_metagame,"player sid="+sid+"is null");
                _report(m_metagame,"成功读取："+sid);
			}
			if(startsWith(message,"/read")){
                string key = "/read ";
                string sid = message.substr(key.length());
				const XmlElement@ root = readPlayerInfo(sid);
                if(root is null) _report(m_metagame,"player sid="+sid+"is null");
                 _report(m_metagame,"成功读取："+sid);
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
            if(startsWith(message,"/checkmyinfo")){
                string m_sid = g_playerInfoBuck.getSidByName(p_name);
                XmlElement root("base");
                    XmlElement main("InviteKey");
                        XmlElement sub("invite_time");
                            sub.setStringAttribute("value","1");
                        XmlElement sub2("inviter");
                    main.appendChild(sub);
                    main.appendChild(sub2);
                root.appendChild(main);
                if(checkTagsInPlayerInfo(m_sid,root)){
                    _report(m_metagame,"最终：查到玩家信息匹配");
                }
            }
            if(startsWith(message,"/checkmyinfo2")){
                string m_sid = g_playerInfoBuck.getSidByName(p_name);
                XmlElement root("base");
                    XmlElement main("InviteKey");
                    main.setStringAttribute("player_name",p_name);
                        XmlElement sub("invite_time");
                            sub.setStringAttribute("value","1");
                        XmlElement sub2("inviter");
                    main.appendChild(sub);
                    main.appendChild(sub2);
                root.appendChild(main);
                if(checkTagsInPlayerInfo(m_sid,root)){
                    _report(m_metagame,"最终：查到玩家信息匹配");
                }
            }
            if(startsWith(message,"/reward")){
                string key = "/reward ";
                string access_tag = message.substr(key.length());
                handleReward(p_name,access_tag);
            }
		}
    }
    // -------------------------------------------
    // target_tags 传入格式如下：
    // <root>
    //     <target_tag (可选)player_name="">
    //         <access_tag  value="1"/>
    //         <access_tag2 />
    //     </target_tag>
    // </root>
    protected bool checkTagsInPlayerInfo(string sid, const XmlElement@ root_target_tags){
        XmlElement@ allInfo = XmlElement(readPlayerInfo(sid));
        if(allInfo is null){
            _log("allInfo is null, in addToPlayersInfo");
            return false;
        }
        array<const XmlElement@> target_tags = root_target_tags.getChilds();
        if(g_debugMode) _report(m_metagame,"要查询的对象的数组大小为="+target_tags.size());
        array<const XmlElement@> m_players = allInfo.getElementsByTagName("player");
        
        bool isAllPlayerValid = true;
        dictionary pass_list;
        for(uint n = 0; n < target_tags.size(); ++n){
            const XmlElement@ target_tag = target_tags[n];
            string target_TagName = target_tag.getName();
            pass_list.set(target_TagName,false);
            if(g_debugMode) _report(m_metagame,"正在检查目标标签:"+target_TagName);

            string target_player_name = "";
            string target_sid = "";
            if(target_tag.hasAttribute("player_name")){
                target_player_name = target_tag.getStringAttribute("player_name");
            }
            if(target_tag.hasAttribute("sid")){
                target_sid = target_tag.getStringAttribute("sid");
            }

            if(g_debugMode) _report(m_metagame,"比对对象的字典输出："+target_tag.toString());

            for(uint i=0; i<m_players.size(); ++i){
                const XmlElement@ m_player = m_players[i];
                string m_player_name = m_player.getStringAttribute("player_name");
                string m_sid = m_player.getStringAttribute("sid");
                if(g_debugMode) _report(m_metagame,"正在检查玩家:"+m_player_name);

                if(target_player_name != "" && target_player_name != m_player_name){ 
                    if(g_debugMode) _report(m_metagame,"目标玩家名:"+target_player_name+"实际玩家名"+m_player_name+"。跳过");
                    continue;
                }
                if(target_sid != "" && target_sid != m_sid) continue;

                bool isThisPlayerFind = false;
                array<const XmlElement@> m_access_tags = m_player.getChilds();
                for(uint j=0; j<m_access_tags.size(); ++j){
                    const XmlElement@ m_access_tag = m_access_tags[j];
                    string m_TagName = m_access_tag.getStringAttribute("AA_tag");
                    if(g_debugMode) _report(m_metagame,"正在比对标签:"+m_TagName);

                    if(g_debugMode) _report(m_metagame,"玩家存档的字典输出："+m_access_tag.toString());

                    // 与玩家列表的access_tag字典进行匹配，若get不到或value错误，则跳出。否则全部通过
                    bool isFindTargetAccessTags = true;
                    if(m_TagName == target_TagName){
                        array<const XmlElement@> sub_tags = target_tag.getChilds();
                        for(uint k=0;k<sub_tags.size();++k){
                            const XmlElement@ sub_tag = sub_tags[k];
                            string sub_TagName = sub_tag.getName();
                            string sub_value = "";
                            if(sub_tag.hasAttribute("value")){
                                sub_value = sub_tag.getStringAttribute("value");
                            }
                            if(g_debugMode) _report(m_metagame,"检查的子标签"+sub_TagName+"值:"+sub_value);
                            if(m_access_tag.hasAttribute(sub_TagName)){
                                string m_access_value = m_access_tag.getStringAttribute(sub_TagName);
                                if(sub_value == "" || sub_value == m_access_value){
                                    isFindTargetAccessTags = true;
                                    if(g_debugMode) _report(m_metagame,"找到匹配的标签"+sub_TagName+"值:"+sub_value);
                                    continue;
                                }else{
                                    // 有任意一次匹配不上，则退出
                                    if(g_debugMode) _report(m_metagame,"未找到匹配的标签"+sub_TagName+"值:"+sub_value);
                                    isFindTargetAccessTags = false;
                                    continue;
                                }
                            }else{
                                if(g_debugMode) _report(m_metagame,"该标签不存在"+sub_TagName+"值:"+sub_value);
                                isFindTargetAccessTags = false;
                                continue;
                            }
                        }
                        //全部通过
                        if(isFindTargetAccessTags){
                            isThisPlayerFind = true;
                            if(g_debugMode) _report(m_metagame,"找到匹配的标签:"+m_TagName);
                            break;
                        }
                    }
                }
                if(isThisPlayerFind){
                    pass_list.set(target_TagName,true);
                    break;
                }
            }
            bool isValid;
            if(pass_list.get(target_TagName,isValid)){
                if(!isValid){
                    isAllPlayerValid = false;
                    if(g_debugMode) _report(m_metagame,"检查 "+target_TagName+" 失败，将isAllPlayerValid设置为false");
                    continue;
                }else{
                    isAllPlayerValid = true;
                    break;
                }

            }
        }

        if(g_debugMode && !isAllPlayerValid) _report(m_metagame,"比对不通过，目标玩家存档未能找到对应键值");
        if(g_debugMode && isAllPlayerValid) _report(m_metagame,"比对通过，目标玩家存档能找到对应键值");
        return isAllPlayerValid;
    }
    // -------------------------------------------
    protected void addToPlayersInfo(array<const XmlElement@> xmls, string sid){
        XmlElement@ allInfo = XmlElement(readPlayerInfo(sid));
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
                    xml.setStringAttribute("AA_tag",TagName);

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
                            string m_TagName = access_tag.getStringAttribute("AA_tag");

                            //排除onRemove对象
                            if(access_tag.hasAttribute("onRemove")){
                                isToRemove = access_tag.getBoolAttribute("onRemove");
                                if(isToRemove){
                                    continue;
                                }
                            }
                            
                            if(TagName == m_TagName){//覆写原对象
                                if(xml.hasAttribute("override")){
                                    string isoverride = xml.getStringAttribute("override");
                                    if(isoverride == "0"){
                                        m_player.appendChild(access_tag);
                                        continue;
                                    }
                                }
                                m_player.appendChild(xml);
                                isExist = true;
                            }else{//保留原对象
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
        savePlayerInfo(m_metagame,sid,allInfo);
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
        
        // 读取存档玩家信息
        // XmlElement@ allInfo = XmlElement(readPlayerInfo());
        // if(allInfo is null){
        //     _log("allInfo is null, in updatePlayers");
        //     return;
        // }
        //获取在线玩家信息
        for(uint i=0;i<players.size();++i){
            XmlElement@ player = XmlElement(players[i]);
            if(player is null){continue;}
            bool is_online = isOnline;
            bool is_main_account = false;
            string player_name = player.getStringAttribute("name");
            string profile_hash = player.getStringAttribute("profile_hash");
            string sid = player.getStringAttribute("sid");
            string ip = "0.0.0.0";
            if(player.hasAttribute("ip")){
                ip = player.getStringAttribute("ip");
            }
            
            // 读取存档玩家信息
            XmlElement@ allInfo = XmlElement(readPlayerInfo(sid));
            if(allInfo is null){
                _log("allInfo is null, in updatePlayers");
                return;
            }
            // 读取存档玩家账号信息
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
                    m_player.setStringAttribute("ip",ip);
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
                playerinfo.setStringAttribute("ip",ip);
                allInfo.appendChild(playerinfo);
            }
            allInfo.removeChild("player",0);
            savePlayerInfo(m_metagame,sid,allInfo);
        }
        // writeXML(m_metagame,m_playerInfo_FILENAME,allInfo);
        if(g_debugMode){
            _report(m_metagame,"savePlayers");
        }
    }

    protected const XmlElement@ readFile(string filename){
        const XmlElement@ root_base = readXML(m_metagame,filename);
        if(root_base is null){
            _log("readFile is null,create"+filename+"是NULL，重新创建");
            _report(m_metagame,"文件名="+filename);
            writeXML(m_metagame,filename,XmlElement(filename));
            @root_base = readXML(m_metagame,filename);
        }
        const XmlElement@ root = root_base.getFirstChild();
        return root;
    }
    protected const XmlElement@ readPlayerInfo(string sid){
        sid = sid+".xml";
        const XmlElement@ root = readXML(m_metagame,sid).getFirstChild();
        if(root is null){
            _log("readPlayerInfo for sid="+sid+" is null,create");
            writeXML(m_metagame,sid,XmlElement("players"));
            @root = readXML(m_metagame,sid).getFirstChild();
        }
        return root;
    }
    protected void savePlayerInfo(Metagame@ m_metagame, string sid, XmlElement@ allInfo){
        sid = sid+".xml";
        writeXML(m_metagame,sid,allInfo);
    }

    protected bool handleReward(string&in p_name,string&in access_tag){
        int pid = g_playerInfoBuck.getPidByName(p_name);
        const XmlElement@ player = getPlayerInfo(m_metagame,pid);
        if(player is null){
            _log("handleReward player is null");
            return false;
        }
        int cid = player.getIntAttribute("character_id");
        //int cid = g_playerInfoBuck.getCidByPid(pid);
        int fid = g_playerInfoBuck.getCidByName(p_name);
        float xp = g_playerInfoBuck.getXpByName(p_name);
        // todo：检测id是否有效

        // 权限兑换
        if(access_tag == "DanceKey_v1"){
            upgrade@ tempTack = upgrade(m_metagame);
            XmlElement newXml("priority");
                newXml.setStringAttribute("key","DanceKey_v1");
                newXml.setStringAttribute("type","Dance");
            tempTack.writeUpgradeFile(p_name,"prioritys",newXml);
            _notify(m_metagame,pid,"You get Dance priority level-1");
            return true;
        }

        // 常规兑换
        array<Resource@> resources = array<Resource@>();
        Resource@ res;
        if(access_tag == "HappyNewYear"){//新年奖励
            if(xp >= 251.773){
                @res = Resource("reward_box_collection.carry_item","carry_item");
                res.addToResources(resources,1);
                @res = Resource("reward_box_weapon_delta.carry_item","carry_item");//MK4
                res.addToResources(resources,3);
                @res = Resource("ex_firework.weapon","weapon");//窜天猴
                res.addToResources(resources,1);
                addListItemInBackpack(m_metagame,cid,resources);

                GiveRP(m_metagame,cid,880000);
                dictionary a;
                a["%reward"] = "RP: 88w";
                notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
                return true;
            }else{
                notify(m_metagame, "You didnt reach the required Rank!", dictionary(), "misc", pid, false, "", 1.0);
                return false;
            }
        }
        if(access_tag == "ImAgreeWithPropose"){//和谐游戏倡议
            if(xp >= 251.773){
                @res = Resource("reward_box_collection.carry_item","carry_item");
                res.addToResources(resources,1);
                addListItemInBackpack(m_metagame,cid,resources);

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
        if(access_tag == "green_hand_level_10"){//十级新手礼包
            if(xp >= 12.965){
                @res = Resource("hd_bonusfactor_al_75","carry_item");
                res.addToResources(resources,3);
                addListItemInBackpack(m_metagame,cid,resources);

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
                @res = Resource("hd_bonusfactor_al_75","carry_item");
                res.addToResources(resources,5);
                addListItemInBackpack(m_metagame,cid,resources);

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
                @res = Resource("hd_bonusfactor_al_75","carry_item");
                res.addToResources(resources,7);
                addListItemInBackpack(m_metagame,cid,resources);

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
                @res = Resource("hd_bonusfactor_al_240","carry_item");
                res.addToResources(resources,5);
                addListItemInBackpack(m_metagame,cid,resources);

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
        if(access_tag == "green_hand_level_60"){//60级礼包
            if(xp >= 2000){
                @res = Resource("hd_bonusfactor_al_240","carry_item");
                res.addToResources(resources,1);
                @res = Resource("samples_acg.carry_item","carry_item");
                res.addToResources(resources,1);
                addListItemInBackpack(m_metagame,cid,resources);

                GiveRP(m_metagame,cid,1000000);
                dictionary a;
                a["%reward"] = "RP: 100w";
                notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
                return true;
            }else{
                notify(m_metagame, "You didnt reach the required Rank!", dictionary(), "misc", pid, false, "", 1.0);
                return false;
            }
        }
        if(access_tag == "green_hand_level_75"){//75级礼包
            if(xp >= 3000){
                @res = Resource("hd_bonusfactor_al_240","carry_item");
                res.addToResources(resources,1);
                @res = Resource("samples_acg.carry_item","carry_item");
                res.addToResources(resources,1);
                addListItemInBackpack(m_metagame,cid,resources);

                GiveRP(m_metagame,cid,1000000);
                dictionary a;
                a["%reward"] = "RP: 100w";
                notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
                return true;
            }else{
                notify(m_metagame, "You didnt reach the required Rank!", dictionary(), "misc", pid, false, "", 1.0);
                return false;
            }
        }
        if(access_tag == "green_hand_level_90"){//90级礼包
            if(xp >= 4500){
                @res = Resource("hd_bonusfactor_al_240","carry_item");
                res.addToResources(resources,1);
                @res = Resource("samples_acg.carry_item","carry_item");
                res.addToResources(resources,1);
                addListItemInBackpack(m_metagame,cid,resources);

                GiveRP(m_metagame,cid,1000000);
                dictionary a;
                a["%reward"] = "RP: 100w";
                notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
                return true;
            }else{
                notify(m_metagame, "You didnt reach the required Rank!", dictionary(), "misc", pid, false, "", 1.0);
                return false;
            }
        }
        if(access_tag == "green_hand_level_100"){//100级礼包
            if(xp >= 5500){
                @res = Resource("hd_bonusfactor_al_240","carry_item");
                res.addToResources(resources,1);
                @res = Resource("samples_acg.carry_item","carry_item");
                res.addToResources(resources,1);
                addListItemInBackpack(m_metagame,cid,resources);

                GiveRP(m_metagame,cid,1000000);
                dictionary a;
                a["%reward"] = "RP: 100w";
                notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
                return true;
            }else{
                notify(m_metagame, "You didnt reach the required Rank!", dictionary(), "misc", pid, false, "", 1.0);
                return false;
            }
        }
        if(access_tag == "green_hand_level_110"){//110级礼包
            if(xp >= 6500){
                @res = Resource("hd_bonusfactor_al_240","carry_item");
                res.addToResources(resources,1);
                @res = Resource("samples_acg.carry_item","carry_item");
                res.addToResources(resources,1);
                addListItemInBackpack(m_metagame,cid,resources);

                GiveRP(m_metagame,cid,1000000);
                dictionary a;
                a["%reward"] = "RP: 100w";
                notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
                return true;
            }else{
                notify(m_metagame, "You didnt reach the required Rank!", dictionary(), "misc", pid, false, "", 1.0);
                return false;
            }
        }
        if(access_tag == "green_hand_level_120"){//120级礼包
            if(xp >= 7500){
                @res = Resource("hd_bonusfactor_al_240","carry_item");
                res.addToResources(resources,1);
                @res = Resource("samples_acg.carry_item","carry_item");
                res.addToResources(resources,1);
                addListItemInBackpack(m_metagame,cid,resources);

                GiveRP(m_metagame,cid,1000000);
                dictionary a;
                a["%reward"] = "RP: 100w";
                notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
                return true;
            }else{
                notify(m_metagame, "You didnt reach the required Rank!", dictionary(), "misc", pid, false, "", 1.0);
                return false;
            }
        }
        if(access_tag == "green_hand_level_130"){//130级礼包
            if(xp >= 8500){
                @res = Resource("hd_bonusfactor_al_240","carry_item");
                res.addToResources(resources,1);
                @res = Resource("samples_acg.carry_item","carry_item");
                res.addToResources(resources,1);
                addListItemInBackpack(m_metagame,cid,resources);

                GiveRP(m_metagame,cid,1000000);
                dictionary a;
                a["%reward"] = "RP: 100w";
                notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
                return true;
            }else{
                notify(m_metagame, "You didnt reach the required Rank!", dictionary(), "misc", pid, false, "", 1.0);
                return false;
            }
        }
        if(access_tag == "green_hand_level_140"){//140级礼包
            if(xp >= 9500){
                @res = Resource("hd_bonusfactor_al_240","carry_item");
                res.addToResources(resources,1);
                @res = Resource("samples_acg.carry_item","carry_item");
                res.addToResources(resources,1);
                addListItemInBackpack(m_metagame,cid,resources);

                GiveRP(m_metagame,cid,1000000);
                dictionary a;
                a["%reward"] = "RP: 100w";
                notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
                return true;
            }else{
                notify(m_metagame, "You didnt reach the required Rank!", dictionary(), "misc", pid, false, "", 1.0);
                return false;
            }
        }
        if(access_tag == "green_hand_level_145"){//145级礼包
            if(xp >= 10000){
                @res = Resource("hd_bonusfactor_al_240","carry_item");
                res.addToResources(resources,1);
                @res = Resource("samples_acg.carry_item","carry_item");
                res.addToResources(resources,1);
                addListItemInBackpack(m_metagame,cid,resources);

                GiveRP(m_metagame,cid,1000000);
                dictionary a;
                a["%reward"] = "RP: 100w";
                notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
                return true;
            }else{
                notify(m_metagame, "You didnt reach the required Rank!", dictionary(), "misc", pid, false, "", 1.0);
                return false;
            }
        }
        if(access_tag == "green_hand_level_150"){//150级礼包
            if(xp >= 20000){
                @res = Resource("hd_bonusfactor_al_240","carry_item");
                res.addToResources(resources,1);
                @res = Resource("samples_acg.carry_item","carry_item");
                res.addToResources(resources,1);
                addListItemInBackpack(m_metagame,cid,resources);

                GiveRP(m_metagame,cid,1000000);
                dictionary a;
                a["%reward"] = "RP: 100w";
                notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
                return true;
            }else{
                notify(m_metagame, "You didnt reach the required Rank!", dictionary(), "misc", pid, false, "", 1.0);
                return false;
            }
        }
        if(access_tag == "green_hand_level_spa"){//SPA级礼包
            if(xp >= 30000){
                @res = Resource("hd_bonusfactor_al_240","carry_item");
                res.addToResources(resources,1);
                @res = Resource("samples_acg.carry_item","carry_item");
                res.addToResources(resources,1);
                @res = Resource("reward_box_collection.carry_item","carry_item");
                res.addToResources(resources,1);
                addListItemInBackpack(m_metagame,cid,resources);

                GiveRP(m_metagame,cid,1000000);
                dictionary a;
                a["%reward"] = "RP: 100w";
                notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
                return true;
            }else{
                notify(m_metagame, "You didnt reach the required Rank!", dictionary(), "misc", pid, false, "", 1.0);
                return false;
            }
        }
        if(access_tag == "green_hand_level_sps"){//SPS级礼包
            if(xp >= 50000){
                @res = Resource("hd_bonusfactor_al_240","carry_item");
                res.addToResources(resources,1);
                @res = Resource("samples_acg.carry_item","carry_item");
                res.addToResources(resources,1);
                @res = Resource("reward_box_collection.carry_item","carry_item");
                res.addToResources(resources,3);
                addListItemInBackpack(m_metagame,cid,resources);

                GiveRP(m_metagame,cid,1000000);
                dictionary a;
                a["%reward"] = "RP: 100w";
                notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
                return true;
            }else{
                notify(m_metagame, "You didnt reach the required Rank!", dictionary(), "misc", pid, false, "", 1.0);
                return false;
            }
        }
        if(access_tag == "Tester"){//测试人员奖励
            @res = Resource("reward_box_weapon_delta.carry_item","carry_item");//MK4
            res.addToResources(resources,1);
            @res = Resource("hd_vote_ticket","carry_item");//民本选票
            res.addToResources(resources,10);
            @res = Resource("kirov_call.projectile","projectile");//基洛夫空艇
            res.addToResources(resources,5);
            @res = Resource("deploy_hd_demolition_truck.weapon","weapon");//自爆卡车
            res.addToResources(resources,8);
            GiveRP(m_metagame,cid,800000);

            addListItemInBackpack(m_metagame,cid,resources);
            dictionary a;
            a["%reward"] = "已送至背包";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "sponsor_mk1"){//赞助者 6
            @res = Resource("hd_bonusfactor_rp_240","carry_item");
            res.addToResources(resources,1);
            @res = Resource("hd_bonusfactor_al_20","carry_item");
            res.addToResources(resources,10);
            @res = Resource("reward_box_skin.carry_item","carry_item");
            res.addToResources(resources,10);

            addListItemInBackpack(m_metagame,cid,resources);
            GiveRP(m_metagame,cid,180000);
            dictionary a;
            a["%reward"] = "RP: 18w 和加成卡";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "sponsor_mk2"){//赞助者 30
            @res = Resource("hd_bonusfactor_al_240","carry_item");
            res.addToResources(resources,2);
            @res = Resource("hd_bonusfactor_al_75","carry_item");
            res.addToResources(resources,5);
            @res = Resource("hd_bonusfactor_al_20","carry_item");
            res.addToResources(resources,5);
            @res = Resource("reward_box_skin.carry_item","carry_item");
            res.addToResources(resources,10);
            @res = Resource("reward_box_weapon_delta.carry_item","carry_item");//MK4
            res.addToResources(resources,1);

            addListItemInBackpack(m_metagame,cid,resources);

            GiveRP(m_metagame,cid,600000);
            dictionary a;
            a["%reward"] = "RP: 60w 和加成卡";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "sponsor_mk3"){//赞助者 68
            @res = Resource("hd_bonusfactor_al_240","carry_item");
            res.addToResources(resources,3);
            @res = Resource("hd_bonusfactor_al_45","carry_item");
            res.addToResources(resources,10);
            @res = Resource("reward_box_skin.carry_item","carry_item");
            res.addToResources(resources,10);
            @res = Resource("reward_box_weapon_v.carry_item","carry_item");//MK5
            res.addToResources(resources,1);

            addListItemInBackpack(m_metagame,cid,resources);

            GiveRP(m_metagame,cid,1200000);
            dictionary a;
            a["%reward"] = "RP: 120w 、加成卡和战利品箱子";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "sponsor_mk4"){//赞助者 200
            @res = Resource("hd_bonusfactor_al_240","carry_item");
            res.addToResources(resources,4);
            @res = Resource("hd_bonusfactor_al_125","carry_item");
            res.addToResources(resources,5);
            @res = Resource("reward_box_skin.carry_item","carry_item");
            res.addToResources(resources,10);
            @res = Resource("reward_box_weapon_v.carry_item","carry_item");//MK5
            res.addToResources(resources,1);
            @res = Resource("reward_box_weapon_delta.carry_item","carry_item");//MK4
            res.addToResources(resources,2);

            addListItemInBackpack(m_metagame,cid,resources);
            GiveRP(m_metagame,cid,2000000);
            dictionary a;
            a["%reward"] = "RP: 200w 、加成卡和战利品箱子";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "sponsor_mk5"){//赞助者 328
            @res = Resource("hd_bonusfactor_al_240","carry_item");
            res.addToResources(resources,10);
            @res = Resource("reward_box_skin.carry_item","carry_item");
            res.addToResources(resources,10);
            @res = Resource("reward_box_vehicle.carry_item","carry_item");
            res.addToResources(resources,10);
            @res = Resource("reward_box_music.carry_item","carry_item");
            res.addToResources(resources,3);
            @res = Resource("reward_box_weapon_v.carry_item","carry_item");//MK5
            res.addToResources(resources,3);
            @res = Resource("reward_box_weapon_delta.carry_item","carry_item");//MK4
            res.addToResources(resources,5);
            @res = Resource("reward_box_weapon_lamda.carry_item","carry_item");//MK3
            res.addToResources(resources,5);
            @res = Resource("reward_box_collection.carry_item","carry_item");//fumo
            res.addToResources(resources,2);

            upgrade@ tempTack = upgrade(m_metagame);
            if(!tempTack.checkAccess(p_name,"prioritys","DanceKey_v1")){
                XmlElement newXml("priority");
                    newXml.setStringAttribute("key","DanceKey_v1");
                    newXml.setStringAttribute("type","Dance");
                tempTack.writeUpgradeFile(p_name,"prioritys",newXml);
                _notify(m_metagame,pid,"You get Dance priority level-1");
            }
            string sid = g_playerInfoBuck.getSidByName(p_name);
            playerStashInfo@ m_playerStashInfo = playerStashInfo(m_metagame,sid,p_name);
            if(!m_playerStashInfo.isOpen(false)){
                m_playerStashInfo.openStash(false);
            }
            m_playerStashInfo.upgradeStash(20,true);
            m_playerStashInfo.openStash(false);

            addListItemInBackpack(m_metagame,cid,resources);
            GiveRP(m_metagame,cid,6480000);
            dictionary a;
            a["%reward"] = "RP: 648w、加成卡和战利品箱子";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "upgradeStash"){//脚本仓库升级
            string sid = g_playerInfoBuck.getSidByName(p_name);
            playerStashInfo@ m_playerStashInfo = playerStashInfo(m_metagame,sid,p_name);
            if(!m_playerStashInfo.isOpen(false)){
                m_playerStashInfo.openStash(false);
            }
            m_playerStashInfo.upgradeStash(10,true);
            m_playerStashInfo.openStash(false);

            dictionary a;
            a["%reward"] = "10格脚本仓库容量";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "Gift_alpha_1"){//小礼品 alpha 系列 钱和加成卡
            @res = Resource("hd_bonusfactor_al_75","carry_item");
            res.addToResources(resources,1);

            addListItemInBackpack(m_metagame,cid,resources);

            GiveRP(m_metagame,cid,10000);
            dictionary a;
            a["%reward"] = "RP: 1w 、加成卡";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "Gift_alpha_2"){//小礼品 alpha 系列 钱和加成卡

            @res = Resource("hd_bonusfactor_al_20","carry_item");
            res.addToResources(resources,3);
            @res = Resource("hd_bonusfactor_xp_45","carry_item");
            res.addToResources(resources,1);
            @res = Resource("hd_bonusfactor_rp_45","carry_item");
            res.addToResources(resources,1);

            addListItemInBackpack(m_metagame,cid,resources);

            GiveRP(m_metagame,cid,10000);
            dictionary a;
            a["%reward"] = "RP: 1w 、加成卡";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "Gift_alpha_3"){//小礼品 alpha 系列 钱和加成卡
            @res = Resource("hd_bonusfactor_al_125","carry_item");
            res.addToResources(resources,2);
            @res = Resource("hd_bonusfactor_xp_45","carry_item");
            res.addToResources(resources,1);
            @res = Resource("hd_bonusfactor_rp_45","carry_item");
            res.addToResources(resources,1);

            addListItemInBackpack(m_metagame,cid,resources);

            GiveRP(m_metagame,cid,10000);
            dictionary a;
            a["%reward"] = "RP: 1w 、加成卡";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "Gift_alpha_4"){//小礼品 alpha 系列 钱和加成卡
            @res = Resource("hd_bonusfactor_xp_240","carry_item");
            res.addToResources(resources,1);
            @res = Resource("hd_bonusfactor_xp_45","carry_item");
            res.addToResources(resources,1);
            @res = Resource("hd_bonusfactor_rp_45","carry_item");
            res.addToResources(resources,1);
            addListItemInBackpack(m_metagame,cid,resources);

            GiveRP(m_metagame,cid,10000);
            dictionary a;
            a["%reward"] = "RP: 1w 、加成卡";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "Gift_alpha_5"){//小礼品 alpha 系列 钱和加成卡
            @res = Resource("hd_bonusfactor_rp_240","carry_item");
            res.addToResources(resources,1);
            @res = Resource("hd_bonusfactor_xp_45","carry_item");
            res.addToResources(resources,1);
            @res = Resource("hd_bonusfactor_rp_45","carry_item");
            res.addToResources(resources,1);
            addListItemInBackpack(m_metagame,cid,resources);

            GiveRP(m_metagame,cid,10000);
            dictionary a;
            a["%reward"] = "RP: 1w 、加成卡";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "Gift_beta_1"){//小礼品 beta 系列 非武器类箱子
            @res = Resource("reward_box_skin.carry_item","carry_item");
            res.addToResources(resources,5);
            addListItemInBackpack(m_metagame,cid,resources);

            GiveRP(m_metagame,cid,10000);
            dictionary a;
            a["%reward"] = "RP: 1w 和战利品箱子";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "Gift_beta_2"){//小礼品 beta 系列 非武器类箱子
            @res = Resource("reward_box_vehicle.carry_item","carry_item");
            res.addToResources(resources,5);
            addListItemInBackpack(m_metagame,cid,resources);

            GiveRP(m_metagame,cid,10000);
            dictionary a;
            a["%reward"] = "RP: 1w 和战利品箱子";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "Gift_beta_3"){//小礼品 beta 系列 非武器类箱子
            @res = Resource("reward_box_music.carry_item","carry_item");
            res.addToResources(resources,5);
            addListItemInBackpack(m_metagame,cid,resources);

            GiveRP(m_metagame,cid,10000);
            dictionary a;
            a["%reward"] = "RP: 1w 和战利品箱子";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "Gift_beta_4"){//小礼品 beta 系列 非武器类箱子
            @res = Resource("reward_box_collection.carry_item","carry_item");
            res.addToResources(resources,1);
            addListItemInBackpack(m_metagame,cid,resources);

            GiveRP(m_metagame,cid,10000);
            dictionary a;
            a["%reward"] = "RP: 1w 和战利品箱子";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "Gift_beta_5"){//小礼品 beta 系列 非武器类箱子
            @res = Resource("reward_box_collection.carry_item","carry_item");
            res.addToResources(resources,1);
            @res = Resource("reward_box_skin.carry_item","carry_item");
            res.addToResources(resources,5);
            @res = Resource("reward_box_music.carry_item","carry_item");
            res.addToResources(resources,3);
            @res = Resource("reward_box_vehicle.carry_item","carry_item");
            res.addToResources(resources,5);
            addListItemInBackpack(m_metagame,cid,resources);

            GiveRP(m_metagame,cid,10000);
            dictionary a;
            a["%reward"] = "RP: 1w 和战利品箱子";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "Gift_gama_1"){//小礼品 gama 系列 武器类箱子
            @res = Resource("reward_box_weapon_1.carry_item","carry_item");
            res.addToResources(resources,1);
            addListItemInBackpack(m_metagame,cid,resources);

            GiveRP(m_metagame,cid,10000);
            dictionary a;
            a["%reward"] = "RP: 1w 和战利品箱子";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "Gift_gama_2"){//小礼品 gama 系列 武器类箱子
            @res = Resource("reward_box_weapon_2.carry_item","carry_item");
            res.addToResources(resources,1);
            addListItemInBackpack(m_metagame,cid,resources);

            GiveRP(m_metagame,cid,10000);
            dictionary a;
            a["%reward"] = "RP: 1w 和战利品箱子";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "Gift_gama_3"){//小礼品 gama 系列 武器类箱子
            @res = Resource("reward_box_weapon_lamda.carry_item","carry_item");
            res.addToResources(resources,1);
            addListItemInBackpack(m_metagame,cid,resources);
            GiveRP(m_metagame,cid,10000);
            dictionary a;
            a["%reward"] = "RP: 1w 和战利品箱子";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "Gift_gama_4"){//小礼品 gama 系列 武器类箱子
            @res = Resource("reward_box_weapon_delta.carry_item","carry_item");
            res.addToResources(resources,1);
            addListItemInBackpack(m_metagame,cid,resources);
            GiveRP(m_metagame,cid,10000);
            dictionary a;
            a["%reward"] = "RP: 1w 和战利品箱子";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "Gift_gama_5"){//小礼品 gama 系列 武器类箱子
            @res = Resource("reward_box_weapon_v.carry_item","carry_item");
            res.addToResources(resources,1);
            addListItemInBackpack(m_metagame,cid,resources);
            GiveRP(m_metagame,cid,10000);
            dictionary a;
            a["%reward"] = "RP: 1w 和战利品箱子";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "ESC"){//ESC小队成员
            @res = Resource("hd_bonusfactor_al_240","carry_item");
            res.addToResources(resources,5);
            @res = Resource("hd_bonusfactor_al_125","carry_item");
            res.addToResources(resources,5);
            @res = Resource("hd_bonusfactor_al_75","carry_item");
            res.addToResources(resources,5);
            @res = Resource("reward_box_weapon_delta.carry_item","carry_item");
            res.addToResources(resources,1);
            @res = Resource("reward_box_weapon_lamda.carry_item","carry_item");
            res.addToResources(resources,1);
            @res = Resource("reward_box_weapon_2.carry_item","carry_item");
            res.addToResources(resources,1);
            @res = Resource("reward_box_weapon_1.carry_item","carry_item");
            res.addToResources(resources,1);
            @res = Resource("reward_box_skin.carry_item","carry_item");
            res.addToResources(resources,15);
            @res = Resource("reward_box_vehicle.carry_item","carry_item");
            res.addToResources(resources,15);
            addListItemInBackpack(m_metagame,cid,resources);

            GiveRP(m_metagame,cid,500000);
            dictionary a;
            a["%reward"] = "RP: 50w 、加成卡和战利品箱子";
            notify(m_metagame, "[欢迎加入ESC！]", a, "misc", pid, false, "", 1.0);
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "inviter_reward"){//邀请者奖励
            @res = Resource("hd_bonusfactor_al_240","carry_item");
            res.addToResources(resources,1);
            @res = Resource("hd_bonusfactor_rp_75","carry_item");
            res.addToResources(resources,2);
            @res = Resource("reward_box_weapon_lamda.carry_item","carry_item");//MK3
            res.addToResources(resources,1);
            @res = Resource("reward_box_skin.carry_item","carry_item");
            res.addToResources(resources,10);
            addListItemInBackpack(m_metagame,cid,resources);

            GiveRP(m_metagame,cid,100000);
            dictionary a;
            a["%reward"] = "RP: 10w 、加成卡和战利品箱子";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "invited_reward"){//被邀请者奖励
            @res = Resource("hd_bonusfactor_al_75","carry_item");
            res.addToResources(resources,10);
            @res = Resource("reward_box_weapon_omega.carry_item","carry_item");//MK1~MK3
            res.addToResources(resources,3);
            @res = Resource("reward_box_weapon_delta.carry_item","carry_item");//MK4
            res.addToResources(resources,1);
            @res = Resource("reward_box_skin.carry_item","carry_item");
            res.addToResources(resources,10);
            @res = Resource("reward_box_vehicle.carry_item","carry_item");
            res.addToResources(resources,5);
            addListItemInBackpack(m_metagame,cid,resources);
            GiveRP(m_metagame,cid,500000);
            dictionary a;
            a["%reward"] = "RP: 50w 、加成卡和战利品箱子";
            notify(m_metagame, "Your Reward has sended", a, "misc", pid, false, "", 1.0);
            return true;
        }
        if(access_tag == "update"){//更新奖励
            @res = Resource("reward_box_weapon_delta.carry_item","carry_item");//MK4
            res.addToResources(resources,1);
            @res = Resource("reward_box_skin.carry_item","carry_item");
            res.addToResources(resources,3);
            @res = Resource("reward_box_vehicle.carry_item","carry_item");
            res.addToResources(resources,3);
            @res = Resource("samples_acg.carry_item","carry_item"); // 研究点
            res.addToResources(resources,1);
            addListItemInBackpack(m_metagame,cid,resources);

            string sid = g_playerInfoBuck.getSidByName(p_name);
            playerStashInfo@ m_playerStashInfo = playerStashInfo(m_metagame,sid,p_name);
            if(!m_playerStashInfo.isOpen(false)){
                m_playerStashInfo.openStash(false);
            }
            m_playerStashInfo.upgradeStash(5,true);
            m_playerStashInfo.openStash(false);

            dictionary a;
            a["%reward"] = "更新奖励已发送至背包";
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
                @res = Resource(key + ".weapon","weapon");
                res.addToResources(resources,1);
                addListItemInBackpack(m_metagame,cid,resources);
                isSend = true;
            } else if (ws == 3){
                int num = 1;
                if(isNumeric(word[2])){
                    num = parseInt(word[2]);
                }
                @res = Resource(key + ".weapon","weapon");
                res.addToResources(resources,num);
                addListItemInBackpack(m_metagame,cid,resources);
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
                @res = Resource(key,"carry_item");
                res.addToResources(resources,1);
                addListItemInBackpack(m_metagame,cid,resources);
                isSend = true;
			} else if (ws == 3){
                int num = 1;
                if(isNumeric(word[2])){
                    num = parseInt(word[2]);
                }
                @res = Resource(key,"carry_item");
                res.addToResources(resources,num);
                addListItemInBackpack(m_metagame,cid,resources);
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
                @res = Resource(key + ".projectile","projectile");
                res.addToResources(resources,1);
                addListItemInBackpack(m_metagame,cid,resources);
                isSend = true;
			} else if (ws == 3){
                int num = 1;
                if(isNumeric(word[2])){
                    num = parseInt(word[2]);
                }
                @res = Resource(key + ".projectile","projectile");
                res.addToResources(resources,num);
                addListItemInBackpack(m_metagame,cid,resources);
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
    array<string> MassageBreakUp(string message, string command, int preNumber)  {
        string s = message.trim().substr(command.length() + preNumber + 1);
        array<string> a = s.split(" ");
        return a;
    }

    // ----------------------------------------------------
	protected void spawnInstanceNearPlayer(int senderId, string key, string type, int factionId = 0, bool skydive = false) {
		_log("spawnInstanceNearPlayer");
		_log("pid ="+senderId+" name="+g_playerInfoBuck.getNameByPid(senderId));
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


const XmlElement@ readFile(Metagame@ m_metagame, string filename,string location = "savegame"){
    const XmlElement@ root_base = readXML(m_metagame,filename,location);
    if(root_base is null){
        _log("readFile is null,create"+filename+"是NULL，重新创建");
        _report(m_metagame,"文件名="+filename);
        writeXML(m_metagame,filename,XmlElement(filename),location);
        @root_base = readXML(m_metagame,filename,location);
    }
    if(root_base is null){
        return null;
    }
    const XmlElement@ root = root_base.getFirstChild();
    return root;
}

// -------------------------------------------
void updateGlobalPlayerInfo(Metagame@ m_metagame, const XmlElement@ newplayer = null,bool&in isOnline = true){
    array<const XmlElement@> players;
    players = getPlayers(m_metagame);
    if(players is null){return;}

    string FILENAME = "_globalPlayerInfo_"+g_server_difficulty_level+".xml";
    string location = "app_data";

    // 读取存档玩家信息
    XmlElement@ allInfo = XmlElement(readFile(m_metagame,FILENAME,location));
    if(allInfo is null){
        _log("allInfo is null, in updateGlobalPlayerInfo");
        return;
    }
    array<const XmlElement@> infos = allInfo.getElementsByTagName("players");
    if(int(infos.size()) == 0){ 
        writeXML(m_metagame,FILENAME,XmlElement(FILENAME),location);
        @allInfo = XmlElement(readFile(m_metagame,FILENAME,location));
    }

    allInfo.removeAllChild();
    //解决空子项问题
    XmlElement a("player");
    a.setBoolAttribute("onRemove",true);
    allInfo.appendChild(a);

    //获取在线玩家信息
    for(uint i=0;i<players.size();++i){
        XmlElement@ player = XmlElement(players[i]);
        if(player is null){
            _log("updateGlobalPlayerInfo player is null");
            continue;}
        bool is_online = isOnline;
        string player_name = player.getStringAttribute("name");
        string profile_hash = player.getStringAttribute("profile_hash");
        string sid = player.getStringAttribute("sid");
        int pid = player.getIntAttribute("player_id");
        int cid = player.getIntAttribute("character_id");
        int fid = player.getIntAttribute("faction_id");
        string ip = "0.0.0.0";
        if(player.hasAttribute("ip")){
            ip = player.getStringAttribute("ip");
        }

        const XmlElement@ character = getCharacterInfo(m_metagame,cid);
        if(character is null){
             _log("updateGlobalPlayerInfo character is null");
            continue;}
        int rp = character.getIntAttribute("rp");
        float xp = character.getFloatAttribute("xp");
 
        XmlElement playerinfo("player");
        playerinfo.setBoolAttribute("is_online",is_online);
        playerinfo.setStringAttribute("player_name",player_name);
        playerinfo.setStringAttribute("profile_hash",profile_hash);
        playerinfo.setStringAttribute("sid",sid);
        playerinfo.setStringAttribute("ip",ip);
        playerinfo.setIntAttribute("faction_id",fid);
        playerinfo.setIntAttribute("character_id",cid);
        playerinfo.setIntAttribute("player_id",pid);
        playerinfo.setIntAttribute("rp",rp);
        playerinfo.setFloatAttribute("xp",xp);
        allInfo.appendChild(playerinfo); 
    }
    allInfo.removeChild("player",0);
    writeXML(m_metagame,FILENAME,allInfo,location);

    if(g_debugMode){
        _report(m_metagame,"saveGlobalPlayerInfo");
    }
}

void removeGlobalPlayerInfo(Metagame@ m_metagame,string player_name){
    // 读取存档玩家信息
    XmlElement@ allInfo = XmlElement(readFile(m_metagame,"_globalPlayerInfo_"+g_server_difficulty_level+".xml","app_data"));
    if(allInfo is null){
        _log("allInfo is null, in updateGlobalPlayerInfo");
        return;
    }
    // 读取存档玩家账号信息
    array<const XmlElement@> m_players = allInfo.getElementsByTagName("player");

    allInfo.removeAllChild();
    //解决空子项问题
    XmlElement a("player");
    a.setBoolAttribute("onRemove",true);
    allInfo.appendChild(a);

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
        //玩家信息存在，则删除
        if(m_name == player_name){
            continue;
        }else{//其他玩家信息不修改存回去
            allInfo.appendChild(m_player);
        }
    }
    allInfo.removeChild("player",0);
    writeXML(m_metagame,"_globalPlayerInfo_"+g_server_difficulty_level+".xml",allInfo,"app_data");
}

void removeAllGlobalPlayerInfo(Metagame@ m_metagame){
    XmlElement@ allInfo = XmlElement("_globalPlayerInfo_"+g_server_difficulty_level+".xml");
    writeXML(m_metagame,"_globalPlayerInfo_"+g_server_difficulty_level+".xml",allInfo,"app_data");
}

const XmlElement@ readGlobalPlayerInfo(Metagame@ m_metagame,string method, string methodValue){
    // 读取存档玩家信息
    string FILENAME = "_globalPlayerInfo_"+g_server_difficulty_level+".xml";
    string location = "app_data";

    XmlElement@ allInfo = XmlElement(readFile(m_metagame,FILENAME,location));
    if(allInfo is null){
        _log("allInfo is null, in readGlobalPlayerInfo");
        return null;
    }
    array<const XmlElement@> m_players = allInfo.getElementsByTagName("player");
    for(uint i=0; i<m_players.size(); ++i){
        const XmlElement@ m_player = m_players[i];
        if(m_player.hasAttribute(method)){
            string m_value = m_player.getStringAttribute(method);
            if(m_value == methodValue){
                return m_player;
            }
        }
    }
    //没有查到
    return null;
}

bool reUpdateGlobalPlayerInfo(Metagame@ m_metagame,int pid,const XmlElement@ &out playerInfo){
    notify(m_metagame,"你的玩家信息丢失，正尝试重新创建", dictionary(), "misc", pid, false, "", 1.0);
    updateGlobalPlayerInfo(m_metagame);
    @playerInfo = readGlobalPlayerInfo(m_metagame,"player_id",""+pid);
    if(playerInfo is null){
        notify(m_metagame,"重新创建失败", dictionary(), "misc", pid, false, "", 1.0);
        return false;
    }else{
        notify(m_metagame,"重新创建成功", dictionary(), "misc", pid, false, "", 1.0);
        return true;
    }
}

// -------------------------------------------
void updateGlobalPlayerInfoTimePlayed(Metagame@ m_metagame,bool clearAll = false){
    array<const XmlElement@> players;
    players = getPlayers(m_metagame);
    if(players is null){return;}
    string FILENAME="_globalPlayerInfoTimePlayed_"+g_server_difficulty_level+".xml";
    string location = "app_data";

    // 读取存档玩家信息
    XmlElement@ allInfo = XmlElement(readFile(m_metagame,FILENAME,location));
    if(allInfo is null){
        _log("allInfo is null, in updateGlobalPlayerInfo");
        return;
    }
    array<const XmlElement@> infos = allInfo.getElementsByTagName("player");
    if(int(infos.size()) == 0 || clearAll){ 
        writeXML(m_metagame,FILENAME,XmlElement(FILENAME),location);
        @allInfo = XmlElement(readFile(m_metagame,FILENAME,location));
    }

    for(uint i=0;i<players.size();++i){
        XmlElement@ player = XmlElement(players[i]);
        if(player is null){continue;}
        string player_name = player.getStringAttribute("name");
        string profile_hash = player.getStringAttribute("profile_hash");
        string sid = player.getStringAttribute("sid");
        string ip = "0.0.0.0";
        if(player.hasAttribute("ip")){
            ip = player.getStringAttribute("ip");
        }

        bool isExist = false;
        // 读取存档玩家账号信息
        array<const XmlElement@> m_players = allInfo.getElementsByTagName("player");

        allInfo.removeAllChild();
        //解决空子项问题
        XmlElement a("player");
        a.setBoolAttribute("onRemove",true);
        allInfo.appendChild(a);

        for(int j = 0 ; j < int(m_players.size()) ; ++j){
            XmlElement@ m_player = XmlElement(m_players[j]);
            string m_name = m_player.getStringAttribute("player_name");
            string m_sid = m_player.getStringAttribute("sid");
            int time_played = m_player.getIntAttribute("time_played");
            //玩家信息存在，则删除重写覆盖
            if(m_sid == sid){
                array<const XmlElement@> childs = m_player.getChilds();
                m_player.removeAllChild();
                m_player.setIntAttribute("time_played",++time_played);
                m_player.setStringAttribute("ip",ip);
                m_player.appendChilds(childs);
                allInfo.appendChild(m_player);

                isExist = true;
            }else{
                allInfo.appendChild(m_player);
            }
        }
        //不存在，新建信息
        if(!isExist){
            XmlElement playerinfo("player");
            playerinfo.setIntAttribute("time_played",0);
            playerinfo.setStringAttribute("player_name",player_name);
            playerinfo.setStringAttribute("profile_hash",profile_hash);
            playerinfo.setStringAttribute("sid",sid);
            playerinfo.setStringAttribute("ip",ip);
            allInfo.appendChild(playerinfo);
        }
        allInfo.removeChild("player",0);
    }
    writeXML(m_metagame,FILENAME,allInfo,location);
}

// -------------------------------------------
string ACTIVITY_FILENAME = "_activity_playinfo.xml";
void handleTesterReward(Metagame@ m_metagame,const XmlElement@ player,string activityName = ""){
    // 读取活动信息
    if(activityName == ""){return;}
    XmlElement@ allInfo = XmlElement(readFile(m_metagame,ACTIVITY_FILENAME));
    if(allInfo is null){
        return;
    }
    if(activityName == "serverTest"){
        // 读取获得玩家细节信息
        string p_sid = player.getStringAttribute("sid");
        int p_pid = player.getIntAttribute("player_id");
        int p_cid = g_playerInfoBuck.getCidByPid(p_pid);
        int all_time_played = 0;
        array<const XmlElement@> m_infos = allInfo.getChilds();
        allInfo.removeAllChild();
        XmlElement a("player");
        a.setBoolAttribute("onRemove",true);
        allInfo.appendChild(a);

        for(int j = 0 ; j < int(m_infos.size()) ; ++j){
            XmlElement@ m_info = XmlElement(m_infos[j]);
            string sid = m_info.getStringAttribute("sid");
            int time_played = m_info.getIntAttribute("time_played");
            if(sid == p_sid){
                all_time_played += time_played;
                m_infos.removeAt(j);
                j--;
            }
        }
        if(all_time_played != 0){
            int rpTimes = int(all_time_played/60);
            bool isRewardWeapon = false;
            if( rpTimes >= 12){ isRewardWeapon = true;}
            if( rpTimes >= 6){ rpTimes = 6;}
            if( rpTimes == 0 ){ rpTimes = 1;}
            GiveRP(m_metagame,p_cid,rpTimes*800000);
            _notify(m_metagame,p_pid,"你的奖励是"+rpTimes*80+"w RP!");
            playerStashInfo m_playerStashInfo(m_metagame,player);
            if(!m_playerStashInfo.isOpen()){
                m_playerStashInfo.openStash();
            }
            m_playerStashInfo.upgradeStash(200,true);
            m_playerStashInfo.openStash();
            _notify(m_metagame,p_pid,"仓库已升级容量!");
            if(isRewardWeapon){
                addItemInBackpack(m_metagame,p_cid,"weapon","hd_scout_main.weapon");
                _notify(m_metagame,p_pid,"特殊武器已送至背包!");
            }
            allInfo.appendChilds(m_infos);
            allInfo.removeChild("player",0);
            writeXML(m_metagame,ACTIVITY_FILENAME,allInfo);
            return;
        }
        _notify(m_metagame,p_pid,"你没有参加过测试，无法领取奖励");
    }
}
