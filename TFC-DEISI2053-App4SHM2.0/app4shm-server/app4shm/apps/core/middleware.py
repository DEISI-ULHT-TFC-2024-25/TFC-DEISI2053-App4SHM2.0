import logging


class RequestLoggingMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)
        self.log_request(request)
        return response

    def log_request(self, request):
        logger = logging.getLogger('django.request')
        logger.info(f"{request.method} {request.path} [{request.user}]")
