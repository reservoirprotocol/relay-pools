## 🌊 Relay Pools

Relay’s vision for cross chain liquidity is that a network of solvers fill user requests instantly with their own capital. That said, not all cross chain orderflow can be filled by solvers:

- solvers won’t always have enough liquidity, especially for large orders, or long tail chains
- solvers themselves need to rebalance inventory

Today, both of these are solved by canonical bridges:

- for large / exotic requests, users directly use the bridge instead of solver
- solvers use the bridge to rebalance

What’s nice about canonical bridges is that they are low cost and support unlimited size. The main downside is speed, sometimes taking up to 7 days.

We think there is an opportunity for something in the middle. Not everyone who holds capital can run a solver, but they can contribute it to a pool, resulting in more available liquidity. Due to the onchain nature of pools, it’s hard to make them as fast as a solver, but they can definitely be much faster than the canonical bridge. And so you unlock improvements for both users and solvers:

- users get more tolerable speed (30 seconds) when there’s no instant solver liquidity
- solvers can fast rebalance against a pool for higher throughput

While there are already other pool based bridges available (Stargate, Across, etc), the idea is that none of these fully optimize for a world dominated by sophisticated solvers and long tail chains, so there is a big gap in the market.

#### Implementation

The rough idea is that Relay pools are used to “accelerate” any existing bridge:

- users send money over a bridge, but via a proxy contract
- in parallel, a fast message (e.g. via Hyperlane) is sent to the pool on the destination
- the pool immediately gives funds to the user, minus a fee, because it knows that repayment is on the way
- when the bridge completes, the funds arrive in the proxy contract
  - if the pool successfully filled the request, the funds are used to replenish the pool
  - if not, then the funds are given to the user

What’s interesting about this pool design is that effectively 100% of volume is getting rebalanced over a bridge. At first glance, this might seem inefficient, because it’s not able to do “netting” of bi-directional flow, as seen in most pool-based bridges. But this is deliberate. The assumption is that if there’s any netting available, solvers will take it. And the only volume that will come to the pool is the “toxic” orderflow, i.e. the one-directional excess. This design embraces that reality and optimizes for it:

- <b>one-sided pools</b>
  - rather than trying to manage connected pools on two or more chains, and rebalance between them, you can have simple one-sided pools
  - there’s no need to manage how liquidity is allocated between pools on different chains, because each pool is isolated, and 100% of volume replenished back to the pool
  - LPs choose exactly where to allocate liquidity, and get a simple deposit/withdraw UX
  - you can still achieve multi-directional flow by deploying multiple (unrelated) pools on different chains, and composing them at the application layer
- <b>permissionless deployment</b>
  - because pools are isolated, it’s much easier to let anyone deploy them
  - this allows faster expansion to new chains
- <b>yield maximization</b>
  - toxic orderflow tends to come in bursts, when solvers receive more demand than anticipated
  - this means that liquidity is often idle, and can be deployed into other protocols to earn a “base yield” when it’s not in use
  - this also pairs nicely with permissionless deployment, because you can have different pools with different risk / yield profiles

#### Example

- user triggered proxied canonical withdrawal: https://odyssey-explorer.ithaca.xyz/tx/0x155d571ab7ec45119e27207f14e6960f7b454185df2dc2600cd00b1ed5c9e24a
- withdrawal went through the fast path, so the user got their funds almost instantly: https://sepolia.etherscan.io/tx/0xf27e29c7bfccef958e2f090f79eea249b02eaf89d2ccd52b146c9892dd11f1cf
- here's the corresponding cross-chain message relayed via Hyperlane: https://explorer.hyperlane.xyz/message/0xd6d803ad98aba91aca4082e8eae51d848522abef1465614f2e0093556c1c61bf
- once the canonical withdrawal went through, the pool got replenished: https://sepolia.etherscan.io/tx/0xd61e8c31c0498117aa095328b05d6ee29e8ccc04d87792bef4917f8039d576f3
