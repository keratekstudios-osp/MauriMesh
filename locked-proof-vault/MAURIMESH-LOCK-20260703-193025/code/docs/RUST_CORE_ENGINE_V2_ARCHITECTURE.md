# MauriMesh Rust Core Engine v2 Architecture

## Purpose

Rust becomes the deterministic, memory-safe, high-performance decision layer for MauriMesh.

Rust enhances:
- packet building
- packet validation
- route scoring
- duplicate/replay blocking
- TTL/hop limit enforcement
- ACK validation
- store-and-forward queue decisions
- simulation ticks
- proof event creation and validation
- runtime truth scoring
- future crypto/PQC layer

## Correct app stack

React Native = UI
TypeScript = orchestration and fallback
Kotlin/Swift = native hardware bridge
Rust = mesh brain
SQLite/MMKV/AsyncStorage = offline memory
Proof Ledger = truth layer
BLE phones = physical proof

## Bad bridge

React Native -> HTTP -> 127.0.0.1:4300

This is not safe for standalone mobile.

## Correct production bridge

React Native -> TypeScript -> Kotlin Native Module -> Rust static library

## Development bridge

React Native -> TypeScript fallback
Replit/API simulation -> Rust CLI optional

## Completion rule

Rust is complete only when the app still works if Rust/native bridge is unavailable.
