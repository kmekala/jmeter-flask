# app.py
from flask import Flask, jsonify, request

app = Flask(__name__)

# Mock Hemostasis Device API: Get test results
@app.route('/hemostasis/device/<device_id>/results', methods=['GET'])
def get_hemostasis_results(device_id):
    response = {
        "device": "ACL TOP Family",
        "device_id": device_id,
        "tests": {
            "D-Dimer": 0.35,
            "Fibrinogen": 3.2,
            "PT/INR": 1.1
        },
        "status": "completed"
    }
    return jsonify(response), 200

# Mock POCT Device API: Get test results
@app.route('/poct/device/<device_id>/results', methods=['GET'])
def get_poct_results(device_id):
    response = {
        "device": "GEM Premier 5000",
        "device_id": device_id,
        "tests": {
            "Blood Gas": 7.4,
            "Lactate": 1.8
        },
        "status": "completed"
    }
    return jsonify(response), 200

# Mock POCT Device API: Calibrate the device
@app.route('/poct/device/<device_id>/calibration', methods=['POST'])
def calibrate_poct_device(device_id):
    response = {
        "device_id": device_id,
        "calibration_status": "success",
        "message": "Device has been calibrated successfully"
    }
    return jsonify(response), 200

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)