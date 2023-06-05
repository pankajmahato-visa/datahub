from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import smtplib

from .config import *
from .converter import *
# for testing purpose import this file
# from .inputs import *

class Reporter:
    #Initalize the class with the data
    def __init__(self,data):
        self.data=data
        self.headings=[]
    
    #Generate Headings for Table
    def get_heading(self,key):
        if self.data[key]:
            text ="<table>"
            text += "<tr>"
            for key in self.data[key][0].keys():
                text += f"<th>{key}</th>"
                self.headings.append(key)
            text += "</tr>"
            return text
        else:
            return "No attributes to show in Database "

    #Generate Rows for Table
    def get_rows(self,key):
        if self.data[key]:
            text = ""
            for item in self.data[key]:
                text += "<tr>"
                for value in self.headings:
                    text += f"<td>{item[value]}</td>"
                text += "</tr>"
            self.headings=[]
            text+="</table>"
            return text
        else:
            " "


    #Generate Tables
    def get_tables(self):
        if self.data:
            text=""
            for key in self.data:
                text+=f"""
                <h2>
                Dataset Name:-{key}
                </h2>
                {self.get_heading(key)}
                {self.get_rows(key)}
                """
            return text
        else:
            return "NO DATABASE CHANGED"
        

    # Initialise message instance in HTML format
    def make_message(self):
        msg = MIMEMultipart()
        msg["Subject"] = SUBJECT
        msg["From"] = FROMADDR
        msg["To"] = ", ".join(TOADDRS)
        # Plain text
        text = f"""\
        {STYLE}
        <h1>
        THE REPORT OF FIELDS
        Date:- {today_date}
        </h1>
        {self.get_tables()}
        """

        body_text = MIMEText(text, "html")  #
        msg.attach(body_text)  # attaching the text body into msg
        return msg


    #Send mail on outlook
    def send_mail(self,smtp_session, msg):
        try:
            smtp_session.sendmail(FROMADDR, TOADDRS, msg.as_string())
            smtp_session.quit()
            print("Mail sent Succesfully")
        except Exception as e:
            print(e)


    def send_message(self,smtp_session):
        # listToJSON(self.data)  #Saving data in JSON File in local Repo
        msg = self.make_message()
        self.send_mail(smtp_session, msg)


    def send_report(self):
        with smtplib.SMTP(host=SMTP_HOST, port=SMTP_PORT) as smtp_session:
            self.send_message(smtp_session)
