import io
from urllib.parse import urlparse
from PIL import Image
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from aiogram import Bot

async def generate_pdf_from_tg_files(bot: Bot, file_ids: list[str]) -> io.BytesIO:
    """
    Downloads images from Telegram using their file_ids,
    resizes them to fit A4 page size, and generates a single PDF.
    
    Returns a BytesIO object containing the PDF data.
    """
    pdf_buffer = io.BytesIO()
    
    # A4 dimensions in points
    a4_width, a4_height = A4
    
    c = canvas.Canvas(pdf_buffer, pagesize=A4)
    
    for i, file_id in enumerate(file_ids):
        try:
            # Get file info from Telegram
            file_info = await bot.get_file(file_id)
            
            # Download file into memory
            file_data = io.BytesIO()
            await bot.download_file(file_info.file_path, file_data)
            file_data.seek(0)
            
            # Open Image with Pillow to get dimensions and convert if necessary
            img = Image.open(file_data)
            if img.mode != 'RGB':
                img = img.convert('RGB')
                
            # Use ReportLab's ImageReader
            from reportlab.lib.utils import ImageReader
            ir = ImageReader(img)
            
            img_width, img_height = img.size
            
            # Calculate aspect ratio
            aspect = img_height / img_width
            
            # Target dimensions (margins: 50 points)
            target_width = a4_width - 100
            target_height = target_width * aspect
            
            # If height exceeds page height, scale by height instead
            if target_height > (a4_height - 100):
                target_height = a4_height - 100
                target_width = target_height / aspect
                
            # Center coordinates
            x = (a4_width - target_width) / 2
            y = (a4_height - target_height) / 2
            
            # Add new page for each image after the first
            if i > 0:
                c.showPage()
                
            c.drawImage(ir, x, y, width=target_width, height=target_height)
            
        except Exception as e:
            print(f"Error processing image {file_id}: {e}")
            continue

    c.save()
    pdf_buffer.seek(0)
    return pdf_buffer
