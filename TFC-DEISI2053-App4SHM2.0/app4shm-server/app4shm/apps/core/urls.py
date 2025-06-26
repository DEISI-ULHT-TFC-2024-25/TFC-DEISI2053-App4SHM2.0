from django.urls import path
from django.conf.urls.static import static
from django.conf import settings
from rest_framework.authtoken import views as rest_views
from . import views
from .views import CreateNetworkView, JoinNetworkView, NetworkInfoView, NetworkStatusView, NetworkReadingsView, \
    DisconnectNetworkView, DeleteNetworkView

urlpatterns = [
    path("", views.index),
    path("api/structures/", views.StructureList.as_view(), name="api-structures"),
    path("api/readings/", views.TimeSeriesList.as_view(), name="api-readings"),
    path("api/frequencies/", views.NaturalFrequenciesList.as_view(), name="api-frequencies"),
    path("api/cable-force/", views.CableForceList.as_view(), name="api-cable_force"),
    path('network/create/', CreateNetworkView.as_view(), name='create-network'),
    path('network/join/', JoinNetworkView.as_view(), name='join-network'),
    path('network/info/', NetworkInfoView.as_view(), name='network-info'),
    path('network/set-status/', NetworkStatusView.as_view(), name='network-status'),
    path('network/readings/', NetworkReadingsView.as_view(), name='network-readings'),
    path('network/disconnect/', DisconnectNetworkView.as_view(), name='disconnect-network'),
    path('network/delete/', DeleteNetworkView.as_view(), name='delete-network'),
    path('api-token-auth/', rest_views.obtain_auth_token)
]

urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
