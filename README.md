
# League Scheduling

A high-performance, feature-rich league scheduling library.

## Table of Contents

- [Requirements](#requirements)
- [Features](#features)
- [Getting started](#getting-started)
- [Contributing](#contributing)

## Requirements

- at least Swift 6.2

## Features

### Scheduling

- [x] 'Fair' scheduling
- [x] Balancing times, locations, and home/away allocations
- [x] Multiple divisions
- [x] Back-to-back matchups
- [x] Flexible game gaps
- [x] Matchup and travel durations
- [x] Time & location availability
- [x] Bye weeks
- [x] Separate game day, division and team settings

### Technical

- [x] Fast, scalable schedule generation
- [x] Protocol Buffers


## Getting Started

<details>

<summary>Swift Package Manager</summary>

1. Add the dependency to your project:

```swift
.package(url: "https://github.com/RandomHashTags/league-scheduling", exact: "0.10.0")
```

2. Use the `LeagueScheduling` product in your target:

```swift
.product(name: "LeagueScheduling", package: "league-scheduling")
````

3. Get your hands on a [`LeagueRequestPayload`](https://github.com/RandomHashTags/league-scheduling/blob/d7bec9d9422427899fc6e53370a84133c437689e/Sources/league-scheduling/generated/RequestPayload.pb.swift) ([protobuf](https://github.com/RandomHashTags/league-scheduling/blob/main/Sources/ProtocolBuffers/RequestPayload.proto)) with the settings you want
    - Supports `Codable` out-of-the-box to make it easy
4. Call [`generate()`](https://github.com/RandomHashTags/league-scheduling/blob/d7bec9d9422427899fc6e53370a84133c437689e/Sources/league-scheduling/generated/extensions/LeagueRequestPayload%2BExtensions.swift#L76) on the request payload

5. Hook up the response to your server/front-end

</details>

## Contributing

This project is owned and maintained by Evan Anderson. All contributions are welcome under the terms of the AGPLv3.