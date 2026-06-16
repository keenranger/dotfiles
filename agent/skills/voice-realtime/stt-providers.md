# Speech-to-Text Providers

## Provider Comparison

| Provider | Model | Korean | Latency | Cost/1000min | Accuracy | Notes |
|----------|-------|--------|---------|--------------|----------|-------|
| OpenAI | gpt-4o-transcribe | Yes | 320ms | $6.00 | Best (8.9% WER) | Highest accuracy |
| Deepgram | nova-3 | Yes (27% improved) | <300ms | $4.30 | High | Fastest, best value |
| Google | chirp_3 | Yes | Medium | Medium | High | Good Korean, reliable |
| CLOVA | - | Excellent | Good | Varies | Very High | Korean-specialized (Naver) |
| AssemblyAI | universal-2 | No (coming) | 270ms | $2.50 | High | Cheapest, no Korean yet |
| ElevenLabs | scribe-v2 | Yes | 150ms | - | Good | Real-time streaming |

## When to Use

### OpenAI gpt-4o-transcribe
- Highest accuracy is critical
- Can tolerate ~320ms latency
- Already in OpenAI ecosystem

### Deepgram Nova-3
- Real-time voice agents (lowest latency)
- Cost-sensitive production
- Korean with good accuracy (27% WER improvement in Nov 2025)

### Google Chirp
- Korean accuracy is important
- Already in Google Cloud ecosystem
- Need enterprise reliability

### CLOVA
- Korean-first application
- Maximum Korean accuracy needed
- Naver ecosystem integration

## Real-world Performance

- Lab conditions: sub-5% WER
- Production (accents, noise): 7-10% WER
- Korean is "Tier 2" accuracy (7-16% WER) for most providers

## Streaming vs Batch

| Provider | Streaming | Interim Results | Best For |
|----------|-----------|-----------------|----------|
| Deepgram | Native | Yes | Real-time voice |
| OpenAI | Available | Limited | High accuracy |
| Google | Available | Yes | Enterprise |

## LiveKit Plugin

```python
# OpenAI (best accuracy)
from livekit.plugins import openai
stt = openai.STT(model="gpt-4o-transcribe", language="ko")

# Deepgram (fastest, best value)
from livekit.plugins import deepgram
stt = deepgram.STT(model="nova-3", language="ko-KR")

# Google (reliable Korean)
from livekit.plugins import google
stt = google.STT(model="chirp_3", languages=["ko-KR"])
```

## Environment Variables

```bash
OPENAI_API_KEY=...      # OpenAI
DEEPGRAM_API_KEY=...    # Deepgram
GOOGLE_API_KEY=...      # Google (or GOOGLE_APPLICATION_CREDENTIALS)
```
