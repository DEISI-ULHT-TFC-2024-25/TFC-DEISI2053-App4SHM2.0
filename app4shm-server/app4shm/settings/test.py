from .base import *

DATABASES = {
    "default": dj_database_url.config(
        default=config("TEST_DATABASE_URL", default="sqlite:///db.sqlite3"),
        conn_max_age=600,
    )
}