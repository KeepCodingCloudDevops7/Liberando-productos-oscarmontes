FROM python:3.8.11-alpine3.14

WORKDIR /service/app
ADD ./src/ /service/app/
COPY requirements.txt /service/app/

RUN apk --no-cache add curl build-base npm
RUN pip install --root-user-action=ignore --upgrade pip 
RUN pip install --root-user-action=ignore -r requirements.txt

ENV PATH="/home/myuser/.local/bin:${PATH}"

EXPOSE 8081

ENV PYTHONUNBUFFERED 1

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=5 \
    CMD curl -s --fail http://localhost:8081/health || exit 1

CMD ["python3", "-u", "app.py"]