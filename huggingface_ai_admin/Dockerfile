# Используем официальный образ Python
FROM python:3.10-slim

# Устанавливаем рабочую директорию
WORKDIR /app

# Копируем файл с зависимостями
COPY requirements.txt .

# Устанавливаем зависимости
RUN pip install --no-cache-dir -r requirements.txt

# Копируем все файлы приложения
COPY . .

# Открываем порт, который использует Gradio
EXPOSE 7860

# Запускаем приложение. Флаг --share создает публичную ссылку (полезно для тестов).
# Для Hugging Face Spaces он не обязателен, но не мешает.
CMD ["gradio", "app.py", "--server_name", "0.0.0.0"]
