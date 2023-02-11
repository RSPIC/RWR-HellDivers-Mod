
// 此文档用于存放脚本文件中所有的固定参数，便于以后数据维护或导出。
// 目前了解到的固定参数包括：技能名称，技能延时，技能间隔，技能持续时间，技能作用范围，技能等级等等。

// parameters for "all_airstrike.as"
dictionary airstrikeIndex = {
        
        // 空武器
        {"",-1},

        // 绝地潜兵 空袭mk3
        {"hd_superearth_airstrike_mk3",1},
        {"hd_superearth_heavy_strafe_mk3",4},

        // 下面这行是用来占位的，在这之上添加新的即可
        {"666",-1}
};

// parameters for "projectile_event.as"
dictionary projectile_eventkey = {

        // 空
        {"",-1},

        {"hd_superearth_airstrike_mk3",1},
        {"hd_superearth_airstrike_mk2",2},
        {"hd_superearth_airstrike_mk1",3},

        {"hd_superearth_heavy_strafe_mk3",4},
        {"hd_superearth_heavy_strafe_mk2",5},
        {"hd_superearth_heavy_strafe_mk1",6},

        {"rangefinder",7},

        // 占位的
        {"666",-1}
};