
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

        // 占位的
        {"666",-1}
};

// 支援信标护甲代码
dictionary offensive_stratagems = {

        // 空
        {"",-1},

        // Offensive 攻击性支援
        {"ddd","hd_offensive_vindicator_dive_bomb_mk3"},
        {"dwsda","hd_offensive_airstrike_mk3"},
        {"dwawda","hd_offensive_laser_strike_mk3"},
        {"dadassd","hd_offensive_shredder_missile_strike_mk3"},
        {"ddsa","hd_offensive_close_air_support_mk3"},
        {"dswwas","hd_offensive_thunderer_barrage_mk3"},
        {"ddw","hd_offensive_strafing_run_mk3"},
        {"dwas","hd_offensive_static_field_conductors_mk3"},
        {"dwawsd","hd_offensive_sledge_precision_artillery_mk3"},
        {"dswsa","hd_offensive_railcannon_strike_mk3"},
        {"dsssas","hd_offensive_missile_barrage_mk3"},
        {"dwad","hd_offensive_incendiary_bombs_mk3"},
        {"ddsw","hd_offensive_heavy_strafing_run_mk3"},

        // defensive 防御性支援
        {"adsw","hd_at_mine_mk3"},
        {"adws","hd_airdropped_stun_mine_mk3"},
        {"aawwda","hd_at47_mk3_call"},
        {"aswda","hd_amg_11_mk3_call"},
        {"aswad","hd_arx_34_mk3_call"},
        {"aswdds","hd_agl8_mk3_call"},
        {"asswda","hd_aac6_tesla_mk3_call"},

        // special 特殊支援
        {"wadsws","hd_nux_223_hellbomb"},
        {"wsdaw","hd_hellpod"},

        // Supply 普通支援
        {"sdsaad","hd_m5_apc_call"},
        {"sdsaws","hd_m5_32_hav_call"},
        {"sdsawd","hd_td110_bastion_call"},
        {"sdsaaw","hd_mc109_motor_call"},
        {"sswd","hd_resupply"},
        {"sdwass","hd_exo44_mk3"},
        {"sdwasa","hd_exo48_mk3"},
        {"sdwasd","hd_exo51_mk3"},

        // 占位的
        {"666",-1}
};