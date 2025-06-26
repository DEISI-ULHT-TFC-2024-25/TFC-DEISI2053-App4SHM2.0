import sentry_sdk
from sentry_sdk.integrations.django import DjangoIntegration

# import app4shm
import logging
from .base import *

# ==============================================================================
# SECURITY SETTINGS
# ==============================================================================

CSRF_COOKIE_SECURE = True
CSRF_COOKIE_HTTPONLY = True

SECURE_HSTS_SECONDS = 60 * 60 * 24 * 7 * 52  # one year
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SECURE_SSL_REDIRECT = True
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")

SESSION_COOKIE_SECURE = True

DEBUG=False

ALLOWED_HOSTS = ['deisi.ulusofona.pt']

STATIC_URL = '/shm/static/'

WHITENOISE_STATIC_PREFIX = '/static/'

# this is handled directly by apache
MEDIA_URL = '/shm-media/'

TIME_ZONE = 'Europe/Lisbon'

LOGGING = {
    'version': 1, # Version of logging
    'disable_existing_loggers': False, #disable logging
    'formatters': {
        'simple': {
            'format': '[{levelname}] [{asctime}] {message}',
            'style': '{',
        },
    },
    'handlers': {
        'file': {
            'level': 'DEBUG',
            'class': 'logging.FileHandler',
            'filename': f'/opt/django/app4shm-server/logs/app4shm.log',
            'formatter': 'simple'
        }
    },
    'root': {
        'handlers': ['file'],
        'level': 'INFO',
    },
    'loggers': {
        'django': {
            'handlers': ['file'],
            'level': 'INFO',
            'propagate': True,
        },
        'django.request': {
            'handlers': ['file'],
            'level': 'DEBUG',
            'propagate': True,
        },
    },
}

# ==============================================================================
# THIRD-PARTY APPS SETTINGS
# ==============================================================================

# sentry_sdk.init(
#     dsn=config("SENTRY_DSN", default=""),
#     environment=SIMPLE_ENVIRONMENT,
#     release="app4shm@%s" % app4shm.__version__,
#     integrations=[DjangoIntegration()],
# )