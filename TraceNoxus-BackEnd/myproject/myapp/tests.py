from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status
from .models import Product
from django.contrib.auth.models import User
from decimal import Decimal

class APITests(TestCase):
    def setUp(self):
        self.client = APIClient()
        # Create a test user
        self.user = User.objects.create_user(
            username='test@example.com',
            email='test@example.com',
            password='testpass123'
        )
        # Create a test product
        self.product = Product.objects.create(
            name='Test Product',
            price=Decimal('99.99'),
            description='Test Description'
        )

    def test_register_user(self):
        url = reverse('register')
        data = {
            'email': 'newuser@example.com',
            'password': 'newpass123'
        }
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(User.objects.filter(username='newuser@example.com').exists())

    def test_login(self):
        url = reverse('login')
        data = {
            'email': 'test@example.com',
            'password': 'testpass123'
        }
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)

    def test_product_list_unauthorized(self):
        url = reverse('product-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_product_list_authorized(self):
        url = reverse('product-list')
        self.client.force_authenticate(user=self.user)
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

    def test_product_create(self):
        url = reverse('product-list')
        self.client.force_authenticate(user=self.user)
        data = {
            'name': 'New Product',
            'price': '149.99',
            'description': 'New Description'
        }
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Product.objects.count(), 2)

    def test_otp_flow(self):
        # Test sending OTP
        send_otp_url = reverse('send-otp')
        data = {'email': 'test@example.com'}
        response = self.client.post(send_otp_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # Note: In a real test, you would need to mock the email sending
        # and get the actual OTP from the cache
        # For this example, we'll just verify the endpoint responds correctly
