
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

        //特殊功能
        {"vehicle_recycle",41},
        {"upgrade",42},

        //技能
        {"acg_texas_skill",43},

        //爆裂魔法 
        {"wand_guiding_01",44}, //弃用
        {"acg_megumin_wand_float",45},

        // 占位的
        {"666",-1}
};

// 支援信标护甲代码
dictionary code_stratagems = {

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
        {"ssdw","hd_sup_mental_detector_call"},

        // Supply 普通支援
        {"sdsaad","hd_m5_apc_call"},
        {"sdsaws","hd_m5_32_hav_call"},
        {"sdsawd","hd_td110_bastion_call"},
        {"sdsaaw","hd_mc109_motor_call"},
        {"sdwass","hd_exo44_mk3"},
        {"sdwasa","hd_exo48_mk3"},
        {"sdwasd","hd_exo51_mk3"},

        // weapons 武器支援
        {"sswd","hd_resupply"}, 
        {"saswd","hd_lmg_mg94_mk3"},
        {"saswwa","hd_lmg_mgx42_mk3"},
        {"saswa","hd_laser_las98_laser_cannon_mk3"},
        {"saswwd","hd_exp_ac22_dum_dum_mk3"},
        {"sawas","hd_exp_obliterator_grenade_launcher_full_upgrade"},
        {"sawaa","hd_exp_m25_rumbler_full_upgrade"},
        {"sasda","hd_pst_flam40_incinerator_mk3"},
        {"sasdd","hd_pst_tox13_avenger_mk3"},
        {"sadda","hd_exp_rl112_recoilless_rifle_mk3"},
        {"sadws","hd_exp_eta17_mk3"},
        {"sawsd","hd_exp_mls4x_commando_mk3"},
        {"swawds","hd_drone_ad334_guard_dog_mk3"},
        {"swaads","hd_drone_ad289_angel_mk3"},
        {"ssads","hd_sup_rep80_mk3"},
        {"sadww","hd_exp_rec6_demolisher_mk3"},
        {"swssd","hd_resupply_pack_mk3"},

        // 占位的
        {"666",-1}
};

//载具回收可用载具
dictionary vehicle_recycle_key = {

        // 空
        {"",-1},

        {"noxe.vehicle",1000},
        {"hd_td110_bastion.vehicle",1500},
        {"hd_mc109_motor.vehicle",100},
        {"hd_m5_apc.vehicle",500},
        {"ex_isu_152.vehicle",1500},
        {"hd_m5_32_hav.vehicle",1000},
        {"63type_107mm_rocket_launcher.vehicle",100},
        {"jeep.vehicle",100},
        {"cyborgs_ifv.vehicle",3000},

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

        {"hd_ad289_angel_mk3",3.0},

        {"hd_vehicle_wrench",0.2},

        // 占位的
        {"666",-1}

};

