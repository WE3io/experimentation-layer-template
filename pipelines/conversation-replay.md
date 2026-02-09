# Conversation Replay Pipeline

**Purpose**  
This document specifies the pipeline for evaluating conversation flow and prompt variants against historical conversation data.

---

## Start Here If…

- **Conversation Evaluation Route** → Core document for this route
- **Understanding evaluation** → Go to [../docs/offline-evaluation.md](../docs/offline-evaluation.md)
- **Running evaluations** → Focus on section 4

---

## 1. Pipeline Overview

```
┌──────────────────────┐     ┌──────────────────────┐     ┌──────────────────────┐
│  Load Historical     │ ──► │  Load Flow/Prompt    │ ──► │  Replay              │
│  Conversations       │     │  Variant              │     │  Conversations       │
│  (Postgres)          │     │  (Registry)          │     │  Per Session         │
└──────────────────────┘     └──────────────────────┘     └──────────────────────┘
                                                                      │
                                                                      ▼
┌──────────────────────┐     ┌──────────────────────┐     ┌──────────────────────┐
│  Store Results       │ ◄── │  Compare vs           │ ◄── │  Compute              │
│  (Postgres)          │     │  Baseline             │     │  Metrics              │
└──────────────────────┘     └──────────────────────┘     └──────────────────────┘
```

---

## 2. Pipeline Steps (Pseudo-code)

### 2.1 Load Historical Conversations

```pseudo
function load_historical_conversations(
    flow_id,
    start_date,
    end_date,
    sample_size=None,
    min_turns=1
):
    # Query conversation events from database
    query = """
        SELECT 
            e.context->>'session_id' as session_id,
            e.context->>'flow_id' as flow_id,
            e.event_type,
            e.timestamp,
            e.payload,
            e.metrics,
            e.context
        FROM exp.events e
        WHERE e.context->>'flow_id' = flow_id
          AND e.event_type IN ('conversation_started', 'message_sent', 'flow_completed', 'user_dropped_off')
          AND e.timestamp BETWEEN start_date AND end_date
        ORDER BY e.context->>'session_id', e.timestamp
    """
    
    events = db.query(query)
    
    # Group events by session
    sessions = group_by_session(events)
    
    # Filter sessions with minimum turn count
    sessions = [s for s in sessions if s.turn_count >= min_turns]
    
    # Sample if needed
    if sample_size and len(sessions) > sample_size:
        sessions = random.sample(sessions, sample_size, random_state=42)
    
    return sessions
```

### 2.2 Load Flow/Prompt Variant

```pseudo
function load_variant_config(variant_id):
    # Get variant from database
    variant = db.query("""
        SELECT v.config, v.experiment_id
        FROM exp.variants v
        WHERE v.id = variant_id
    """)
    
    # Extract prompt and flow configuration
    config = variant.config
    
    if config.execution_strategy == "prompt_template":
        prompt_version_id = config.prompt_config.prompt_version_id
        flow_id = config.flow_config.flow_id
        
        # Load prompt from registry
        prompt = db.query("""
            SELECT pv.file_path, pv.model_provider, pv.model_name, pv.config_defaults
            FROM exp.prompt_versions pv
            WHERE pv.id = prompt_version_id
        """)
        
        # Load prompt content from file system
        prompt_content = read_file(prompt.file_path)
        
        # Load flow definition
        flow = load_flow_definition(flow_id)
        
        return {
            "prompt_content": prompt_content,
            "prompt_config": prompt,
            "flow": flow,
            "params": config.params
        }
    else:
        raise ValueError("Variant must use prompt_template execution strategy")
```

### 2.3 Replay Conversations

```pseudo
function replay_conversation(session, variant_config):
    # Initialize flow orchestrator with variant config
    orchestrator = FlowOrchestrator(
        flow=variant_config.flow,
        prompt_content=variant_config.prompt_content,
        model_provider=variant_config.prompt_config.model_provider,
        model_name=variant_config.prompt_config.model_name,
        params=variant_config.params
    )
    
    # Replay each message from historical session
    results = []
    current_state = variant_config.flow.initial_state
    
    for historical_message in session.messages:
        # Get user input from historical message
        user_input = historical_message.payload.message_text
        
        # Process message through flow orchestrator
        response = orchestrator.process_message(
            session_id=session.session_id,
            message=user_input,
            current_state=current_state
        )
        
        # Track state transitions
        if response.state_transition:
            current_state = response.next_state
        
        # Store replay result
        results.append({
            "turn_number": historical_message.metrics.turn_number,
            "user_input": user_input,
            "bot_response": response.message.text,
            "state": current_state,
            "state_transition": response.state_transition,
            "latency_ms": response.metrics.latency_ms if hasattr(response, 'metrics') else None
        })
        
        # Check if flow completed
        if response.flow_completed:
            break
    
    return {
        "session_id": session.session_id,
        "original_completed": session.completed,
        "replay_completed": response.flow_completed if hasattr(response, 'flow_completed') else False,
        "original_turns": session.turn_count,
        "replay_turns": len(results),
        "results": results
    }
```

### 2.4 Compute Metrics

```pseudo
function compute_metrics(replay_results, original_session):
    metrics = {}
    
    # Completion rate (did replay complete like original?)
    metrics["completion_match"] = (
        1.0 if replay_results.replay_completed == original_session.completed else 0.0
    )
    
    # Turn count difference
    turn_diff = replay_results.replay_turns - original_session.turn_count
    metrics["turn_count_diff"] = turn_diff
    metrics["turn_count_ratio"] = (
        replay_results.replay_turns / original_session.turn_count 
        if original_session.turn_count > 0 else None
    )
    
    # State progression match
    original_states = [m.context.current_state for m in original_session.messages]
    replay_states = [r.state for r in replay_results.results]
    metrics["state_progression_match"] = compute_state_match(original_states, replay_states)
    
    # Average latency
    latencies = [r.latency_ms for r in replay_results.results if r.latency_ms]
    metrics["avg_latency_ms"] = mean(latencies) if latencies else None
    
    # Completion time (if completed)
    if replay_results.replay_completed:
        start_time = replay_results.results[0].timestamp
        end_time = replay_results.results[-1].timestamp
        metrics["completion_time_seconds"] = (end_time - start_time).total_seconds()
    
    # Data collection accuracy (if flow collects data)
    if original_session.data_collected:
        replay_data = extract_collected_data(replay_results.results)
        metrics["data_collection_accuracy"] = compare_data_accuracy(
            original_session.data_collected,
            replay_data
        )
    
    return metrics
```

### 2.5 Compare vs Baseline

```pseudo
function compare_with_baseline(candidate_metrics, baseline_metrics):
    comparison = {
        "completion_match": {
            "candidate": candidate_metrics.completion_match,
            "baseline": baseline_metrics.completion_match,
            "diff": candidate_metrics.completion_match - baseline_metrics.completion_match,
            "passed": candidate_metrics.completion_match >= baseline_metrics.completion_match
        },
        "turn_count_ratio": {
            "candidate": candidate_metrics.turn_count_ratio,
            "baseline": baseline_metrics.turn_count_ratio,
            "diff": candidate_metrics.turn_count_ratio - baseline_metrics.turn_count_ratio,
            # Prefer fewer turns (ratio closer to 1.0 or lower)
            "passed": candidate_metrics.turn_count_ratio <= baseline_metrics.turn_count_ratio * 1.1
        },
        "state_progression_match": {
            "candidate": candidate_metrics.state_progression_match,
            "baseline": baseline_metrics.state_progression_match,
            "diff": candidate_metrics.state_progression_match - baseline_metrics.state_progression_match,
            "passed": candidate_metrics.state_progression_match >= baseline_metrics.state_progression_match
        },
        "avg_latency_ms": {
            "candidate": candidate_metrics.avg_latency_ms,
            "baseline": baseline_metrics.avg_latency_ms,
            "diff": candidate_metrics.avg_latency_ms - baseline_metrics.avg_latency_ms,
            # Prefer lower latency
            "passed": candidate_metrics.avg_latency_ms <= baseline_metrics.avg_latency_ms * 1.2
        }
    }
    
    # Overall pass if majority of metrics pass
    passed_count = sum(1 for m in comparison.values() if m["passed"])
    overall_passed = passed_count >= len(comparison) * 0.7
    
    return {
        "comparison": comparison,
        "passed": overall_passed,
        "passed_ratio": passed_count / len(comparison)
    }
```

### 2.6 Store Results

```pseudo
function store_results(
    variant_id,
    flow_id,
    dataset_version,
    metrics,
    comparison,
    evaluation_run_id
):
    # Store aggregate results (similar to offline_replay_results structure)
    db.insert("exp.conversation_replay_results", {
        "variant_id": variant_id,
        "flow_id": flow_id,
        "dataset_version": dataset_version,
        "evaluation_run_id": evaluation_run_id,
        "completion_match_score": metrics.completion_match,
        "turn_count_ratio": metrics.turn_count_ratio,
        "state_progression_match": metrics.state_progression_match,
        "avg_latency_ms": metrics.avg_latency_ms,
        "completion_time_seconds": metrics.completion_time_seconds,
        "data_collection_accuracy": metrics.data_collection_accuracy,
        "baseline_variant_id": comparison.baseline_variant_id if comparison else None,
        "is_better_than_baseline": comparison.passed if comparison else None,
        "status": "completed"
    })
```

---

## 3. Full Pipeline

```pseudo
function run_conversation_evaluation(
    variant_id,
    flow_id,
    start_date,
    end_date,
    baseline_variant_id=None,
    sample_size=None,
    min_turns=1
):
    # Start evaluation run
    evaluation_run_id = generate_uuid()
    
    # Load historical conversations
    sessions = load_historical_conversations(
        flow_id=flow_id,
        start_date=start_date,
        end_date=end_date,
        sample_size=sample_size,
        min_turns=min_turns
    )
    
    # Load candidate variant config
    candidate_config = load_variant_config(variant_id)
    
    # Load baseline variant config if specified
    baseline_config = None
    if baseline_variant_id:
        baseline_config = load_variant_config(baseline_variant_id)
    
    # Replay each session
    candidate_results = []
    baseline_results = []
    
    for session in sessions:
        # Replay with candidate variant
        candidate_replay = replay_conversation(session, candidate_config)
        candidate_metrics = compute_metrics(candidate_replay, session)
        candidate_results.append(candidate_metrics)
        
        # Replay with baseline variant
        if baseline_config:
            baseline_replay = replay_conversation(session, baseline_config)
            baseline_metrics = compute_metrics(baseline_replay, session)
            baseline_results.append(baseline_metrics)
    
    # Aggregate results
    candidate_aggregate = aggregate_metrics(candidate_results)
    
    # Compare with baseline
    comparison = None
    if baseline_results:
        baseline_aggregate = aggregate_metrics(baseline_results)
        comparison = compare_with_baseline(candidate_aggregate, baseline_aggregate)
    
    # Store results
    dataset_version = f"{flow_id}_{start_date}_{end_date}"
    store_results(
        variant_id=variant_id,
        flow_id=flow_id,
        dataset_version=dataset_version,
        metrics=candidate_aggregate,
        comparison=comparison,
        evaluation_run_id=evaluation_run_id
    )
    
    # Log results
    print(f"\nConversation Replay Evaluation Results:")
    print(f"  Sessions evaluated: {len(sessions)}")
    print(f"  Completion match: {candidate_aggregate.completion_match:.2%}")
    print(f"  Avg turn count ratio: {candidate_aggregate.turn_count_ratio:.2f}")
    print(f"  State progression match: {candidate_aggregate.state_progression_match:.2%}")
    print(f"  Avg latency: {candidate_aggregate.avg_latency_ms:.0f}ms")
    
    if comparison:
        print(f"\n  Comparison with baseline:")
        print(f"    Passed: {comparison.passed}")
        print(f"    Pass ratio: {comparison.passed_ratio:.2%}")
    
    return {
        "metrics": candidate_aggregate,
        "comparison": comparison,
        "evaluation_run_id": evaluation_run_id
    }
```

---

## 4. Running the Pipeline

### 4.1 Command Line

```bash
python pipelines/conversation_replay.py \
    --variant_id 660e8400-e29b-41d4-a716-446655440001 \
    --flow_id user_onboarding \
    --start_date 2025-01-01 \
    --end_date 2025-01-31 \
    --baseline_variant_id 550e8400-e29b-41d4-a716-446655440000 \
    --sample_size 100 \
    --min_turns 3
```

### 4.2 Script Template

```pseudo
# pipelines/conversation_replay.py

import argparse
from datetime import datetime

def main():
    parser = argparse.ArgumentParser(description="Replay historical conversations against variant")
    parser.add_argument("--variant_id", required=True, help="Variant ID to evaluate")
    parser.add_argument("--flow_id", required=True, help="Flow ID to evaluate")
    parser.add_argument("--start_date", required=True, help="Start date (YYYY-MM-DD)")
    parser.add_argument("--end_date", required=True, help="End date (YYYY-MM-DD)")
    parser.add_argument("--baseline_variant_id", help="Baseline variant ID for comparison")
    parser.add_argument("--sample_size", type=int, help="Number of sessions to sample")
    parser.add_argument("--min_turns", type=int, default=1, help="Minimum turns per session")
    
    args = parser.parse_args()
    
    start_date = datetime.fromisoformat(args.start_date)
    end_date = datetime.fromisoformat(args.end_date)
    
    result = run_conversation_evaluation(
        variant_id=args.variant_id,
        flow_id=args.flow_id,
        start_date=start_date,
        end_date=end_date,
        baseline_variant_id=args.baseline_variant_id,
        sample_size=args.sample_size,
        min_turns=args.min_turns
    )
    
    print(f"\nEvaluation completed: {result['evaluation_run_id']}")

if __name__ == "__main__":
    main()
```

---

## 5. Input Data Sources

### 5.1 Historical Conversations

Historical conversations are loaded from `exp.events` table:
- Filter by `flow_id` in `context.flow_id`
- Filter by event types: `conversation_started`, `message_sent`, `flow_completed`, `user_dropped_off`
- Group events by `session_id` in `context.session_id`
- Order events chronologically within each session

### 5.2 Session Structure

Each historical session contains:
- `session_id`: Unique session identifier
- `flow_id`: Flow that was executed
- `messages`: Chronological list of events
- `completed`: Boolean indicating if flow completed
- `turn_count`: Number of message exchanges
- `data_collected`: Data collected during conversation (if applicable)

---

## 6. Evaluation Metrics

### 6.1 Completion Match

**Definition**: Whether the replay completed in the same way as the original conversation.

**Calculation**: 
- `1.0` if both completed or both dropped off
- `0.0` if one completed and the other dropped off

**Use case**: Primary indicator of flow behavior consistency

### 6.2 Turn Count Ratio

**Definition**: Ratio of replay turn count to original turn count.

**Calculation**: `replay_turns / original_turns`

**Use case**: Measure conversation efficiency (lower is better, closer to 1.0 is ideal)

### 6.3 State Progression Match

**Definition**: How well the replay matches the original state progression.

**Calculation**: Sequence alignment score comparing state sequences

**Use case**: Measure flow logic consistency

### 6.4 Average Latency

**Definition**: Average response time per message in the replay.

**Calculation**: `AVG(latency_ms)` across all replay messages

**Use case**: Performance monitoring

### 6.5 Completion Time

**Definition**: Total time from start to completion (if completed).

**Calculation**: `end_timestamp - start_timestamp`

**Use case**: User experience measurement

### 6.6 Data Collection Accuracy

**Definition**: Accuracy of data collected during replay compared to original (if applicable).

**Calculation**: Field-by-field comparison of collected data

**Use case**: Validate data collection flows

---

## 7. Comparison Logic

### 7.1 Baseline Comparison

When a baseline variant is specified:
- Replay same sessions with baseline variant
- Compare metrics between candidate and baseline
- Determine if candidate is "better" than baseline

### 7.2 Pass Criteria

A variant passes evaluation if:
- **Completion match**: ≥ baseline (maintains completion behavior)
- **Turn count ratio**: ≤ baseline * 1.1 (not significantly worse)
- **State progression match**: ≥ baseline (maintains flow logic)
- **Average latency**: ≤ baseline * 1.2 (not significantly slower)

**Overall pass**: At least 70% of metrics pass

---

## 8. Output Format

### 8.1 Database Results

Results stored in `exp.conversation_replay_results` table:
- `variant_id`: Evaluated variant
- `flow_id`: Flow that was evaluated
- `dataset_version`: Identifier for historical dataset used
- `completion_match_score`: Aggregate completion match
- `turn_count_ratio`: Aggregate turn count ratio
- `state_progression_match`: Aggregate state progression match
- `avg_latency_ms`: Average latency
- `completion_time_seconds`: Average completion time
- `data_collection_accuracy`: Data collection accuracy (if applicable)
- `baseline_variant_id`: Baseline variant (if compared)
- `is_better_than_baseline`: Boolean pass/fail result
- `status`: Evaluation status

### 8.2 Evaluation Report

Pipeline outputs:
- Aggregate metrics summary
- Per-session detailed results (optional)
- Comparison with baseline (if provided)
- Pass/fail determination

---

## 9. Acceptance Criteria

### 9.1 Hard Requirements

| Criterion | Requirement |
|-----------|-------------|
| Completion match | ≥ 80% (maintains completion behavior) |

### 9.2 Comparison Requirements

| Criterion | Requirement |
|-----------|-------------|
| Turn count ratio | ≤ baseline * 1.1 |
| State progression match | ≥ baseline |
| Average latency | ≤ baseline * 1.2 |

---

## 10. TODO: Implementation Notes

- [ ] Implement conversation replay logic in Flow Orchestrator
- [ ] Add state progression matching algorithm
- [ ] Implement data collection accuracy comparison
- [ ] Create `exp.conversation_replay_results` table schema
- [ ] Add CLI interface
- [ ] Configure parallel processing for large session sets
- [ ] Add detailed per-session result storage (optional)

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| [../docs/offline-evaluation.md](../docs/offline-evaluation.md) | Evaluation concepts |
| [../services/flow-orchestrator/API_SPEC.md](../services/flow-orchestrator/API_SPEC.md) | Flow orchestrator API |
| [../services/flow-orchestrator/DESIGN.md](../services/flow-orchestrator/DESIGN.md) | Flow orchestrator design |
