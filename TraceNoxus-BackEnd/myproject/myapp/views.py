from rest_framework.decorators import api_view, permission_classes
from django.contrib.auth.models import User
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Product
from .serializers import ProductSerializer, UserSerializer
from rest_framework import generics, permissions, viewsets, filters
from django.contrib.auth import authenticate
from rest_framework.views import APIView
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser
from rest_framework_simplejwt.tokens import RefreshToken
from django.core.mail import send_mail
import random
from django.core.cache import cache
from .models import Lesson 
from django.contrib.auth import get_user_model
from django.conf import settings
from django.utils import timezone
from .serializers import (
    UserRegistrationSerializer,
    OTPVerificationSerializer,
    LoginSerializer,
    UserListSerializer,
    ForgotPasswordResetSerializer,
    ForgotPasswordOtpVerifySerializer,
    ForgotPasswordRequestSerializer,
    LessonSerializer,

)

User = get_user_model()

@api_view(['GET'])
@permission_classes([AllowAny])
def health(request):
    return Response({'status': 'ok'})

@api_view(['GET'])
def product_list(request):
    products = Product.objects.all()
    serializer = ProductSerializer(products, many=True)
    return Response(serializer.data)

class ProductListCreate(generics.ListCreateAPIView):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
    permission_classes = [permissions.IsAuthenticated]

class ProductRetrieveUpdateDestroy(generics.RetrieveUpdateDestroyAPIView):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
    permission_classes = [permissions.IsAuthenticated]

class RegisterView(APIView):
    permission_classes = [AllowAny]
    serializer_class = UserSerializer

    def post(self, request):
        serializer = self.serializer_class(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            refresh = RefreshToken.for_user(user)
            return Response({
                'user': serializer.data,
                'refresh': str(refresh),
                'access': str(refresh.access_token),
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        identifier = request.data.get("email") or request.data.get("username")
        password = request.data.get("password")
        
        if not identifier or not password:
            return Response(
                {"error": "Both identifier (email or username) and password are required"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Try to find user by email or username
        try:
            if '@' in identifier:
                user = User.objects.get(email=identifier)
            else:
                user = User.objects.get(username=identifier)
        except User.DoesNotExist:
            return Response(
                {"error": "No account found with these credentials"},
                status=status.HTTP_404_NOT_FOUND
            )
            
        user = authenticate(request, username=user.username, password=password)

        if user:
            refresh = RefreshToken.for_user(user)
            return Response({
                "refresh": str(refresh),
                "access": str(refresh.access_token),
                "user": UserSerializer(user).data,
                "message": "Login successful"
            })
        return Response(
            {"error": "Invalid credentials. Please check your password and try again."},
            status=status.HTTP_401_UNAUTHORIZED
        )

class SendOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get("email")
        if not User.objects.filter(email=email).exists():
            return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)

        otp = random.randint(1000, 9999)
        cache.set(f"otp_{email}", otp, timeout=300)  # store OTP for 5 minutes

        try:
            send_mail(
                subject="Your OTP Code",
                message=f"Your OTP is {otp}",
                from_email="no-reply@example.com",
                recipient_list=[email],
            )
            return Response({"message": "OTP sent"})
        except Exception as e:
            return Response({"error": "Failed to send OTP"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class VerifyOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get("email")
        otp = request.data.get("otp")

        stored_otp = cache.get(f"otp_{email}")
        if stored_otp and str(stored_otp) == str(otp):
            cache.delete(f"otp_{email}")
            request.session['email'] = email
            return Response({"message": "OTP verified"})
        return Response({"error": "Invalid or expired OTP"}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET', 'PATCH'])
@permission_classes([IsAuthenticated])
def get_user_profile(request):
    user = request.user
    if request.method == 'GET':
        return Response({
            'name': user.username or "",
            'email': user.email or "",
            'profile_image_url': getattr(user, 'profile_image_url', "") or "",
            'age': getattr(user, 'age', None),
        })
    elif request.method == 'PATCH':
        data = request.data
        if 'name' in data:
            user.username = data['name']
        if 'age' in data:
            user.age = data['age']
        # Add profile_image_url update if needed
        user.save()
        return Response({
            'name': user.username or "",
            'email': user.email or "",
            'profile_image_url': getattr(user, 'profile_image_url', "") or "",
            'age': getattr(user, 'age', None),
        })

def generate_otp():
    return ''.join([str(random.randint(0, 9)) for _ in range(4)])

def send_otp_email(email, otp):
    subject = 'Your OTP for Account Verification'
    message = f'Your OTP is: {otp}. This OTP will expire in 5 minutes.'
    from_email = settings.EMAIL_HOST_USER
    recipient_list = [email]
    
    send_mail(subject, message, from_email, recipient_list)

@api_view(['POST'])
@permission_classes([AllowAny])
def register_user(request):
    # First, clean up any expired registrations
    User.delete_expired_registrations()
    
    print("Registration request data:", request.data)
    serializer = UserRegistrationSerializer(data=request.data)
    if serializer.is_valid():
        print("Serializer is valid")
        user = serializer.save()
        otp = generate_otp()
        user.otp = otp
        user.otp_created_at = timezone.now()
        user.save()
        
        try:
            print("Attempting to send email to:", user.email)
            send_otp_email(user.email, otp)
            return Response({
                'message': 'Registration successful. Please verify your email within 1 minute.'
            }, status=status.HTTP_201_CREATED)
        except Exception as e:
            print("Email error:", str(e))
            user.delete()
            return Response({
                'error': f'Failed to send OTP email: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    print("Serializer errors:", serializer.errors)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([AllowAny])
def verify_otp(request):
    # First, clean up any expired registrations
    User.delete_expired_registrations()
    
    serializer = OTPVerificationSerializer(data=request.data)
    if serializer.is_valid():
        email = serializer.validated_data['email']
        otp = serializer.validated_data['otp']
        
        try:
            user = User.objects.get(email=email)
            
            # Check if registration has expired
            if user.is_registration_expired():
                user.delete()
                return Response({
                    'error': 'Registration expired. Please register again.'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            if user.otp == otp and user.is_otp_valid():
                user.is_verified = True
                user.otp = None
                user.otp_created_at = None
                user.save()
                
                return Response({
                    'message': 'Account verified successfully. You can now login.'
                }, status=status.HTTP_200_OK)
            else:
                return Response({
                    'error': 'Invalid or expired OTP.'
                }, status=status.HTTP_400_BAD_REQUEST)
        except User.DoesNotExist:
            return Response({
                'error': 'User not found.'
            }, status=status.HTTP_404_NOT_FOUND)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([AllowAny])
def login_user(request):
    serializer = LoginSerializer(data=request.data)
    if serializer.is_valid():
        email = serializer.validated_data['email']
        password = serializer.validated_data['password']
        
        try:
            user = User.objects.get(email=email)
            if not user.is_verified:
                return Response({
                    'error': 'Please verify your email before logging in.'
                }, status=status.HTTP_403_FORBIDDEN)
            
            if user.check_password(password):
                refresh = RefreshToken.for_user(user)
                return Response({
                    'refresh': str(refresh),
                    'access': str(refresh.access_token),
                }, status=status.HTTP_200_OK)
            else:
                return Response({
                    'error': 'Invalid credentials.'
                }, status=status.HTTP_401_UNAUTHORIZED)
        except User.DoesNotExist:
            return Response({
                'error': 'User not found.'
            }, status=status.HTTP_404_NOT_FOUND)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class ProductViewSet(viewsets.ModelViewSet):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
    permission_classes = [IsAuthenticated]

class UserListView(generics.ListAPIView):
    """
    API endpoint that allows all users to be viewed.
    Only accessible by admin users.
    """
    queryset = User.objects.all().order_by('-date_joined')
    serializer_class = UserListSerializer
    permission_classes = [IsAdminUser]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['username', 'email', 'first_name', 'last_name']
    ordering_fields = ['date_joined', 'username', 'email', 'is_verified']

    def get_queryset(self):
        queryset = super().get_queryset()
        # Add query parameters for filtering
        is_verified = self.request.query_params.get('is_verified', None)
        is_superuser = self.request.query_params.get('is_superuser', None)
        is_active = self.request.query_params.get('is_active', None)

        if is_verified is not None:
            queryset = queryset.filter(is_verified=is_verified.lower() == 'true')
        if is_superuser is not None:
            queryset = queryset.filter(is_superuser=is_superuser.lower() == 'true')
        if is_active is not None:
            queryset = queryset.filter(is_active=is_active.lower() == 'true')

        return queryset

    def list(self, request, *args, **kwargs):
        response = super().list(request, *args, **kwargs)
        # Add summary statistics
        total_users = self.get_queryset().count()
        verified_users = self.get_queryset().filter(is_verified=True).count()
        superusers = self.get_queryset().filter(is_superuser=True).count()
        active_users = self.get_queryset().filter(is_active=True).count()

        response.data = {
            'total_users': total_users,
            'verified_users': verified_users,
            'superusers': superusers,
            'active_users': active_users,
            'results': response.data
        }
        return response
    
@api_view(['POST'])
@permission_classes([AllowAny])
def send_forgot_password_otp(request):
    serializer = ForgotPasswordRequestSerializer(data=request.data)
    if serializer.is_valid():
        email = serializer.validated_data['email']
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)

        otp = generate_otp()
        cache.set(f"forgot_otp_{email}", otp, timeout=300)  # 5 minutes

        try:
            send_mail(
                subject="Your OTP for Password Reset",
                message=f"Your OTP is {otp}",
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[email],
            )
            return Response({"message": "OTP sent"})
        except Exception as e:
            return Response({"error": "Failed to send OTP"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    else:
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([AllowAny])
def verify_forgot_password_otp(request):
    serializer = ForgotPasswordOtpVerifySerializer(data=request.data)
    if serializer.is_valid():
        email = serializer.validated_data['email']
        otp = serializer.validated_data['otp']
        stored_otp = cache.get(f"forgot_otp_{email}")
        if stored_otp and str(stored_otp) == str(otp):
            cache.delete(f"forgot_otp_{email}")
            request.session['reset_email'] = email  # <--- THIS LINE IS REQUIRED
            return Response({"message": "OTP verified"})
        return Response({"error": "Invalid or expired OTP"}, status=status.HTTP_400_BAD_REQUEST)
    else:
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([AllowAny])
def reset_password(request):
    print("Request data:", request.data)
    serializer = ForgotPasswordResetSerializer(data=request.data)
    if serializer.is_valid():
        email = request.data.get('email')
        if not email:
            return Response({"error": "Email is required"}, status=status.HTTP_400_BAD_REQUEST)
        new_password = serializer.validated_data['new_password']
        try:
            user = User.objects.get(email=email)
            user.set_password(new_password)
            user.save()
            return Response({"message": "Password reset successful"})
        except User.DoesNotExist:
            return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)
    else:
        print("Serializer errors:", serializer.errors)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def lesson_list(request):
    if request.method == 'GET':
        lessons = Lesson.objects.all()
        serializer = LessonSerializer(lessons, many=True)
        return Response(serializer.data)
    elif request.method == 'POST':
        serializer = LessonSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=201)
        return Response(serializer.errors, status=400)

class LessonViewSet(viewsets.ModelViewSet):
    queryset = Lesson.objects.all()
    serializer_class = LessonSerializer