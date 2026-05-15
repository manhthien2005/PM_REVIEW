# ADR-024: Simulator-web Flow Event WebSocket — Live Sequence Diagram

**Status:** 🟡 Proposed (Redesign 2026-05-15)
**Date:** 2026-05-15
**Decision-maker:** ThienPDM (solo)
**Tags:** [iot-sim, frontend, websocket, demo, ux]
**Resolves:** B3 (Simulator-web UX Mid scope)

## Context

Brainstorm B3 chốt Mid scope cho simulator-web demo UX:
- Status chips per data type
- Sequence diagram Mermaid live render
- Multi-device coordinator (elderly + family panel)
- Demo mode toggle

ADR này focus **WebSocket channel cho flow events** — kết nối real-time giữa IoT sim BE và simulator-web FE để render sequence diagram chạy node-by-node.

**Forces:**
- Persona Charter chốt: panel chấm cần narrative rõ ràng, sequence diagram live impressive
- Current simulator-web SessionRunnerPage thiếu flow visualization
- IoT sim BE đã có `/ws/logs/{session_id}` channel (pattern reusable)
- Mỗi tick + alert + risk eval cần emit event để FE highlight node

**Constraints:**
- WebSocket broadcast: multiple subscriber per session (operator + panel chấm)
- Event volume: tick 5s × N device + alert + risk eval → up to ~10 events/sec peak
- Memory: queue per subscriber, drop nếu slow consumer
- FE render budget: Mermaid update <500ms per event để smooth

**References:**
- Brainstorm B3
- Phase 2 target topology section 5.3 + section 6
- Existing pattern `api_server/ws/log_stream.py`

## Decision

**Chose:** Option A — Add new WebSocket channel `/ws/flow/{session_id}` cho flow events. FE consume + render Mermaid live.

**Why:**
1. **B3 Mid scope chốt** — Charter persona panel chấm demo
2. **Reuse pattern** — `/ws/logs/{session_id}` proven, just add `/ws/flow/{session_id}`
3. **WebSocket appropriate** — desktop browser, persistent connection OK (unlike mobile)
4. **Demo differentiator** — Mermaid live sequence diagram unique cho đồ án
5. **BE event emit minimal cost** — `asyncio.Queue.put_nowait()` overhead nano-second

## Options considered

### Option A (CHOSEN): Dedicated WebSocket `/ws/flow/{session_id}`

**Description:**

**BE side (Phase 7):**

```python
# Iot_Simulator_clean/api_server/ws/flow_stream.py (NEW)
async def handle_ws_flow(websocket: WebSocket, session_id: str):
    await websocket.accept()
    runtime = get_runtime()
    queue = asyncio.Queue(maxsize=100)  # drop if slow consumer
    runtime.subscribe_flow_events(session_id, queue)
    try:
        while True:
            event = await queue.get()
            await websocket.send_json(event)
    except WebSocketDisconnect:
        pass
    finally:
        runtime.unsubscribe_flow_events(session_id, queue)

# api_server/main.py extend
@app.websocket("/ws/flow/{session_id}")
async def ws_flow(websocket: WebSocket, session_id: str) -> None:
    await handle_ws_flow(websocket, session_id)

# api_server/dependencies.py extend SimulatorRuntime
class SimulatorRuntime:
    def __init__(self):
        # ... existing
        self._flow_subscribers: dict[str, list[asyncio.Queue]] = defaultdict(list)
        self._flow_lock = asyncio.Lock()
    
    async def subscribe_flow_events(self, session_id: str, queue: asyncio.Queue):
        async with self._flow_lock:
            self._flow_subscribers[session_id].append(queue)
    
    async def unsubscribe_flow_events(self, session_id: str, queue: asyncio.Queue):
        async with self._flow_lock:
            self._flow_subscribers[session_id].remove(queue)
    
    def publish_flow_event(self, session_id: str, event: dict):
        """Called sync from tick handlers."""
        for queue in self._flow_subscribers.get(session_id, []):
            try:
                queue.put_nowait(event)
            except asyncio.QueueFull:
                logger.debug("Flow event queue full, dropping")
```

**Event emit points:**

```python
# Sample emit points in dependencies.py / services/
def _execute_pending_tick_publish(...):
    # ... HTTP push to BE
    self.publish_flow_event(session_id, {
        "ts": _utc_now_iso(),
        "device_id": ...,
        "step": "vitals_ingest",
        "status": "done" if publish_ok else "error",
        "payload": {"duration_ms": publish_latency_ms, "ack_count": ack_count},
    })

def _publish_alert_to_backend(...):
    self.publish_flow_event(session_id, {
        "step": "alert_push",
        "status": "done",
        "payload": {"severity": severity, "fcm_dispatched": True, "recipients": 2},
    })

# After /telemetry/imu-window response received (Phase 7 flow):
self.publish_flow_event(session_id, {
    "step": "imu_predict",
    "status": "done",
    "payload": {"confidence": 0.95, "label": "fall", "action": "sos_dispatched"},
})
```

**FE side (Phase 7):**

```tsx
// simulator-web/src/components/sequence_diagram/useSequenceFlow.ts
export function useSequenceFlow(sessionId: string) {
  const [events, setEvents] = useState<FlowEvent[]>([]);
  const [activeStep, setActiveStep] = useState<string | null>(null);
  
  useEffect(() => {
    if (!sessionId) return;
    
    const ws = new WebSocket(
      `ws://localhost:8002/ws/flow/${sessionId}`
    );
    
    ws.onmessage = (msg) => {
      const event = JSON.parse(msg.data) as FlowEvent;
      setEvents((prev) => [...prev, event].slice(-100));
      setActiveStep(event.step);
      
      // Auto-clear active after 500ms (animation duration)
      setTimeout(() => setActiveStep(null), 500);
    };
    
    return () => ws.close();
  }, [sessionId]);
  
  return { events, activeStep };
}
```

```tsx
// simulator-web/src/components/sequence_diagram/SequenceDiagramLive.tsx
export function SequenceDiagramLive({ events, activeStep }: Props) {
  const mermaidCode = useMemo(() => buildMermaidFromEvents(events, activeStep), [events, activeStep]);
  
  return <MermaidRenderer code={mermaidCode} />;
}

function buildMermaidFromEvents(events: FlowEvent[], activeStep: string | null): string {
  // Generate sequenceDiagram syntax dynamically
  // Highlight activeStep in different color (CSS class)
  return `
sequenceDiagram
    participant SIM as IoT sim
    participant BE as Mobile BE
    ${events.map(e => `${e.step === activeStep ? '%% ACTIVE' : ''}\nSIM->>BE: ${e.step} (${e.status})`).join('\n')}
  `;
}
```

**Event schema:**

```typescript
type FlowStep = 
  | "vitals_ingest" | "vitals_validation" | "risk_eval" 
  | "imu_push" | "imu_predict" | "fall_persist" | "sos_create"
  | "sleep_push" | "sleep_predict"
  | "alert_push"
  | "fcm_dispatch"
  | "db_insert"
  | "websocket_emit";

type FlowEvent = {
  ts: string;                    // ISO timestamp
  session_id: string;
  device_id: string;
  step: FlowStep;
  status: "pending" | "running" | "done" | "error" | "skipped";
  payload?: Record<string, any>; // step-specific details
};
```

**Pros:**
- Demo dramatic — Mermaid live render
- Operator can debug flow visually
- Pattern reusable cho admin web (future)
- Event emit overhead minimal
- WebSocket OK cho desktop browser

**Cons:**
- New WebSocket channel + event publication infra
- FE Mermaid render library dependency (`react-mermaid2` or similar)
- ~4-5h implement (B3 scope)

**Effort:** M (~4-5h):
- 1h: BE flow_stream.py + SimulatorRuntime extend
- 1h: BE event emit points across handlers
- 1h: FE useSequenceFlow hook
- 1h: FE Mermaid live render component
- 1h: Integration smoke test

### Option B (rejected): Polling REST `/api/v1/sim/sessions/{id}/flow-events`

**Description:** FE poll BE every 500ms for flow events list.

**Pros:**
- No WebSocket complexity
- Simpler error handling

**Cons:**
- Polling 500ms = 2 req/sec sustained → server load
- Latency 500ms-1s lag
- Less smooth animation

**Why rejected:** WebSocket vastly better UX for desktop browser, pattern already proven.

### Option C (rejected): Server-Sent Events (SSE) `/api/v1/sim/sessions/{id}/flow-stream`

**Description:** SSE 1-way streaming.

**Pros:**
- Simpler than WebSocket
- 1-way fits server-push

**Cons:**
- Browser support OK but WebSocket has more libraries
- WebSocket pattern already in IoT sim FE (/ws/logs)
- Consistency over marginal simplicity

**Why rejected:** Reuse existing WebSocket pattern.

### Option D (rejected): Embed flow info trong existing `/ws/logs/{session_id}` channel

**Description:** Multiplex flow events qua log channel với event type discriminator.

**Pros:**
- Reuse channel
- 1 connection

**Cons:**
- Log channel cho log messages, mixed concern
- FE consumer phải filter
- Schema confusion

**Why rejected:** Separation of concerns — flow events distinct purpose.

## Consequences

### Positive
- B3 Mid scope simulator-web UX achieved
- Demo dramatic differentiator
- BE-FE realtime flow visualization
- Future: pattern reusable cho admin ops dashboard
- Debug rich (operator thấy flow chạy)

### Negative / Trade-offs accepted
- New WebSocket channel infra
- ~4-5h effort Phase 7
- FE Mermaid render library
- BE memory: queue per subscriber

### Follow-up actions required
- [ ] Phase 7 slice 1: BE `/ws/flow/{session_id}` endpoint + flow_stream.py
- [ ] Phase 7 slice 2: SimulatorRuntime subscribe/publish flow events
- [ ] Phase 7 slice 3: Event emit points across handlers (tick, alert, risk, FCM)
- [ ] Phase 7 slice 4: FE `useSequenceFlow` hook + `SequenceDiagramLive` component
- [ ] Phase 7 slice 5: FE multi-device coordinator panel
- [ ] Phase 7 slice 6: FE status chips rolling 10 latest
- [ ] Phase 7 slice 7: FE demo mode toggle (polling 3s → 1s)
- [ ] Phase 7 slice 8: Integration smoke test demo flow

## Reverse decision triggers

- Nếu Mermaid render lag >500ms per event → switch to custom canvas-based viz
- Nếu WebSocket flaky → fallback REST polling 500ms
- Nếu event volume >50/sec → consider sampling/throttling

## Related

- Brainstorm B3 (Simulator-web UX Mid)
- Phase 2 topology section 5.3 + section 6
- Existing pattern: `Iot_Simulator_clean/api_server/ws/log_stream.py`
- New components Phase 7:
  - `simulator-web/src/components/sequence_diagram/`
  - `simulator-web/src/components/multi_device/`
  - `simulator-web/src/components/status_chips/`
  - `simulator-web/src/components/demo_mode/`

## Notes

### FE component tree (Phase 7 build)

```
simulator-web/src/pages/SessionRunnerPage.tsx
├── <LinkedProfileCoordinator>
│   ├── <ElderlyDevicePanel>
│   │   ├── DeviceCard
│   │   ├── ScenarioPicker
│   │   ├── ApplyButton
│   │   └── LastTickOutput
│   └── <FamilyDevicePanel>  (read-only)
│       ├── LinkedUserInfo
│       └── FCMStatus
├── <SequenceDiagramLive>
│   └── <MermaidRenderer>
├── <StatusChipsRoll>
│   └── <StatusChipItem> × 10
└── <DemoModeToggle>
```

### Mermaid library evaluation

Em recommend `mermaid` npm package + custom React wrapper (no `react-mermaid2` — outdated):

```ts
// MermaidRenderer.tsx
import { useEffect, useRef } from 'react';
import mermaid from 'mermaid';

mermaid.initialize({ startOnLoad: false, theme: 'default' });

export function MermaidRenderer({ code }: { code: string }) {
  const ref = useRef<HTMLDivElement>(null);
  
  useEffect(() => {
    if (!ref.current) return;
    
    const id = `mermaid-${Date.now()}`;
    mermaid.render(id, code).then(({ svg }) => {
      if (ref.current) ref.current.innerHTML = svg;
    });
  }, [code]);
  
  return <div ref={ref} />;
}
```

### Event volume budget

- Tick 5s × 5 device = 1 event/sec average
- Alert/fall: bursty, ~5 events per alert flow
- Demo mode 1s tick: 5 events/sec peak

Queue size 100 = ~20 seconds buffer cho slow consumer. OK.

### Demo mode toggle scope

Env flag `DEMO_MODE` exposed FE:
- `false` (default): tick 5s, polling 3s — production-realistic
- `true`: tick 1s, polling 1s — demo dramatic

Backend `SimulatorRuntime.demo_mode` setter via `POST /api/v1/sim/settings/demo-mode`.
FE Riverpod / Zustand state subscribe.
