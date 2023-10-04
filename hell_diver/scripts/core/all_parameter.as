
// 此文档用于存放脚本文件中所有的固定参数，便于以后数据维护或导出。
// 目前了解到的固定参数包括：技能名称，技能延时，技能间隔，技能持续时间，技能作用范围，技能等级等等。

// parameters for "all_airstrike.as"
dictionary airstrikeIndex = {
        
        // 空武器
        {"",-1},

        // 绝地潜兵 空袭mk3
        {"hd_superearth_airstrike_mk3",1},

        {"hd_superearth_heavy_strafe_mk3",4},

        {"hd_superearth_vindicator_dive_bomb_mk3",8},

        {"hd_superearth_incendiary_bombs_mk3",11},

        {"hd_superearth_thunderer_barrage_mk3",14},

        {"hd_superearth_laser_strike_mk3",17},

        {"hd_superearth_strafing_run_mk3",20},

        {"hd_superearth_close_air_support_mg_mk3",23},
        {"hd_superearth_close_air_support_missile_mk3",24},

        {"hd_superearth_missile_barrage_mk3",29},

        {"hd_superearth_railcannon_strike_mk3",32},

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

        {"hd_offensive_vindicator_dive_bomb_mk3",8},

        {"hd_offensive_incendiary_bombs_mk3",11},

        {"hd_offensive_thunderer_barrage_mk3",14},

        {"hd_offensive_laser_strike_mk3",17},

        {"hd_offensive_strafing_run_mk3",20},

        {"hd_offensive_close_air_support_mk3",23},

        {"hd_offensive_missile_barrage_mk3",29},

        {"hd_offensive_railcannon_strike_mk3",32},

        //功能型武器
        {"hd_rep80_mk3",35},

        {"hd_ad289_angel_mk3",38},
        {"hd_ad289_angel_auto",38},

        //特殊功能
        {"vehicle_recycle",41},
        {"upgrade",42},

        //技能
        {"acg_texas_skill",43},

        //爆裂魔法 
        {"wand_guiding_01",44}, //弃用
        {"acg_megumin_wand_float",45},

        {"acg_patricia_fataldrive",46},

        {"hyper_mega_bazooka_launcher_skill",47},

        {"acg_laisha_southern_cross",48},
        //火箭发射任务
        {"hd_sms_for_launcher",49},
        //维吉尔 月牙天冲
        {"ex_vergil_getsuga_tenshou",50},
        //维吉尔 次元斩-绝
        {"ex_vergil_skill",51},
        //飞马鸟时 Skill技能
        {"acg_exo_toki_skill",52},
        //飞马鸟时 AI 空降
        {"acg_exo_toki_ai_spawn",53},
        //伊芙利特 技能
        {"acg_arknight_ifrit_skill",54},
        //喷气包 AI 空降
        {"hd_hellpod_dropping_spawn_ai_jetpack",55},

        // 占位的
        {"666",-1}
};

//载具回收可用载具
dictionary vehicle_recycle_key = {

        // 空
        {"",-1},

        {"noxe.vehicle",500},
        {"hd_td110_bastion.vehicle",500},
        {"hd_mc109_motor.vehicle",100},
        {"hd_m5_apc.vehicle",300},
        {"ex_isu_152.vehicle",800},
        {"hd_m5_32_hav.vehicle",300},
        {"63type_107mm_rocket_launcher.vehicle",100},
        {"jeep.vehicle",100},
        {"cyborgs_ifv.vehicle",3000},
        {"ex_sturmtiger_tank.vehicle",1000},
        {"ex_apocalypse_tank.vehicle",1000},
        {"ex_kv2_gup.vehicle",1000},
        {"ex_sherman.vehicle",1000},
        {"ba_crusader.vehicle",1000},
        {"ex_m18.vehicle",500},
        {"ba_torumaru_tiger.vehicle",1000},
        {"is2_m1895.vehicle",1000},
        {"himars.vehicle",1000},
        {"mtlb_2b9.vehicle",1000},
        {"m61a5.vehicle",1000},
        {"borsig.vehicle",1000},
        {"uragan.vehicle",1000},
        {"mi_24.vehicle",1000},
        {"bell_360.vehicle",1000},
        {"mh_60s.vehicle",1000},
        {"zbd09.vehicle",800},

        // 占位的
        {"666",-1}

};
//载具超额血量比例
dictionary vehicle_overhealth_key = {

        // 空
        {"",-1},

        {"noxe.vehicle",1.0},
        {"hd_mc109_motor.vehicle",2.0},

        // 占位的
        {"666",-1}

};
//不可修复载具
dictionary vehicle_repair_deny_key = {

        // 空
        {"",-1},

        {"repair_crane.vehicle",1},

        {"hd_apb_mk3.vehicle",1},

        // 占位的
        {"666",-1}

};
//修复工具修复量(百分比/定值)
dictionary repairtool_key = {

        // 空
        {"",-1},

        {"hd_rep80_mk3",0.1},

        {"hd_rep80_mk2",0.05},

        {"hd_vehicle_wrench",0.2},

        // 占位的
        {"666",-1}

};

