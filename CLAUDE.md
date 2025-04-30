# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands
- Build: `forge build`
- Test all: `forge test`
- Test single: `forge test --match-path test/SpecificTest.t.sol`
- Test with verbosity: `forge test -vvv`
- Format: `forge fmt`
- Deploy script: `forge script script/Counter.s.sol:CounterScript`
- Gas snapshots: `forge snapshot`
- Local node: `anvil`

## Code Style Guidelines
- Use Solidity ^0.8.20
- Follow SPDX license declarations (MIT or UNLICENSED)
- Organize imports: external libraries first, then local imports
- Naming: PascalCase for contracts/interfaces, camelCase for functions/variables
- Use descriptive error messages in require statements
- Emit events for state changes and important operations
- Validate addresses (non-zero) before use
- Use immutable for contract-level constants that don't change
- Format code with `forge fmt` before committing
- Comment complex logic with // comments before functions