FROM python:3.10.0-alpine as builder
ENV PYTHONUNBUFFERED 1
ENV PYTHONDONTWRITEBYTECODE 1

RUN apk update && apk upgrade && \
    apk add --no-cache bash git gcc openssl-dev libffi-dev postgresql-dev python3-dev musl-dev cargo

RUN pip install --upgrade pip

RUN mkdir /code
WORKDIR /code
ADD requirements.txt /code/

RUN pip wheel --no-cache-dir --wheel-dir /code/wheels -r requirements.txt

FROM python:3.10.0-alpine
ENV PYTHONUNBUFFERED 1
ENV PYTHONDONTWRITEBYTECODE 1

RUN addgroup -S ocl && adduser -S ocl -G ocl

ENV APP_HOME=/code

RUN mkdir -p $APP_HOME /temp /staticfiles

RUN chown -R ocl:ocl $APP_HOME /temp /staticfiles

WORKDIR $APP_HOME

RUN apk update && apk upgrade && apk add --no-cache libpq bash curl

RUN pip install --upgrade pip

COPY --from=builder /code/wheels /wheels
COPY --from=builder /code/requirements.txt .
RUN pip install --no-cache /wheels/*
RUN rm -rf /wheels

ADD --chown=ocl:ocl . $APP_HOME

USER ocl

RUN chmod +x set_build_version.sh wait_for_it.sh startup.sh start_celery_worker.sh ping_celery_worker.sh start_flower.sh

ARG SOURCE_COMMIT

RUN ["bash", "-c", "./set_build_version.sh"]

EXPOSE 8000

CMD ["bash", "-c", "./startup.sh"]
