# AI Resume Ranker

[![Code Style](https://img.shields.io/badge/code%20style-black-000000.svg )](https://github.com/psf/black )
[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=flutter&logoColor=white )](https://flutter.dev/ )
[![Python](https://img.shields.io/badge/Python-3.10-blue.svg )](https://www.python.org/ )

An AI-based system that ranks resumes based on relevance to a given job description.

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

Backend: http:// Your System Ip Address :5000
![image](https://github.com/user-attachments/assets/44af2b8d-6997-4598-9f03-dc2f21df0ab8)

Frontend: Runs on muliple plateforms such as Android,Web,Ios etc.

### 📬 Feedback / Contributions
Feel free to open an issue or submit a pull request if you'd like to improve or extend this project!

## 📸 Snap Shots

### 🖼️ Flutter App Interface  
![interface](https://github.com/user-attachments/assets/679bbbe5-19bd-4ee5-ab5d-763cb3e75804)

### 🧾 Exported PDF  
![pdf](https://github.com/user-attachments/assets/02a03440-f6a9-485d-926a-138a515fd714)

