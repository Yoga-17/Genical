from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import google.generativeai as genai
import langflow
import os
from dotenv import load_dotenv

load_dotenv()

api_key = os.getenv("GOOGLE_API_KEY")
if not api_key:
    raise ValueError("GOOGLE_API_KEY is not set in the environment variables")

genai.configure(api_key=api_key)

app = FastAPI()


# Define request model
class QuestionRequest(BaseModel):
    question: str


async def get_response(question: str) -> str:
    model = genai.GenerativeModel("gemini-pro")
    agent = "Pharmacists"
    command = """Generate a response that is easy to understand for someone without a medical background. 
    Focus on providing details about the medicine's information, primary purpose, precautions or side effects, history, dosage, and common medical formula. 
    For the common formula, mention only one main chemical formula. 
    Ensure each answer is less than 50 words and easy to understand for someone without a medical background."""
    json_format = {
        "response": {
            "medicine_name": "string",
            "medicine_information": "string",
            "history": "string",
            "primary_purpose": "string",
            "precautions": "string",
            "chemical_formula": "string",
            "dosage": "string",
        }
    }

    question = f"You are {agent}. Follow these commands {command} for this medicine:{question}. Output in dictionary with this format {json_format} without triple quotes."
    try:

        from langflow import load_flow_from_json

        flow = load_flow_from_json("Genical.json")
        response = flow(question)
        return response
    except Exception as langflow_error:
        try:
            model = genai.GenerativeModel("gemini-pro")
            agent = "Pharmacists"
            command = """Generate a response that is easy to understand for someone without a medical background. 
Focus on providing details about the medicine's information, primary purpose, precautions or side effects, history, dosage, and common medical formula. 
For the common formula, mention only one main chemical formula. 
Ensure each answer is less than 50 words and easy to understand for someone without a medical background."""
            json_format = {
                "response": {
                    "medicine_name": "string",
                    "medicine_information": "string",
                    "history": "string",
                    "primary_purpose": "string",
                    "precautions": "string",
                    "chemical_formula": "string",
                    "dosage": "string",
                }
            }

            question = f"You are {agent}. Follow these commands {command} for this medicine:{question}. Output in dictionary with this format {json_format} without triple quotes."
            response = model.generate_content(question)
            response = " ".join(response.text.split())
            # Remove the surrounding square brackets
            if response.startswith("[") and response.endswith("]"):
                response = response[1:-1]
            return response
        except Exception as gemini_error:
            raise HTTPException(
                status_code=500,
                detail=f"LangFlow error: {langflow_error}. Gemini error: {gemini_error}",
            )


# Define endpoint to get response
@app.post("/get-response/")
async def get_response_endpoint(request: QuestionRequest):
    response = await get_response(request.question)
    return {"response": response}
