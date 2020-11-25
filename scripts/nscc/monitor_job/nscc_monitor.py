import smtplib
from email.mime.text import MIMEText
from email.header import Header
import subprocess
import time
import argparse
import datetime
import logging

FROM_ADDR = '@163.com'
PASSWORD = ''
SMTP_SERVER = 'smtp.163.com'


def send_email(server, to_addr, job_id):
    current_time = datetime.datetime.now()
    content = 'Job {} is currently running. Detected at {}'.format(
        job_id, current_time)
    msg = MIMEText(content, 'plain', 'utf-8')

    msg['From'] = Header(FROM_ADDR)
    msg['To'] = Header(to_addr)
    msg['Subject'] = Header('Your NSCC Job is Running')
    server.sendmail(FROM_ADDR, to_addr, msg.as_string())
    server.quit()


def listen_to_qstat(job_id, interval=600):
    logging.info("Start listening for {}".format(job_id))
    while True:
        qstat_info = subprocess.getoutput('qstat')
        qstat_info = qstat_info.split('\n')
        for line in qstat_info:
            if job_id in line and line.split()[-2] == "R":
                logging.info("Detected job start for: {}".format(job_id))
                return

        time.sleep(interval)


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--job", type=str)
    parser.add_argument("--interval", type=int, default=600)
    parser.add_argument("--email", type=str)
    return parser.parse_args()


def main():
    args = parse_args()
    logging.basicConfig(
        filename="./monitor_{}.log".format(args.job), level=logging.DEBUG)
    logging.info("Setting up server")

    # set up email server
    server = smtplib.SMTP_SSL(host=SMTP_SERVER)
    server.connect(host=SMTP_SERVER, port=465)
    server.login(FROM_ADDR, PASSWORD)

    listen_to_qstat(args.job, args.interval)
    send_email(server, args.email, args.job)


if __name__ == "__main__":
    main()
