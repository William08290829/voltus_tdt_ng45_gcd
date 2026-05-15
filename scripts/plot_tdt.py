# -*- coding: utf-8 -*-
import os
import argparse
import numpy as np
import matplotlib.pyplot as plt

def plot_all_layers_tdt(tdt_filepath, output_dir, design_name):
    with open(tdt_filepath, 'r') as f:
        lines = f.readlines()
    
    layers_data = {}
    current_layer = None
    matrix = []
    x_coords, y_coords = [], []
    reading_matrix = False
    
    # 逐行解析資料
    for line in lines:
        line = line.strip()
        
        # 遇到新的 LAYER，準備切換紀錄的目標
        if line.startswith('LAYER'):
            # 如果前面已經有讀到矩陣，先把它存進字典裡
            if current_layer and len(matrix) > 0:
                layers_data[current_layer] = np.array(matrix)
            
            # 更新當前正在讀取的層級名稱 (例如: FEOL, metal1)
            current_layer = line.split()[1] 
            matrix = []
            reading_matrix = False
            continue
            
        if line.startswith('XCOR'):
            if not x_coords: # 假設各層網格大小一致，只抓一次座標即可
                x_coords = [float(val) for val in line.split()[1:]]
            continue
            
        if line.startswith('YCOR'):
            if not y_coords:
                y_coords = [float(val) for val in line.split()[1:]]
            reading_matrix = True
            continue
            
        if reading_matrix:
            # 遇到空行或 END 標籤，代表這層的矩陣結束了
            if not line or line.startswith('END_TEMPERATURE'):
                if current_layer and len(matrix) > 0:
                    layers_data[current_layer] = np.array(matrix)
                    matrix = []
                reading_matrix = False
                continue 
            
            row = [float(val) for val in line.split()]
            matrix.append(row)

    # ==========================================
    # 開始為每一層繪製獨立的圖片
    # ==========================================
    if x_coords and y_coords:
        extent = [min(x_coords), max(x_coords), min(y_coords), max(y_coords)]
    else:
        extent = None
        
    # 遍歷剛剛存下來的所有層級資料
    for layer_name, mat in layers_data.items():
        # 座標修正：上下翻轉
        mat = np.flipud(mat)
        
        plt.figure(figsize=(10, 8))
        im = plt.imshow(mat, cmap='inferno', interpolation='nearest', origin='lower', extent=extent)
        
        plt.colorbar(im, label='Temperature Delta (C)')
        
        # 在標題加上目前的 Layer 名稱
        plt.title(f'Voltus TDT Heatmap - {design_name} ({layer_name})')
        plt.xlabel('X Coordinate (um)')
        plt.ylabel('Y Coordinate (um)')
        
        plt.tight_layout()
        
        # 輸出檔名會自動加上層級名稱 (例如: tdt_heatmap_gcd_FEOL.png)
        output_filename = f"tdt_heatmap_{design_name}_{layer_name}.png"
        output_filepath = os.path.join(output_dir, output_filename)
        
        plt.savefig(output_filepath, dpi=300)
        plt.close()
        
        print(f"Success! Saved Layer [{layer_name}] as: {output_filepath}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate Heatmaps for ALL layers from Voltus TDT file.")
    parser.add_argument("input_file", help="Path to the input TDT file")
    args = parser.parse_args()

    input_filepath = args.input_file
    input_dir = os.path.dirname(input_filepath) or "."
    base_name = os.path.basename(input_filepath)

    if base_name.endswith('_tdt.txt'):
        design_name = base_name.replace('_tdt.txt', '')
    elif base_name.endswith('.txt'):
        design_name = base_name.replace('.txt', '')
    else:
        design_name = base_name

    # 執行多層繪圖函數
    plot_all_layers_tdt(input_filepath, input_dir, design_name)