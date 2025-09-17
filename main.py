# main.py - Versão Completa e Corrigida

# Passo 1: Importar todas as ferramentas necessárias
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from supabase import create_client, Client # A correção do create_client está aqui
import os

# --- PASSO 2: CONFIGURAÇÃO ---
# Cole aqui os valores que você copiou do seu projeto Supabase
SUPABASE_URL = "https://gpgszkvlgrhyrjsrtwg.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdwZ3N4emt2bGdyaHlpanNydHdnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgxMDU2NDcsImV4cCI6MjA3MzY4MTY0N30.-K17SCvWgbFFXuJpxnvkvAOA9VU38ncs3EINUM6NhEo"

# Conecta-se ao Supabase usando as suas chaves
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Cria a nossa aplicação API
app = FastAPI()

# --- PASSO 3: MODELOS DE DADOS ---
# Define como devem ser os dados que chegam pela API
class UsuarioCadastro(BaseModel):
    nome_completo: str
    email: str
    senha: str

class FamiliaCadastro(BaseModel):
    id_do_usuario: str
    nome_da_familia: str

# --- PASSO 4: ROTAS DA API (OS "ENDEREÇOS") ---
@app.post("/usuarios/cadastrar")
async def cadastrar_usuario(dados: UsuarioCadastro):
    """
    Cria um novo usuário no sistema de autenticação da Supabase.
    """
    try:
        # Cria o usuário na autenticação (email/senha)
        user_auth = supabase.auth.sign_up({
            "email": dados.email,
            "password": dados.senha,
        })
        
        user_id = user_auth.user.id

        # Insere os dados adicionais (nome completo) na nossa tabela 'usuarios'
        supabase.table("usuarios").insert({
            "id": user_id,
            "nome_completo": dados.nome_completo
        }).execute()
        
        return {"mensagem": "Usuário cadastrado com sucesso!", "id_do_usuario": user_id}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/familias/criar")
async def criar_familia(dados: FamiliaCadastro):
    """
    Cria uma nova família e associa o usuário a ela.
    """
    try:
        # Insere a nova família na tabela 'familias'
        response_familia = supabase.table("familias").insert({
            "nome_da_familia": dados.nome_da_familia
        }).execute()
        
        id_da_nova_familia = response_familia.data[0]['id']

        # Atualiza o cadastro do usuário para incluir o ID da família que ele criou
        supabase.table("usuarios").update({
            "id_da_familia": id_da_nova_familia
        }).eq("id", dados.id_do_usuario).execute()

        return {"mensagem": "Família criada e associada com sucesso!", "id_da_familia": id_da_nova_familia}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))