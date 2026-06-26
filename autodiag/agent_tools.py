import re

def extract_dtc_codes(text):
    codes = re.findall(r'\b[PBCU][0-9]{4}\b', text.upper())
    return list(set(codes))

def full_diagnosis():
    from obd_module import get_obd_data, format_obd_data
    data = get_obd_data()
    return format_obd_data(data)

def get_screen_text():
    return ""
