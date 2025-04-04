from PIL import Image
import os

def make_square_image(input_path, output_path=None):
    """
    将图片裁剪成正方形，保持质量不变
    裁剪方式为居中裁剪
    """
    if output_path is None:
        # 如果没有指定输出路径，则在原文件名基础上添加_square
        filename, ext = os.path.splitext(input_path)
        output_path = f"{filename}_square{ext}"
    
    # 打开图片
    img = Image.open(input_path)
    width, height = img.size
    
    # 确定裁剪尺寸和位置
    if width > height:
        # 宽图，需要从两侧裁剪
        left = (width - height) // 2
        top = 0
        right = left + height
        bottom = height
    else:
        # 高图，需要从上下裁剪
        left = 0
        top = (height - width) // 2
        right = width
        bottom = top + width
    
    # 裁剪并保存
    square_img = img.crop((left, top, right, bottom))
    
    # 保存图片，保持原始质量
    if img.format == 'JPEG':
        square_img.save(output_path, quality=100, subsampling=0)
    else:
        square_img.save(output_path)
    
    print(f"正方形图片已保存到 {output_path}")
    return output_path

if __name__ == "__main__":
    # 图标路径
    icon_path = "assets/icon/app_icon.jpg"
    
    # 处理图片
    output_path = "assets/icon/app_icon_square.jpg"
    make_square_image(icon_path, output_path)
    
    print("完成！请在pubspec.yaml中更新图标路径为:", output_path)
    print("然后运行: flutter pub run flutter_launcher_icons") 