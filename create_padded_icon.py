from PIL import Image, ImageOps
import os

def create_padded_icon(input_path, output_path, padding_percent=30):
    """
    创建一个带有额外边距的图标
    
    参数:
        input_path: 输入图片路径
        output_path: 输出图片路径
        padding_percent: 边距百分比 (0-100)，数值越大边距越大
    """
    # 打开原图
    img = Image.open(input_path)
    
    # 确保图片是正方形
    width, height = img.size
    size = max(width, height)
    
    if width != height:
        # 创建新的正方形画布
        square = Image.new('RGBA', (size, size), (255, 255, 255, 0))
        # 将原图粘贴到中心
        offset = ((size - width) // 2, (size - height) // 2)
        square.paste(img, offset)
        img = square
    
    # 计算新尺寸
    padding = int(size * padding_percent / 100)
    new_size = size + 2 * padding
    
    # 创建带边距的新图像
    padded = Image.new('RGBA', (new_size, new_size), (255, 255, 255, 0))
    padded.paste(img, (padding, padding))
    
    # 保存
    padded.save(output_path)
    print(f"创建了带边距的图标: {output_path}")

if __name__ == "__main__":
    # 输入和输出路径
    input_path = "assets/icon/app_icon.jpg"
    output_path = "assets/icon/app_icon_padded.png"
    
    # 创建带50%边距的图标
    create_padded_icon(input_path, output_path, padding_percent=50)
    
    print("图标已创建完成，请在pubspec.yaml中更新图标路径为:", output_path)
    print("并运行: flutter pub run flutter_launcher_icons") 