## Solidity Development Template

The first thing you should do is get [Foundry](https://book.getfoundry.sh/) installed.

Do do this, follow the [instructions here](https://book.getfoundry.sh/getting-started/installation) under the "Use Foundryup" section. Namely:
1. Run `curl -L https://foundry.paradigm.xyz | bash` in your terminal.
2. Run `foundryup` in your terminal.

Once that has successfully run, then run `forge build` in the top directory of this repository in your terminal to compile and link all of the code (with the libraries) up.

Once you do this, you are ready to start editing, compiling, testing, and deploying the code in this repository.

Below you can find documentation on how to use forge (the Soldity development framework being used in this repository) and other [Foundry](https://book.getfoundry.sh/) tools available to you after running `foundryup`.

## Foundry Documentation

https://book.getfoundry.sh/

## Foundry Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
