FROM python:3.10-slim

WORKDIR /app

# Copy requirements and install them
COPY requirements_gui.txt .
RUN pip install --no-cache-dir -r requirements_gui.txt

# Copy the rest of the application
COPY app.py .

# Expose port 8501 for Streamlit
EXPOSE 8501

# Command to run the application
CMD ["streamlit", "run", "app.py", "--server.address=0.0.0.0"]
