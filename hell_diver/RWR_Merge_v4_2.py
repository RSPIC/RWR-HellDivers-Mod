import os
import xml.etree.ElementTree as ET
from xml.dom import minidom
import re

await_all_items = [
    "invasion_all_vehicles.xml",
    "invasion_all_throwables.xml",
    "invasion_all_weapons.xml",
]

# 键值对为: 文件名: 文件绝对路径
possible_files = {}
invasion_all = []

# 保留xml缩进
def saveXML(root, filename):
    rawText = ET.tostring(root)
    dom = minidom.parseString(rawText).toprettyxml(indent="", newl="")
    f = open(filename,'w',encoding='utf-8')
    with open(filename, 'w', encoding="utf-8") as f:
        for line in re.split('[\n>]',dom):
            line = line.strip()
            if(line!=''):
                f.write(f"\t{line}>\n")
                
    # dom.writexml(f, "", indent, newl, encoding)
    
problem_path2 = ["./weapons\hd_side_p2_peacemaker_version.weapon","_vehicle_hvy.base"]
# base文件誊写
def base_file_change(current_root,base_file_path,error = 0):
    
    try:
        #print(f"hihihi - 1 - {base_file_path}")
        base_root = ET.parse(base_file_path)
        base_root = base_root.getroot()
        
        if base_root is None:
            return current_root
        
        if "file" in base_root.attrib:
            if base_root.attrib["file"]!="" and base_root.attrib["file"] in possible_files:
                base_root = base_file_change(base_root,possible_files[base_root.attrib["file"]],(possible_files[base_root.attrib["file"]] in problem_path2))
                
        #print(f"hihihi - 2 - {base_file_path}")

        # 开始合并。由于xml前面的标签会覆盖后面标签，故直接将原base武器接在最终武器上后返回
        # 去除base文件weapon节点中标志性的file标签，并且合并tag
        
        # 2022/8/25/ 由乌鸦发现，common是上比下优先，stance是下比上优先，需要专门修改
        
        # 将 weapon 主节点的标签进行修改（注意weapon节点本身是有属性的）        
        
        for (tag1,tag2) in base_root.attrib.items():
            if(tag1 not in current_root.attrib):
                current_root.set(tag1,tag2)
        if "file" in current_root.attrib:
            del current_root.attrib["file"]
        
        #print(f"hihihi - 3 - {base_file_path}")
        
        # 对子节点进行修改，其中部分tag有特殊处理逻辑
        for base_tags in base_root:
            # print(base_tags.tag)
            
            # 对 weapon 中的 specification 子节点，直接将 现武器 没有的嫁接上 base武器 的数据即可
            #print(f"hihihi - 4 - {base_file_path}")
            if(base_tags.tag=="specification"):
                #print(f"hihihi - 4 - 1 - {base_file_path}")
                if(current_root.find(base_tags.tag)==None):
                    new_tag = ET.Element(base_tags.tag)
                    for (tag1,tag2) in base_tags.attrib.items():
                        new_tag.set(tag1,tag2)
                    current_root.append(new_tag)
                else:
                    for (tag1,tag2) in base_tags.attrib.items():
                        if(tag1 not in current_root.find("specification").attrib):
                            current_root.find("specification").set(tag1,tag2)
                        
            # 对 weapon 中的 commonness 子节点，如果 现武器 有，直接无视；没有则照搬 base武器 数据
            elif(base_tags.tag=="commonness"):
                #print("find commonness conflict")
                #print(f"hihihi - 4 - 2 - {base_file_path}")
                if(current_root.find(base_tags.tag)!=None):
                    continue
                else:
                    current_root.append(base_tags)
                #print("--commonness conflict solved--")    
                
            # 对 weapon 中的 stance 子节点，如果 现武器 有，直接无视；没有则照搬 base武器 数据
            elif(base_tags.tag=="stance"):
                #print("find stance conflict")
                #print(f"hihihi - 4 - 3 - {base_file_path}")
                if(current_root.find(base_tags.tag)!=None):
                    jud = 0
                    #print(current_root.findall("stance")[0].attrib)
                    for current_tags in current_root.findall("stance"):
                        if (base_tags.attrib['state_key']==current_tags.attrib['state_key']):
                            jud = 1
                            break
                    if(jud):
                        continue
                    else:
                        current_root.append(base_tags)
                else:
                    current_root.append(base_tags)
                #print("--stance conflict solved--")

            elif(base_tags.tag=="modifier"):
                #print(f"hihihi - 4 - 4 - {base_file_path}")
                if(current_root.find(base_tags.tag)!=None):
                    jud = 0
                    for current_tags in current_root.findall("modifier"):
                        if (base_tags.attrib['class']==current_tags.attrib['class']):
                            jud = 1
                            break
                    if(jud):
                        continue
                    else:
                        current_root.append(base_tags)
                else:
                    current_root.append(base_tags)
                    
            # 对 vehicle 的 control,physics 子节点，直接将 现武器 没有的嫁接上 base武器 的数据即可
            elif(base_tags.tag in {"control","physics"}):
                #if(error==1):
                    #print("find commonness conflict")
                    #print(f"hihihi - 4 - 2 - {base_file_path}")
                if(current_root.find(base_tags.tag)==None):
                    new_tag = ET.Element(base_tags.tag)
                    for (tag1,tag2) in base_tags.attrib.items():
                        new_tag.set(tag1,tag2)
                    current_root.append(new_tag)
                else:
                    for (tag1,tag2) in base_tags.attrib.items():
                        if(tag1 not in current_root.find(base_tags.tag).attrib):
                            current_root.find(base_tags.tag).set(tag1,tag2)
                #print("--commonness conflict solved--")             
                    
            else:
                current_root.append(base_tags) 
        
        return current_root
    
    except Exception as e:
        print('====错误明细是',e.__class__.__name__,e)
        exit(0)

problem_of_single_merge = [] # was "./vehicles\hd_td110_bastion.vehicle"
not_base_file = ["_token_skin.xml"]

# 单个文件的base文件合并
def single_basefile_merge(merged_xml_root,path,elmnt):
    
    # 报错文件
    error_file = []    
        
    try:
        root = ET.parse(path)
        root = root.getroot()
        sub = root.findall(elmnt)
        
        # 只有element
        if(root.attrib):
            if("file" in root.attrib):
                
                kk = 0
                gg = root.attrib["file"]
                if path in problem_of_single_merge:
                    print(f"jjj - {gg}")
                    kk = 1
                    
                if(root.attrib["file"] not in not_base_file and root.attrib["file"]!=""):
                    root = base_file_change(root,possible_files[root.attrib["file"]],kk)
            root = current_file_edit(root,path,elmnt)
            merged_xml_root.append(root) 
            
        # 存在用elements囊括的多element结构    
        else:
            try:
                for subb in sub:
                    try:
                        if("file" in subb.attrib):
                            gg = subb.attrib["file"]
                            #if path in problem_of_single_merge:
                            #    print(f"jjj - {gg}")
                            if(subb.attrib["file"] not in not_base_file and subb.attrib["file"]!=""):
                                subb = base_file_change(subb,possible_files[subb.attrib["file"]],(possible_files[subb.attrib["file"]] in problem_path))
                    # 提示报错原因
                    except Exception as e:
                        error_file.append(path)
                        print(f"\n!!!===--== Error file: {path} ===!!!")
                        print(subb.attrib,subb.tag)
                        print('错误明细是',e.__class__.__name__,e)   
                        exit(0)
        
                    subb = current_file_edit(subb,path,elmnt)                       
                    merged_xml_root.append(subb)            
                    # print("------")
                
            # 提示报错原因
            except Exception as e:
                error_file.append(path)
                print(f"!!!===== Error file: {path} ===!!!")
                print('错误明细是',e.__class__.__name__,e)   
        
    
    # 提示报错原因
    except Exception as e:
        error_file.append(path)
        print(f"!!!=== Error file: {path} ===!!!")
        print('错误明细是',e.__class__.__name__,e)   
            
    return merged_xml_root

problem_path = ["./weapons\acg_incomparable_damage.projectile"] # was "./vehicles\hd_td110_bastion.vehicle"
#处理单个文件
def current_file_edit(current_root,path,elmnt):

    if(path in problem_path):
        print(f"\n---Current file: {path}---")

    for root_tags in current_root:
        if(path in problem_path):
            print(f"---Current tag: {root_tags.tag}---")
        # 武器文件自带一个projectile标签，需要专门处理
        if(root_tags.tag=="projectile" and elmnt=="weapon"):
            #print("===ready to merge projectile===")
                    
            root_tags = file_change_projectile(root_tags)
            #print(f"checking......{current_root}{path}")
    
    return current_root

# weapon武器下projectile标签的特殊撰写逻辑
def file_change_projectile(currenti_projectile):
    current_projectile = currenti_projectile
    #print("====proceeding projectile merge====")
    if("file" not in current_projectile.attrib): return current_projectile
        
    projectile_name = current_projectile.attrib['file']        
    del current_projectile.attrib["file"]
    #print("9090:---"+projectile_name)
    projectile_path = possible_files[projectile_name]

    base_projectile = ET.parse(projectile_path)
    base_projectile = base_projectile.getroot()
     
    for (tag11,tag12) in base_projectile.attrib.items():
        if(tag11 not in current_projectile.attrib):
            current_projectile.set(tag11,tag12)
    
    for base_tags in base_projectile:
        
        if(base_tags==None):break
        tagi = base_tags.tag
        #print("1010:---"+tagi)
        
        if(current_projectile.find(tagi)!=None):
            if(tagi=="effect" or tagi=="sound"): #可以叠加
                #print("Case 1 --- |||")
                jud = 0
                for current_tags in current_projectile.findall(tagi):
                    jud = 0
                    for (tag1,tag2) in base_tags.attrib.items():
                        if(tag1 not in current_projectile.find(tagi).attrib):
                            if(base_tags.attrib[tag1]!=current_tags.attrib[tag1]):
                                jud = 1
                                break
                        else:
                            jud = 1
                            break
                    if(jud==0):break
                if(jud==1):current_projectile.append(base_tags)

                #print("--stance conflict solved--")
                
            else: #其它全部覆盖
                #print("Case 2 --- |||")
                for (tag1,tag2) in base_tags.attrib.items():
                    if(tag1 not in current_projectile.find(tagi).attrib):
                        current_projectile.find(tagi).set(tag1,tag2)
        else:
            #print("=!hehe!=")
            current_projectile.append(base_tags)
    
    #print("==Finally++!")
    #for hh in current_projectile:
        #print(hh.tag+" ")
    return current_projectile

# 根据all文件定位实际使用了的文件
def get_file_list(file_path, elmnt, error_file, sign):
    file_list = []
    
    root = ET.parse(file_path)
    root = root.getroot()
    sub = root.findall(elmnt)
    if(elmnt=="valuable"):
        sub = root.findall("carry_item")

    if(len(sign)<=18):
        print(f"{sign} --- Now processing: {file_path} ---")      
    
    for subb in sub:
        try:
            file = subb.attrib["file"]
            file_name = os.path.basename(file)
            file_ext = file_name.split('.')[-1]

            if file_name not in possible_files: continue
            
            if file_ext == elmnt:
                file_list.append(possible_files[file_name])
            
            else:
                file_list.extend(get_file_list(possible_files[file_name], elmnt, error_file,f"{sign}==="))
       
        except Exception as e:
            if(subb.tag==elmnt):
                file_list.append(file_path)
            
            else:
                print(f"【Error file: {file_path} 】")
                print(f"【Error attribute: {subb} 】")
                print('错误明细是',e.__class__.__name__,e) 

    return file_list

# xml合并
def MergeRWRXML(elmnt,file_list):
    file_num = len(file_list)
    print(f"== {file_num} {elmnt} files found. ==")
    
    merged_xml_root = ET.Element(f"{elmnt}s")
    if(elmnt=="valuable"):
        merged_xml_root = ET.Element("carry_items")
    
    for file in file_list:
        merged_xml_root = single_basefile_merge(merged_xml_root,file,elmnt)
        # print(file)
        # merged_xml_root = single_file_edit()
   
    saveXML(merged_xml_root,f"merged_{elmnt}.{elmnt}")
    
# 特殊例外文件
ex_collect_file = ["_vehicle_hvy.base","_acg_all_throwables.xml","_ui.weapon_base"]

# 收集包下所有文件
def collect_files():
    for root, dirs, files in os.walk("./"):
        for file in files:
            file_path = os.path.join(root, file)
            ext = os.path.splitext(file)[-1]
            
            if "模板" in file_path or \
                file.startswith("merged_"): 
                    continue
            
            if file.startswith("invasion_all_") and ext == ".xml":
                invasion_all.append(file_path)
                
            elif ext in {".weapon", ".projectile", ".vehicle",".xml",".base"} or file in ex_collect_file:
                possible_files[file] = file_path
                
# 主程序
if __name__ == "__main__":

    collect_files()
 
    print("\n== Files loaded. ==")
    print(f"total file number: {len(possible_files)}")
                    
    await_vehicles = []                
    await_projectiles = []
    await_weapons = []
    
    error_file = []
    
    print(invasion_all)

    for i in invasion_all:
        if "invasion_all_vehicles" in i:
            await_vehicles = get_file_list(i,"vehicle", error_file,"")
        if "invasion_all_throwables" in i:
            await_projectiles = get_file_list(i,"projectile", error_file,"")
        if "invasion_all_weapons" in i:
            await_weapons = get_file_list(i,"weapon", error_file,"")

    print("== Await Files Loaded. ==")
    print(f"vehicles: {len(await_vehicles)}")
    print(f"projectiles: {len(await_projectiles)}")
    print(f"weapons: {len(await_weapons)}")

    # 如果错误信息存在,则更新error_log.txt文件;否则删除之前的error_log.txt文件(如果存在)
    if error_file:
        with open("error_log.txt", "w") as f:
            for error in error_file:
                f.write(error + "\n")
    else:
        if os.path.exists("error_log.txt"):
            os.remove("error_log.txt")

    MergeRWRXML("vehicle", await_vehicles)
    MergeRWRXML("projectile", await_projectiles)  
    MergeRWRXML("weapon", await_weapons)

    