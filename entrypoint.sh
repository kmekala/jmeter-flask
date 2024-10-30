#!/bin/bash

# Function to log messages with timestamp
log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1"
}

# Set the timezone to the value passed as an environment variable (if any)
if [ -n "$TZ" ]; then
    log "Setting timezone to $TZ"
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
    echo "$TZ" > /etc/timezone
else
    log "Using default timezone: $(date)"
fi

# Start the Flask mock API in the background
log "Starting Flask mock API..."
python3 /opt/flask/app.py &
sleep 5  # Wait for Flask API to be ready

# Get the current timestamp and create directories for results and reports
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULTS_DIR=${RESULTS_DIR:-"/opt/jmeter/results/$TIMESTAMP"}
HTML_REPORT_DIR="$RESULTS_DIR/html-report"
TMP_JTL_DIR="$RESULTS_DIR/tmp-jtl"
mkdir -p "$RESULTS_DIR" "$HTML_REPORT_DIR" "$TMP_JTL_DIR"

log "Results will be saved in $RESULTS_DIR"
log "Creating directories for HTML reports and temporary JTL files"

# Temporary file to store JTL file paths for later combination
JTL_FILE_LIST="$RESULTS_DIR/jtl_file_list.txt"
touch "$JTL_FILE_LIST"

# Common JMeter properties to ensure consistent output
JMETER_COMMON_OPTS="-Jjmeter.save.saveservice.timestamp_format=ms \
                    -Jjmeter.save.saveservice.output_format=csv \
                    -Jjmeter.save.saveservice.assertion_results=all \
                    -Jjmeter.save.saveservice.successful=true \
                    -Jjmeter.save.saveservice.label=true \
                    -Jjmeter.save.saveservice.response_code=true \
                    -Jjmeter.save.saveservice.response_message=true \
                    -Jjmeter.save.saveservice.thread_name=true \
                    -Jjmeter.save.saveservice.bytes=true \
                    -Jjmeter.save.saveservice.sent_bytes=true \
                    -Jjmeter.save.saveservice.latency=true \
                    -Jjmeter.save.saveservice.idleTime=true \
                    -Jjmeter.save.saveservice.connectTime=true \
                    -Duser.timezone=$TZ"

# Function to run individual JMeter tests
run_test() {
    local TEST_PLAN=$1
    local TEST_NAME=$(basename "$TEST_PLAN" .jmx)
    local JTL_FILE="$TMP_JTL_DIR/${TEST_NAME}.jtl"
    
    log "Running test: $TEST_NAME ..."
    jmeter $JMETER_COMMON_OPTS -n -t "$TEST_PLAN" -l "$JTL_FILE"
    
    if [ $? -eq 0 ]; then
        log "$TEST_NAME completed. Results saved in $JTL_FILE"
    else
        log "Error: Failed to run $TEST_NAME."
        exit 1
    fi

    # Generate HTML report for this test
    HTML_REPORT_SUBDIR="$HTML_REPORT_DIR/${TEST_NAME}-report"
    jmeter -g "$JTL_FILE" -o "$HTML_REPORT_SUBDIR"
    
    if [ $? -eq 0 ]; then
        log "HTML report for $TEST_NAME generated at $HTML_REPORT_SUBDIR"
    else
        log "Error: Failed to generate HTML report for $TEST_NAME."
        exit 1
    fi

    # Record the path of the JTL file for later combination
    echo "$JTL_FILE" >> "$JTL_FILE_LIST"
}

# Export function for parallel execution
export -f run_test
export TMP_JTL_DIR HTML_REPORT_DIR JTL_FILE_LIST JMETER_COMMON_OPTS

# Run tests either in parallel or sequentially
if [ "$PARALLEL" = true ]; then
    log "Running tests in parallel..."
    find /opt/jmeter/tests/ -name "*.jmx" | xargs -n 1 -P 4 -I {} bash -c 'run_test "$@"' _ {}
else
    log "Running tests sequentially..."
    for TEST_PLAN in /opt/jmeter/tests/*.jmx; do
        run_test "$TEST_PLAN"
    done
fi

# Combine all JTL files into a single combined report
COMBINED_JTL="$RESULTS_DIR/combined-report.jtl"

# Add the header from the first file and concatenate the rest without headers
log "Combining JTL files into one report..."
FIRST_FILE=true
while read -r JTL; do
    if [ "$FIRST_FILE" = true ]; then
        cat "$JTL" > "$COMBINED_JTL"
        FIRST_FILE=false
    else
        tail -n +2 "$JTL" >> "$COMBINED_JTL"
    fi
done < "$JTL_FILE_LIST"

# Generate a combined HTML report
log "Generating combined HTML report..."
jmeter -g "$COMBINED_JTL" -o "$HTML_REPORT_DIR/combined-report"

if [ $? -eq 0 ]; then
    log "Combined HTML report generated at $HTML_REPORT_DIR/combined-report"
else
    log "Error: Failed to generate combined HTML report."
    exit 1
fi

# Move results to the desired directory
FINAL_REPORT_DIR="/werfen-jmeter-flask/reports/$TIMESTAMP"
log "Moving results to final directory: $FINAL_REPORT_DIR"
mkdir -p "$FINAL_REPORT_DIR"
cp -r "$RESULTS_DIR"/* "$FINAL_REPORT_DIR"

# Clean up temporary files
log "Cleaning up temporary files..."
rm -rf "$TMP_JTL_DIR" "$JTL_FILE_LIST"

log "All tests completed successfully!"