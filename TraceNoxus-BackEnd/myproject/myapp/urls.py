from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    register_user,
    verify_otp,
    login_user,
    ProductViewSet,
    UserListView,
    send_forgot_password_otp,
    verify_forgot_password_otp,
    reset_password,
    LessonViewSet,
    lesson_list,
    health
)

router = DefaultRouter()
router.register(r'lessons', LessonViewSet, basename='lesson')

urlpatterns = [
    path('', include(router.urls)),
    path('health/', health, name='health'),
    path('register/', register_user, name='register'),
    path('verify-otp/', verify_otp, name='verify-otp'),
    path('login/', login_user, name='login'),
    path('users/', UserListView.as_view(), name='user-list'),
    path('send-forgot-password-otp/', send_forgot_password_otp, name='send-forgot-password-otp'),
    path('verify-forgot-password-otp/', verify_forgot_password_otp, name='verify-forgot-password-otp'),
    path('reset-password/', reset_password, name='reset-password'),
    path('lessons/', lesson_list, name='lesson-list'),
]