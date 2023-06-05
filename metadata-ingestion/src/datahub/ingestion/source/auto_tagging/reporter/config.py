from datetime import date
FROMADDR = ""

TOADDRS = ["",]
SMTP_HOST = "corpportal.visa.com"
SMTP_PORT = 25
DUMMY_DATA_PATH = "custom_source/src/reporter/dummy_data.json"
DATA_STORE_PATH = "test.json"

today_date = date.today().strftime("%d/%m/%Y")
SUBJECT = f"Reports from Datahub {today_date}"
STYLE= f"""
    <style>
        table {{
        font-family: arial, sans-serif;
        border-collapse: collapse;
        width: 100%;
        }}

        td, th {{
        border: 1px solid #dddddd;
        text-align: left;
        padding: 8px;
        }}

        tr:nth-child(even) {{
        background-color: #dddddd;
        }}
    </style>
"""
