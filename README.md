# Azure OpenAI RealTime Voice with Agents in Chainlit

## Introduction

This repo is inspired by:

- [From Zero to Hero: Building Your First Voice Bot with GPT-4o Real-Time API using Python](https://techcommunity.microsoft.com/t5/ai-azure-ai-services-blog/from-zero-to-hero-building-your-first-voice-bot-with-gpt-4o-real/ba-p/4269038)
- [Github repo](https://github.com/monuminu/AOAI_Samples/tree/main/realtime-assistant-support)

And adds a reusable mechanism to plug in agents and achieve agentic design with RealTime Voice API:

- Agents are registered beforehand, providing a system message and tools
- A root agent is also defined, as the entry point for the conversation
- At runtime, each agent is enriched by as many function calls as the other avaible agents, including their description. This way the model can invoke them by using tools.
- When the case, instead of providing the func call result, the current session is update with new agent system message and tools.

## How to use

1. Clone this repo
2. Create a virtual environment
3. Install the requirements with `pip install -r requirements.txt`
4. Run `cp .env.sample .env` and fill in the required values. __NOTE__: it is recommended to use Entra ID authentication
5. Run `invoke start`
6. Click the microphone button and start talking (messages are also supported but only after recording is started)

## IMPORTANT NOTES

- As of October 29th 2024, Chainlit audio streaming support is available starting from version `2.0.dev2`. Future versions may have additional breaking changes.
- Additionally, RealTime API is in preview and may have breaking changes.
- In order to use the RealTime API, you need to have an Azure OpenAI resource with a deployed `gpt4o-realtime-preview` model. You can find more information on how to deploy the model in the [official documentation](https://docs.microsoft.com/en-us/azure/cognitive-services/openai/gpt4o-realtime-preview).
- If you don't provide `AZURE_OPENAI_KEY` in the `.env` file, Azure Entra ID will be used for authentication. You can find more information on how to use Entra ID in the [official documentation](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/managed-identity).
  - In this case, remember to `az login` and `az account set --subscription <SUBSCRIPTION_ID>` before running the application locally.

## Scenarios

You can ask about service, such as

- Purchasing services (home, mobile, etc.)
- Technical support
- Activate services

### Activate a new home Internet service

_Hi, I want to subscribe a new Internet plan for my home. Can you help me with that?_

### Technical support

- _"Internet on my phone is not working"_
- _"Internet at home is not working"_
- _"My phone does not recognize my Sim Card"_

## Azure Deployment

```bash
az group create --name <RG NAME> --location <LOCATION>

# Deploy the infrastructure, but use a fake container image since ACR is not yet created
az deployment group create --resource-group <RG NAME> -f infra/main.bicep --parameters openAIName=<NAME> openAIResourceGroupName=<AOAI RG NAME> useFakeContainerImage=true

# Build and push chat container image
.\infra\push-images.p1 -RG <RG NAME> -Apps chat
```
