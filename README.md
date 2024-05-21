## AutoBuyContract

a contract that uses any and all native currency it is sent to buy from a Uniswap pool.

---

### To Deploy
1. Install [Foundry](https://book.getfoundry.sh/) - you can get it by following the [instructions here](https://book.getfoundry.sh/getting-started/installation) under the "Use Foundryup" section. Namely:
    - Run `curl -L https://foundry.paradigm.xyz | bash`
    - Run `foundryup`
2. Run `forge create AutoBuyContract --constructor-args <WETH_CONTRACT_ADDRESS> <WETH_UNISWAP_POOL_ADDRESS> --rpc-url <RPC_URL> --private-key <YOUR_PRIVATE_KEY>` where:
    - <WETH_CONTRACT_ADDRESS> = The contract address of the canonical wrapped version of the native currency of the chain you're deploying to
    - <WETH_UNISWAP_POOL_ADDRESS> = The contract address of the Uniswap Pool between the wrapped native currency and the token you want this contract to autobuy (make sure that the wrapped native token is `token0` and the other token is `token1` on that contract, you can check on the pool contract's Etherscan page)
    - <RPC_URL> = An RPC url by which to access the chain you want to deploy to (you can find a bunch of public ones [here](https://github.com/jk-labs-inc/jokerace/tree/staging/packages/react-app-revamp/config/wagmi/custom-chains) if you need)
    - <YOUR_PRIVATE_KEY> = The private key of the wallet (THIS SHOULD BE A HOT WALLET, DO NOT DEPLOY THINGS FROM WALLETS THAT HAVE A LOT OF MONEY IN THEM) you would like to deploy from - there are other ways connect a wallet with forge's `create` command if you'd like to check them out [here](https://book.getfoundry.sh/reference/forge/forge-create) too

Once you deploy, when you send the chain's native currency to this contract, it will take it, auto-buy the token you have configured it to, and then send that token where you have configured it to.
