# AI Resume Ranker

[![Code Style](https://img.shields.io/badge/code%20style-black-000000.svg )](https://github.com/psf/black )
[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=flutter&logoColor=white )](https://flutter.dev/ )
[![Python](https://img.shields.io/badge/Python-3.8+-blue.svg )](https://www.python.org/ )

A simple AI-powered resume ranker that ranks resumes based on similarity to a job description.

## 🧾 Description

This app lets you:
- Upload multiple PDF resumes
- Enter a job description
- Rank resumes using NLP and cosine similarity
- Download a PDF report with results

## 💻 Setup Instructions

### Backend (Python Flask)

```bash
pip install flask spacy scikit-learn fpdf pandas PyPDF2
python -m spacy download en_core_web_sm
cd backend
python app.py
```
### Frontend (Flutter)
- Make sure you have Flutter SDK installed. 
```bash
cd frontend
flutter pub get
flutter run
```
### 📦 Run Both Locally
Make sure both the backend and frontend are running:

Backend: http://<Your System Ip Address>:5000
Frontend: Runs on mobile/emulator

### 📬 Feedback / Contributions
Feel free to open an issue or submit a pull request if you'd like to improve or extend this project!

### 📸 Snap Shots
![pdf](https://github.com/user-attachments/assets/25b01898-efff-4c1d-93ef-b98d738ec88b)
![interface](https://github.com/user-attachments/assets/3992ff25-28a4-48b9-b174-dd957b63a79e)
