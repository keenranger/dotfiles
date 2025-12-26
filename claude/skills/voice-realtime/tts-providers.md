# Text-to-Speech Providers

## Provider Comparison

| Provider | Korean | Latency | Quality | Cost | Notes |
|----------|--------|---------|---------|------|-------|
| OpenAI | Yes | ~200ms | Good | $6/1M chars | Simple, 13 voices |
| ElevenLabs | Yes | ~75ms | Excellent | Higher | Best quality, emotion |
| Cartesia | Alpha | ~40ms | Very Good | Medium | Lowest latency |
| Google Cloud | Yes | Medium | Good | $4/1M chars | 16 Korean voices, cheapest |
| Gemini (beta) | TBD | ~200ms | Good | Free tier | Controllable via instructions |

## When to Use

### OpenAI TTS
- Simple setup needed
- Standard quality acceptable
- Already using OpenAI

### ElevenLabs
- Premium voice quality required
- Voice cloning needed
- ~75ms latency acceptable

### Cartesia Sonic-3
- Ultra-low latency critical (<40ms)
- Real-time interruption handling
- Korean support still alpha

### Google Cloud TTS
- Cost is primary concern
- Need Korean voice variety (16 voices)
- Enterprise reliability required

### Gemini TTS (beta)
- Want style control via instructions
- Integrated with Gemini pipeline
- Experimental use case

## Korean Voice Options

### Google Cloud TTS (16 voices)
```
# Standard (cost-efficient)
ko-KR-Standard-A (Female)
ko-KR-Standard-B (Female)
ko-KR-Standard-C (Male)
ko-KR-Standard-D (Male)

# Chirp3 HD Premium (12 voices)
Achernar, Aoede, Autonoe, Callirrhoe, Despina (Female)
Achird, Algenib, Algieba, Alnilam, Charon, Enceladus, Zubenelgenubi (Male)
```

### ElevenLabs
- Use Multilingual v2 or Flash v2.5 model
- Officially expanded to Korea market
- Voice cloning available for custom Korean voice

## LiveKit Plugin

```python
# OpenAI (simple)
from livekit.plugins import openai
tts = openai.TTS(voice="nova")

# ElevenLabs (best quality)
from livekit.plugins import elevenlabs
tts = elevenlabs.TTS(
    voice_id="your-voice-id",
    model="eleven_multilingual_v2",
)

# Cartesia (lowest latency)
from livekit.plugins import cartesia
tts = cartesia.TTS(voice_id="your-voice-id")

# Google Cloud (cost-effective Korean)
from livekit.plugins import google
tts = google.TTS(language="ko-KR", voice_name="ko-KR-Standard-A")

# Gemini (controllable style)
from livekit.plugins import google
tts = google.beta.GeminiTTS(
    model="gemini-2.5-flash-preview-tts",
    voice_name="Zephyr",
    instructions="Speak in a friendly and calm tone.",
)
```

## Environment Variables

```bash
OPENAI_API_KEY=...           # OpenAI
ELEVEN_API_KEY=...           # ElevenLabs
CARTESIA_API_KEY=...         # Cartesia
GOOGLE_API_KEY=...           # Google/Gemini
GOOGLE_APPLICATION_CREDENTIALS=... # Google Cloud (file path)
```
