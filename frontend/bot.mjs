const { ethers } = require("ethers");

const provider = new ethers.providers.JsonRpcProvider(process.env.RPC_URL || "http://127.0.0.1:8545");
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

const ABI = [
    "function borrowers(uint) view returns (address)",
    "function _isHealthy(address) view returns (bool)",
    "function liquidate(address) external",
];

const MARKETS = [
    "0x0000000000000000000000000000000000000003",
    "0x0000000000000000000000000000000000000004",
    "0x0000000000000000000000000000000000000005",
];

async function run() {
    for (const addr of MARKETS) {
        const m = new ethers.Contract(addr, ABI, wallet);
        for (let i = 0; ; i++) {
            let b;
            try { b = await m.borrowers(i); } catch { break; }
            if (!(await m._isHealthy(b))) await (await m.liquidate(b)).wait();
        }
    }
}

console.log("бот запущен");
run();
setInterval(run, 10 * 60 * 1000);