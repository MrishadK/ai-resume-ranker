from io import BytesIO
import os
import logging
from flask import Flask, request, jsonify, send_file
from werkzeug.utils import secure_filename
import PyPDF2
import spacy
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np
from fpdf import FPDF

# === Setup ===
app = Flask(__name__)
UPLOAD_FOLDER = './uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# === Logging setup ===
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# === NLP model ===
try:
    nlp = spacy.load("en_core_web_sm")
except Exception as e:
    logging.error("Failed to load spaCy model: %s", e)
    raise

# Global variable to store last ranking result
last_results = []

# === Utility Functions ===
def extract_text_from_pdf(file_path):
    """Extracts text from a PDF file."""
    try:
        text = ""
        with open(file_path, 'rb') as f:
            reader = PyPDF2.PdfReader(f)
            for page in reader.pages:
                page_text = page.extract_text()
                if page_text:
                    text += page_text
        logging.info("Successfully extracted text from PDF.")
        return text
    except Exception as e:
        logging.error("Error reading PDF file: %s", e)
        return ""

def extract_name_from_resume(text):
    lines = [line.strip() for line in text.split('\n') if line.strip()]
    for line in lines[:5]:
        words = line.split()
        if len(words) <= 3 and all(w[0].isupper() and w.isalpha() for w in words):
            return line
    return "Unknown"

def preprocess_text(text):
    doc = nlp(text.lower())
    tokens = [token.lemma_ for token in doc if not token.is_stop and token.is_alpha]
    return " ".join(tokens)

def vectorize_texts(texts):
    vectorizer = TfidfVectorizer()
    vectors = vectorizer.fit_transform(texts)
    return vectors

def score_resumes(job_description, resumes):
    job_desc_proc = preprocess_text(job_description)
    resumes_proc = [preprocess_text(r) for r in resumes]
    all_texts = [job_desc_proc] + resumes_proc
    try:
        vectors = vectorize_texts(all_texts)
        similarities = cosine_similarity(vectors[0], vectors[1:])[0]
        max_score = np.max(similarities) if similarities.size > 0 else 1.0
        scaled_scores = (similarities / max_score) * 10
        return scaled_scores.tolist()
    except Exception as e:
        logging.error("Error scoring resumes: %s", e)
        return [0.0] * len(resumes)

# === API Endpoints ===
@app.route('/rank', methods=['POST'])
def rank_resumes_api():
    logging.info("Received request to /rank")

    job_description = request.form.get('job_description')
    if not job_description:
        logging.warning("Job description missing")
        return jsonify({"error": "Job description missing"}), 400

    files = request.files.getlist('resumes')
    if not files:
        logging.warning("No resume files uploaded")
        return jsonify({"error": "No resume files uploaded"}), 400

    resumes_texts = []
    filenames = []
    names = []

    for file in files:
        filename = secure_filename(file.filename)
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)

        try:
            file.save(filepath)
            text = extract_text_from_pdf(filepath)
            if not text.strip():
                logging.warning("Empty or unreadable content in %s", filename)
                continue
            resumes_texts.append(text)
            filenames.append(filename)
            name = extract_name_from_resume(text)
            names.append(name)
        except Exception as e:
            logging.error("Failed to process file %s: %s", filename, e)

    if not resumes_texts:
        logging.warning("No valid resume content found")
        return jsonify({"error": "No valid resume content found"}), 400

    scores = score_resumes(job_description, resumes_texts)
    results = [{"name": n, "filename": f, "score": round(s, 2)} for f, n, s in zip(filenames, names, scores)]
    results = sorted(results, key=lambda x: x['score'], reverse=True)

    global last_results
    last_results = results
    logging.info("Ranked %d resumes successfully", len(results))

    return jsonify(results)

@app.route('/download-report', methods=['GET'])
def download_report():
    logging.info("Received request to /download-report")

    global last_results
    if not last_results:
        logging.warning("No data available for report")
        return jsonify({"error": "No data available. Please rank resumes first."}), 400

    job_description = request.args.get('job_description', default='')
    if not job_description.strip():
        job_description = "No job description provided."

    try:
        pdf = FPDF()
        pdf.add_page()
        pdf.set_auto_page_break(auto=True, margin=15)
        pdf.set_font("Arial", size=12)

        # Title
        pdf.cell(0, 10, txt="Resume Ranking Report", ln=True, align='C')
        pdf.ln(5)

        # Job Description Section
        pdf.set_font("Arial", 'B', 12)
        pdf.cell(0, 8, txt="Job Description", ln=True)
        pdf.set_font("Arial", size=10)
        for line in job_description.split('\n'):
            pdf.multi_cell(0, 6, txt=line.strip())
        pdf.ln(10)

        # Ranked Candidates
        pdf.set_font("Arial", 'B', 12)
        pdf.cell(0, 8, txt="Ranked Candidates", ln=True)
        pdf.set_font("Arial", size=10)

        for item in last_results:
            pdf.ln(5)
            pdf.cell(0, 6, txt=f"Name: {item['name']}", ln=True)
            pdf.cell(0, 6, txt=f"File: {item['filename']}", ln=True)
            pdf.cell(0, 6, txt=f"Score: {item['score']}/10", ln=True)
            pdf.cell(0, 4, txt="-" * 60, ln=True)

        logging.info("Generated PDF report with job description")

        pdf_bytes = pdf.output(dest='S').encode('latin1')
        return send_file(
            BytesIO(pdf_bytes),
            mimetype='application/pdf',
            as_attachment=True,
            download_name='resume_ranking_report.pdf'
        )

    except Exception as e:
        logging.error("Error generating PDF: %s", e)
        return jsonify({"error": "Failed to generate PDF"}), 500

# === Run App ===
if __name__ == '__main__':
    print("🚀 Starting Flask Resume Ranker API...")
    app.run(debug=True, host='0.0.0.0', port=5000)