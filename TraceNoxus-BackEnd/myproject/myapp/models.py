from django.db import models
from django.contrib.auth.models import AbstractUser
from django.utils import timezone
from datetime import timedelta

# Create your models here.

class CustomUser(AbstractUser):
    email = models.EmailField(unique=True)
    is_verified = models.BooleanField(default=False)
    otp = models.CharField(max_length=4, null=True, blank=True)
    otp_created_at = models.DateTimeField(null=True, blank=True)
    registered_at = models.DateTimeField(auto_now_add=True)
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']

    def __str__(self):
        return self.email

    def is_otp_valid(self):
        if self.otp_created_at is None:
            return False
        now = timezone.now()
        time_diff = now - self.otp_created_at
        return time_diff.total_seconds() <= 300  # OTP valid for 5 minutes

    def is_registration_expired(self):
        """Check if unverified registration has expired (1 minute)"""
        if self.is_verified:
            return False
        now = timezone.now()
        time_diff = now - self.registered_at
        return time_diff.total_seconds() > 60  # 1 minute expiry

    @classmethod
    def delete_expired_registrations(cls):
        """Delete all unverified accounts that are older than 1 minute"""
        expiry_time = timezone.now() - timedelta(minutes=1)
        cls.objects.filter(
            is_verified=False,
            registered_at__lt=expiry_time
        ).delete()

    class Meta:
        db_table = 'myapp_customuser'

class Product(models.Model):
    name = models.CharField(max_length=100)
    price = models.DecimalField(max_digits=6, decimal_places=2)
    description = models.TextField()

class Lesson(models.Model):
    code = models.CharField(max_length=20)
    title = models.CharField(max_length=100)
    teacher = models.CharField(max_length=100)
    # Each lesson can have multiple questions (flashcard style)

class Question(models.Model):
    lesson = models.ForeignKey(Lesson, related_name='questions', on_delete=models.CASCADE)
    text = models.CharField(max_length=255)
    answer = models.CharField(max_length=255) 