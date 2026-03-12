import aiohttp
import io
import json

async def upload_pdf_to_hemis(student_token: str, pdf_buffer: io.BytesIO, filename: str = "faollik.pdf") -> str:
    """Uploads a PDF to HEMIS platform and returns the file URL/ID"""
    
    # URL based on Swagger docs for file upload
    url = "https://student.jmcu.uz/rest/v1/education/task-upload"
    headers = {
        "Authorization": f"Bearer {student_token}",
        "Accept": "application/json"
    }
    
    data = aiohttp.FormData()
    data.add_field('comment', 'Ijtimoiy faollik asosi')
    # Use the PDF buffer
    data.add_field('filename[]', pdf_buffer.getvalue(), filename=filename, content_type='application/pdf')
    
    async with aiohttp.ClientSession() as session:
        async with session.post(url, headers=headers, data=data) as response:
            try:
                result = await response.json()
                print(f"[HEMIS UPLOAD RESULT] HTTP {response.status}: {result}")
                
                if response.status == 200 and result.get("success"):
                    # Based on standard hemis file upload response, it usually returns data inside data list
                    data_obj = result.get("data", [])
                    if isinstance(data_obj, list) and len(data_obj) > 0:
                         return data_obj[0].get("url", "")
                    elif isinstance(data_obj, dict):
                         return data_obj.get("url", "")
            except Exception as e:
                print(f"[HEMIS UPLOAD ERROR] {e}")
            return ""

async def submit_social_activity_to_hemis(student_token: str, name: str, description: str, date: str, criteria_id: int, pdf_url: str):
    """"
    Creates social activity and updates criteria with PDF url
    """
    
    # 1. Create Application
    create_url = "https://student.jmcu.uz/rest/v1/social-activity/application-create"
    headers = {
        "Authorization": f"Bearer {student_token}",
        "Accept": "application/json",
        "Content-Type": "application/json"
    }
    
    create_payload = {
        "name": name,
        "description": description,
        "application_date": date,
        "criteria": [
            {
                "criteria_id": criteria_id
            }
        ]
    }
    
    async with aiohttp.ClientSession() as session:
        async with session.post(create_url, headers=headers, json=create_payload) as response:
            create_result = await response.json()
            print(f"[HEMIS CREATE APP RESULT] {create_result}")
            
            if not create_result.get("success"):
                return {"success": False, "error": "Application creation failed", "details": create_result}
                
            app_data = create_result.get("data", {})
            # Depending on response, we might get back the ID of the criteria to update
            # We assume it returns an array of criteria with their IDs
            created_criteria = app_data.get("criteria", [])
            
            if not created_criteria:
                # Some APIs return simple success
                pass 

    # 2. Update Criteria with Basis (PDF URL)
    # The Swagger said: POST /v1/social-activity/criteria-update
    # Requires: id (integer), point (number), basis (string)
    
    # We need the ID of the created criteria. If it's in created_criteria:
    if created_criteria:
        criteria_update_id = created_criteria[0].get("id")
        
        update_url = "https://student.jmcu.uz/rest/v1/social-activity/criteria-update"
        update_payload = {
            "id": criteria_update_id,
            "point": 0, # usually tutor sets points or it has a max
            "basis": f"Ilova orqali yuborilgan: {pdf_url}" if pdf_url else description
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(update_url, headers=headers, json=update_payload) as update_response:
                update_result = await update_response.json()
                print(f"[HEMIS UPDATE CRITERIA RESULT] {update_result}")
                
    return {"success": True, "message": "Synced with HEMIS"}

