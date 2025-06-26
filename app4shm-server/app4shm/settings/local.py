from .base import *

SECRET_KEY = 'django-insecure-og9(ir*f=#9hg0enw)9enh5(@0n$k8jl^v9xp@0pkb4&dzo5pd'

# DATABASES = {
#     'default': {
#         'ENGINE': 'django.db.backends.sqlite3',
#         'NAME': BASE_DIR / 'db.sqlite3',
#     }
# }

LOGGING = {
   'version': 1,
   'disable_existing_loggers': False,
   'formatters': {
        'simple': {
            'format': '[{levelname}] [{asctime}] {message}',
            'style': '{',
        },
    },
   'handlers': {
      'console': {
         'class': 'logging.StreamHandler',
         'formatter': 'simple'
      },
      'file': {
         'level': 'DEBUG',
         'class': 'logging.FileHandler',
         'filename': 'debug.log',
      },
   },
   'root': {
        'handlers': ['console'],
        'level': 'INFO',
    },
   'loggers': {
      'django': {
         'handlers': ['console'],
         'level': 'INFO',
         'propagate': True,
      },
      'django.request': {
         'handlers': ['console'],
         'level': 'DEBUG',
         'propagate': True,
      },
   },
}