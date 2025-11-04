from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import Product
from .models import Lesson
from .models import Question

User = get_user_model()

class UserRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    
    class Meta:
        model = User
        fields = ('email', 'username', 'password')
    
    def create(self, validated_data):
        user = User.objects.create_user(
            email=validated_data['email'],
            username=validated_data['username'],
            password=validated_data['password'],
            is_verified=False
        )
        return user
    

class ForgotPasswordRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()

class ForgotPasswordOtpVerifySerializer(serializers.Serializer):
    email = serializers.EmailField()
    otp = serializers.CharField(max_length=4)

class ForgotPasswordResetSerializer(serializers.Serializer):
    email = serializers.EmailField()
    new_password = serializers.CharField(min_length=6)

class OTPVerificationSerializer(serializers.Serializer):
    email = serializers.EmailField()
    otp = serializers.CharField(max_length=4)

class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField()

class ProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = '__all__'

class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    email = serializers.EmailField(required=True)

    
    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'password', 'first_name', 'last_name')
        extra_kwargs = {
            'password': {'write_only': True},
            'email': {'required': True},
            'username': {'required': True}
        }

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', '')
        )
        return user

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value

    def validate_username(self, value):
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError("A user with this username already exists.")
        return value

class UserListSerializer(serializers.ModelSerializer):
    date_joined = serializers.DateTimeField(format="%Y-%m-%d %H:%M:%S", read_only=True)
    last_login = serializers.DateTimeField(format="%Y-%m-%d %H:%M:%S", read_only=True)
    registered_at = serializers.DateTimeField(format="%Y-%m-%d %H:%M:%S", read_only=True)

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'is_verified', 'is_superuser', 
                 'is_staff', 'is_active', 'date_joined', 'last_login', 
                 'registered_at', 'first_name', 'last_name')
        read_only_fields = fields


class QuestionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Question
        fields = ['id', 'text', 'answer']

class LessonSerializer(serializers.ModelSerializer):
    questions = QuestionSerializer(many=True)

    class Meta:
        model = Lesson
        fields = ['id', 'code', 'title', 'teacher', 'questions']

    def create(self, validated_data):
        questions_data = validated_data.pop('questions')
        lesson = Lesson.objects.create(**validated_data)
        for question_data in questions_data:
            Question.objects.create(lesson=lesson, **question_data)
        return lesson
    

    def update(self, instance, validated_data):
        questions_data = validated_data.pop('questions')
        instance.code = validated_data.get('code', instance.code)
        instance.title = validated_data.get('title', instance.title)
        instance.teacher = validated_data.get('teacher', instance.teacher)
        instance.save()

        # Remove old questions
        instance.questions.all().delete()
        # Add new questions
        for question_data in questions_data:
            Question.objects.create(lesson=instance, **question_data)
        return instance