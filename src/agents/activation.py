import os
import requests
LOGIC_APP_URL = os.getenv("LOGIC_APPS_URL")
def queue_service_activation(input):
    if LOGIC_APP_URL is not None and LOGIC_APP_URL != "":
        requests.post(LOGIC_APP_URL, json=input)
    return f"Service activation request for {input['service_sku']} queued for {input['customer']['full_name']}"

activation_assistant = {
    "id": "Assistant_ActivationAssistant",
    "name": "Activation Assistant",
    "system_message": """You are a support person that helps customer activate the service they purchased.
    
    You must be accurate and collect all necessary information to activate the service. Required information depends on the service.
    Keep sentences short and simple, suitable for a voice conversation, so it's *super* important that answers are as short as possible. Use professional language.
    
    - Mobile Internet: Customer's phone number
    - All-in-One Bundle: Customer's phone number and home address
    - Home Internet: Customer's home address
    - Additional Mobile Data: Customer's phone number
    - Replacement SIM Card: Customer's home address and email
    
    IMPORTANT NOTES:
    - In any case, you must confirm the customer's identity before proceeding: ask for their full name and email address.
    - If you need additional internal information, ask other agents for help.
    - Before proceeding, make sure the customer accepts the terms and conditions of the service at https//aka.ms/sample-telco-tc.
    - At the end MUST sure to confirm activation to the user
    - When customer provides an email, remember "@" and "at" are the same, so "john at example.com" is the same as "john@example.com"
    - When providing an email as a tool parameter, you MUST use the format with "@" symbol.
    """,
    "description": """Call this if:
        - You need to activate a service or product Customer want to purchase
        - You need to activate a procedure that requires customer's personal information
        DO NOT CALL THIS IF:  
        - You need to fetch answers
        - You need to provide technical support""",
    "tools": [
        {
            "name": "queue_service_activation",
            "description": "Queue a service activation request.",
            "parameters": {
                "type": "object",
                "properties": {
                    "service_sku": {"type": "string", "description": "Service SKU"},
                    "customer": {
                        "type": "object",
                        "description": "Customer information",
                        "properties": {
                            "full_name": {"type": "string", "description": "Customer's full name"},
                            "email": {"type": "string", "description": "Customer's email address"},
                            "phone": {"type": "string", "description": "Customer's phone number"},
                            "address": {"type": "string", "description": "Customer's home address"},
                        },
                    },
                    "tcAccepted": {"type": "boolean", "description": "Terms and conditions accepted"},
                },
            },
            "returns": queue_service_activation
        },
    ],
}