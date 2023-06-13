
//中断请求 Interrupt Request
class _IRQ {
    protected dictionary key_list;      //string 字典-记录键值
    protected dictionary cid_state;    //int 字典-角色状态：如死亡后无效

    _IRQ(string key,bool flag){
        key_list[key] = flag;
    }

    void set(string key,bool flag){
        key_list[key] = flag;
    }
    void set(int cid,bool flag){
        string key = "" + cid;
        cid_state[key] = flag;
    }

    bool get(string key){
        bool flag;
        if (!key_list.get(key, flag) || !flag) {
            return false;
        }
        key_list.delete(key);
        return true;
    }
    bool cidValid(int cid){
        string key = "" + cid;
        bool flag;
        if (cid_state.get(key, flag) && flag) {
            return true;
        }
        cid_state.delete(key);
        return false;
    }

    bool isExist(string key){
        bool flag;
        if (key_list.get(key, flag)) {
            return true;
        }else{
            return false;
        }
    }

    void remove(string key){
        key_list.delete(key);
    }
    void remove(int cid){
        string key = "" + cid;
        cid_state.delete(key);
    }

    void clearAll(){
        key_list.deleteAll();
        cid_state.deleteAll();
    }

    string _test() {
        array<string>@ keys = key_list.getKeys();
        array<string>@ keys2 = cid_state.getKeys();
        string result = "";

        for (uint i = 0; i < keys.length(); i++) {
            string key = keys[i];
            bool value;
            key_list.get(key, value);
            result += "Key: " + key + ", Value: " + (value ? "true" : "false") + "\n";
        }

        for (uint i = 0; i < keys2.length(); i++) {
            string key = keys2[i];
            int cid = parseInt(key);
            bool value;
            cid_state.get(key, value);
            result += "cid: " + key + ", Value: " + (value ? "true" : "false") + "\n";
        }

        return result;
    }
}

_IRQ@ g_IRQ = _IRQ("",false);   //该全局变量会在task传送后的函数中的start()里面自动赋值，自动清理