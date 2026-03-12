import requests
import time
import hashlib
import os

from config import CLICK_SECRET_KEY, CLICK_SERVICE_ID

# Mock data
click_trans_id = "1234568"
service_id = CLICK_SERVICE_ID
click_paydoc_id = "987655"
merchant_trans_id = "8000000085888" 
amount = "10000"
action = 0
sign_time = "2026-03-11 12:00:00"

raw = f"{click_trans_id}{service_id}{CLICK_SECRET_KEY}{merchant_trans_id}{amount}{action}{sign_time}"
sign_string = hashlib.md5(raw.encode('utf-8')).hexdigest()

data = {
    "click_trans_id": click_trans_id,
    "service_id": service_id,
    "click_paydoc_id": click_paydoc_id,
    "merchant_trans_id": merchant_trans_id,
    "amount": amount,
    "action": action,
    "error": 0,
    "error_note": "",
    "sign_time": sign_time,
    "sign_string": sign_string
}

try:
    response = requests.post("http://127.0.0.1:8000/api/v1/payment/click", data=data)
    print("STATUS:", response.status_code)
    print("RESPONSE:", response.text)
except Exception as e:
    print("ERROR:", e)

