import base64
import datetime
import json

from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import padding


CF_SIGNED_URL_KEY_PAIR_ID = "K1T8R2X3Y7VJUM"
with open("private_key.pem", "rb") as key_file:
    CF_SIGNED_URL_PRIVATE_KEY = key_file.read()

# key pair id is expected to be str
# private key is expected to be bytes

# fix possible escaped newlines
CF_SIGNED_URL_PRIVATE_KEY = CF_SIGNED_URL_PRIVATE_KEY.replace(b'\\n', b'\n')


# or, define your own

def generate_cloudfront_signature(message: bytes, private_key: bytes):
    private_key_signer = serialization.load_pem_private_key(
        private_key,
        password=None,
        backend=default_backend()
    )
    return private_key_signer.sign(message, padding.PKCS1v15(), hashes.SHA1())


def make_cloudfront_policy(resource: str, expire_epoch_time: int):
    policy = {
        'Statement': [{
            'Resource': resource,
            'Condition': {
                'DateLessThan': {
                    'AWS:EpochTime': expire_epoch_time
                }
            }
        }]
    }
    return json.dumps(policy).replace(" ", "")


def url_base64_encode(data: bytes):
    return base64.b64encode(data).replace(b'+', b'-').replace(b'=', b'_').replace(b'/', b'~').decode('utf-8')


def url_base64_decode(data: bytes):
    return base64.b64encode(data).replace(b'-', b'+').replace(b'_', b'=').replace(b'~', b'/').decode('utf-8')


def generate_cloudfront_signed_url(url: str, expire_seconds: int):
    expire_epoch_time = (datetime.datetime.now() + datetime.timedelta(seconds=expire_seconds)).timestamp()
    expire_epoch_time = int(expire_epoch_time)
    policy = make_cloudfront_policy(url, expire_epoch_time)
    signature = generate_cloudfront_signature(policy.encode('utf-8'), CF_SIGNED_URL_PRIVATE_KEY)

    signed_url = f"{url}?" \
                 f"Policy={url_base64_encode(policy.encode('utf-8'))}&" \
                 f"Signature={url_base64_encode(signature)}&" \
                 f"Key-Pair-Id={CF_SIGNED_URL_KEY_PAIR_ID}"

    return signed_url


if __name__ == "__main__":

    resource_url = "https://cdn.iamrishabh.tech/output_video.mp4"
    signed_url = generate_cloudfront_signed_url(resource_url, 3600)  # Expires in 1 hour # time in seconds
    print(signed_url)