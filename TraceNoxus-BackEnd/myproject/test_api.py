import requests
import json

BASE_URL = 'http://localhost:8000'

def test_register():
    print("\nTesting Register Endpoint...")
    response = requests.post(
        f'{BASE_URL}/register/',
        json={
            'email': 'testuser@example.com',
            'password': 'testpass123'
        }
    )
    print(f'Status Code: {response.status_code}')
    print(f'Response: {response.json()}\n')
    return response.status_code == 201

def test_login():
    print("\nTesting Login Endpoint...")
    response = requests.post(
        f'{BASE_URL}/login/',
        json={
            'email': 'testuser@example.com',
            'password': 'testpass123'
        }
    )
    print(f'Status Code: {response.status_code}')
    print(f'Response: {response.json()}\n')
    if response.status_code == 200:
        return response.json().get('access')
    return None

def test_create_product(token):
    print("\nTesting Create Product Endpoint...")
    headers = {'Authorization': f'Bearer {token}'}
    response = requests.post(
        f'{BASE_URL}/products/',
        headers=headers,
        json={
            'name': 'Test Product',
            'price': '99.99',
            'description': 'Test Description'
        }
    )
    print(f'Status Code: {response.status_code}')
    print(f'Response: {response.json()}\n')
    return response.status_code == 201

def test_list_products(token):
    print("\nTesting List Products Endpoint...")
    headers = {'Authorization': f'Bearer {token}'}
    response = requests.get(
        f'{BASE_URL}/products/',
        headers=headers
    )
    print(f'Status Code: {response.status_code}')
    print(f'Response: {response.json()}\n')
    return response.status_code == 200

def test_otp_flow():
    print("\nTesting OTP Flow...")
    # Send OTP
    response = requests.post(
        f'{BASE_URL}/send-otp/',
        json={'email': 'testuser@example.com'}
    )
    print(f'Send OTP Status Code: {response.status_code}')
    print(f'Send OTP Response: {response.json()}\n')
    
    # Note: In a real test, you would need to get the OTP from email or cache
    # For this example, we'll just verify the endpoint responds correctly
    return response.status_code == 200

def main():
    print("Starting API Tests...")
    
    # Test registration
    if not test_register():
        print("Registration failed!")
        return
    
    # Test login
    token = test_login()
    if not token:
        print("Login failed!")
        return
    
    # Test product creation
    if not test_create_product(token):
        print("Product creation failed!")
        return
    
    # Test product listing
    if not test_list_products(token):
        print("Product listing failed!")
        return
    
    # Test OTP flow
    if not test_otp_flow():
        print("OTP flow failed!")
        return
    
    print("All tests completed successfully!")

if __name__ == '__main__':
    main() 