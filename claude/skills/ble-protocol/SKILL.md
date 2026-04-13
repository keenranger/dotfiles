---
name: ble-protocol
description: BLE protocol debugging -- HCI snoop capture, tshark packet analysis, GATT handle reverse engineering, SMP pairing troubleshooting. Use when debugging BLE bonding failures, analyzing BLE traffic, reverse engineering BLE device protocols, or working with Android BLE stack issues.
user-invocable: false
---

# BLE Protocol Debugging

## HCI Snoop Capture

### Enable

Settings > Developer options > Enable Bluetooth HCI snoop log (toggle ON).
`adb shell settings put` alone may not work on Samsung -- must use UI toggle.
Bluetooth off/on after enabling to start fresh log.

### Extract

```bash
adb bugreport output.zip
unzip output.zip -d output
find output -name "btsnoop_hci*"
# Typical: FS/data/log/bt/btsnoop_hci.log
```

### Analyze with tshark

```bash
brew install wireshark  # includes tshark

# SMP pairing packets (full decode)
tshark -r btsnoop_hci.log -Y "btsmp" -V

# ATT operations table
tshark -r btsnoop_hci.log -Y "btatt" -T fields \
  -e frame.number -e frame.time_relative -e btatt.opcode \
  -e btatt.handle -e btatt.value -E header=y -E separator='|'

# Filter around specific frame
tshark -r btsnoop_hci.log -Y "btatt && frame.number > 420 && frame.number < 440" -V
```

### Key ATT Opcodes

| Opcode | Name |
|--------|------|
| 0x0a | Read Request |
| 0x0b | Read Response |
| 0x12 | Write Request |
| 0x13 | Write Response |
| 0x52 | Write Command (no response) |
| 0x1b | Notification |
| 0x01 | Error Response |

## GATT Handle Reverse Engineering

When GATT discovery is cached, snoop won't have handle-UUID mapping. To resolve unknown handles:

### Handle Allocation Rules

```
Service declaration:        1 handle
Characteristic declaration: 1 handle
Characteristic value:       1 handle
CCCD descriptor:            +1 handle (only if Notify or Indicate bit set)
```

### Property Bit Decoding

```
0x02: Read
0x04: Write Without Response
0x08: Write
0x10: Notify    -> CCCD +1 handle
0x20: Indicate  -> CCCD +1 handle
```

Example: properties=30 (0x1E) = Read + WriteNR + Write + Notify -> has CCCD

### Cross-Reference Method

1. Get full service/characteristic list from app logcat (UUIDs + properties)
2. Count handles per characteristic using rules above
3. Find anchor points: read a handle in snoop, decode hex value, match to known data (e.g., device name, model string)
4. Count forward/backward from anchors to identify unknown handles

## SMP Pairing Debugging

### Common Failure Codes

| Code | Meaning |
|------|---------|
| fail_reason=83 | SMP_PAIR_AUTH_FAIL (0x50 + 0x03): auth requirements mismatch |
| status=137 | GATT_INSUFFICIENT_ENCRYPTION |
| status=5 | GATT_INSUFFICIENT_AUTHENTICATION |
| HCI reason=14 | HOST_REJECT_SECURITY: local stack rejecting, not remote device |

### SMP Pairing Request Fields

- IO Capability: NoIO(0x03), KeyboardDisplay(0x04), etc.
- AuthReq: Bonding(0x01), MITM(0x04), Secure Connections(0x08), CT2(0x20)
- Key Distribution: LTK(0x01), IRK(0x02), CSRK(0x04), LinkKey(0x08)

### Android Auto-Pairing (Android 8+)

Reading an encrypted characteristic returns status 137/5. Android auto-initiates SMP, shows system dialog, retries read on success. In `onCharacteristicRead`: do NOT consume continuation on 137/5 -- let the retry deliver the result.

### createBond Gotchas

- `createBond()` uses TRANSPORT_AUTO -- may fail for LE devices
- `createBond(TRANSPORT_LE)` via reflection: `device.javaClass.getMethod("createBond", Int::class.javaPrimitiveType).invoke(device, 2)`
- `removeBond()` via reflection: `device.javaClass.getMethod("removeBond").invoke(device)`
- Samsung: GATT may drop during bonding -- reconnect after bond completes

## Debugging Approach

When BLE bonding fails:

1. **Logcat first**: check `onCharacteristicRead` status codes, bond state transitions
2. **Compare with working app**: if another app works, capture both logcats, find the divergence point
3. **HCI snoop**: capture from working app, analyze SMP parameters and ATT sequence before bonding
4. **Reverse engineer**: map handles to UUIDs, identify proprietary writes/reads before SMP starts
5. **Implement and verify**: replicate the exact ATT sequence, test
