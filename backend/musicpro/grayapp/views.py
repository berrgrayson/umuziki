from django.shortcuts import render
from rest_framework import status
from rest_framework.response import Response
from rest_framework.decorators import api_view
from django.contrib.auth.models import User
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.serializers import ModelSerializer
from django.contrib.auth.hashers import make_password
from django.core.mail import send_mail
from django.core.signing import Signer, BadSignature
from django.conf import settings
from django.contrib.auth import get_user_model

signer = Signer()



def send_verification_email(user):
    token = signer.sign(user.email)
    verification_link = f"http://localhost:8000/api/verify-email/{token}"
    
    subject = 'Vérification de votre email'
    message = f'Cliquez sur le lien suivant pour vérifier votre email : {verification_link}'
    from_email = settings.DEFAULT_FROM_EMAIL
    
    send_mail(subject, message, from_email, [user.email])


@api_view(['GET'])
def verify_email(request, token):
    User = get_user_model()

    try:
        email = signer.unsign(token)
        user = User.objects.get(email=email)

        if user.is_active:
            return Response({'message': 'Votre email est déjà vérifié.'}, status=status.HTTP_400_BAD_REQUEST)

        # Activer l'utilisateur
        user.is_active = True
        user.save()

        return Response({'message': 'Votre email a été vérifié avec succès.'}, status=status.HTTP_200_OK)
    
    except (User.DoesNotExist, BadSignature):
        return Response({'error': 'Le lien de vérification est invalide.'}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
def signup(request):
    # Récupérer les données de la requête
    username = request.data.get('username')
    password = request.data.get('password')
    email = request.data.get('email')
    User = get_user_model()
    # Vérifier si l'utilisateur existe déjà
    if User.objects.filter(username=username).exists():
        return Response({'error': 'Cet utilisateur existe déjà.'}, status=status.HTTP_400_BAD_REQUEST)

    # Créer un nouvel utilisateur
    user = User.objects.create(
        username=username,
        password=make_password(password), 
        email=email,
        is_active=False
    )
    send_verification_email(user)

    return Response({'message': 'Utilisateur créé avec succès.Veuillez vérifier votre email'}, status=status.HTTP_201_CREATED)

class UserSerializer(ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email']  # Sélection des champs à retourner

# Vue pour récupérer la liste des utilisateurs
@api_view(['GET'])
def get_users(request):
    # Récupérer tous les utilisateurs
    users = User.objects.all()

    # Sérialiser les utilisateurs
    serializer = UserSerializer(users, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)

# Récupérer les informations de l'utilisateur authentifié
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_authenticated_user(request):
    user = request.user  # Récupère l'utilisateur authentifié
    serializer = UserSerializer(user)
    return Response(serializer.data, status=status.HTTP_200_OK)

# Modifier l'utilisateur authentifié
@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_authenticated_user(request):
    user = request.user  # Récupère l'utilisateur authentifié

    # Mise à jour des informations utilisateur
    user.username = request.data.get('username', user.username)
    user.email = request.data.get('email', user.email)

    # Mise à jour du mot de passe si fourni
    if request.data.get('password'):
        user.password = make_password(request.data.get('password'))

    user.save()
    return Response({'message': 'Informations de l\'utilisateur modifiées avec succès.'}, status=status.HTTP_200_OK)
