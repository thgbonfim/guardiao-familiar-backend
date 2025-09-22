# Guardião Familiar 👵❤️

## 📝 Descrição

Guardião Familiar é um projeto de aplicativo, desenvolvido em Flutter e Python, com o objetivo de criar uma plataforma de tranquilidade e coordenação do cuidado para famílias com parentes idosos.

O sistema permite que os cuidadores (filhos, netos) cadastrem lembretes de remédios, e que os parentes idosos confirmem a toma da medicação através de uma interface ultra-simplificada. O aplicativo também conta com um sistema de alerta proativo que notifica a família caso um remédio seja esquecido.

Este repositório contém o código-fonte para o **Aplicativo Móvel (Frontend)** e para a **API (Backend)**.

---

## ✨ Funcionalidades do MVP (Versão Atual)

* **Backend (Python/FastAPI):**
    * [x] API para cadastro de Usuários, Famílias, Parentes e Remédios.
    * [x] API para confirmação da toma de remédios.
    * [x] API para login de usuários.
    * [x] Conexão com banco de dados persistente (Supabase).
    * [x] Verificação de conexão com o banco na inicialização.
    * [x] Sistema "Vigia" que roda em segundo plano para detectar remédios esquecidos (simulação de alerta).
* **Frontend do Cuidador (Flutter):**
    * [x] Fluxo completo de cadastro de usuário e criação de família.
    * [x] Painel principal que busca e exibe dados da API.
    * [x] Fluxo completo de cadastro de parentes e lembretes de remédio.
    * [x] Conexão real com o backend.
* **Frontend do Parente (Flutter):**
    * [x] Protótipo de interface ultra-simplificada para confirmação de remédios.

---

## 🛠️ Tecnologias Utilizadas

* **Frontend (App):**
    * [Flutter](https://flutter.dev/) (Dart)
* **Backend (API):**
    * [Python](https://www.python.org/)
    * [FastAPI](https://fastapi.tiangolo.com/)
* **Banco de Dados:**
    * [Supabase](https://supabase.com/) (PostgreSQL)

---

## 🚀 Como Executar o Projeto

### 1. Backend
- Navegue até a pasta `guardiao-familiar-backend`.
- Crie um ambiente virtual (recomendado): `python -m venv venv` e ative-o.
- Instale as dependências: `pip install -r requirements.txt`.
- Crie um arquivo chamado `.env` na mesma pasta e adicione suas credenciais do Supabase:
  ```
  SUPABASE_URL="SUA_URL_AQUI"
  SUPABASE_KEY="SUA_KEY_AQUI"
  ```
- Execute o servidor: `uvicorn main:app --reload`


### 2. Frontend
- Abra a pasta raiz do projeto (`guardiao_familiar`) no seu editor.
- Baixe as dependências: `flutter pub get`.
- Garanta que o backend está rodando.
- Se necessário, atualize a constante `_apiUrl` nos arquivos `.dart` para apontar para o seu backend (o endereço `http://10.0.2.2:8000` já é o correto para o emulador do Android).
- Selecione um emulador e execute o app (F5 no VS Code).
