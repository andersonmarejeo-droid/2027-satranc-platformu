# Server-authoritative online match contract

The mobile client now has a typed `FirebaseMatchAuthorityClient` boundary and
can switch to `submitOnlineMove` with
`--dart-define=CHESS_SERVER_AUTHORITY_ENABLED=true`. The endpoint contract is:

```json
{
  "matchId": "40 lower-case hex characters",
  "expectedPly": 0,
  "uci": "e2e4",
  "idempotencyKey": "matchId:expectedPly:uci"
}
```

The callable must run in `europe-west3`, require Firebase Auth and App Check,
replay every UCI move with a server chess engine, validate turn ownership,
server time and the 180-second inactivity policy, and commit the move plus an
idempotency record in one Firestore transaction. A successful response is:

```json
{ "accepted": true, "matchId": "...", "ply": 1 }
```

The client refreshes the match snapshot after an accepted response, so the
server remains the only source for clocks, result and terminal state. Duplicate
requests with the same key must return the original accepted result without
appending another move.

## Deployment gate

The existing Firebase project is on the Spark plan. Cloud Functions/Cloud Run
deployment and App Check enforcement remain external release actions until a
billable backend is approved. The Dart adapter is therefore disabled by
default; the Firestore transaction path remains available for the current
closed test binary. Before enabling the flag, deploy the callable, run the
two-device legal/illegal/duplicate/timeout matrix, and then enforce App Check
after observing valid-token traffic.
