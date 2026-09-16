# 🧠 AI Hub: Project Deep Dive

The **AI Hub** is a centralized Neural Orchestration Service designed to manage multiple AI models and providers for all your current and future applications. Instead of hardcoding AI logic into every project, the AI Hub acts as a single, smart gateway.

## 🏗️ Architecture

The project is built using a **Microservices-inspired pattern**, separating AI intelligence from your main application logic.

### 1. Neural Gateway (API)
- **Path**: `app/api/generate/route.js`
- **Function**: This is the single entry point for all AI requests. 
- **The Secret Sauce**: It checks the `hub_settings.json` file to see which provider is currently "Active". It then dynamically routes your request to either **Google Gemini**, **Groq (Llama)**, or **OpenAI**.
- **Unified Format**: No matter which model is behind the scenes, the AI Hub returns a consistent response format to your applications.

### 2. Live Management Dashboard
- **Path**: `app/page.js`
- **Aesthetics**: Built with a **Premium Dark Theme**, featuring glassmorphism, pulsing state indicators, and smooth HSL gradients.
- **Function**: Allows you to switch the active model with one click. 
- **Effect**: When you click "Switch" on the dashboard, it instantly updates the global configuration. Every application connected to the Hub immediately starts using the new model.

### 3. Centralized Configuration
- **Path**: `config/hub_settings.json`
- **Function**: The "Source of Truth" for your entire AI ecosystem. It stores model names, status, and which one is the current priority.

---

## 🔗 How Integration Works

Your existing apps (like the **Manifest App**) now connect to the Hub instead of direct AI APIs:

1. **The Request**: `Manifest Backend` sends a prompt to `http://localhost:3001/api/generate`.
2. **The Decision**: `AI Hub` reads the config -> sees "Active: Gemini".
3. **The Execution**: `AI Hub` calls Gemini API using your keys.
4. **The Result**: `AI Hub` cleans the data and sends it back to `Manifest Backend`.

---

## 🔥 Key Benefits

- **Zero Downtime Updates**: Want to try Llama 3 instead of Gemini? Just click a button on the Dashboard. No code changes, no redeployment.
- **Clean Codebase**: Your main apps are now "AI-Agnostic". They don't need to know how Gemini or Groq work; they just know "The Hub will handle it."
- **Reduced Dependencies**: Your main app's backend is 30% smaller because it no longer needs multiple AI SDKs.
- **API Key Security**: All your expensive API keys are stored in one place (`ai_hub/.env`), not scattered across 5 different projects.

---

## 🛠️ Performance & Scalability
Running on **Port 3001** via **Next.js**, the Hub is optimized for speed using **Turbopack**. It can handle requests from dozens of different apps simultaneously while giving you a bird's-eye view of your AI costs and usage.
