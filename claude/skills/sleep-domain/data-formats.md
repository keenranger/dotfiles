# Sleep Data Formats

## Hypnogram Data

Array of sleep stages at regular intervals (typically 30-second epochs).

```
stages: [0, 0, 1, 1, 2, 2, 2, 3, 3, 2, 4, 4, 4, ...]
```

Stage encoding may vary by system.

## Insight Formats

### V1 Format (Legacy)
Flat category structure.

### V2 Format (Current)
5-category structure for stage insights:
- Structured categories
- Widget transformation support
- AI summary integration

When migrating V1 to V2: ensure proper category mapping.

## HealthKit Integration

Converting HealthKit sleep data to Asleep hypnogram format:
- HealthKit uses different stage classifications
- Time zone handling is critical
- Map HealthKit stages to internal representation

## Timezone Handling

- Sessions stored with `created_timezone`
- Display should respect user's current timezone OR session timezone
- Be explicit about which timezone is used for display
