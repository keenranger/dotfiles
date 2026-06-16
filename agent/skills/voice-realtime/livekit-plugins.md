# LiveKit Agents Plugins

## Installation

```bash
# Core with common plugins
pip install "livekit-agents[openai,google,silero,turn-detector]~=1.3"

# Additional STT/TTS plugins (as needed)
pip install livekit-plugins-deepgram
pip install livekit-plugins-elevenlabs
pip install livekit-plugins-cartesia
```

## Voice Agent Pattern

```python
from livekit.agents import AgentSession, JobContext, cli
from livekit.plugins import openai, silero
from livekit.plugins.turn_detector.multilingual import MultilingualModel

async def entrypoint(ctx: JobContext):
    await ctx.connect()

    session = AgentSession(
        stt=openai.STT(model="gpt-4o-transcribe", language="ko"),
        llm=openai.LLM(model="gpt-4o"),
        tts=openai.TTS(voice="nova"),
        vad=silero.VAD.load(),
        turn_detection=MultilingualModel(),
    )

    await session.start(ctx.room)

if __name__ == "__main__":
    cli.run_app(entrypoint)
```

## STT Plugin Examples

### OpenAI (highest accuracy)
```python
from livekit.plugins import openai

stt = openai.STT(
    model="gpt-4o-transcribe",  # or "gpt-4o-mini-transcribe"
    language="ko",  # ISO-639-1
)
```

### Deepgram (fastest, best value)
```python
from livekit.plugins import deepgram

stt = deepgram.STT(
    model="nova-3",
    language="ko-KR",
    interim_results=True,
)
```

### Google (reliable Korean)
```python
from livekit.plugins import google

stt = google.STT(
    model="chirp_3",
    languages=["ko-KR"],
    spoken_punctuation=False,
)
```

## TTS Plugin Examples

### OpenAI
```python
from livekit.plugins import openai

tts = openai.TTS(voice="nova")  # 13 voices: alloy, ash, ballad, coral, echo, fable, onyx, nova, sage, shimmer, verse, marin, cedar
```

### ElevenLabs (best quality)
```python
from livekit.plugins import elevenlabs

tts = elevenlabs.TTS(
    voice_id="your-voice-id",
    model="eleven_multilingual_v2",
)
```

### Cartesia (lowest latency ~40ms)
```python
from livekit.plugins import cartesia

tts = cartesia.TTS(voice_id="your-voice-id")
```

### Google Cloud (cost-effective Korean)
```python
from livekit.plugins import google

tts = google.TTS(
    language="ko-KR",
    voice_name="ko-KR-Standard-A",
)
```

### Gemini TTS (controllable style)
```python
from livekit.plugins import google

tts = google.beta.GeminiTTS(
    model="gemini-2.5-flash-preview-tts",
    voice_name="Zephyr",
    instructions="Speak in a friendly and calm tone.",
)
```

## VAD Configuration

Silero VAD (Voice Activity Detection):

```python
from livekit.plugins import silero

vad = silero.VAD.load(
    min_speech_duration=0.05,      # Min speech to start (seconds)
    min_silence_duration=0.55,     # Silence to confirm end
    activation_threshold=0.5,       # Speech probability (0-1)
    sample_rate=16000,             # 8000 or 16000 Hz
    prefix_padding_duration=0.5,   # Audio padding before speech
)
```

Resource: ~400MB RAM, runs on CPU.

## Turn Detection

MultilingualModel for context-aware turn detection:

```python
from livekit.plugins.turn_detector.multilingual import MultilingualModel

turn_detection = MultilingualModel()
```

- 14 languages: EN, ES, FR, DE, IT, PT, NL, ZH, JA, KO, ID, TR, RU, HI
- 99.3-99.4% true positive, 85.1-96.3% true negative
- Latency: 50-160ms per turn
- Resource: ~396MB model

**Why both VAD + turn detector:**
- VAD: detects speech vs silence (acoustic)
- Turn detector: understands when user finished (semantic)
- Prevents interrupting during natural pauses like "I need to think..."

## LangChain Integration

```python
from livekit.plugins import langchain

session = AgentSession(
    llm=langchain.LLMAdapter(graph=your_langgraph_workflow),
    stt=...,
    tts=...,
)
```

## Common Patterns

### Language-based provider switching
```python
def get_stt_for_language(language: str):
    if language == "ko":
        return deepgram.STT(model="nova-3", language="ko-KR")
    return openai.STT(model="gpt-4o-transcribe", language=language)
```

### Fallback on error
```python
async def transcribe_with_fallback(audio):
    try:
        return await primary_stt.transcribe(audio)
    except Exception:
        return await fallback_stt.transcribe(audio)
```

## Environment Variables

```bash
# LiveKit
LIVEKIT_API_KEY=...
LIVEKIT_API_SECRET=...
LIVEKIT_URL=wss://your-project.livekit.cloud

# Providers
OPENAI_API_KEY=...
DEEPGRAM_API_KEY=...
ELEVEN_API_KEY=...
CARTESIA_API_KEY=...
GOOGLE_API_KEY=...
GOOGLE_APPLICATION_CREDENTIALS=/path/to/credentials.json
```
