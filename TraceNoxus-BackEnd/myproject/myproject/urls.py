"""
URL configuration for myproject project.
Main URL routing configuration that includes app-specific URLs.
"""
from django.contrib import admin
from django.urls import path, include
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from django.views.generic import RedirectView
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView, SpectacularRedocView
from myapp.views import send_forgot_password_otp, verify_forgot_password_otp, reset_password, get_user_profile

urlpatterns = [
    # Django admin interface
    path('admin/', admin.site.urls),
    
    # API endpoints
    path('api/', include('myapp.urls')),
    
    # JWT authentication endpoints
    path('api/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    
    # API Schema and Documentation
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),
    path('api/send-forgot-password-otp/', send_forgot_password_otp, name='send-forgot-password-otp'),
    path('api/verify-forgot-password-otp/', verify_forgot_password_otp, name='verify-forgot-password-otp'),
    path('api/reset-password/', reset_password, name='reset-password'),
    # Redirect root URL to Swagger UI
    path('', RedirectView.as_view(url='/api/docs/', permanent=False)),
    path('api/user/', get_user_profile, name='get-user-profile'),
]
