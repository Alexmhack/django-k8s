FROM python:3.10.14-slim

COPY . /app/

WORKDIR /app/

RUN apt-get update && \
	apt-get install -y \
	python3-dev \
	gcc \
	libpq-dev \
	python3-setuptools \
	make \
	build-essential

RUN python3.10 -m venv /opt/venv && \
	/opt/venv/bin/python -m pip install --upgrade pip && \
	/opt/venv/bin/python -m pip install -r requirements.txt

RUN apt-get remove -y --purge gcc build-essential && \
	apt-get autoremove -y && \
	rm -rf /var/lib/apt/lists*

RUN chmod +x entrypoint.sh

CMD ["/app/entrypoint.sh"]  # CMD / ENTRYPOINT
