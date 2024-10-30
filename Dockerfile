# Start with an Ubuntu base image
FROM ubuntu:20.04

# Set environment variables for non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install dependencies (Java, wget, curl, Chromium, Flask, Python3, Pip)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    openjdk-11-jre-headless \
    wget \
    curl \
    chromium-driver \
    python3 \
    python3-pip \
    tzdata && \
    rm -rf /var/lib/apt/lists/*

# Set environment variables for JMeter
ENV JMETER_VERSION=5.5
ENV JMETER_HOME=/opt/jmeter
ENV PATH=$JMETER_HOME/bin:$PATH

# Download and install JMeter
RUN wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz && \
    tar -xzf apache-jmeter-${JMETER_VERSION}.tgz -C /opt && \
    mv /opt/apache-jmeter-${JMETER_VERSION} /opt/jmeter && \
    rm apache-jmeter-${JMETER_VERSION}.tgz

# Install the JMeter Plugins Manager
RUN curl -L https://jmeter-plugins.org/get/ -o /tmp/plugins-manager.jar && \
    mkdir -p /opt/jmeter/lib/ext && \
    mv /tmp/plugins-manager.jar /opt/jmeter/lib/ext/

# Install Flask and dependencies for the mock API
COPY app/requirements.txt /opt/flask/requirements.txt

# Ensure Werkzeug is downgraded to 2.0.3 to prevent compatibility issues with Flask
RUN pip3 install --no-cache-dir werkzeug==2.0.3

# Install the rest of the Python dependencies for the Flask app
RUN pip3 install --no-cache-dir -r /opt/flask/requirements.txt

# Set the working directory
WORKDIR /opt/jmeter

# Copy the tests folder into the container
COPY tests/ /opt/jmeter/tests/

# Copy the Flask application folder
COPY app/ /opt/flask/

# Copy the entrypoint script into the container
COPY entrypoint.sh /opt/jmeter/entrypoint.sh

# Make the entrypoint script executable
RUN chmod +x /opt/jmeter/entrypoint.sh

# Expose Flask port
EXPOSE 5000

# Set the entrypoint for the container
ENTRYPOINT ["/opt/jmeter/entrypoint.sh"]