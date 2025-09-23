import os
import uuid
from typing import List, Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()  # Carrega variáveis do arquivo .env

# --- Conexão com o Supabase ---
url: str = os.getenv("SUPABASE_URL")
key: str = os.getenv("SUPABASE_KEY")
supabase: Client = create_client(url, key)

# --- Lifespan: validação ao iniciar ---
@asynccontextmanager
async def lifespan(app: FastAPI):
    print("Iniciando servidor e verificando Supabase...")
    try:
        response = supabase.table("familias").select("id", count='exact').limit(1).execute()
        if getattr(response, 'error', None):
            raise Exception(f"Erro no Supabase: {response.error.message}")
        print("✅ Supabase conectado com sucesso.")
    except Exception as e:
        print(f"\n❌ ERRO CRÍTICO: {e}\n")
        raise RuntimeError("Falha ao conectar com o Supabase.") from e
    yield
    print("Servidor desligado.")

app = FastAPI(lifespan=lifespan)

# --- Modelos de dados ---
class UsuarioCadastro(BaseModel):
    nome_completo: str
    email: str
    senha: str

class FamiliaCadastro(BaseModel):
    id_do_usuario: str
    nome_da_familia: str

class ParenteCadastro(BaseModel):
    id_da_familia: str
    nome: str
    apelido: Optional[str] = None

class RemedioCadastro(BaseModel):
    id_do_parente: str
    nome_do_remedio: str
    horario: str
    dias_da_semana: List[str]

class RemedioConfirmacao(BaseModel):
    id_do_remedio: str

class UsuarioLogin(BaseModel):
    email: str
    senha: str

# --- Rotas da API ---
@app.post("/usuarios/login")
async def login_usuario(dados: UsuarioLogin):
    try:
        auth = supabase.auth.sign_in_with_password({
            "email": dados.email,
            "password": dados.senha
        })
        user_id = auth.user.id
        usuario_response = supabase.table("usuarios").select("id, nome_completo, id_da_familia").eq("id", user_id).single().execute()
        usuario = usuario_response.data

        familia = None
        if usuario and usuario.get("id_da_familia"):
            familia_response = supabase.table("familias").select("id, nome_da_familia").eq("id", usuario["id_da_familia"]).single().execute()
            familia = familia_response.data

        return {
            "mensagem": "Login bem-sucedido!",
            "usuario": usuario,
            "familia": familia
        }

    except Exception as e:
        raise HTTPException(status_code=401, detail=f"E-mail ou senha inválidos. Erro: {str(e)}")

@app.post("/usuarios/cadastrar")
async def cadastrar_usuario(dados: UsuarioCadastro):
    try:
        auth = supabase.auth.sign_up({"email": dados.email, "password": dados.senha})
        if not auth.user:
            raise Exception("Falha ao criar o usuário.")
        user_id = auth.user.id
        supabase.table("usuarios").insert({
            "id": user_id,
            "nome_completo": dados.nome_completo
        }).execute()
        return {"mensagem": "Usuário cadastrado com sucesso!", "id_do_usuario": user_id}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/familias/criar")
async def criar_familia(dados: FamiliaCadastro):
    try:
        familia_response = supabase.table("familias").insert({
            "nome_da_familia": dados.nome_da_familia
        }).execute()
        if getattr(familia_response, 'error', None):
            raise Exception(familia_response.error.message)

        id_nova_familia = familia_response.data[0]["id"]

        update_response = supabase.table("usuarios").update({
            "id_da_familia": id_nova_familia
        }).eq("id", dados.id_do_usuario).execute()
        if getattr(update_response, 'error', None):
            raise Exception(update_response.error.message)

        return {
            "mensagem": "Família criada e associada com sucesso!",
            "id": id_nova_familia,
            "nome_da_familia": dados.nome_da_familia
        }

    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/parentes/cadastrar", status_code=status.HTTP_201_CREATED)
async def cadastrar_parente(dados: ParenteCadastro):
    try:
        response = supabase.table("parentes").insert({
            "id_da_familia": dados.id_da_familia,
            "nome": dados.nome,
            "apelido": dados.apelido
        }).execute()
        if getattr(response, 'error', None):
            raise Exception(response.error.message)

        return {
            "mensagem": "Parente cadastrado com sucesso!",
            "id": response.data[0]["id"],
            "nome": dados.nome,
            "apelido": dados.apelido
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# --- Endpoint atualizado para cadastrar remédio com ID único ---
@app.post("/remedios/cadastrar")
async def cadastrar_remedio(dados: RemedioCadastro):
    try:
        # --- Gera ID único para cada remédio ---
        id_unico = str(uuid.uuid4())  # ID totalmente único

        response = supabase.table("remedios").insert({
            "id": id_unico,
            "id_do_parente": dados.id_do_parente,
            "nome_do_remedio": dados.nome_do_remedio,
            "horario": dados.horario,
            "dias_da_semana": dados.dias_da_semana
        }).execute()
        if getattr(response, 'error', None):
            raise Exception(response.error.message)

        return {
            "mensagem": "Lembrete de remédio cadastrado com sucesso!",
            "id_do_remedio": id_unico
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/remedios/confirmar")
async def confirmar_remedio(dados: RemedioConfirmacao):
    try:
        response = supabase.table("confirmacoes").insert({
            "id_do_remedio": dados.id_do_remedio
        }).execute()
        if getattr(response, 'error', None):
            raise Exception(response.error.message)
        return {"mensagem": "Confirmação registrada com sucesso!"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/familias/{familia_id}/parentes")
async def listar_parentes_da_familia(familia_id: str):
    try:
        response = supabase.table("parentes").select("*").eq("id_da_familia", familia_id).execute()
        if getattr(response, 'error', None):
            raise Exception(response.error.message)
        return response.data
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/parentes/{parente_id}/remedios")
async def listar_remedios_do_parente(parente_id: str):
    try:
        remedios_response = supabase.table("remedios").select("*").eq("id_do_parente", parente_id).execute()
        if getattr(remedios_response, 'error', None):
            raise Exception(remedios_response.error.message)
        remedios = remedios_response.data

        remedio_ids = [r['id'] for r in remedios]
        if remedio_ids:
            confirmacoes_response = supabase.table("confirmacoes").select("id_do_remedio").in_("id_do_remedio", remedio_ids).execute()
            if getattr(confirmacoes_response, 'error', None):
                raise Exception(confirmacoes_response.error.message)
            confirmados_ids = {c['id_do_remedio'] for c in confirmacoes_response.data}
        else:
            confirmados_ids = set()

        for remedio in remedios:
            remedio['foi_tomado'] = remedio['id'] in confirmados_ids

        return remedios
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
