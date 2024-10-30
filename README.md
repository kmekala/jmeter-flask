# Running JMeter and Flask Mock API with Docker (Without docker-compose)
This guide provides step-by-step instructions for manually building and running the jmeter and flask_mock services using Docker commands. This is an alternative to using docker-compose.

# Prerequisites
Ensure you have Docker installed on your system.

## Steps
### 1. Build the Docker Images
You need to build Docker images for both the JMeter and Flask Mock API services.

## Build the flask_mock image:

## Flask Application:
```
The Flask app simulates diagnostic devices by providing mocked endpoints for testing purposes. It is configured to run inside a Docker container, ensuring a consistent environment.
```

```
docker build -t my-flask-mock -f Dockerfile .
```
```
This command builds the my-flask-mock image using the Dockerfile located in the current directory.
```
## Build the jmeter image:

```
docker build -t my-jmeter .
```
This command builds the my-jmeter image using the current directory as the build context.

## 2. Run the flask_mock Container
Run the flask_mock container and expose it on port 5000:

```
docker run -d --name flask_mock -p 5000:5000 my-flask-mock python3 /opt/flask/app.py
```

```
-d: Runs the container in detached mode.
--name flask_mock: Names the container flask_mock.
-p 5000:5000: Maps port 5000 of the container to port 5000 on the host.
my-flask-mock: The image we built earlier.
python3 /opt/flask/app.py: The command to run the Flask application.
```

## 3. Run the jmeter Container
After the flask_mock container is running, you can now run the jmeter container. This container will link to the flask_mock container:

```
docker run --name jmeter \
    -e TZ="UTC" \
    --link flask_mock \
    -v $(pwd)/tests:/opt/jmeter/tests \
    -v $(pwd)/reports:/opt/jmeter/results \
    my-jmeter /opt/jmeter/entrypoint.sh

 ```

```
--name jmeter: Names the container jmeter.
-e TZ="UTC": Sets the environment variable TZ to UTC.
--link flask_mock: Links the jmeter container to the flask_mock container to allow communication between them.
-v $(pwd)/tests:/opt/jmeter/tests: Mounts the local tests directory to /opt/jmeter/tests in the container.
-v $(pwd)/reports:/opt/jmeter/reports: Mounts the local reports directory to /opt/jmeter/reports in the container.
my-jmeter: The image we built earlier for jmeter.
/opt/jmeter/entrypoint.sh: The entrypoint script for the jmeter container.
```

# Project Structure
```
.
├── Dockerfile
├── README.md
├── app
│   ├── app.py
│   └── requirements.txt
├── docker-compose.yml
├── entrypoint.sh
└── tests
    └── poct_test_plan.jmx
```

# Components

```
Dockerfile: Defines the Docker image for the Flask application.
README.md: Documentation for the project.
app/: Contains the Flask application.
app.py: The main Flask application file.
requirements.txt: Python dependencies for the Flask app.
docker-compose.yml: Configuration for Docker Compose to set up services.
entrypoint.sh: Script to initialize and run the application.
tests/: Contains JMeter test plans.
poct_test_plan.jmx: JMeter test plan for performance testing.
```

# Setup Instructions

## Prerequisites
```
Docker
Docker Compose
```

# Getting Started

## Clone the repository:
```
git clone <repository-url>
cd <repository-directory>
```
