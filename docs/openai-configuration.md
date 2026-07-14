# OpenAI and Azure OpenAI Configuration

This guide describes how to configure the Huly AI Bot service with either standard OpenAI or Azure OpenAI, including key configuration variables and troubleshooting deployment/model mismatches.

## Configuration Variables

The `aibot` service is configured using the following environment variables:

| Environment Variable | Description |
| :--- | :--- |
| `OPENAI_API_KEY` | Your OpenAI API key or Azure OpenAI key. |
| `OPENAI_BASE_URL` | The API base endpoint. For standard OpenAI, use `https://api.openai.com/v1/`. For Azure OpenAI, use `https://{YOUR_RESOURCE_NAME}.openai.azure.com/openai/v1/`. |
| `OPENAI_MODEL` | The model name or Azure deployment name for the chat assistant. Fallback: `gpt-4o-mini` |
| `OPENAI_TRANSLATE_MODEL` | The model name or Azure deployment name used for text translation. Fallback: `gpt-4o-mini` |
| `OPENAI_SUMMARY_MODEL` | The model name or Azure deployment name used for message summaries. Fallback: `gpt-4o-mini` |

> [!IMPORTANT]
> The Huly AI Bot service reads the standard `OPENAI_` prefixed variables (not `AI_OPENAI_`). Be sure to define both or use the non-prefixed variables to ensure they are read correctly by the bot.

---

## Azure OpenAI Setup & Troubleshooting

### Problem: `DeploymentNotFound (404)` Error
When switching from public OpenAI to Azure OpenAI, the bot may crash with a `DeploymentNotFound` or `404 The API deployment for this resource does not exist` error.

### Why this happens
1. **Azure Deployment Names**: Unlike the public OpenAI API (where the model parameter is a standard identifier like `gpt-4o`), Azure OpenAI requires the `model` parameter in API requests to match the **Deployment Name** you created in your Azure OpenAI Studio.
2. **Missing Env Var / Fallback**: If you only configure `AI_OPENAI_MODEL` (and not `OPENAI_MODEL`), the AI Bot falls back to its default value: `gpt-4o-mini`. If you do not have an Azure deployment named exactly `gpt-4o-mini`, the request will fail.

### Resolution
In your `docker-compose.yml`, specify the non-prefixed variables mapping to your exact Azure deployment name. For example, if your deployment is named `gpt-5.4-mini`:

```yaml
  aibot:
    image: hardcoreeng/ai-bot:${HULY_VERSION}
    environment:
      - OPENAI_BASE_URL=https://synthdatagen1.openai.azure.com/openai/v1/
      - OPENAI_API_KEY=YOUR_AZURE_API_KEY
      
      # Keep AI_ prefixed variables if other external tools require them
      - AI_OPENAI_MODEL=gpt-5.4-mini
      - AI_OPENAI_TRANSLATE_MODEL=gpt-5.4-mini
      - AI_OPENAI_SUMMARY_MODEL=gpt-5.4-mini

      # Add these so the AI Bot itself reads the correct deployment name
      - OPENAI_MODEL=gpt-5.4-mini
      - OPENAI_TRANSLATE_MODEL=gpt-5.4-mini
      - OPENAI_SUMMARY_MODEL=gpt-5.4-mini
```

---

## Huly Love Agent & Realtime Transcription

`love-agent` is Huly's real-time meeting minutes daemon. It connects to the LiveKit server, subscribes to participants' audio streams when transcription is enabled, and feeds the audio to OpenAI's Realtime API to perform speech-to-text.

### 1. Network Configuration (Host Networking)
WebRTC requires direct UDP port connections for streaming audio. When running `love-agent` inside a standard Docker Bridge network (e.g., `huly_net`), Docker's dynamic port NATing blocks WebRTC ICE candidate handshakes. The agent will join the room but never receive audio (resulting in no logs saying `Subscribing to track`).

* **Resolution**: Run `love-agent` in **`network_mode: host`**.
* **Impact**: Since it uses host networking, it must communicate with the `aibot` service via the host loopback IP. Set `PLATFORM_URL` to `http://127.0.0.1:4010` (instead of `http://aibot:4010`).

### 2. Platform Authentication (JWT Token Setup)
The `love-agent` must authenticate itself to the `aibot` backend when updating meeting minutes transcriptions. The backend expects a valid JWT token signed with Huly's `SECRET` and containing the AI Bot's account UUID. Passing the raw secret string as the `PLATFORM_TOKEN` will fail with a `401 Unauthorized` API error.

#### How to Generate the JWT:
1. Locate your Huly `SECRET` in `/opt/huly/.env`.
2. Locate the AI Bot's `personUuid` in `aibot-1` startup logs (look for `"AI person uuid"`).
3. Generate a JWT token with the following payload signed with the `SECRET` using HMAC-SHA256:
   ```json
   {
     "account": "AI_BOT_PERSON_UUID"
   }
   ```
4. Set the generated token string as `PLATFORM_TOKEN` in `loveagent`'s environment variables.

### 3. OpenAI Realtime GA API Migration
OpenAI has fully deprecated and decommissioned the Beta Realtime API. All legacy connections are rejected with errors like `beta_api_shape_disabled` or `unknown_parameter`. 

The following changes were made to Huly's STT provider code (`love-agent/src/openai/stt.ts`) to comply with the General Availability (GA) Realtime API:

1. **Removed Deprecated Header**: Deleted the `'OpenAI-Beta': 'realtime=v1'` header from the WebSocket connection request.
2. **Updated WebSocket Endpoint**: Changed the URL from `wss://api.openai.com/v1/realtime?intent=transcription` to target the GA model explicitly:
   `wss://api.openai.com/v1/realtime?model=gpt-realtime-2.1-mini` (or `gpt-realtime-mini`).
3. **Updated Event Name**: Changed the client event type from `transcription_session.update` to `session.update`.
4. **Corrected Schema Nesting**: Nested transcription configuration inside `audio.input` and updated the parameter names to GA standards:
   * Replaced `modalities` with `output_modalities: ["text"]` to restrict the session output to text.
   * Set `session.type` to `"realtime"` to indicate the session class.
   * Pointed transcription model to `"gpt-realtime-whisper"` (or `"whisper-1"`).
   * Removed legacy `language` and `prompt` variables from the transcription object.

#### Correct GA Session Update JSON Payload:
```json
{
  "type": "session.update",
  "session": {
    "type": "realtime",
    "output_modalities": ["text"],
    "audio": {
      "input": {
        "transcription": {
          "model": "gpt-realtime-whisper"
        },
        "turn_detection": {
          "type": "server_vad",
          "threshold": 0.5,
          "prefix_padding_ms": 300,
          "silence_duration_ms": 500
        }
      }
    }
  }
}
```
