# main.py - Versão Final e Definitiva com Todas as Lógicas e Correções

import os
import asyncio
from datetime import datetime, timedelta, time
from typing import List, Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv() # Carrega as variáveis do arquivo .env

# --- Conexão com o Supabase ---
url: str = os.getenv("SUPABASE_URL")
key: str = os.getenv("SUPABASE_KEY")
supabase: Client = create_client(url, key)
# ---------------------------------

# --- Lógica do Vigia de Alertas ---
async def vigia_de_remedios():
    while True:
        await asyncio.sleep(60) # Verifica a cada 60 segundos
        print(f"VIGIA: Verificando remédios às {datetime.now().strftime('%H:%M:%S')} (Hora do Servidor)")
        try:
            agora = datetime.now()
            data_hoje_str = agora.strftime("%Y-%m-%d")
            dias_pt = ["segunda", "terca", "quarta", "quinta", "sexta", "sabado", "domingo"]
            dia_da_semana_hoje = dias_pt[agora.weekday()]

            response_remedios = supabase.table("remedios").select("*, parentes:id_do_parente(nome, familias:id_da_familia(nome_da_familia))").execute()
            
            if hasattr(response_remedios, 'data') and response_remedios.data:
                for remedio in response_remedios.data:
                    if dia_da_semana_hoje in remedio.get("dias_da_semana", []):
                        horario_remedio = datetime.strptime(remedio["horario"], "%H:%M").time()
                        horario_agendado_hoje = datetime.combine(agora.date(), horario_remedio)

                        if agora > (horario_agendado_hoje + timedelta(minutes=15)):
                            response_confirmacoes = supabase.table("confirmacoes").select("id", count='exact').eq("id_do_remedio", remedio['id']).gte("data_confirmacao", data_hoje_str).execute()
                            
                            if getattr(response_confirmacoes, 'count', 0) == 0:
                                parente_info = remedio.get('parentes', {}) or {}
                                familia_info = parente_info.get('familias', {}) or {}
                                
                                print("\n" + "!"*60)
                                print(f"### ALERTA (Família: {familia_info.get('nome_da_familia', 'N/A')}) ###")
                                print(f"### O parente '{parente_info.get('nome', 'N/A')}' PODE TER ESQUECIDO o remédio '{remedio['nome_do_remedio']}' das {remedio['horario']}! ###")
                                print("!"*60 + "\n")
                                supabase.table("confirmacoes").insert({"id_do_remedio": remedio['id']}).execute()
        except Exception as e:
            print(f"ERRO NO VIGIA: {e}")

# --- Gerenciador de Ciclo de Vida do App ---
@asynccontextmanager
async def lifespan(app: FastAPI):
    print("INFO: Servidor iniciando...")
    try:
        response = supabase.table("familias").select("id", count='exact').limit(1).execute()
        if getattr(response, 'error', None): raise Exception(f"Erro no Supabase: {response.error.message}")
        print("✅ Conexão com o Supabase bem-sucedida!")
    except Exception as e:
        print("\n" + "!"*60); print(f"❌ ERRO CRÍTICO: Não foi possível conectar ao banco de dados.\n   Detalhe: {e}"); print("!"*60 + "\n")
        raise RuntimeError("Falha na inicialização do banco de dados.") from e
    
    print("INFO: Iniciando a tarefa do vigia de remédios em segundo plano...")
    asyncio.create_task(vigia_de_remedios())
    
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

# --- Rotas da API ---
@app.post("/usuarios/login")
async def login_usuario(dados: UsuarioLogin):
    try:
        auth_response = supabase.auth.sign_in_with_password({"email": dados.email, "password": dados.senha})
        user_id = auth_response.user.id
        user_data_response = supabase.table("usuarios").select("id, nome_completo, id_da_familia").eq("id", user_id).single().execute()
        if getattr(user_data_response, 'error', None): raise Exception(user_data_response.error.message)
        usuario = user_data_response.data
        familia = None
        if usuario and usuario.get('id_da_familia'):
            familia_response = supabase.table("familias").select("id, nome_da_familia").eq("id", usuario['id_da_familia']).single().execute()
            if getattr(familia_response, 'error', None): raise Exception(familia_response.error.message)
            familia = familia_response.data
        return {"mensagem": "Login bem-sucedido!", "usuario": usuario, "familia": familia}
    except Exception as e:
        raise HTTPException(status_code=401, detail="E-mail ou senha inválidos. Por favor, tente novamente.")

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
        error_message = str(e)
        detail = "Ocorreu um erro inesperado no cadastro."
        if "User already registered" in error_message: detail = "Este e-mail já está em uso. Tente outro."
        elif "Password should be at least 6 characters" in error_message: detail = "A senha deve ter no mínimo 6 caracteres."
        raise HTTPException(status_code=400, detail=detail)

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

@app.get("/familia/{familia_id}/dashboard")
async def get_dashboard_data(familia_id: str):
    try:
        response_parentes = supabase.table("parentes").select("*, remedios(*)").eq("id_da_familia", familia_id).execute()
        if getattr(response_parentes, 'error', None): raise Exception(response_parentes.error.message)
        parentes_com_remedios = response_parentes.data
        data_hoje_str = datetime.now().strftime("%Y-%m-%d")
        ids_de_todos_remedios = [remedio['id'] for parente in parentes_com_remedios for remedio in parente['remedios']]
        if not ids_de_todos_remedios: return parentes_com_remedios
        response_confirmacoes = supabase.table("confirmacoes").select("id_do_remedio").isin("id_do_remedio", ids_de_todos_remedios).gte("data_confirmacao", data_hoje_str).execute()
        if getattr(response_confirmacoes, 'error', None): raise Exception(response_confirmacoes.error.message)
        ids_confirmados_hoje = {confirmacao['id_do_remedio'] for confirmacao in response_confirmacoes.data}
        for parente in parentes_com_remedios:
            parente['remedios'] = [r for r in parente['remedios'] if r['id'] not in ids_confirmados_hoje]
        return parentes_com_remedios
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/parentes/{parente_id}")
async def buscar_dados_do_parente(parente_id: str):
    try:
        response = supabase.table("parentes").select("*").eq("id", parente_id).single().execute()
        if getattr(response, 'error', None):
             raise HTTPException(status_code=404, detail="Parente não encontrado.")
        return response.data
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/parentes/{parente_id}/remedios")
async def listar_remedios_do_parente(parente_id: str):
    try:
        response_remedios = supabase.table("remedios").select("*").eq("id_do_parente", parente_id).execute()
        if getattr(response_remedios, 'error', None): raise Exception(response_remedios.error.message)
        
        todos_os_remedios = response_remedios.data
        if not todos_os_remedios:
            return []

        data_hoje_str = datetime.now().strftime("%Y-%m-%d")
        ids_dos_remedios = [remedio['id'] for remedio in todos_os_remedios]

        response_confirmacoes = supabase.table("confirmacoes").select("id_do_remedio").isin("id_do_remedio", ids_dos_remedios).gte("data_confirmacao", data_hoje_str).execute()
        if getattr(response_confirmacoes, 'error', None): raise Exception(response_confirmacoes.error.message)

        ids_confirmados_hoje = {confirmacao['id_do_remedio'] for confirmacao in response_confirmacoes.data}
        remedios_pendentes = [remedio for remedio in todos_os_remedios if remedio['id'] not in ids_confirmados_hoje]
        
        return remedios_pendentes
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))