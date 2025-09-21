import gradio as gr
from huggingface_hub import InferenceClient
import os

# Системный промпт для настройки поведения модели
SYSTEM_PROMPT = """
You are a world-class expert in Linux system administration.
Your task is to convert a user's request in natural language into a SINGLE, executable shell command.
- Do NOT provide any explanation.
- Do NOT use markdown or any other formatting.
- Do NOT suggest multiple options.
- Just return the raw command, ready to be executed.

Example:
User: list all running docker containers
You: docker ps
"""

# Используем модель Meta Llama 3 70B - одна из лучших на данный момент
MODEL = "meta-llama/Meta-Llama-3-70B-Instruct"

def generate_command(user_request, hf_token):
    """
    Обращается к Hugging Face Inference API для генерации команды.
    """
    if not user_request:
        return "Ошибка: Запрос не может быть пустым."
    if not hf_token:
        return "Ошибка: Hugging Face Token не может быть пустым. Его можно получить в настройках вашего профиля Hugging Face."

    try:
        client = InferenceClient(model=MODEL, token=hf_token)
        
        # Формируем сообщения для модели
        messages = [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user_request},
        ]

        # Выполняем запрос к API
        response = client.chat_completion(
            messages=messages,
            max_tokens=200,
            temperature=0.1, # Низкая температура для более предсказуемых и точных команд
        )
        
        command = response.choices[0].message.content.strip()
        
        # Дополнительная очистка, чтобы убрать возможные артефакты
        if command.startswith("`") and command.endswith("`"):
            command = command[1:-1]
        if command.startswith("bash\n"):
            command = command.replace("bash\n", "", 1)

        return command

    except Exception as e:
        # Возвращаем более детальную ошибку для отладки
        return f"Произошла ошибка API: {str(e)}"

# Создаем интерфейс Gradio
with gr.Blocks() as demo:
    gr.Markdown(
        """
        # 🤖 AI System Administrator Assistant
        Введите ваш запрос на естественном языке, и ИИ преобразует его в готовую к выполнению shell-команду.
        **Внимание:** Этот инструмент — ваш помощник. Всегда проверяйте предложенные команды перед выполнением в реальной системе.
        """
    )
    
    hf_token_input = gr.Textbox(
        label="Hugging Face User Access Token",
        placeholder="Введите ваш токен HF (начинается с hf_...)",
        type="password",
        info="Нужен для доступа к API. Можно создать в Settings -> Access Tokens вашего профиля."
    )
    
    user_input = gr.Textbox(label="Ваш запрос", placeholder="Например: 'покажи все файлы в текущей папке, отсортированные по размеру'")
    
    generate_button = gr.Button("Сгенерировать команду")
    
    output_command = gr.Textbox(label="Предложенная команда", interactive=False, lines=3)

    generate_button.click(
        fn=generate_command,
        inputs=[user_input, hf_token_input],
        outputs=output_command
    )
    
    gr.Markdown(
        """
        ---
        *Модель, используемая для генерации: `meta-llama/Meta-Llama-3-70B-Instruct`.*
        """
    )

if __name__ == "__main__":
    demo.launch()
