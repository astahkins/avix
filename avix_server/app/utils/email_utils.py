def send_verification_code(email: str, code: str) -> None:
    print(f"Код подтверждения для {email}: {code}")

    # Later replace this stub with real SMTP sending via smtplib:
    # create SMTP connection, authenticate, build MIME message, send email.
