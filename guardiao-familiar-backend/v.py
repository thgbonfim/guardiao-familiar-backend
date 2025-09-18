# main.py - Versão Final Corrigida para Supabase Python
import os
import asyncio
from datetime import datetime, timedelta
from typing import List, Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from supabase import create_client, Client

# --- Conexão com o Supabase ---
url: str = "https://gpgsxzkvlgrhyijsrtwg.supabase.co"
key: str = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdwZ3N4emt2bGdyaHlpanNydHdnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgxMDU2NDcsImV4cCI6MjA3MzY4MTY0N30.-K17SCvWgbFFXuJpxnvkvAOA9VU38ncs3EINUM6NhEo"

supabase: Client = create_client(url, key)
# --- Lógica do Vigia de Alertas (Adaptada para Supabase) ---
async def vigia_de_remedios():
    while True:
        print(f"VIGIA: Verificando remédios às {datetime.now().strftime('%H:%M:%S')}...")
        try:
            agora = datetime.now()
            data_hoje_str = agora.strftime("%Y-%m-%d")
            dias_pt = ["segunda", "terca", "quarta", "quinta", "sexta", "sabado", "domingo"]
            dia_da_semana_hoje = dias_pt[agora.weekday()]

            # 1. Busca todos os remédios com os dados do parente e da família
            response_remedios, error = supabase.table("remedios").select("*, parentes:id_do_parente(nome, familias:id_da_familia(nome_da_familia))").execute()
            if error: raise Exception(f"Erro ao buscar remédios: {error.message}")

            if response_remedios[1]: # A API v2 retorna uma tupla (request, response)
                for remedio in response_remedios[1]:
                    # 2. Verifica se o remédio é para hoje
                    if dia_da_semana_hoje in remedio["dias_da_semana"]:
                        horario_remedio = datetime.strptime(remedio["horario"], "%H:%M").time()
                        horario_agendado_hoje = datetime.combine(agora.date(), horario_remedio)

                        # 3. Verifica se o horário já passou (com tolerância de 15 min)
                        if agora > (horario_agendado_hoje + timedelta(minutes=15)):
                            # 4. Verifica se já não foi confirmado ou alertado hoje
                            response_confirmacoes, count_error = supabase.table("confirmacoes").select("id", count='exact').eq("id_do_remedio", remedio['id']).gte("data_confirmacao", data_hoje_str).execute()
                            
                            if count_error: raise Exception(f"Erro ao contar confirmações: {count_error.message}")

                            if response_confirmacoes[1] is None or len(response_confirmacoes[1]) == 0:
                                # 5. Dispara o Alerta!
                                parente_info = remedio.get('parentes', {}) or {}
                                familia_info = parente_info.get('familias', {}) or {}
                                
                                print("\n" + "!"*60)
                                print(f"### ALERTA (Família: {familia_info.get('nome_da_familia', 'N/A')}) ###")
                                print(f"### O parente '{parente_info.get('nome', 'N/A')}' PODE TER ESQUECIDO o remédio '{remedio['nome_do_remedio']}' das {remedio['horario']}! ###")
                                print("!"*60 + "\n")

                                # 6. Marca no banco que o alerta foi enviado para não alertar de novo hoje
                                supabase.table("confirmacoes").insert({"id_do_remedio": remedio['id']}).execute()
        except Exception as e:
            print(f"ERRO NO VIGIA: {e}")

        # O vigia "dorme" por 60 segundos
        await asyncio.sleep(60)

# --- Detector de Erros na Inicialização ---
@asynccontextmanager
async def lifespan(app: FastAPI):
    print("INFO: Servidor iniciando...")
    print("INFO: Verificando a conexão com o banco de dados Supabase...")
    try:
        response = supabase.table("familias").select("id").limit(1).execute()
        if hasattr(response, "error") and response.error:
            raise Exception(f"Erro de permissão ou regra no Supabase: {response.error}")
        print("✅ Conexão com o Supabase bem-sucedida!")
    except Exception as e:
        print("\n" + "!"*60)
        print("❌ ERRO CRÍTICO: Não foi possível conectar ao banco de dados Supabase.")
        print(f"   Detalhe do erro: {e}")
        print("   Verifique se a URL e a KEY estão corretas e se as tabelas foram criadas.")
        print("   O servidor NÃO será iniciado.")
        print("!"*60 + "\n")
        raise RuntimeError("Falha na inicialização do banco de dados.") from e
    
    yield
    print("INFO: Servidor desligado.")

app = FastAPI(lifespan=lifespan)

# --- Modelos de Dados ---
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


# --- Rotas da API ---
@app.post("/usuarios/cadastrar")
async def cadastrar_usuario(dados: UsuarioCadastro):
    try:
        user_auth_response = supabase.auth.sign_up(
            {"email": dados.email, "password": dados.senha}
        )
        if not user_auth_response.user:
            raise Exception("Usuário não pôde ser criado.")
        user_id = user_auth_response.user.id

        response = supabase.table("usuarios").insert({
            "id": user_id,
            "nome_completo": dados.nome_completo
        }).execute()

        if hasattr(response, "error") and response.error:
            raise Exception(response.error)
        return {"mensagem": "Usuário cadastrado com sucesso!", "id_do_usuario": user_id}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/familias/criar")
async def criar_familia(dados: FamiliaCadastro):
    try:
        response = supabase.table("familias").insert({
            "nome_da_familia": dados.nome_da_familia
        }).execute()
        if hasattr(response, "error") and response.error:
            raise Exception(response.error)

        id_da_nova_familia = response.data[0]['id']

        update_response = supabase.table("usuarios").update({
            "id_da_familia": id_da_nova_familia
        }).eq("id", dados.id_do_usuario).execute()
        if hasattr(update_response, "error") and update_response.error:
            raise Exception(update_response.error)

        return {"mensagem": "Família criada e associada com sucesso!", "id_da_familia": id_da_nova_familia}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/parentes/cadastrar")
async def cadastrar_parente(dados: ParenteCadastro):
    try:
        response = supabase.table("parentes").insert({
            "id_da_familia": dados.id_da_familia,
            "nome": dados.nome,
            "apelido": dados.apelido
        }).execute()
        if hasattr(response, "error") and response.error:
            raise Exception(response.error)

        id_do_parente = response.data[0]['id']
        return {"mensagem": "Parente cadastrado com sucesso!", "id_do_parente": id_do_parente}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/remedios/cadastrar")
async def cadastrar_remedio(dados: RemedioCadastro):
    try:
        response = supabase.table("remedios").insert({
            "id_do_parente": dados.id_do_parente,
            "nome_do_remedio": dados.nome_do_remedio,
            "horario": dados.horario,
            "dias_da_semana": dados.dias_da_semana
        }).execute()
        if hasattr(response, "error") and response.error:
            raise Exception(response.error)

        id_do_remedio = response.data[0]['id']
        return {"mensagem": "Lembrete de remédio cadastrado com sucesso!", "id_do_remedio": id_do_remedio}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/remedios/confirmar")
async def confirmar_remedio(dados: RemedioConfirmacao):
    try:
        response = supabase.table("confirmacoes").insert({
            "id_do_remedio": dados.id_do_remedio
        }).execute()
        if hasattr(response, "error") and response.error:
            raise Exception(response.error)

        return {"mensagem": "Confirmação registrada com sucesso!"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/familias/{familia_id}/parentes")
async def listar_parentes_da_familia(familia_id: str):
    try:
        response = supabase.table("parentes").select("*").eq("id_da_familia", familia_id).execute()
        if hasattr(response, "error") and response.error:
            raise Exception(response.error)
        return response.data
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/parentes/{parente_id}/remedios")
async def listar_remedios_do_parente(parente_id: str):
    try:
        response = supabase.table("remedios").select("*").eq("id_do_parente", parente_id).execute()
        if hasattr(response, "error") and response.error:
            raise Exception(response.error)
        return response.data
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
