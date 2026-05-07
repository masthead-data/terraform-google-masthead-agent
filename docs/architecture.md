# Architecture

## Project Mode

```text
┌─────────────────────────────────────┐
│        Single GCP Project           │
│                                     │
│  ┌──────────────┐  ┌─────────────┐  │
│  │ Log Sinks    │→ │   Pub/Sub   │  │
│  │ (Project)    │  │   Topics    │  │
│  └──────────────┘  └─────────────┘  │
│         ↓                ↓          │
│  ┌──────────────────────────────┐   │
│  │       IAM Bindings           │   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
```

- IAM bindings applied at the **project level**
- Log sinks created at the **project level**
- All resources in one project

## Organization Mode

```text
┌────────────────────────────────────────┐
│        GCP Folder(s) (optional)        │
│  ┌──────────────────────────────────┐  │
│  │  All Child Projects              │  │
│  └──────────────────────────────────┘  │
│              ↓                         │
│  ┌──────────────────────────────────┐  │
│  │  Folder-Level Log Sinks          │  │
│  │  + IAM Bindings (inherited)      │  │
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘
              ↓
┌────────────────────────────────────────┐
│     Additional Projects (optional)     │
│  ┌──────────────────────────────────┐  │
│  │  Project-Level Log Sinks         │  │
│  │  + IAM Bindings                  │  │
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘
              ↓
┌────────────────────────────────────────┐
│           Deployment Project           │
│  ┌──────────────────────────────────┐  │
│  │  Centralized Pub/Sub Topics      │  │
│  │  + Subscriptions                 │  │
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘
```

- **For folders**: IAM bindings applied at **folder level** (inherited by all child projects)
- **For folders**: Log sinks created at **folder level**
- **For additional projects**: IAM bindings and log sinks applied at **project level**
- Centralized Pub/Sub in deployment project
