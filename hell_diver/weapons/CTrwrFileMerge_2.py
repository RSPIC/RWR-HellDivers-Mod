from contextlib import nullcontext
import os
import re
from traceback import print_tb
import xml.etree.ElementTree as ET 
from xml.dom import minidom 

# ori_file_path记得改为游戏目录路径

ori_file_path = r"D://Developing//github//GFL-Castling//packages//GFL_Castling//"
ori_rwr_file_path = r"C://SSDgames//steamapps//common//RunningWithRifles//media//packages//vanilla//"
save_path = r"D://Developing//github//GFL-Castling//packages//GFL_Castling//weapons//"

selected_elements = {
    "weapon":["weapons//","all_weapons.xml"],
    # "projectile":["weapons//","all_throwables.xml"],
    # "vehicle":"vehicles//",
    "carry_item":["items//","all_carry_items.xml"],
    # "valuable":["items","valuable_item.xml"]
    
}

# 未完成的文件tag
imcompleted_tags = [
    "t-cms",
    "ange_2"
]

# 用不着的base的tag
useless_tag = [
    "specification",
    "commonness",
    "stance"
]

# 保留xml缩进
def saveXML(root, filename):
    rawText = ET.tostring(root)
    dom = minidom.parseString(rawText).toprettyxml(indent="", newl="")
    f = open(filename,'w',encoding='utf-8')
    with open(filename, 'w', encoding="utf-8") as f:
        for line in re.split('[\n>]',dom):
            line = line.strip()
            if(line!=''):
                jud = 0
                for (element,file_path) in selected_elements.items():
                    if((f"<{element}" in line) or ("<?xml" in line)):
                        jud = 1
                        f.write(f"{line}>\n")
                        break
                    elif(f"</{element}" in line):
                        jud = 1
                        f.write(f"{line}>\n\n")
                        break                        
                if(not jud):
                    f.write(f"\t{line}>\n")
                
    # dom.writexml(f, "", indent, newl, encoding)

# base文件誊写
def base_file_change(current_rot,ori_path,base_file_path):

    base_root = ET.parse(f"{ori_path}{base_file_path}")
    base_root = base_root.getroot()
    
    # 开始合并。由于xml前面的标签会覆盖后面标签，故直接将原base武器接在最终武器上后返回
    # 去除base文件weapon节点中标志性的file标签，并且合并tag
    
    # 2022/8/25/ 由乌鸦发现，common是上比下优先，stance是下比上优先，需要专门修改
    
    # 将 weapon 主节点的标签进行修改（注意weapon节点本身是有属性的）
    for (tag1,tag2) in base_root.attrib.items():
        current_rot.set(tag1,tag2)
    del current_rot.attrib["file"]
    
    # 对 weapon 的子节点进行修改
    for base_tags in base_root:
        
        # 对 specification 子节点，直接将 现武器 没有的嫁接上 base武器 的数据即可
        if(base_tags.tag=="specification"):
            for (tag1,tag2) in base_tags.attrib.items():
                if(tag1 not in current_rot.find("specification").attrib):
                    current_rot.find("specification").set(tag1,tag2)
                    
        # 对 commonness 子节点，如果 现武器 有，直接无视；没有则照搬 base武器 数据
        elif(base_tags.tag=="commonness"):
            # print("find commonness conflict")
            if(current_rot.find(base_tags.tag)!=None):
                continue
            else:
                current_rot.append(base_tags)
            # print("--commonness conflict solved--")    
        # 对 stance 子节点，如果 现武器 有，直接无视；没有则照搬 base武器 数据
        elif(base_tags.tag=="stance"):
            # print("find stance conflict")
            if(current_rot.find(base_tags.tag)!=None):
                jud = 0
                # print(current_rot.findall("stance")[0].attrib)
                for current_tags in current_rot.findall("stance"):
                    if (base_tags.attrib['state_key']==current_tags.attrib['state_key']):
                        jud = 1
                        break
                if(jud):
                    continue
                else:
                    current_rot.append(base_tags)
            else:
                current_rot.append(base_tags)
            # print("--stance conflict solved--")
            # 
        elif(base_tags.tag=="modifier"):
            # print("find modifier conflict")
            if(current_rot.find(base_tags.tag)!=None):
                jud = 0
                # print(current_rot.findall("modifier")[0].attrib)
                for current_tags in current_rot.findall("modifier"):
                    if (base_tags.attrib['class']==current_tags.attrib['class']):
                        jud = 1
                        break
                if(jud):
                    continue
                else:
                    current_rot.append(base_tags)
            else:
                current_rot.append(base_tags)
        else:
            current_rot.append(base_tags) 
    
    return current_rot

def single_file_merge(merged_xml_root,file,elmnt,path):
    
    jud = 0
    # 检测是否有标记中的未完成的武器
    for jud_tag in imcompleted_tags:
        if jud_tag in file:
            print(f"【incompleted file: {file}】")
            jud = 1
            break
        
    # 报错文件
    error_file = []    
    if(not jud):
        
        #注意是原版的还是ct的base文件
        jud_file = f"{path}{file}"
        if(not os.path.exists(jud_file)):
            path = f"{ori_rwr_file_path}weapons//"
            
        try:
            root = ET.parse(f"{path}{file}")
            root = root.getroot()
            sub = root.findall(elmnt)
            
            # 只有element
            if(root.attrib):
                if("file" in root.attrib):
                    root = base_file_change(root,path,root.attrib["file"])
                merged_xml_root.append(root) 
                
            # 存在用elements囊括的多element结构    
            else:
                for subb in sub:
                    if("file" in subb.attrib):
                        subb = base_file_change(subb,path,subb.attrib["file"])
                    merged_xml_root.append(subb)            
                    # print("------")
        
        # 提示报错原因
        except Exception as e:
            error_file.append(file)
            print(f"!!!=== Error file: {file} ===!!!")
            print('错误明细是',e.__class__.__name__,e)   
            
    return merged_xml_root

# 根据all文件定位实际使用了的文件
def get_file_list(file_tag,file_folder,file_name,sign):
    weapon_file_list = []
    
    file = f"{ori_file_path}{file_folder}//{file_name}"
    if(not os.path.exists(file)):
        file = f"{ori_rwr_file_path}{file_folder}//{file_name}"
        
    root = ET.parse(file)
    root = root.getroot()
    sub = root.findall(file_tag)
    if(file_tag=="valuable"):
        sub = root.findall("carry_item")
    
    if(len(sign)<=8):
        print(f"{sign}|| --- Now processing: {file_name} ---")      
    
    for subb in sub:    
        try:
            fin_file = subb.attrib["file"]
            if(file_tag=="valuable"):
                weapon_file_list.append(fin_file)
            elif(fin_file.split('.')[-1]==file_tag):
                weapon_file_list.append(fin_file)
            else:
                weapon_file_list.extend(get_file_list(file_tag,file_folder,fin_file,f"{sign}==="))
                
        except Exception as e:
            print(f"【Error file: {file_name} 】")
            print('错误明细是',e.__class__.__name__,e) 

    return weapon_file_list

# xml合并
def MergeRWRXML(elmnt,folder,pth):
    
    path = f"{ori_file_path}{folder}"
    # print(path)
    
    file_list = get_file_list(elmnt,folder,pth,'')
    file_num = len(file_list)
    print(f"== {file_num} {elmnt} files found. ==")
    
    merged_xml_root = ET.Element(f"{elmnt}s")
    if(elmnt=="valuable"):
        merged_xml_root = ET.Element("carry_items")
    
    for file in file_list:
        merged_xml_root = single_file_merge(merged_xml_root,file,elmnt,path)
   
    saveXML(merged_xml_root,f"{save_path}merged_{elmnt}.{elmnt}")
        
if __name__ == '__main__':
    
    print("=== Start merging ===")
    
    for (element,[file_folder,file_path]) in selected_elements.items():
        print(f"+++ Start Merging {element} files +++")
        MergeRWRXML(element,file_folder,file_path)
    
    print("=== Merge complete ===")