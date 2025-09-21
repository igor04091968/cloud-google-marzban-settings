# AI System Administrator Assistant Space

This Hugging Face Space provides a web interface to an AI assistant that converts natural language queries into executable shell commands.

## How it Works

This application uses the Gradio library to create a user interface. When you enter a request, it securely sends it to the **Hugging Face Inference API**, which runs the powerful `meta-llama/Meta-Llama-3-70B-Instruct` model to generate the appropriate command.

The model itself is **not** running in this Space. The Space only hosts the lightweight interface, making it fast and efficient.

## How to Deploy and Use

1.  **Create a Hugging Face Space:**
    *   Click on your profile picture, then "New Space".
    *   Give it a name (e.g., `ai-admin-assistant`).
    *   Select "Docker" as the Space SDK and choose the "Blank" template.
    *   Choose the free CPU hardware tier.
    *   Click "Create Space".

2.  **Upload Files:**
    *   In your new Space repository, go to the "Files" tab.
    *   Click "Add file" -> "Upload files".
    *   Upload the `Dockerfile`, `requirements.txt`, `app.py`, and this `README.md` file from the `/home/rachkovii68/huggingface_ai_admin/` directory.

3.  **Get a User Access Token:**
    *   This is a **critical** step. The app will not work without it.
    *   Go to your Hugging Face Settings -> Access Tokens.
    *   Click "New token". Give it a name and assign it the `read` role.
    *   Copy the generated token (it will start with `hf_`).

4.  **Use the App:**
    *   Once the Space finishes building (you can see the logs in the "Build" tab), the application interface will appear.
    *   Paste your User Access Token into the designated field.
    *   Type your request in plain language (e.g., "find all files larger than 100MB in the home directory").
    *   Click "Generate Command".

## Security Warning

**Never run a command suggested by the AI on a production system without fully understanding what it does.** This tool is an assistant, not an autonomous operator. Always verify the commands before execution.
