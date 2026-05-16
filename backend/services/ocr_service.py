import logging
import os
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)


class OCRService:
    def extract_text_from_image(self, image_path: str) -> str:
        try:
            import pytesseract
            from PIL import Image
            from django.conf import settings

            if hasattr(settings, 'TESSERACT_PATH') and settings.TESSERACT_PATH:
                pytesseract.pytesseract.tesseract_cmd = settings.TESSERACT_PATH

            image = Image.open(image_path)
            image = self._preprocess_image(image)
            text = pytesseract.image_to_string(image, lang='eng', config='--psm 6')
            return text.strip()
        except Exception as e:
            logger.error(f'OCR extraction failed for {image_path}: {e}')
            raise

    def extract_text_from_pdf(self, pdf_path: str) -> str:
        texts = []
        try:
            import pdfplumber
            with pdfplumber.open(pdf_path) as pdf:
                for page in pdf.pages:
                    text = page.extract_text()
                    if text:
                        texts.append(text)
        except Exception as e:
            logger.error(f'PDF text extraction failed: {e}')

        if not texts:
            texts = self._ocr_pdf_pages(pdf_path)

        return '\n\n'.join(texts)

    def _ocr_pdf_pages(self, pdf_path: str) -> list:
        try:
            from pdf2image import convert_from_path
            images = convert_from_path(pdf_path, dpi=200)
            texts = []
            for i, image in enumerate(images):
                temp_path = f'/tmp/pdf_page_{i}.png'
                image.save(temp_path)
                try:
                    text = self.extract_text_from_image(temp_path)
                    if text:
                        texts.append(text)
                finally:
                    if os.path.exists(temp_path):
                        os.remove(temp_path)
            return texts
        except Exception as e:
            logger.error(f'PDF OCR failed: {e}')
            return []

    def _preprocess_image(self, image):
        from PIL import Image, ImageFilter, ImageEnhance
        if image.mode != 'L':
            image = image.convert('L')
        image = image.filter(ImageFilter.SHARPEN)
        enhancer = ImageEnhance.Contrast(image)
        image = enhancer.enhance(2)
        return image

    def extract_text(self, file_path: str, file_type: str) -> str:
        if file_type == 'pdf':
            return self.extract_text_from_pdf(file_path)
        elif file_type in ('image', 'png', 'jpg', 'jpeg', 'webp'):
            return self.extract_text_from_image(file_path)
        raise ValueError(f'Unsupported file type: {file_type}')


ocr_service = OCRService()
