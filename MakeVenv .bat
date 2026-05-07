python -m venv .venv
call .venv\Scripts\activate.bat
pip install -r requirements.txt
pip freeze > requirements.txt
echo "Virtual environment setup complete. To activate, run: call .venv\Scripts\activate.bat"