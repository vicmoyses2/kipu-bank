# 🏦 KipuBank

**KipuBank** is a simple smart contract that simulates a decentralized bank with a **global deposit cap (`bankCapacity`)** and a **maximum withdrawal limit per transaction**.  
Each user can deposit and withdraw ETH securely, while the total contract balance can never exceed the defined capacity.

---

## 📘 Description

KipuBank allows users to:
- Deposit ETH into their account balance.
- Withdraw ETH up to their personal balance, respecting the per-transaction withdrawal limit.
- Query both their own balance and the total contract balance.

The contract enforces:
- A **global capacity limit** (`i_bankCapacity`) set at deployment.
- A **maximum withdrawal per transaction** (`i_maxWithdrawPerTx`).
- **Reentrancy protection** on withdrawals.
- **Explicit revert reasons** for invalid actions (e.g., insufficient balance, invalid deposit path, exceeding capacity).

All deposits and withdrawals are tracked through emitted events.

---

## ⚙️ Deployment Instructions

### 🧩 1. Using Remix IDE

1. Open [Remix IDE](https://remix.ethereum.org/).
2. Create a new Solidity file, e.g. `KipuBank.sol`, and paste the contract code.
3. Select **Solidity Compiler** → version `0.8.24` and compile.
4. Go to the **Deploy & Run Transactions** tab:
   - Environment: `Injected Provider - MetaMask` (or `Remix VM` for local testing)
   - Enter constructor parameters:
     - `bankCapacity`: maximum total ETH that the contract can hold (e.g. `100 ether`)
     - `maxWithdrawPerTx`: max withdrawal per transaction (e.g. `10 ether`)
5. Click **Deploy** and confirm the transaction in MetaMask.

✅ Once deployed, you will see the contract interface with its public functions.

---

### 🔧 2. Using Foundry (CLI)

Make sure you have [Foundry](https://book.getfoundry.sh/getting-started/installation) installed.

```bash
# Compile
forge build

# Test (if tests are added)
forge test

# Deploy (example using Anvil local network)
forge create --rpc-url http://127.0.0.1:8545   --private-key <YOUR_PRIVATE_KEY>   src/KipuBank.sol:KipuBank   --constructor-args 100000000000000000000 10000000000000000000
```

In this example:
- `100000000000000000000` = 100 ETH (bank capacity)
- `10000000000000000000` = 10 ETH (max withdraw per tx)

---

## 💬 Interaction Guide

After deployment, you can interact directly via **Remix**, **Etherscan**, or **Foundry CLI**.

### 1. Deposit ETH
```solidity
deposit()
```
- Send ETH using the value field in Remix or `--value` in a Foundry call.
- Reverts if the deposit exceeds the global bank capacity.

---

### 2. Withdraw ETH
```solidity
withdraw(uint256 amount)
```
- Withdraw up to your recorded balance.
- Reverts if:
  - Amount > your balance
  - Amount > `i_maxWithdrawPerTx`
  - Amount == 0

---

### 3. Check Balances

- **Contract balance:**
  ```solidity
  getContractBalance()
  ```

- **User balance:**
  ```solidity
  getUserBalance(address user)
  ```

---

### 4. View Counters
- `depositCount` → total successful deposits  
- `withdrawCount` → total successful withdrawals

---

## 🧰 Interaction via Foundry CLI (`cast` commands)

After deploying your contract, export your variables:
```bash
export RPC_URL=http://127.0.0.1:8545
export PRIVATE_KEY=<YOUR_PRIVATE_KEY>
export CONTRACT=<DEPLOYED_CONTRACT_ADDRESS>
export ME=<YOUR_EOA_ADDRESS>
```

### 🔹 Deposit ETH
Deposit 2 ETH to your balance:
```bash
cast send $CONTRACT "deposit()" --value 2ether --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

---

### 🔹 Withdraw ETH
Withdraw 1 ETH from your balance:
```bash
cast send $CONTRACT "withdraw(uint256)" 1000000000000000000 --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```
(`1000000000000000000` = 1 ether in wei)

---

### 🔹 Read Balances
Get the contract’s ETH balance:
```bash
cast call $CONTRACT "getContractBalance()" --rpc-url $RPC_URL
```

Get your user balance:
```bash
cast call $CONTRACT "getUserBalance(address)" $ME --rpc-url $RPC_URL
```

---

### 🔹 View Counters
Get number of deposits:
```bash
cast call $CONTRACT "depositCount()" --rpc-url $RPC_URL
```

Get number of withdrawals:
```bash
cast call $CONTRACT "withdrawCount()" --rpc-url $RPC_URL
```

---

## 🛡️ Security Notes
- The contract includes a **nonReentrant guard** to prevent reentrancy attacks.
- Direct ETH transfers to the contract (`receive`/`fallback`) are **blocked** to enforce deposits only via the `deposit()` function.
- Immutable parameters ensure `bankCapacity` and `maxWithdrawPerTx` cannot be changed after deployment.

---

## 🧑‍💻 Example (Remix)
| Action | Value (ETH) | Input |
|--------|--------------|--------|
| Deploy | — | bankCapacity = 100, maxWithdrawPerTx = 10 |
| Deposit | 2 | Click **deposit()**, value = 2 |
| Withdraw | — | amount = 1 |
| Check balance | — | getUserBalance(your_address) |

---

## 🧾 License
MIT License © 2025  
Developed for educational purposes as part of the **ETH-KIPU** blockchain learning project.