from saml2.entity_category.edugain import COC
from saml2 import BINDING_HTTP_REDIRECT
from saml2 import BINDING_PAOS
from saml2.saml import NAME_FORMAT_BASIC
from saml2.saml import NAMEID_FORMAT_UNSPECIFIED1

BASE = 'https://{{ KEYSTONE_PUBLIC_SERVICE_HOST }}'
PATH = '/v3/OS-FEDERATION/identity_providers/ipsilon/protocols/saml2/auth'
URL = BASE + PATH


CONFIG = {
    "entityid": URL,
    # 'entity_category': [COC],
    "description": "ECP Authentication to OpenStack",
    "service": {
        "sp": {
            "authn_requests_signed": True,
            "logout_requests_signed": True,
            "name_id_format": NAMEID_FORMAT_UNSPECIFIED1,
            "endpoints": {
                "assertion_consumer_service": [
                    ("%s/paosResponse" % URL, BINDING_PAOS)
                ],
                # "single_logout_service": [
                #     ("%s/logout" % URL, BINDING_HTTP_REDIRECT)
                # ],
            }
        },
    },
    "key_file": "metadata.key",
    "cert_file": "metadata.cert",
    "metadata": {"local": ["idp-metadata.xml"]},
}
