# ==============================================================================
# === СКРИПТ ДЛЯ ОБУЧЕНИЯ МОДЕЛИ В KAGGLE ===
# ==============================================================================

# --- 1. Установка всех необходимых библиотек ---
# Unsloth устанавливается напрямую с GitHub для последней версии
get_ipython().system('pip install "unsloth[kaggle-new] @ git+https://github.com/unslothai/unsloth.git"')
get_ipython().system('pip install --no-deps transformers trl peft accelerate bitsandbytes')

import torch
from unsloth import FastLanguageModel
from transformers import TrainingArguments
from trl import SFTTrainer
from datasets import load_dataset
import zipfile
import os

# --- 2. Настройки обучения ---
# !!! ВАЖНО: ПРОВЕРЬТЕ ЭТОТ ПУТЬ В KAGGLE !!!
# После загрузки файла, наведите на него курсор в правой панели "Data" и скопируйте путь.
# Скорее всего, он будет выглядеть примерно так.
training_data_file = "/kaggle/input/training-data-txt/training_data.txt"

model_name = "unsloth/gemma-2b-it-bnb-4bit"
output_dir = "/kaggle/working/trained_model" # Kaggle сохраняет результаты в /kaggle/working
max_seq_length = 2048
num_train_epochs = 1

print("---> Unsloth Fine-Tuning Script for Kaggle ---")
print(f"Model: {model_name}")
print(f"Dataset: {training_data_file}")
print(f"Output: {output_dir}")
print("---------------------------------------------")


# --- 3. Загрузка модели с 4-битной квантизацией ---
print("\n---> Loading model...")
model, tokenizer = FastLanguageModel.from_pretrained(
    model_name = model_name,
    max_seq_length = max_seq_length,
    dtype = None,
    load_in_4bit = True,
)
print("--- Model loaded successfully!")


# --- 4. Конфигурация LoRA (PEFT) ---
print("\n---> Configuring LoRA adapter...")
model = FastLanguageModel.get_peft_model(
    model,
    r = 16,
    target_modules = ["q_proj", "k_proj", "v_proj", "o_proj",
                      "gate_proj", "up_proj", "down_proj"],
    lora_alpha = 16,
    lora_dropout = 0,
    bias = "none",
    use_gradient_checkpointing = True,
    random_state = 3407,
    use_rslora = False,
    loftq_config = None,
)
print("--- LoRA configured successfully!")


# --- 5. Загрузка и форматирование данных ---
# Проверяем, существует ли файл данных, перед загрузкой
if not os.path.exists(training_data_file):
    print(f"!!! ERROR: Cannot find the training data file at '{training_data_file}'")
    print("!!! Please upload your 'training_data.txt' file and double-check the path in the script.")
else:
    print(f"\n---> Loading dataset from {training_data_file}...")
    dataset = load_dataset("text", data_files={"train": training_data_file})
    print("--- Dataset loaded successfully!")

    # --- 6. Настройка тренера ---
    print("\n---> Setting up the SFTTrainer...")
    trainer = SFTTrainer(
        model = model,
        tokenizer = tokenizer,
        train_dataset = dataset["train"],
        dataset_text_field = "text",
        max_seq_length = max_seq_length,
        dataset_num_proc = 2,
        packing = False,
        args = TrainingArguments(
            per_device_train_batch_size = 2,
            gradient_accumulation_steps = 4,
            warmup_steps = 5,
            num_train_epochs = num_train_epochs,
            learning_rate = 2e-4,
            fp16 = not torch.cuda.is_bf16_supported(),
            bf16 = torch.cuda.is_bf16_supported(),
            logging_steps = 1,
            optim = "adamw_8bit",
            weight_decay = 0.01,
            lr_scheduler_type = "linear",
            seed = 3407,
            output_dir = "/kaggle/working/outputs", # Временная папка для логов
        ),
    )
    print("--- Trainer configured successfully!")


    # --- 7. Запуск обучения ---
    print("\n---> Starting training... This will take some time.")
    trainer.train()
    print("--- Training completed!")


    # --- 8. Сохранение и архивация модели ---
    print(f"\n---> Saving trained model to {output_dir}...")
    model.save_pretrained(output_dir)
    tokenizer.save_pretrained(output_dir)
    print("--- Model saved successfully!")

    print(f"\n---> Zipping the model for download...")
    zip_name = f'/kaggle/working/trained_model.zip'
    with zipfile.ZipFile(zip_name, 'w', zipfile.ZIP_DEFLATED) as zf:
        for root, dirs, files in os.walk(output_dir):
            for file in files:
                zf.write(os.path.join(root, file),
                           os.path.relpath(os.path.join(root, file),
                                           os.path.join(output_dir, '..'))))
    print(f"--- Model zipped to {zip_name}!")
    print("\n--- All done! You can now save the notebook and download the output from the 'Data' tab of the notebook viewer. ---")
