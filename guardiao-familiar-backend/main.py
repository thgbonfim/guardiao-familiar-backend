# main.py - Versão Definitiva com Lógica de Alerta e Sintaxe Corrigida

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import uuid
from datetime import datetime, timedelta, time
import asyncio
from contextlib import asynccontextmanager
from supabase import create_client, Client

# --- Configuração do Supabase ---
# ATENÇÃO: COLOQUE AQUI AS CREDENCIAIS DO SEU PROJETO VÁLIDO
url: str = "https://gpgsxzkvlgrhyijsrtwg.supabase.co"
key: str = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdwZ3N4emt2bGdyaHlpanNydHdnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgxMDU2NDcsImV4cCI6MjA3MzY4MTY0N30.-K17SCvWgbFFXuJpxnvkvAOA9VU38ncs3EINUM6NhEo"
supabase: Client = create_client(url, key)
# ---------------------------------
# main.py - Versão Final e Completa com Login
#
# --- Detector de Erros na Inicialização ---
@asynccontextmanager
async def lifespan(app: FastAPI):
    print("INFO: Servidor iniciando...")
    print("INFO: Verificando a conexão com o banco de dados Supabase...")
    try:
        response = supabase.table("familias").select("id", count='exact').limit(1).execute()
        if getattr(response, 'error', None):
            raise Exception(f"Erro no Supabase: {response.error.message}")
        print("✅ Conexão com o Supabase bem-sucedida!")
    except Exception as e:
        print("\n" + "!"*60)
        print("❌ ERRO CRÍTICO: Não foi possível conectar ao banco de dados.")
        print(f"   Detalhe: {e}")
        print("!"*60 + "\n")
        raise RuntimeError("Falha na inicialização do banco de dados.") from e
    
    yield
    print("INFO: Servidor desligado.")

app = FastAPI(lifespan=lifespan)

# --- Modelos de Dados ---
class UsuarioCadastro(BaseModel): nome_completo: str; email: str; senha: str
class FamiliaCadastro(BaseModel): id_do_usuario: str; nome_da_familia: str
class ParenteCadastro(BaseModel): id_da_familia: str; nome: str; apelido: Optional[str] = None
class RemedioCadastro(BaseModel): id_do_parente: str; nome_do_remedio: str; horario: str; dias_da_semana: List[str]
class RemedioConfirmacao(BaseModel): id_do_remedio: str
class UsuarioLogin(BaseModel): email: str; senha: str

# --- Rotas da API (Todas Corrigidas) ---
@app.post("/usuarios/login")
async def login_usuario(dados: UsuarioLogin):
    try:
        auth_response = supabase.auth.sign_in_with_password({"email": dados.email, "password": dados.senha})
        user_id = auth_response.user.id
        
        user_data_response = supabase.table("usuarios").select("id, nome_completo, id_da_familia").eq("id", user_id).single().execute()
        if getattr(user_data_response, 'error', None): raise Exception(user_data_response.error.message)
        usuario = user_data_response.data
        
        familia = None
        # ### CORREÇÃO PRINCIPAL AQUI ###
        # Só tenta buscar a família se o usuário tiver um id_da_familia
        if usuario and usuario.get('id_da_familia'):
            familia_response = supabase.table("familias").select("id, nome_da_familia").eq("id", usuario['id_da_familia']).single().execute()
            if getattr(familia_response, 'error', None): raise Exception(familia_response.error.message)
            familia = familia_response.data

        return {
            "mensagem": "Login bem-sucedido!",
            "usuario": usuario,
            "familia": familia # Pode ser None se o usuário ainda não criou uma família
        }
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"E-mail ou senha inválidos. Erro: {str(e)}")
@app.post("/usuarios/cadastrar")
async def cadastrar_usuario(dados: UsuarioCadastro):
    try:
        user_auth_response = supabase.auth.sign_up({"email": dados.email, "password": dados.senha})
        if not user_auth_response.user: raise Exception("Usuário não pôde ser criado.")
        user_id = user_auth_response.user.id
        response = supabase.table("usuarios").insert({"id": user_id, "nome_completo": dados.nome_completo}).execute()
        if getattr(response, 'error', None): raise Exception(response.error.message)
        return {"mensagem": "Usuário cadastrado com sucesso!", "id_do_usuario": user_id}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/familias/criar")
async def criar_familia(dados: FamiliaCadastro):
    try:
        response = supabase.table("familias").insert({"nome_da_familia": dados.nome_da_familia}).execute()
        if getattr(response, 'error', None): raise Exception(response.error.message)
        id_da_nova_familia = response.data[0]['id']
        response_update = supabase.table("usuarios").update({"id_da_familia": id_da_nova_familia}).eq("id", dados.id_do_usuario).execute()
        if getattr(response_update, 'error', None): raise Exception(response_update.error.message)
        return {"mensagem": "Família criada e associada com sucesso!", "id_da_familia": id_da_nova_familia}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# ... (O resto das rotas seguem o mesmo padrão corrigido) ...
@app.post("/parentes/cadastrar")
async def cadastrar_parente(dados: ParenteCadastro):
    try:
        response = supabase.table("parentes").insert({"id_da_familia": dados.id_da_familia, "nome": dados.nome, "apelido": dados.apelido}).execute()
        if getattr(response, 'error', None): raise Exception(response.error.message)
        id_do_parente = response.data[0]['id']
        return {"mensagem": "Parente cadastrado com sucesso!", "id_do_parente": id_do_parente}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/remedios/cadastrar")
async def cadastrar_remedio(dados: RemedioCadastro):
    try:
        response = supabase.table("remedios").insert({"id_do_parente": dados.id_do_parente, "nome_do_remedio": dados.nome_do_remedio, "horario": dados.horario, "dias_da_semana": dados.dias_da_semana}).execute()
        if getattr(response, 'error', None): raise Exception(response.error.message)
        id_do_remedio = response.data[0]['id']
        return {"mensagem": "Lembrete de remédio cadastrado com sucesso!", "id_do_remedio": id_do_remedio}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/remedios/confirmar")
async def confirmar_remedio(dados: RemedioConfirmacao):
    try:
        response = supabase.table("confirmacoes").insert({"id_do_remedio": dados.id_do_remedio}).execute()
        if getattr(response, 'error', None): raise Exception(response.error.message)
        return {"mensagem": "Confirmação registrada com sucesso!"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/familias/{familia_id}/parentes")
async def listar_parentes_da_familia(familia_id: str):
    try:
        response = supabase.table("parentes").select("*").eq("id_da_familia", familia_id).execute()
        if getattr(response, 'error', None): raise Exception(response.error.message)
        return response.data
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/parentes/{parente_id}/remedios")
async def listar_remedios_do_parente(parente_id: str):
    try:
        response = supabase.table("remedios").select("*").eq("id_do_parente", parente_id).execute()
        if getattr(response, 'error', None): raise Exception(response.error.message)
        return response.data
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))