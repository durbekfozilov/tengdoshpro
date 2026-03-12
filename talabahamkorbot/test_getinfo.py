import requests

data = {
    "action": 1,
    "params": {
        "merchant_trans_id": "8000000085888"
    }
}

try:
    response = requests.post("http://127.0.0.1:8000/api/v1/payment/click/getinfo", json=data)
    print("STATUS:", response.status_code)
    print("RESPONSE:", response.text)
except Exception as e:
    print("ERROR:", e)

